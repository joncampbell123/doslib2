;--------------------------------------------------------------------------------------
; VGARAS1.COM
; 
; Setup VGA 320x200x256 and do per-scanline palette effects
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100

		push	cs
		pop	ds
		mov	word [scancount],0

; setup the mode
		mov	ax,19		; mode 0x13 VGA 320x200x256
		int	10h

; wait for vblank (and end)
loop1:		cli
		call	vblank

		mov	si,[scancount]
		inc	word [scancount]
		mov	cx,300

; as the raster scan runs down the screen, hack the 0th palette entry
; to make a smooth gradient
hscan:		call	hblank		; wait for hsync
		mov	dx,0x3C8
		xor	al,al
		out	dx,al		; write(0x3C8,0)
		inc	dx
		push	cx
		mov	cl,3
		mov	ax,si		; write(0x3C9,si)
		out	dx,al
		shr	ax,cl
		out	dx,al
		shr	ax,cl
		out	dx,al
		pop	cx
		inc	si
		loop	hscan
		sti

; if keyboard input, then exit
		mov	ah,1
		int	16h
		jz	loop1

; eat keyboard input
		xor	ax,ax
		int	16h

; restore text mode
		mov	ax,3
		int	10h

; exit
		mov	ax,0x4C00
		int	21h

;-----------------------------------

hblank:		; first wait for hblank
		mov	dx,0x3DA

.l1:		in	al,dx
		test	al,0x01
		jz	.l1

		; then wait for hblank to complete
.l2:		in	al,dx
		test	al,0x01
		jnz	.l2

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

		segment	.bss

scancount:	resw	1

