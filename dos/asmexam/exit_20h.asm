;--------------------------------------------------------------------------------------
; EXIT_20H.COM
; 
; Proof of concept next-smallest DOS program that exits to DOS.
;
; INT 20h is another interrupt vector that DOS programs can use to terminate safely
;
; http://www.ctyme.com/intr/rb-2471.htm
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		int	20h

