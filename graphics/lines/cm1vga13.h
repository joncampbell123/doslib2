
#define WIDTH 320
#define HEIGHT 200

#define pageflip()

#if TARGET_BITS == 16
static unsigned char far *VRAM = MK_FP(0xA000,0x0000);
#else
static unsigned char *VRAM = (unsigned char*)0xA0000;
#endif

static void setup_graphics() {
	__asm {
		mov	ax,19
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
	_fmemset(VRAM,0,320*200);
#else
	memset(VRAM,0,320*200);
#endif
}

static inline void plot(int x,unsigned int y,unsigned char pixel) {
	VRAM[(y * 320U) + x] = pixel;
}

