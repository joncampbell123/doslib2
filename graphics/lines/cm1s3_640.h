
#define WIDTH 640
#define HEIGHT 480

#define pageflip()

static unsigned char current_bank = 0;
static unsigned char vbeinfo[256];
#if TARGET_BITS == 16
static unsigned char far *VRAM = MK_FP(0xA000,0x0000);
#else
static unsigned char *VRAM = (unsigned char*)0xA0000;
#endif

static void setup_graphics() {
	unsigned short i=0;
	unsigned char t;

	__asm {
		mov	ax,0x4F02
		mov	bx,0x101		; 640x480x256
		int	10h
		mov	ax,i
	}

	if ((i&0xFF00) != 0) {
		__asm {
			mov	ax,3
			int	10h
		}
		printf("Failed to set VESA BIOS 640x480x256 mode\n");
		exit(0);
	}

#if TARGET_BITS == 16
	__asm {
		mov	ax,0x4F01
		mov	cx,0x101
		mov	di,seg vbeinfo
		mov	es,di
		mov	di,offset vbeinfo
		int	10h
		mov	i,ax
	}
#else
	__asm {
		mov	ax,0x4F01
		mov	cx,0x101
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

	/* make sure banked mode is on */
	outp(0x3D4,0x31);
	t = inp(0x3D5);
	outp(0x3D5,t | 1);
}

static void unsetup_graphics() {
	__asm {
		mov	ax,3
		int	10h
	}
}

static inline void bank_switch(unsigned char n) {
	unsigned char t;

	outp(0x3D4,0x35); t = inp(0x3D5);
	outp(0x3D5,(t&0xF0) | (n&0xF));

	outp(0x3D4,0x51); t = inp(0x3D5);
	outp(0x3D5,(t&(~0x0C)) | (((n>>4)&0x3)<<2));

	outp(0x3D4,0x6A); t = inp(0x3D5);
	outp(0x3D5,n&0x7F);

	current_bank = n;
}

static void clear_screen() {
	unsigned int banks;

	for (banks=0;banks < 5;banks++) {
		bank_switch(banks);
#if TARGET_BITS == 16
		_fmemset(VRAM,0,0xFFF0);
		_fmemset(VRAM+0xFFF0UL,0,0x10);
#else
		memset(VRAM,0,0x10000);
#endif
	}
}

static inline void plot(int x,unsigned int y,unsigned char pixel) {
	unsigned int off;

	{
		unsigned long o = (((unsigned long)y) * 640UL) + (unsigned long)x;
		unsigned char bank = (unsigned char)(o >> 16UL);
		off = (unsigned int)o & 0xFFFFU;

		if (bank != current_bank)
			bank_switch(bank);
	}

	VRAM[off] = pixel;
}

