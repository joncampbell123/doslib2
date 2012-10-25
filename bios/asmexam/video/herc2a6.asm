;--------------------------------------------------------------------------------------
; HERC2A6.COM
;
; Setup Hercules 720x348 graphics, tweaked to run as 640x348, and render a bitmap.
; Note that Hercules video ram is interlaced, like CGA, across 4 rows.
;
; WARNING: This code does NOT check whether you have an actual Hercules.
;          Also, I do not yet have a test machine setup to actually test whether this
;          code works on real hardware. All I know at this point is that it works under
;          DOSBox with machine=hercules.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		push	cs
		pop	ds

;------------------------------------------------------------
		mov	ax,7		; setup mode 80x25 mono
		int	10h

		mov	dx,0x03BF	; out(0x3BF,3)	allow graphics enable page 1
		mov	al,0x03
		out	dx,al

		mov	dl,0xB8		; out(0x3B8,0x02)  disable video and set mode
		mov	al,0x02
		out	dx,al

		mov	bl,0		; BL=reg
		mov	si,herc_gfx_crtc; SI=CRTC register table
		mov	cx,12		; CX=number of registers to write

hercsetup:	mov	al,bl		; <- out(0x3B4,BL)
		mov	dl,0xB4
		out	dx,al
		lodsb
		inc	dl
		out	dx,al		; <- out(0x3B5,[si])
		inc	bl
		loop	hercsetup

		mov	dl,0xB8		; out(0x3B8,0x0A)  enable video
		mov	al,0x0A
		out	dx,al
;---------------------------------------------------

		mov	si,bitmap
		mov	dx,348/4
		call	display

		mov	ax,7		; we can't leave it in graphics
		int	10h

		ret

display:	cld
		mov	ax,0xB000
		mov	es,ax
		xor	di,di
		mov	cx,4
totalloop:	push	si
		push	di
		push	cx
		mov	cx,dx

.rowloop:	push	cx
		mov	cx,80		; one row = 80 bytes = 640 pixels
		rep	movsb		; do the copy
		pop	cx
		add	si,80*3		; step forward three more rows
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

herc_gfx_crtc:	db	0x2F,0x28,0x29,0x07, 0x5B,0x02,0x57,0x57, 0x02,0x03,0x00,0x00

bitmap:; NTS: The bitmap is in CGA 2-color format but NOT interleaved
incbin		"lolcat-hammahtime-640x348.herc.raw.herc"

		segment .bss

