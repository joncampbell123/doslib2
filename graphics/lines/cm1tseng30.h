
#define WIDTH 800
#define HEIGHT 600

#define pageflip()

#include "cmtseng.h"

#if TARGET_BITS == 16
static unsigned char far *VRAM = MK_FP(0xA000,0x0000);
#else
static unsigned char *VRAM = (unsigned char*)0xA0000;
#endif

static void setup_graphics() {
	unsigned char t=0;

	tseng_detect();

	__asm {
		mov	ax,0x30
		int	10h

		mov	ah,0x0F
		int	10h
		mov	t,al
	}

	if (t != 0x30) {
		__asm {
			mov	ax,3
			int	10h
		}

		printf("Unable to set Tseng ET4000 800x600x256 graphics mode\n");
		exit(0);
	}
}

static void unsetup_graphics() {
	__asm {
		mov	ax,3
		int	10h
	}
}

static inline void tseng_bankswitch(unsigned char n) {
	if (et4000) {
		/* NTS: read bank bits 0-3, write bank bits 4-7 */
		outp(0x3CD,n | (n << 4));
	}
	else {
		/* NTS: read bank bits 0-2, write bank bits 3-5, segment size bits 6-7 where 0=128KB 1=64KB 2=1M linear */
		outp(0x3CD,n | (n << 3) | 0x40); /* set write bank to bank N, bank segment size 64KB */
	}

	current_bank = n;
}

static void clear_screen() {
	unsigned int banks;

	for (banks=0;banks < 8;banks++) {
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
		unsigned long o = (((unsigned long)y) * 800UL) + (unsigned long)x;
		unsigned char bank = (unsigned char)(o >> 16UL);
		off = (unsigned int)o & 0xFFFFU;

		if (bank != current_bank)
			tseng_bankswitch(bank);
	}

	VRAM[off] = pixel;
}

