;--------------------------------------------------------------------------------------
; INT21_01.COM
; 
; Demonstrates using INT 21h AH=01 to read STDIN.
; DOS echoes input when reading this way.
; You can terminate the program using CTRL+C or CTRL+Z (EOF)
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

loop1:		mov	ah,0x01
		int	21h
		cmp	al,26		; CTRL+Z?
		jnz	loop1		; if not, keep going

		ret

