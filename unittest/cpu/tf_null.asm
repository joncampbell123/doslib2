;--------------------------------------------------------------------------------------
; TF_NULL.COM
; Test trap flag sanity by executing NOPs.
; Meant to run from within TFL8086.COM to log each instruction.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		cli			; clear interrupts (will be skipped by TF log mechanism)

		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

		ret

		db			"This program is meant to run in TRAPLOG"

