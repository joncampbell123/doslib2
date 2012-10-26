;--------------------------------------------------------------------------------------
; EGA16C.COM
; 
; Use the BIOS to set EGA 640x350 16-color planar mode. Then display a bitmap.
; This uses a faster method of rendering by column to reduce the number of I/O
; reads/writes to the VGA registers and therefore increase performance. This is
; especially important on anything later than a Pentium where I/O is slower than
; memory-mapped I/O.
;
; This code also demonstrates Write Mode 1. After displaying the image it uses Write Mode 1
; to move the screen up 1 pixel per vertical retrace.
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

		push	cs
		pop	ds
		mov	word [status_port],0x3DA
		int	11h
		and	al,0x30
		cmp	al,0x30
		jne	not_mono
		mov	word [status_port],0x3BA
not_mono:

		cld
		mov	ax,0xA000
		mov	es,ax

; draw top part
		xor	di,di		; start at top
		mov	ax,seg bitmap_part1
		mov	ds,ax
		mov	si,bitmap_part1
		mov	cx,80*175	; 175 rows x 80 bytes
		call	draw_bitmap
		mov	ax,seg bitmap_part2
		mov	ds,ax
		mov	si,bitmap_part2
		mov	cx,80*175	; 175 rows x 80 bytes
		call	draw_bitmap

; wait for user
		xor	ax,ax
		int	16h

; now use write mode 1 to bitblt one part of the screen to another
scrollanim:	call	vblank
		call	scrollup
		mov	ah,1		; any key press?
		int	16h
		jz	scrollanim	; loop if not
		xor	ax,ax
		int	16h		; eat the key

; restore text mode
		mov	ax,3
		int	10h

; exit
		mov	ax,0x4C00
		int	21h

; scroll the entire screen up one row
scrollup:	mov	ax,0x0905	; write reg 5 = (read mode 1, write mode 1)
		call	gc_write

		push	ds
		push	es
		pop	ds
		cld

		; copy the first scanline to the 350th row
		mov	di,80*350
		xor	si,si
		mov	cx,80
		rep	movsb

		; copy the screen up
		xor	di,di
		mov	si,80
		mov	cx,80*350
		rep	movsb

		pop	ds
		ret

vblank:		; first wait for vblank to finish
		mov	dx,[cs:status_port]

.l1:		in	al,dx
		test	al,0x08
		jnz	.l1

		; then wait for vblank
.l2:		in	al,dx
		test	al,0x08
		jz	.l2
		
		ret

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
		mov	ax,0x0A05	; write reg 5 = (read mode 1, write mode 2)
		call	gc_write
	; ------ OK, start drawing
		mov	byte [cs:bitmask],0x80
.bitmaskloop:	mov	ah,[cs:bitmask]
		shr	byte [cs:bitmask],1
		mov	al,0x08
		call	gc_write

		call	draw_bitmap_upnib

		mov	ah,[cs:bitmask]
		mov	al,0x08
		call	gc_write

		call	draw_bitmap_lonib

		inc	si
		shr	byte [cs:bitmask],1
		jnc	.bitmaskloop

		add	di,cx
		ret

draw_bitmap_lonib:
		push	si
		push	di
		push	cx
		push	dx
		mov	dx,cx

.l1:		mov	al,[es:di]		; load VGA latches
		lodsb
		add	si,4 - 1		; 4 bytes per 8 pixels, -1 for lodsb
		stosb
		dec	dx
		jnz	.l1

		pop	dx
		pop	cx
		pop	di
		pop	si

		ret

draw_bitmap_upnib:
		push	si
		push	di
		push	cx
		push	dx
		mov	dx,cx
		mov	cl,4

.l1:		mov	al,[es:di]		; load VGA latches
		lodsb
		shr	al,cl
		add	si,4 - 1		; 4 bytes per 8 pixels, -1 for lodsb
		stosb
		dec	dx
		jnz	.l1

		pop	dx
		pop	cx
		pop	di
		pop	si

		ret

; AH=data to write AL=register index
gc_write:	mov	dx,0x3CE
		out	dx,al
		inc	dx
		mov	al,ah
		out	dx,al
		ret

bitmask:	db	1
status_port:	resw	1

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

