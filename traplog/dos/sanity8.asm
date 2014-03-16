;--------------------------------------------------------------------------------------
; SANITY8.COM
;
; 386 or higher: test capture of floating point state
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		nop			; placeholder in case CPU skips first instruction before TRAP

		finit
		fld	qword [f_1]
		fld	qword [f_2]
		fadd	st0,st1

; done. exit
		mov	ax,0x4C00
		int	21h

		segment .data

f_1:		dq	1.0
f_2:		dq	2.0

		segment .bss

tmp:		resd	1

