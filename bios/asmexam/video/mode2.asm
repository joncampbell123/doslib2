;--------------------------------------------------------------------------------------
; MODE2.COM
; 
; Use the BIOS to set mode 2 (80x25 alphanumeric) mono
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		mov	ax,2
		int	10h

		ret

