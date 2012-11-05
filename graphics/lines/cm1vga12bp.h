
#define WIDTH 640
#define HEIGHT 480
#define PAGES 2

static unsigned char current_bpage = 0;
static unsigned char current_bpage_mask = 0x03;
static unsigned char next_bpage_shift = 2;
static unsigned char next_bpage = 1;
static unsigned char next_bpage_mask = 0x0C;
#if TARGET_BITS == 16
static volatile unsigned char far *VRAM = MK_FP(0xA000,0x0000);
#else
static volatile unsigned char *VRAM = (volatile unsigned char*)0xA0000;
#endif

static void setup_graphics() {
	__asm {
		mov	ax,18
		int	10h
	}

	/* program a 4-color palette */
	{
		unsigned char pal[4];
		unsigned int i;

		for (i=0;i < 4;i++) pal[i] = (i * 63) / 3;

		inp(0x3DA);
		for (i=0;i < 16;i++) {
			outp(0x3C0,i);
			outp(0x3C0,i);
		}
		outp(0x3C0,0x20);

		outp(0x3C8,0);
		for (i=0;i < 4;i++) {
			outp(0x3C9,pal[i]);
			outp(0x3C9,pal[i]);
			outp(0x3C9,pal[i]);
		}
		for (;i < 16;i++) {
			outp(0x3C9,pal[i>>2U]);
			outp(0x3C9,pal[i>>2U]);
			outp(0x3C9,pal[i>>2U]);
		}
	}

	current_bpage = 0;
	current_bpage_mask = 0x03;
	next_bpage = 1;
	next_bpage_mask = 0x0C;

	outp(0x3C4,0x02);
	outp(0x3C5,next_bpage_mask);
	outp(0x3C6,current_bpage_mask);
}

static void unsetup_graphics() {
	__asm {
		mov	ax,3
		int	10h
	}
}

static void pageflip() {
	current_bpage_mask = next_bpage_mask;
	current_bpage = next_bpage;
	if (++next_bpage >= PAGES) {
		next_bpage = 0;
		next_bpage_shift = 0;
		next_bpage_mask = 0x03;
	}
	else {
		next_bpage_shift += 2;
		next_bpage_mask <<= 2;
	}

	outp(0x3C4,0x02);
	outp(0x3C5,next_bpage_mask);
	outp(0x3C6,current_bpage_mask);
}

static void clear_screen() {
	outp(0x3CE,0x05);
	outp(0x3CF,0x00);	/* write mode 0 */
	outp(0x3CE,0x08);
	outp(0x3CF,0xFF);

#if TARGET_BITS == 16
	_fmemset((unsigned char far*)VRAM,0,80*480);
#else
	memset((unsigned char*)VRAM,0,80*480);
#endif
}

static inline void plot(int x,unsigned int y,unsigned char pixel) {
	unsigned char tmp;
	unsigned int o;

	outp(0x3CE,0x05);
	outp(0x3CF,0x02);	/* write mode 2 */
	outp(0x3CE,0x08);
	outp(0x3CF,0x80 >> (x & 7)); x >>= 3;
	o = (y * 80U) + x;

	/* VGA planar modes are kind of weird.
	 * First issue a dummy read, and throw it away, to load the VGA latches */
	tmp = VRAM[o];
	/* then write our pixel data */
	VRAM[o] = pixel << next_bpage_shift;
}

