;--------------------------------------------------------------------------------------
; TSRNDOS1.COM
;
; Terminate and stay resident, MS-DOS 1.x style. It doesn't do anything other than
; leave a signature in memory you can see with a debugger or memory dumping tool.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		; NTS: At least on MS-DOS 6.22, the DOS kernel converts to paragraphs
		;      and rounds UP, so we don't need to pad the byte count.
		mov	dx,end_of_image ; DX = number of BYTES to keep resident
					; CS = PSP segment
		int	27h

signature:	db	'TSR null is resident'
end_of_image:	equ	$

