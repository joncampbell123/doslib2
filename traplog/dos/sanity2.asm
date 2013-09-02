;--------------------------------------------------------------------------------------
; SANITY2.COM
;
; Tests that the program is able to detect simple cases of attempting to break out of
; trap flag logging.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		nop			; placeholder in case CPU skips first instruction before TRAP

; try to break out of trap flag logging using the simplest
; and dumbest of methods
		pushf
		pop	ax
		and	ax,~0x100	; clear TF
		push	ax
		popf

; RESULTS:
;    MS-DOS 6.22 + QEMU i386: The CPU appears to issue one more TRAP after POPF,
;      which clearly shows the TF bit having been reset. Assuming the real deal
;      does that, it means continuing the trace is as simple as setting the TF
;      bit again.

; what if I attempt to break out using IRET?
		pushf
		pop	ax
		and	ax,~0x100	; clear TF
		push	ax
		push	cs
		push	iret_jmp1
		iret			; GO!
iret_jmp1: ; <- Tadaaaaaah!

; RESULTS:
;    MS-DOS 6.22 + QEMU i386: The CPU appears to issue one more TRAP after POPF,
;      which clearly shows the TF bit having been reset. Assuming the real deal
;      does that, it means continuing the trace is as simple as setting the TF
;      bit again.

; done. exit
		mov	ax,0x4C00
		int	21h

		segment .data

		segment .bss

