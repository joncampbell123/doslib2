;--------------------------------------------------------------------------------------
; SANITY6.COM
;
; 286 or higher: test whether it catches attempts to execute LMSW
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		nop			; placeholder in case CPU skips first instruction before TRAP
		xor	ax,ax
		lmsw	ax		; fake out for testing: this clears protected mode

; done. exit
		mov	ax,0x4C00
		int	21h

		segment .data

		segment .bss

tmp:		resd	1

