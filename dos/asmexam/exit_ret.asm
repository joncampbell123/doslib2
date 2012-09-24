;--------------------------------------------------------------------------------------
; EXIT_RET.COM
; 
; Proof of concept smallest DOS program that exits to DOS.
; This works because DOS (for CPM compatibility) stores 0x0000 on the stack when
; starting a program. If you return to 0x0000, you end up at CS:0 where DOS stored
; 0xCD 0x20 (INT 20h), thus safely terminating the program.
;
; For more information see:
; http://en.wikipedia.org/wiki/Program_Segment_Prefix
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		ret

