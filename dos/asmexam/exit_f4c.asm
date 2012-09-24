;--------------------------------------------------------------------------------------
; EXIT_F4C.COM
; 
; The normal method used by DOS programs to terminate and exit to DOS.
; INT 21h AH=4Ch. Not supported by anything older than MS-DOS 2.0
;
; http://www.ctyme.com/intr/rb-2974.htm
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		mov	ax,4C00h
		int	21h

