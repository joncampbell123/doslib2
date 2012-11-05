
#define WIDTH 640
#define HEIGHT 480

#define pageflip()

static unsigned char current_bank = 0;
#if TARGET_BITS == 16
static unsigned char far *VRAM = MK_FP(0xA000,0x0000);
#else
static unsigned char *VRAM = (unsigned char*)0xA0000;
#endif

static void setup_graphics() {
	unsigned char t=0;

	/* TODO: Detection routine */

	__asm {
		mov	ax,0x5F
		int	10h

		mov	ah,0x0F
		int	10h
		mov	t,al
	}

	if (t != 0x5F) {
		__asm {
			mov	ax,3
			int	10h
		}

		printf("Unable to set Paradise 640x480x256 graphics mode\n");
		exit(0);
	}

	/* enable extensions */
	outpw(0x3CE,0x050F);
	outpw(0x3D4,0x8529);
	outpw(0x3C4,0x4806);

	/* single paging mode */
	outp(0x3C4,0x11);
	outp(0x3C5,inp(0x3C5) & 0x7F);
	outp(0x3C4,0x0B);
	outp(0x3C5,inp(0x3C5) & 0xF7);
}

static void unsetup_graphics() {
	__asm {
		mov	ax,3
		int	10h
	}
}

static inline void tseng_bankswitch(unsigned char n) {
	outpw(0x3CE,(n << 12) + 0x09);
	current_bank = n;
}

static void clear_screen() {
	unsigned int banks;

	for (banks=0;banks < 5;banks++) {
		tseng_bankswitch(banks);
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
			tseng_bankswitch(bank);
	}

	VRAM[off] = pixel;
}

