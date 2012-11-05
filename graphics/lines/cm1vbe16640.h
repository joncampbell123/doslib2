
#define WIDTH 640
#define HEIGHT 480

#define pageflip()

static unsigned char bankto64 = 0;
static unsigned char current_bank = 0;
static unsigned char vbeinfo[256];
#if TARGET_BITS == 16
static unsigned short far *VRAM = MK_FP(0xA000,0x0000);
#else
static unsigned short *VRAM = (unsigned short*)0xA0000;
#endif

static void setup_graphics() {
	unsigned short i=0;

	__asm {
		mov	ax,0x4F02
		mov	bx,0x110		; 640x480x16-bit
		int	10h
		mov	ax,i
	}

	if ((i&0xFF00) != 0) {
		__asm {
			mov	ax,3
			int	10h
		}
		printf("Failed to set VESA BIOS 640x480x16-bit mode\n");
		exit(0);
	}

#if TARGET_BITS == 16
	__asm {
		mov	ax,0x4F01
		mov	cx,0x110
		mov	di,seg vbeinfo
		mov	es,di
		mov	di,offset vbeinfo
		int	10h
		mov	i,ax
	}
#else
	__asm {
		mov	ax,0x4F01
		mov	cx,0x110
		mov	di,seg vbeinfo
		mov	es,di
		mov	edi,offset vbeinfo
		int	10h
		mov	i,ax
	}
#endif
	if ((i&0xFF00) != 0) {
		__asm {
			mov	ax,3
			int	10h
		}
		printf("Failed to get VBE info\n");
		exit(0);
	}

	/* TODO: Look at window size/granularity and compute how much we must shift up
	 *       to convert bank number to 64KB banks */
}

static void unsetup_graphics() {
	__asm {
		mov	ax,3
		int	10h
	}
}

static inline void bank_switch(unsigned char n) {
	n <<= bankto64;

	__asm {
		mov	ax,0x4F05		; set window
		mov	bx,0x0000		; window A
		mov	dl,n
		xor	dh,dh
		int	10h
	}

	current_bank = n;
}

static void clear_screen() {
	unsigned int banks;

	for (banks=0;banks < 10;banks++) {
		bank_switch(banks);
#if TARGET_BITS == 16
		_fmemset(VRAM,0,0xFFF0);
		_fmemset(VRAM+(0xFFF0UL>>1UL),0,0x10);
#else
		memset(VRAM,0,0x10000);
#endif
	}
}

static inline void plot(int x,unsigned int y,unsigned char pixel) {
	unsigned int off;

	{
		unsigned long o = (((unsigned long)y) * 640UL) + (unsigned long)x;
		unsigned char bank = (unsigned char)(o >> 15UL);
		off = (unsigned int)o & 0x7FFFU;

		if (bank != current_bank)
			bank_switch(bank);
	}

	VRAM[off] = pixel?0xFFFF:0x0000;
}

