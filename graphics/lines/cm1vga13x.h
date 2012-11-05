
#define WIDTH 320
#define HEIGHT 200

#define pageflip()

static unsigned short		crtc_address = 0x3D0;
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

#if TARGET_BITS == 16
	if ((*((unsigned short far*)MK_FP(0x0040,0x63)) & 0xFF0) == 0x3B0)
		crtc_address = 0x3B0;
#else
	if ((*((unsigned short*)(0x00400 + 0x63)) & 0xFF0) == 0x3B0)
		crtc_address = 0x3B0;
#endif

	outp(0x3C4,0x04);
	outp(0x3C5,0x06);
	outp(0x3C4,0x02);
	outp(0x3C5,0x0F);
	outp(crtc_address+0x4,0x14);
	outp(crtc_address+0x5,0x00);
	outp(crtc_address+0x4,0x17);
	outp(crtc_address+0x5,0xE3);
}

static void unsetup_graphics() {
	__asm {
		mov	ax,3
		int	10h
	}
}

static void clear_screen() {
	outp(0x3C4,0x02);
	outp(0x3C5,0x0F);

#if TARGET_BITS == 16
	_fmemset(VRAM,0,80*200);
#else
	memset(VRAM,0,80*200);
#endif
}

static inline void plot(int x,unsigned int y,unsigned char pixel) {
	outp(0x3C4,0x02);
	outp(0x3C5,0x01 << (x & 3U)); x >>= 2;
	VRAM[(y * 80U) + x] = pixel;
}

