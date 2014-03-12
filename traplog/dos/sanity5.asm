;--------------------------------------------------------------------------------------
; SANITY5.COM
;
; 386 or higher: test whether it captures all 32 bits of the 386 regs.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		nop			; placeholder in case CPU skips first instruction before TRAP
		push	cs
		pop	ds

; load registers with values
		cli
		mov	[tmp],esp
		mov	eax,0x12345678
		mov	ebx,0x87654321
		mov	ecx,0xABCDEF01
		mov	edx,0x10FEDCBA
		mov	esi,0x11223344
		mov	edi,0x44332211
		mov	ebp,0xAABBCCDD
		mov	esp,0xDDCCBBAA
		nop
		nop
		mov	esp,[tmp]

; make sure we can see EFLAGS by toggling bit 21 harmlessly
; NTS: Some emulators, including DOSBox, do not correctly restore
;      32-bit EFLAGS from the INT 1 trap interrupt and therefore
;      will lose the upper 16 bits on the next trap interrupt.
;      It's reasonable to assume there may be some non-Intel
;      processors that make the same mistake.
;
;      Note that because of this, the 386 builds of TFL8086.ASM
;      are written to overwrite the stack frame with a 32-bit
;      IRETD to ensure EFLAGS is restored properly.
		pushfd

		pushfd
		pop	eax
		xor	eax,1 << 21
		push	eax
		popfd

		nop
		nop

		popfd

		sti

; done. exit
		mov	ax,0x4C00
		int	21h

		segment .data

		segment .bss

tmp:		resd	1

