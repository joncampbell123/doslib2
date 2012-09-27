;--------------------------------------------------------------------------------------
; FCB_PSP.COM
; 
; Show the first two FCBs in the Program Segment Prefix, if DOS initialized them
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	bx,0x5C
		call	puts_fcb

		mov	bx,0x6C
		call	puts_fcb

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

crlf:		db	13,10,'$'

		segment .bss

fcb:		resb	0x25

; WARNING: We don't know how large DOS will make the record size, therefore this must be last!
dta:		resb	0x100

