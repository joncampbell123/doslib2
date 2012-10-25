;--------------------------------------------------------------------------------------
; CGA4A.COM
; 
; Use the BIOS to set CGA 320x200 4-color mode.
; This mode is not as straightforward as you think: there are 2 bits per pixel, but
; the rows are interleaved across two 8KB banks, even rows (0,2,4,6..) are at 0x0000 and
; odd rows (1,3,5,7..) are at 0x2000.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		push	cs
		pop	ds

		mov	ax,4
		int	10h

		mov	dx,186/2
		mov	si,bitmap
		call	display

		mov	dx,200/2
		mov	si,bitmap2
		call	display

		ret

display:	cld
		mov	ax,0xB800
		mov	es,ax
		xor	di,di
		mov	cx,2
totalloop:	push	si
		push	di
		push	cx
		mov	cx,dx		; DX = # of rows per pass

.rowloop:	push	cx
		mov	cx,80		; one row = 80 bytes = 320 pixels
		rep	movsb		; do the copy
		pop	cx
		add	si,80		; step forward one more row
		loop	.rowloop

		pop	cx
		pop	di
		pop	si
		add	di,0x2000	; step forward 8K
		add	si,80		; step forward one source bitmap scanline
		loop	totalloop

		; wait for user input
		xor	ax,ax
		int	16h

		ret

		segment .data

bitmap:; NTS: The bitmap is in CGA 4-color format but NOT interleaved
incbin		"parrot-cga-320x186.raw.ppm.cga"

bitmap2:
incbin		"billgates-cga-320x200.raw.ppm.cga"

		segment .bss

