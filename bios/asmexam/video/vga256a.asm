;--------------------------------------------------------------------------------------
; VGA256A.COM
; 
; Setup VGA 320x200x256 and display a bitmap
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

; read data into memory
		mov	ah,0x3F
		mov	bx,[cs:handle]
		mov	dx,seg bitmap_hdr
		mov	ds,dx
		mov	dx,bitmap_hdr
		mov	cx,(320*200) + (256*4) + 0x36
		int	21h

; close file
		mov	ah,0x3E
		mov	bx,[cs:handle]
		int	21h

; setup the mode
		mov	ax,19		; mode 0x13 VGA 320x200x256
		int	10h

; load the color palette
		cld
		mov	si,seg bitmap_palette
		mov	ds,si
		mov	si,bitmap_palette
		mov	cx,256
		mov	dx,0x3C8
		xor	al,al
		out	dx,al
		inc	dx

palette_load:	push	cx
		mov	cl,2

		lodsb
		shr	al,cl
		push	ax

		lodsb
		shr	al,cl
		push	ax

		lodsb
		shr	al,cl
		out	dx,al
		pop	ax
		out	dx,al
		pop	ax
		out	dx,al

		lodsb

		pop	cx
		loop	palette_load

		cld
		mov	ax,0xA000
		mov	es,ax

; draw top part
		xor	di,di		; start at top
		mov	ax,seg bitmap
		mov	ds,ax
		mov	si,bitmap
		mov	cx,(320*200)/2	; 320*200 pixel pairs
		rep	movsw

; wait for user
		xor	ax,ax
		int	16h

; restore text mode
		mov	ax,3
		int	10h

; exit
		mov	ax,0x4C00
		int	21h

; data
str_bmp:	db	'vga256p1.200',0
handle:		resw	1

		segment data1

; NTS: The bitmap totals 112KB, which Watcom will not allow to fit in one segment.
;      So we split it up into a top half and bottom half across two segments.
;      The image is 16-color (4-bit) packed. The includes here assume a bitmap
;      saved by the GIMP in Windows BMP format that is 640x350 16-color 4-bit packed.
;      This version assumes the default EGA palette and does not include it from the bitmap.
bitmap_hdr:	resb	0x36
bitmap_palette:	resb	256*4
bitmap:		resb	320*200

		segment stack class=stack

		resw		1024

		segment bss

