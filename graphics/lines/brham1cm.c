
#include "common1.h"

static int clip_line(struct pos2 *out,struct pos2 in[2]) {
	int dx,dy;

	memcpy(out,in,sizeof(struct pos2)*2); /* copy 2 array elements to out from in, becomes memcpy() underneath */
	if (out[0].x < 0 && out[1].x < 0) return 0;
	if (out[0].y < 0 && out[1].y < 0) return 0;
	if (out[0].x >= WIDTH && out[1].x >= WIDTH) return 0;
	if (out[0].y >= HEIGHT && out[1].y >= HEIGHT) return 0;
	if (out[0].x == out[1].x && out[0].y == out[1].y) return 1;

	dx = out[1].x - out[0].x;
	dy = out[1].y - out[0].y;

	if (dx == 0) {
		if (out[0].y < 0) out[0].y = 0;
		if (out[0].y >= HEIGHT) out[0].y = HEIGHT-1;
		if (out[1].y < 0) out[1].y = 0;
		if (out[1].y >= HEIGHT) out[1].y = HEIGHT-1;
	}
	else if (dy == 0) {
		if (out[0].x < 0) out[0].x = 0;
		if (out[0].x >= WIDTH) out[0].x = WIDTH-1;
		if (out[1].x < 0) out[1].x = 0;
		if (out[1].x >= WIDTH) out[1].x = WIDTH-1;
	}
	else {
		float m = ((float)dy) / dx;

		do {
			if (out[0].x < 0) {
				out[0].y += (int)(m * -out[0].x);
				out[0].x = 0;
				continue;
			}
			else if (out[1].x < 0) {
				out[1].y += (int)(m * -out[1].x);
				out[1].x = 0;
				continue;
			}

			if (out[0].x >= WIDTH) {
				out[0].y -= (int)(m * (out[0].x + 1 - WIDTH));
				out[0].x = WIDTH-1;
				continue;
			}
			else if (out[1].x >= WIDTH) {
				out[1].y -= (int)(m * (out[1].x + 1 - WIDTH));
				out[1].x = WIDTH-1;
				continue;
			}

			if (out[0].y < 0) {
				out[0].x += (int)(-out[0].y / m);
				out[0].y = 0;
				continue;
			}
			else if (out[1].y < 0) {
				out[1].x += (int)(-out[1].y / m);
				out[1].y = 0;
				continue;
			}

			if (out[0].y >= HEIGHT) {
				out[0].x -= (int)((out[0].y + 1 - HEIGHT) / m);
				out[0].y = HEIGHT-1;
				continue;
			}
			else if (out[1].y >= HEIGHT) {
				out[1].x -= (int)((out[1].y + 1 - HEIGHT) / m);
				out[1].y = HEIGHT-1;
				continue;
			}

			break;
		} while (1);
	}

	return 1;
}

static void draw_line(int x1,int y1,int x2,int y2,unsigned char pixel) {
	int dx,dy,x,y,error;

	dx = x2 - x1;
	dy = y2 - y1;
	if (abs(dy) > abs(dx)) {
		if (y2 < y1) {
			x = x1; x1 = x2; x2 = x; dx = -dx;
			y = y1; y1 = y2; y2 = y; dy = -dy;
		}

		x = x1; y = y1;
		plot(x,y++,pixel);
		if (dx >= 0) {
			error = (2*dx) - dy;
			for (;y <= y2;y++) {
				if (error > 0) {
					plot(++x,y,pixel);
					error += 2 * (dx - dy);
				}
				else {
					plot(x,y,pixel);
					error += 2 * dx;
				}
			}
		}
		else {
			dx = -dx;
			error = (2*dx) - dy;
			for (;y <= y2;y++) {
				if (error > 0) {
					plot(--x,y,pixel);
					error += 2 * (dx - dy);
				}
				else {
					plot(x,y,pixel);
					error += 2 * dx;
				}
			}
		}
	}
	else {
		if (x2 < x1) {
			x = x1; x1 = x2; x2 = x; dx = -dx;
			y = y1; y1 = y2; y2 = y; dy = -dy;
		}

		x = x1; y = y1;
		plot(x++,y,pixel);
		if (dy >= 0) {
			error = (2*dy) - dx;
			for (;x <= x2;x++) {
				if (error > 0) {
					plot(x,++y,pixel);
					error += 2 * (dy - dx);
				}
				else {
					plot(x,y,pixel);
					error += 2 * dy;
				}
			}
		}
		else {
			dy = -dy;
			error = (2*dy) - dx;
			for (;x <= x2;x++) {
				if (error > 0) {
					plot(x,--y,pixel);
					error += 2 * (dy - dx);
				}
				else {
					plot(x,y,pixel);
					error += 2 * dy;
				}
			}
		}
	}
}

#include "common1m.c"

