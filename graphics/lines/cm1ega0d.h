
#define WIDTH 320
#define HEIGHT 200

#define pageflip()

#if TARGET_BITS == 16
static volatile unsigned char far *VRAM = MK_FP(0xA000,0x0000);
#else
static volatile unsigned char *VRAM = (volatile unsigned char*)0xA0000;
#endif

static void setup_graphics() {
	__asm {
		mov	ax,13
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
	outp(0x3CE,0x05);
	outp(0x3CF,0x00);	/* write mode 0 */
	outp(0x3CE,0x08);
	outp(0x3CF,0xFF);

#if TARGET_BITS == 16
	_fmemset((unsigned char far*)VRAM,0,80*200);
#else
	memset((unsigned char*)VRAM,0,80*200);
#endif
}

static inline void plot(int x,unsigned int y,unsigned char pixel) {
	unsigned char tmp;
	unsigned int o;

	outp(0x3CE,0x05);
	outp(0x3CF,0x02);	/* write mode 2 */
	outp(0x3CE,0x08);
	outp(0x3CF,0x80 >> (x & 7)); x >>= 3;
	o = (y * 40U) + x;

	/* VGA planar modes are kind of weird.
	 * First issue a dummy read, and throw it away, to load the VGA latches */
	tmp = VRAM[o];
	/* then write our pixel data */
	VRAM[o] = pixel;
}

