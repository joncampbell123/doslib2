
static unsigned char et4000 = 0;
static unsigned char current_bank = 0;

static void tseng_detect() {
	unsigned char t,t2;

	/* detect TSENG first (NTS: This is pretty iffy though in my opinion) */
	inp(0x3DA);
	outp(0x3C0,0x16);	/* misc register */
	t = inp(0x3C1);

	inp(0x3DA);
	outp(0x3C0,0x16);
	outp(0x3C0,t ^ 0x30);

	inp(0x3DA);
	outp(0x3C0,0x16);
	t2 = inp(0x3C1);

	inp(0x3DA);
	outp(0x3C0,0x16 | 0x20);
	outp(0x3C0,t);

	if (t2 != (t ^ 0x30)) {
		printf("WARNING: Doesn't act like a TSENG ET3000/4000 chip. Hit ESC now to exit\n");
		do {
			t = getch();
			if (t == 27) exit(0);
		} while (t != 13);
	}

	/* try to enable ET4000 extensions */
	outp(0x3BF,0x03);
	outp(0x3D8,0xA0);

	/* which TSENG? */
	outp(0x3D4,0x33);
	t = inp(0x3D5);

	outp(0x3D4,0x33);
	outp(0x3D5,t ^ 0x0F);

	outp(0x3D4,0x33);
	t2 = inp(0x3D5);

	outp(0x3D4,0x33);
	outp(0x3D5,t);

	if (t2 == (t ^ 0x0F))
		et4000 = 1;
}

