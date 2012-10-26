;--------------------------------------------------------------------------------------
; VGA256D.COM
; 
; Setup VGA 320x400x256 and display a bitmap. This is done (as usual) by setting
; 320x200x256 mode then tweaking the "maximum scan line" register on VGA hardware.
; This trick is so common, even Microsoft uses it internally in Windows 95 (both for
; the boot logo and within DISPDIB.DLL to provide 320x400x256 fullscreen modes for
; Windows such as when playing an AVI full screen).
;
; This version uses the more common unchained "mode x" method.
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

; read data into memory (part1)
		mov	ah,0x3F
		mov	bx,[cs:handle]
		mov	dx,seg bitmap_hdr
		mov	ds,dx
		mov	dx,bitmap_hdr
		mov	cx,(320*200) + (256*4) + 0x36
		int	21h

; read data into memory (part2)
		mov	ah,0x3F
		mov	bx,[cs:handle]
		mov	dx,seg bitmap_part2
		mov	ds,dx
		mov	dx,bitmap_part2
		mov	cx,(320*200)
		int	21h

; close file
		mov	ah,0x3E
		mov	bx,[cs:handle]
		int	21h

; setup the mode
		mov	ax,19		; mode 0x13 VGA 320x200x256
		int	10h

		mov	dx,0x3D4
		mov	al,0x09
		out	dx,al
		inc	dx
		mov	al,0x40
		out	dx,al		; <- tweak 320x200 into 320x400

		mov	dx,0x3C4
		mov	al,0x04
		out	dx,al		; address reg 4 of the sequencer
		inc	dx
		mov	al,0x06		; Chain 4 disable, extended memory enable, disable odd/even
		out	dx,al
		dec	dx

		mov	al,0x02		; now reg 2
		out	dx,al
		inc	dx
		mov	al,0x0F		; enable all planes
		out	dx,al

		mov	dx,0x3D4

		mov	al,0x14
		out	dx,al
		inc	dx
		mov	al,0x00		; write CRTC reg 0x14 turn off long mode
		out	dx,al
		dec	dx

		mov	al,0x17
		out	dx,al
		inc	dx
		mov	al,0xE3		; write CRTC reg 0x17 enable byte mode
		out	dx,al
		dec	dx

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
		mov	ax,seg bitmap
		mov	ds,ax
		xor	di,di		; start at top
		mov	si,bitmap
		mov	cx,80*200
		call	blit

; draw bottom part
		mov	ax,seg bitmap_part2
		mov	ds,ax
		mov	si,bitmap_part2
		mov	di,80*200
		mov	cx,80*200
		call	blit

; wait for user
		xor	ax,ax
		int	16h

; restore text mode
		mov	ax,3
		int	10h

; exit
		mov	ax,0x4C00
		int	21h

; blitting routine
blit:		mov	byte [cs:bitmask],0x11

.loop1:		mov	dx,0x3C4
		mov	al,0x02
		out	dx,al
		inc	dx
		mov	al,[cs:bitmask]
		out	dx,al

		push	si
		push	di
		push	cx
.loop2:		lodsb
		add	si,3
		stosb
		loop	.loop2
		pop	cx
		pop	di
		pop	si
		inc	si

		shl	byte [cs:bitmask],1
		jnc	.loop1
		ret

; data
str_bmp:	db	'vga256p1.400',0
handle:		resw	1
bitmask:	resb	1

		segment data1

; NTS: The bitmap totals 112KB, which Watcom will not allow to fit in one segment.
;      So we split it up into a top half and bottom half across two segments.
;      The image is 16-color (4-bit) packed. The includes here assume a bitmap
;      saved by the GIMP in Windows BMP format that is 640x350 16-color 4-bit packed.
;      This version assumes the default EGA palette and does not include it from the bitmap.
bitmap_hdr:	resb	0x36
bitmap_palette:	resb	256*4
bitmap:		resb	320*200

		segment data2

bitmap_part2:	resb	320*200

		segment stack class=stack

		resw		1024

		segment bss

