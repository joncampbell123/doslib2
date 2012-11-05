
int main() {
	int msmouse=0;
	struct pos2 point[2],clipped[2];
	int c,redraw=1;
	int pointsel=0;
	int doclip=1;

	/* microsoft mouse present? */
#if TARGET_BITS == 16
	if (*((unsigned long*)MK_FP(0,0x33*4)) != 0) {
		__asm {
			xor	ax,ax		; AH=0 reset driver
			int	33h
			or	ax,ax
			jz	notinst
			inc	[msmouse]
notinst:
		}
	}
#else
#endif

	point[0].x = WIDTH/4;
	point[0].y = WIDTH/4;
	point[1].x = WIDTH*3/4;
	point[1].y = HEIGHT*4/5;
	setup_graphics();

	do {
		if (redraw) {
			redraw = 0;
			clear_screen();
			if (point[0].x >= 0 && point[0].x < WIDTH && point[0].y >= 0 && point[0].y < HEIGHT)
				plot(point[0].x,point[0].y,0x04);
			if (point[1].x >= 0 && point[1].x < WIDTH && point[1].y >= 0 && point[1].y < HEIGHT)
				plot(point[1].x,point[1].y,0x04);
			if (doclip) {
				if (clip_line(clipped,point)) {
					draw_line(clipped[0].x,clipped[0].y,clipped[1].x,clipped[1].y,0x0F);
				}
			}
			else {
				draw_line(point[0].x,point[0].y,point[1].x,point[1].y,0x0F);
			}

			pageflip();
		}

		if (kbhit()) {
			c = getch();
			if (c == 0) c = getch() << 8;

			if (c == 27) break;
			else if (c == ' ') pointsel ^= 1;
			else if (c == 0x4800) { /* UP */
				point[pointsel].y--;
				redraw = 1;
			}
			else if (c == 0x5000) { /* DOWN */
				point[pointsel].y++;
				redraw = 1;
			}
			else if (c == 0x4B00) { /* LEFT */
				point[pointsel].x--;
				redraw = 1;
			}
			else if (c == 0x4D00) { /* RIGHT */
				point[pointsel].x++;
				redraw = 1;
			}
		}
		else if (msmouse) {
			short int px=0,py=0,btns=0;

			__asm {
				mov	ax,3		; return mouse position
				int	33h
				mov	btns,bx
				mov	px,cx
				mov	py,dx
			}

#if WIDTH <= 320
			px >>= 1;
#endif

			if (btns & 1) {
				if (px != point[pointsel].x || py != point[pointsel].y) {
					point[pointsel].x = px;
					point[pointsel].y = py;
					redraw = 1;
				}
			}
		}
	} while (1);

	unsetup_graphics();
	return 0;
}

