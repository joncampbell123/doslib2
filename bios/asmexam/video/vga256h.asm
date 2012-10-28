;--------------------------------------------------------------------------------------
; VGA256H.COM
; 
; Setup VGA 320x480x256 and display a bitmap. This is done (as usual) by setting
; 320x200x256 mode then tweaking the "maximum scan line" register on VGA hardware.
; This trick is so common, even Microsoft uses it internally in Windows 95 (both for
; the boot logo and within DISPDIB.DLL to provide 320x480x256 fullscreen modes for
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

; read data into memory (part3)
		mov	ah,0x3F
		mov	bx,[cs:handle]
		mov	dx,seg bitmap_part3
		mov	ds,dx
		mov	dx,bitmap_part3
		mov	cx,(320*80)
		int	21h

; close file
		mov	ah,0x3E
		mov	bx,[cs:handle]
		int	21h

; setup the mode
		mov	ax,19		; mode 0x13 VGA 320x200x256
		int	10h

		push	cs
		pop	ds
		mov	word [crt_port],0x3D4
		mov	word [status_port],0x3DA
		int	11h
		and	al,0x30
		cmp	al,0x30
		jne	not_mono
		mov	word [crt_port],0x3B4
		mov	word [status_port],0x3BA
not_mono:

		mov	al,0xE1
		mov	dx,0x3C2
		out	dx,al		; write misc output reg

		mov	al,0x00		; reg 0
		out	dx,al
		inc	dx
		mov	al,0x00		; reset
		out	dx,al
		dec	dx

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
		dec	dx

		mov	al,0x00		; reg 0
		out	dx,al
		inc	dx
		mov	al,0x03		; clear reset
		out	dx,al
		dec	dx

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

		mov	al,0xE3
		mov	dx,0x3C2
		out	dx,al		; write misc output reg

		cld
		mov	dx,0x3D4
		mov	si,seg crtc240
		mov	ds,si
		mov	si,crtc240
		mov	cx,CRTC_PARAMS
crtc_loop:	lodsw
		out	dx,ax
		dec	cx
		jnz	crtc_loop

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

; draw mid part
		mov	ax,seg bitmap_part2
		mov	ds,ax
		mov	si,bitmap_part2
		mov	di,80*200
		mov	cx,80*200
		call	blit

; draw bottom part
		mov	ax,seg bitmap_part3
		mov	ds,ax
		mov	si,bitmap_part3
		mov	di,80*400
		mov	cx,80*80
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
str_bmp:	db	'vga256p1.480',0
handle:		resw	1
bitmask:	resb	1
crt_port:	dw	1
status_port:	dw	1
scale:		dw	0x100
scale_dir:	dw	1

CRTC_PARAMS	equ	11
crtc240:	dw	0x2C11		; vertical retrace end (must be first to clear bit 7)
		dw	0x0D06		; vertical total
		dw	0x3E07		; overflow reg
		dw	0xEA10		; vertical retrace start
		dw	0xDF12		; vertical display enable end
		dw	0x0014		; underline location
		dw	0xE715		; vertical blank start
		dw	0x0616		; vertical blank end
		dw	0xE317		; mode control
		dw	0xAC11		; vertical retrace end (MUST BE LAST because it sets bit 7: protect)
		dw	0x4009		; max scanline count

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

		segment data3

bitmap_part3:	resb	320*80

		segment stack class=stack

		resw		1024

		segment bss

