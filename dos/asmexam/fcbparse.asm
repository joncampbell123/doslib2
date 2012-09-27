;--------------------------------------------------------------------------------------
; FCBPARSE.COM
; 
; Demonstrates using INT 21h AH=0x29 PARSE FILENAME INTO FCB
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

		mov	si,0x81		; parse command line into FCB
		mov	di,fcb
		mov	ah,0x29
		mov	al,0x01		; skip leading separators
		int	21h
		cmp	al,0xFF
		jz	parse_fail

		call	puthex

		mov	ah,0x09
		mov	dx,crlf
		int	21h

		mov	bx,fcb
		call	puts_fcb

		ret

parse_fail:	mov	ah,0x09
		mov	dx,str_parse_fail
		int	21h
		ret

puts_fcb:	cld
		mov	cx,8		; print name
		lea	si,[bx+1]
		call	putslen
		mov	dl,'.'
		call	putcd
		mov	cx,3
		lea	si,[bx+1+8]
		call	putslen

		mov	ah,0x09
		mov	dx,crlf
		int	21h

		ret

; entry:
;   CX = number of chars
;   SI = string
putslen:	push	cx
putslenloop1:	lodsb
		cmp	al,' '
		jz	putslenloop2
		mov	dl,al
		mov	ah,0x02
		int	21h
putslenloop2:	loop	putslenloop1
		pop	cx
		ret

; entry:
;   DL = char
putcd:		mov	ah,0x02
		int	21h
		ret

; entry:
;   AL = single-digit binary to print as hexadecimal
puthex:		and	al,0xF
		cmp	al,10
		jb	puthexr
		add	al,'A' - 10 - '0'
puthexr:	add	al,'0'
		mov	dl,al
		call	putcd
		ret

		segment .data

str_parse_fail:	db	'Parse fail'
crlf:		db	13,10,'$'

		segment .bss

fcb:		resb	0x25

