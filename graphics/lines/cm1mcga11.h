
#define WIDTH 640
#define HEIGHT 480

#if TARGET_BITS == 16
static unsigned char far *VRAM = MK_FP(0xA000,0x0000);
#else
static unsigned char *VRAM = (unsigned char*)0xA0000;
#endif

static void setup_graphics() {
	__asm {
		mov	ax,18
		int	10h
	}
}

static void unsetup_graphics() {
	__asm {
		mov	ax,3
		int	10h
	}
}

static void clear_screen() {
#if TARGET_BITS == 16
	_fmemset((unsigned char far*)VRAM,0,80*480);
#else
	memset((unsigned char*)VRAM,0,80*480);
#endif
}

static inline void plot(int x,unsigned int y,unsigned char pixel) {
	unsigned char mask,tmp;
	unsigned int o;

	mask = 0x80 >> (x & 7); x >>= 3;
	o = (y * 80U) + x;

	/* then write our pixel data */
	tmp = VRAM[o];
	if (pixel) tmp |= mask;
	else tmp &= ~mask;
	VRAM[o] = tmp;
}

