;--------------------------------------------------------------------------------------
; DPB_10.COM
;
; Ask DOS for the Disk Parameter Block.
; Well... PC-DOS 1.0 doesn't provide this function.
; This is not just conjecture, I took it upon myself
; to trace into the DOS kernel using DEBUG.COM and found the
; function responsible for the call:
;
; 00B1:00DD    MOV AL,0
; 00B1:00DE    RET
;
; This appears to be a stub function, which means that PC-DOS
; 1.0 does not provide the function, and therefore the Ralph Brown
; interrupt list is wrong on the subject of PC-DOS/MS-DOS 1.0.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		ret
