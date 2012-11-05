
#define WIDTH 320
#define HEIGHT 200
#define PAGES 8

static unsigned char		current_vpage = 0;
static unsigned int		current_vpage_offset = 0;
static unsigned char		next_vpage = 0;
static unsigned int		next_vpage_offset = 0;
static unsigned short		crtc_address = 0x3D0;
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

#if TARGET_BITS == 16
	if ((*((unsigned short far*)MK_FP(0x0040,0x63)) & 0xFF0) == 0x3B0)
		crtc_address = 0x3B0;
#else
	if ((*((unsigned short*)(0x00400 + 0x63)) & 0xFF0) == 0x3B0)
		crtc_address = 0x3B0;
#endif

	current_vpage = 0;
	current_vpage_offset = 0;
	next_vpage = 1;
	next_vpage_offset = 40*200;
}

static void unsetup_graphics() {
	__asm {
		mov	ax,3
		int	10h
	}
}

static void pageflip() {
	current_vpage = next_vpage;
	current_vpage_offset = next_vpage_offset;
	if (++next_vpage >= PAGES) {
		next_vpage = 0;
		next_vpage_offset = 0;
	}
	else {
		next_vpage_offset += 40*200;
	}

	/* then reprogram the display offset */
	outp(crtc_address+0x4,0x0C);
	outp(crtc_address+0x5,current_vpage_offset>>8);
	outp(crtc_address+0x4,0x0D);
	outp(crtc_address+0x5,current_vpage_offset);

	/* wait for vertical retrace */
	while ((inp(crtc_address+0xA) & 8) == 0);

	/* then wait for vretrace to end */
	while (inp(crtc_address+0xA) & 8);
}

static void clear_screen() {
	outp(0x3CE,0x05);
	outp(0x3CF,0x00);	/* write mode 0 */
	outp(0x3CE,0x08);
	outp(0x3CF,0xFF);

#if TARGET_BITS == 16
	_fmemset((unsigned char far*)(VRAM + next_vpage_offset),0,40*200);
#else
	memset((unsigned char*)(VRAM + next_vpage_offset),0,40*200);
#endif
}

static inline void plot(int x,unsigned int y,unsigned char pixel) {
	unsigned char tmp;
	unsigned int o;

	outp(0x3CE,0x05);
	outp(0x3CF,0x02);	/* write mode 2 */
	outp(0x3CE,0x08);
	outp(0x3CF,0x80 >> (x & 7)); x >>= 3;
	o = (y * 40U) + x + next_vpage_offset;

	/* VGA planar modes are kind of weird.
	 * First issue a dummy read, and throw it away, to load the VGA latches */
	tmp = VRAM[o];
	/* then write our pixel data */
	VRAM[o] = pixel;
}

