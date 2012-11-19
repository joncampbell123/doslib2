;--------------------------------------------------------------------------------------
; PEEKM86.COM
; 
; Utility for poking around the contents of memory, including any possible structures
; preceeding allocated segments, the contents of the DOS segment, and the interrupt
; vector tables. This code is written to use only alphanumeric memory and DOS services
; such that it will run properly under PC-DOS 1.0 up to MS-DOS 7.0/Win95, using
; File Control Blocks (note that FCBs don't on under Win95OSR2/Win98/WinME FAT32 drives).
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

; flags bitfield
FL_REDRAW		equ	0x01
FL_FULLREDRAW		equ	0x02
FL_STATUS_REDRAW	equ	0x04

; code segment
		segment .text

; setup segments
		mov	ax,cs
		mov	ds,ax
		xor	ax,ax
		mov	es,ax

; make sure 80x25 is set
		mov	ax,3
		int	10h

; autodetect mono/stereo
		int	11h
		and	al,0x30		; bits 5-4 initial video mode
		cmp	al,0x30		; if bits 5-4 are both 1 then mono
		jne	not_mono
		mov	byte [vseg+1],0xB0	; change 0xB800 to 0xB000 if mono or hercules
not_mono:

; main loop
mainloop:	call	do_redraw
		call	do_status_redraw
		call	do_keyboard_input
		jmp	short mainloop

; exit
exit2dos:	mov	ah,2
		xor	bh,bh
		mov	dx,0x1800	; DH=0x18 (24) DL=0x00
		int	10h

		xor	ax,ax		; AH=0
		int	21h
		hlt

; redraw
do_redraw:	test	word [flags],FL_REDRAW		; are we to redraw?
		jnz	.doit
		ret
.doit:		and	word [flags],~FL_REDRAW		; clear redraw flag
		push	ds
		push	es
		cld
		xor	di,di
		xor	si,si
		mov	cx,24
		mov	ds,[cs:viewseg]
		mov	es,[cs:vseg]
; so, DS=segment to dump  ES=video ram
.rowdraw:	push	cx
		push	di

; row #1: segment
		mov	bx,ds
		mov	ah,0x07

; set color to yellow if selected, else gray
		cmp	bx,[cs:selseg]
		jnz	.row_start
		mov	ah,0x0E

; draw segment value
.row_start:	mov	cl,4
		mov	dx,4

		push	si
.row_segment:	rol	bx,cl
		push	bx
		and	bx,0xF
		mov	al,[cs:hexes+bx]
		stosw
		pop	bx
		dec	dx
		jnz	.row_segment
		pop	si

; space
		mov	al,' '
		stosw
		stosw

; hex digits
		push	si
		mov	dx,16		; NTS CL=4 still
		xor	bh,bh
.row_hexdigits:	mov	ch,[si]
		inc	si

		mov	bl,ch
		rol	bl,cl
		and	bl,0xF
		mov	al,[cs:hexes+bx]
		stosw

		mov	bl,ch
		and	bl,0xF
		mov	al,[cs:hexes+bx]
		stosw

		mov	al,' '
		stosw

		dec	dx
		jnz	.row_hexdigits
		pop	si

		stosw

; raw chars
		push	si
		mov	dx,16		; NTS CL=4 still
.row_rawdigits:	lodsb
		stosw
		dec	dx
		jnz	.row_rawdigits
		pop	si

; end of row, increment to next row or exit
		pop	di
		pop	cx
		mov	ax,ds
		inc	ax
		mov	ds,ax
		add	di,80*2
		loop	.rowdraw

; done drawing
		pop	es
		pop	ds
		ret

; status redraw
do_status_redraw:
		test	word [flags],FL_STATUS_REDRAW	; are we to redraw?
		jnz	.doit
		ret
.doit:		and	word [flags],~FL_STATUS_REDRAW	; clear redraw flag

		cld
		mov	es,[cs:vseg]
		mov	si,[cs:status_str]
		mov	di,80*2*24
		mov	ah,0x0A
.l1:		lodsb
		or	al,al
		jz	.l1e
		stosw
		jmp	short .l1
.l1e:

		ret

; keyboard input
do_keyboard_input:
		mov	ah,8		; character input w/o echo
		int	21h
		cmp	al,0		; extended chars start with 0
		jz	.ext_key
; non-extended key
		cmp	al,27
		jz	.key_exit2dos
		cmp	al,'G'		; shift+G = go to
		jz	.key_goto_prompt
		cmp	al,'C'		; shift+C = go to code
		jz	.key_goto_code
		ret
; extended key processing, so we're reading the second char
.ext_key:	mov	ah,8
		int	21h
; extended key in AL
		cmp	al,0x48		; up arrow
		jz	.key_uparrow
		cmp	al,0x49		; page up
		jz	.key_pageup
		cmp	al,0x50		; down arrow
		jz	.key_downarrow
		cmp	al,0x51		; page down
		jz	.key_pagedown
		ret
; ESC: exit to dos
.key_exit2dos:	jmp	exit2dos
; SHIFT+G = GOTO
.key_goto_prompt:mov	word [entry_word],0
		jmp	goto_prompt
; SHIFT+C = goto code
.key_goto_code:	mov	ax,cs
		mov	[selseg],ax
		mov	[viewseg],ax
		or	word [flags],FL_FULLREDRAW | FL_REDRAW
		ret
; UP ARROW
.key_uparrow:	mov	ax,[selseg]
		mov	bx,ax
		dec	ax
		mov	[selseg],ax
		cmp	bx,[viewseg]
		jnz	.key_uparrow_noviewscroll
		mov	[viewseg],ax
.key_uparrow_noviewscroll:
		or	word [flags],FL_FULLREDRAW | FL_REDRAW
		ret
; DOWN ARROW
.key_downarrow:	mov	ax,[selseg]
		mov	bx,ax
		sub	bx,23
		inc	ax
		mov	[selseg],ax
		cmp	bx,[viewseg]
		jnz	.key_downarrow_noviewscroll
		inc	bx
		mov	[viewseg],bx
.key_downarrow_noviewscroll:
		or	word [flags],FL_FULLREDRAW | FL_REDRAW
		ret
; PAGE UP
.key_pageup:	mov	ax,[selseg]
		sub	ax,23
		mov	[selseg],ax
		mov	[viewseg],ax
		or	word [flags],FL_FULLREDRAW | FL_REDRAW
		ret
; PAGE DOWN
.key_pagedown:	mov	ax,[selseg]
		mov	[viewseg],ax
		add	ax,23
		mov	[selseg],ax
		or	word [flags],FL_FULLREDRAW | FL_REDRAW
		ret

;-----------------------------------------------
; goto prompt
;-----------------------------------------------
goto_prompt:	; move cursor to bottom of screen
		mov	ah,0x02
		xor	bh,bh
		mov	dx,0x1800	; DH=0x18 (24) DL=0x00
		int	10h

		; newline
		mov	ah,0x09
		mov	dx,str_goto_prompt
		int	21h

		; prompt
		mov	word [entry_word_buf+0],0x0005 ; 4 chars + newline
		mov	byte [entry_word_buf+2],13
		mov	ah,0x0A
		mov	dx,entry_word_buf
		int	21h

		; parse input
		cld
		mov	cl,4
		xor	bx,bx
		mov	si,entry_word_buf+2
.l1:		call	loadhexdigit
		jc	.l1e
		shl	bx,cl
		or	bl,al
		jmp	short .l1
.l1e:		mov	[selseg],bx
		mov	[viewseg],bx

		; return (out of keyboard call)
		or	word [flags],FL_FULLREDRAW | FL_REDRAW | FL_STATUS_REDRAW
		ret

; loadhexdigit
; input:
;     DS:SI=char to parse
; output:
;     AL=hex digit
;     CF=0
;   or
;     CF=1
loadhexdigit:	lodsb
		or	al,0x20
		sub	al,'0'
		jc	.fail
		cmp	al,10
		jl	.ok
		sub	al,'a' - ('0' + 10)
		jc	.fail
		cmp	al,15
		ja	.fail
.ok:		clc
		ret
.fail:		stc
		ret

		segment .data

str_goto_prompt:db	13,10,'Go to segment: $'
hexes:		db	'0123456789ABCDEF'
flags:		dw	FL_REDRAW | FL_FULLREDRAW | FL_STATUS_REDRAW
default_status:	db	'ESC=quit  Shift+G=goto  Shift+C=codeseg  Use arrow keys',0

vseg:		dw	0xB800
viewseg:	dw	0
selseg:		dw	0
status_str:	dw	default_status

		segment .bss

entry_word:	resw	1
entry_word_buf:	resb	2+6

