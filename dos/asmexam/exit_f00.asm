;--------------------------------------------------------------------------------------
; EXIT_F00.COM
; 
; MS-DOS 1.0 compatible exit to DOS using INT 21h AH=0x00
;
; http://www.ctyme.com/intr/rb-2551.htm
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		xor	ah,ah
		int	21h

