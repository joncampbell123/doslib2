;--------------------------------------------------------------------------------------
; INT21_0D.COM
; 
; Flush disk buffers, disk reset
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		mov	ah,0x0D
		int	21h

		ret

