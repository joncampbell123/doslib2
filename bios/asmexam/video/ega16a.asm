;--------------------------------------------------------------------------------------
; EGA16A.COM
; 
; Use the BIOS to set EGA 640x350 16-color planar mode. Then display a bitmap.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode

		segment text class=code

..start:	push	cs
		pop	ds

; load bitmap from file into memory
		mov	ax,0x3D00	; AH=0x3D OPEN FILE AL=0 compat sharing
		mov	dx,str_bmp	; DS:DX = path to file
		int	21h
		jnc	open_ok

		mov	ax,0x4C01
		int	21h
		hlt
open_ok:	mov	[cs:handle],ax

; read data into memory, part 1
		mov	ah,0x3F
		mov	bx,[cs:handle]
		mov	dx,seg bitmap_hdr
		mov	ds,dx
		mov	dx,bitmap_hdr
		mov	cx,(320*175) + 0x76
		int	21h

; read data into memory, part 2
		mov	ah,0x3F
		mov	bx,[cs:handle]
		mov	dx,seg bitmap_part2
		mov	ds,dx
		mov	dx,bitmap_part2
		mov	cx,(320*175)
		int	21h

; close file
		mov	ah,0x3E
		mov	bx,[cs:handle]
		int	21h

; setup the mode
		mov	ax,16		; mode 0x10 EGA 640x350x16
		int	10h

		cld
		mov	ax,0xA000
		mov	es,ax

; draw top part
		xor	di,di		; start at top
		mov	ax,seg bitmap_part1
		mov	ds,ax
		mov	si,bitmap_part1
		mov	cx,320*175	; 320*175 pixel pairs
		call	draw_bitmap
; and then the bottom part
		mov	ax,seg bitmap_part2
		mov	ds,ax
		mov	si,bitmap_part2
		mov	cx,320*175	; 320*175 pixel pairs
		call	draw_bitmap

; wait for user
		xor	ax,ax
		int	16h

; restore text mode
		mov	ax,3
		int	10h

; exit
		mov	ax,0x4C00
		int	21h

; packet bitmap blitting.
; we use write mode 2 to place the packed 4-bit pixels onscreen.
; NOTE: You may notice this code is SLOW. That is due to the inner loop
;       doing one memory write and several I/O per pixel. Optimized
;       implementations update the write mask (I/O) once per column and
;       render the bitmap column-wise in strips instead to reduce the
;       I/O necessary for the operation.
draw_bitmap:
	; assuming: ES = 0xA000, SI = packed data to blit, CX = number of pixel pairs (bytes), DI = vram address
	; ------ Setup EGA write mode 2
		mov	ax,0x0605	; write reg 5 = 0x06 (read mode 1, write mode 2)
		call	gc_write
	; ------ OK, start drawing
		mov	bh,0x80		; BH=bitmask
.dualpixel:	xchg	bx,cx		; swap CX and BX -> CH=bitmask CL=4
		mov	cl,4

		mov	ah,ch		; AH=bitmask
		ror	ch,1		; rotate mask
		mov	al,8		; AL=graphics controller reg 8
		call	gc_write

		lodsb			; load pixel pair
		mov	ah,al		; AH=AL

		; first pixel of pair
		shr	al,cl		; AH >>= 4 (CL=4)
		mov	cl,[es:di]	; read VGA ram to load the latches (we don't care about CL anymore)
		mov	[es:di],al	; write to VRAM. VGA will expand our 4 bits to each plane

		; update mask
		push	ax
		mov	ah,ch		; AH=bitmask
		mov	al,8		; AL=graphics controller reg 8
		call	gc_write
		pop	ax

		; second pixel of pair
		mov	al,ah
		mov	cl,[es:di]	; read VGA ram to load the latches (we don't care about CL anymore)
		mov	[es:di],al	; write to VRAM. VGA will expand our 4 bits to each plane

		; rotate mask. if bit wraps around, then advance memory address
		ror	ch,1
		jnc	.nocarry
		inc	di
.nocarry:

		xchg	bx,cx		; swap CX and BX -> CX=count and BH=bitmask
		loop	.dualpixel
		ret

; AH=data to write AL=register index
gc_write:	mov	dx,0x3CE
		out	dx,al
		inc	dx
		mov	al,ah
		out	dx,al
		ret

; data
str_bmp:	db	'ega35std.350',0
handle:		resw	1

		segment data1

; NTS: The bitmap totals 112KB, which Watcom will not allow to fit in one segment.
;      So we split it up into a top half and bottom half across two segments.
;      The image is 16-color (4-bit) packed. The includes here assume a bitmap
;      saved by the GIMP in Windows BMP format that is 640x350 16-color 4-bit packed.
;      This version assumes the default EGA palette and does not include it from the bitmap.
bitmap_hdr:	resb	0x76
bitmap_part1:	resb	320*175

		segment data2

bitmap_part2:	resb	320*175

		segment stack class=stack

		resw		1024

		segment bss

