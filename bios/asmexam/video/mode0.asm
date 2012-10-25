;--------------------------------------------------------------------------------------
; MODE0.COM
; 
; Use the BIOS to set mode 0 (40x25 alphanumeric) mono
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		xor	ax,ax
		int	10h

		ret

