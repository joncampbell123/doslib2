
#define WIDTH 320
#define HEIGHT 200

#define pageflip()

#if TARGET_BITS == 16
static unsigned char far *VRAM = MK_FP(0xB800,0x0000);
#else
static unsigned char *VRAM = (unsigned char*)0xB8000;
#endif

static void setup_graphics() {
	__asm {
		mov	ax,4
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
	_fmemset((unsigned char far*)VRAM,0,16384);
#else
	memset((unsigned char*)VRAM,0,80*16384);
#endif
}

static inline void plot(int x,unsigned int y,unsigned char pixel) {
	unsigned char mask,tmp;
	unsigned int o;

	mask = 0xC0 >> ((x & 3U) * 2U); x >>= 2;
	o = ((y>>1U) * 80U) + x + ((y&1U) << 13U);

	/* then write our pixel data */
	tmp = VRAM[o];
	if (pixel) tmp |= mask;
	else tmp &= ~mask;
	VRAM[o] = tmp;
}

