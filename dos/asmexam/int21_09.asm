;--------------------------------------------------------------------------------------
; INT21_09.COM
;
; Print $-terminated string.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		push	cs
		pop	ds
		mov	dx,stringofs
		mov	ah,0x09		; console input
		int	21h

		ret

stringofs:	db	"This is a string",13,10,'$'

