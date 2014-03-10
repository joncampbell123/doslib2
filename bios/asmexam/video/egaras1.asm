;--------------------------------------------------------------------------------------
; EGARAS1.COM
; 
; Setup EGA 320x200x16 and do per-scanline palette effects
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100

		push	cs
		pop	ds

; setup the mode
		mov	ax,16		; mode 0x10 EGA 640x350x16
		int	10h

; clear interrupts for the program, empty keyboard
		cli
		call	eat_keyboard

; wait for vblank (and end)
loop1:		call	vblank

		mov	si,[scancount]
		inc	word [scancount]
		mov	cx,330

; as the raster scan runs down the screen, hack the 0th palette entry
; to make a smooth gradient
hscan:		mov	dx,0x3C0
		mov	al,0
		out	dx,al		; attribute controller palette index 0

		mov	bx,si
		and	bx,0x3F
		mov	al,[palmap+bx]
		out	dx,al		; and use SI as the new entry

		mov	al,0x20		; and then reenable video
		out	dx,al

		inc	si
		call	hblank		; wait for hsync
		loop	hscan

; if keyboard input, then exit
		in	al,64h
		test	al,1
		jz	loop1		; no data, keep looping
		in	al,60h
		cmp	al,0x81		; escape (keyup)?
		jnz	loop1
		call	eat_keyboard

; restore text mode and interrupts
		mov	ax,3
		int	10h
		sti

; exit
		mov	ax,0x4C00
		int	21h

;-----------------------------------

hblank:		; first wait for hblank to complete
		mov	dx,0x3DA

.l1:		in	al,dx
		test	al,0x01
		jnz	.l1

		; then wait for hblank
.l2:		in	al,dx
		test	al,0x01
		jz	.l2

		ret

;-----------------------------------

vblank:		; first wait for vblank
		mov	dx,0x3DA

.l1:		in	al,dx
		test	al,0x08
		jz	.l1

		; then wait for vblank to complete
.l2:		in	al,dx
		test	al,0x08
		jnz	.l2
		
		ret

;-----------------------------------

eat_keyboard:	in	al,60h		; eat the data
		nop			; IODELAY
		nop			; IODELAY
		in	al,64h
		test	al,1
		jnz	eat_keyboard
		ret

		segment .data

; NTS: Remember that the EGA palette index has 2-bit R/G/B (B at bits 0-1) AND
;      that for B, bit 0 is the MSB and bit 3 is the LSB.
%define rgb(r,g,b) (((b>>1)&1) + ((b&1)<<3) + (((g>>1)&1)<<1) + ((g&1)<<4) + (((r>>1)&1)<<2) + ((r&1)<<5))
palmap:		db	rgb(0,0,0), rgb(0,0,1), rgb(0,0,2), rgb(0,0,3)
		db	rgb(0,1,3), rgb(0,2,3), rgb(0,3,3), rgb(0,3,2)
		db	rgb(0,3,1), rgb(0,3,0), rgb(1,3,0), rgb(2,3,0)
		db	rgb(3,3,0), rgb(3,2,0), rgb(3,1,0), rgb(3,0,0)

		db	rgb(3,0,1), rgb(3,0,2), rgb(3,0,3), rgb(2,0,3)
		db	rgb(1,0,3), rgb(0,0,3), rgb(0,0,2), rgb(0,0,1)
		db	rgb(0,0,0), rgb(1,1,1), rgb(2,2,2), rgb(3,3,3)
		db	rgb(3,2,2), rgb(3,1,1), rgb(2,1,1), rgb(1,1,2)

		db	rgb(1,1,3), rgb(2,2,3), rgb(3,3,3), rgb(3,2,3)
		db	rgb(3,1,3), rgb(3,0,3), rgb(2,0,3), rgb(1,0,3)
		db	rgb(0,0,3), rgb(0,1,2), rgb(0,2,1), rgb(0,3,0)
		db	rgb(1,3,0), rgb(2,3,0), rgb(3,3,0), rgb(3,2,0)

		db	rgb(3,1,0), rgb(3,0,0), rgb(2,1,1), rgb(1,2,2)
		db	rgb(1,2,3), rgb(0,1,2), rgb(0,0,1), rgb(1,0,1)
		db	rgb(1,0,0), rgb(2,1,0), rgb(3,1,0), rgb(3,1,1)
		db	rgb(2,1,1), rgb(1,1,1), rgb(1,1,0), rgb(1,0,1)

		segment	.bss

scancount:	resw	1

