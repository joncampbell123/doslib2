;--------------------------------------------------------------------------------------
; MODE3.COM
; 
; Use the BIOS to set mode 3 (80x25 alphanumeric)
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		mov	ax,3
		int	10h

		ret

