;--------------------------------------------------------------------------------------
; INT21_0A.COM
;
; Buffered input test
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory
		section .text

		push	cs
		pop	ds

		mov	ah,0x0A		; buffered input, first pass
		mov	dx,buffer
		int	21h

		mov	bl,[buffer+1]	; number of chars
		xor	bh,bh
		mov	byte [bx+buffer+2],'$' ; write '$' after the last char

		mov	ah,0x09
		mov	dx,yousaid
		int	21h

		mov	ah,0x09		; print string
		mov	dx,buffer+2
		int	21h

		mov	ah,0x09
		mov	dx,crlf
		int	21h

		mov	ah,0x0A		; buffered input, second pass
		mov	dx,buffer
		int	21h

		mov	bl,[buffer+1]	; number of chars
		xor	bh,bh
		mov	byte [bx+buffer+2],'$' ; write '$' after the last char

		mov	ah,0x09
		mov	dx,yousaid
		int	21h

		mov	ah,0x09		; print string
		mov	dx,buffer+2
		int	21h

		mov	ah,0x09
		mov	dx,crlf
		int	21h

		ret

yousaid:	db	'You said $'
crlf:		db	13,10,'$'

buffer:		db	80		; size of buffer
		db	0		; number of chars from last input

		section .bss

		resb	80		; the actual chars. assigned to the space past the end of the COM image

