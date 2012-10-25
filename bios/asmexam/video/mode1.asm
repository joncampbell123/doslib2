;--------------------------------------------------------------------------------------
; MODE1.COM
; 
; Use the BIOS to set mode 1 (40x25 alphanumeric)
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		mov	ax,1
		int	10h

		ret

