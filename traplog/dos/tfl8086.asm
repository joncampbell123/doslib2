;--------------------------------------------------------------------------------------
; TFL8086.COM
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

; read the command line, skip leading whitespace
		mov	si,0x81
ld1:		lodsb
		cmp	al,' '
		jz	ld1
		dec	si

; and then NUL-terminate the line
		mov	bl,[0x80]
		xor	bh,bh
		add	bl,0x81
		mov	byte [bx],0

; SI is still the (now ASCIIZ) string
		cmp	byte [si],0	; is it NULL-length?
		jnz	param_ok
		mov	dx,str_need_param
		call	puts
		ret			; return to DOS
param_ok:

		mov	ax,4C00h
		int	21h

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .text

str_need_param:	db	'Need a program to run'
crlf:		db	13,10,'$'

