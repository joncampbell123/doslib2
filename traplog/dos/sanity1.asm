;--------------------------------------------------------------------------------------
; SANITY1.COM
;
; Sets registers to specific values, to test that the trap flag logging utility works
; correctly
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

; the first instruction is a NOP. whether or not it gets skipped in trap flag logging
; is noted by the instruction pointer. nothing else gets changed.
;
; The purpose is to understand exactly what the CPU does immediately after TFL8086.COM
; transfers control via IRET: Does it execute the instruction then trigger INT 0x01?
; or does it trigger INT 0x01 and then execute the instruction?
;
; Results so far:
;   MS-DOS 6.22 + QEMU i386 emulation: IRET -> EXECUTE NOP -> TRAP INTERRUPT

		nop			; just in case

; set registers up.
;
; Trap interrupt ordering:
;   Testing so far shows that when the CPU executes the trap interrupt, CS:IP points
;   at the instruction it is about to execute, not what it just executed.

		mov	ax,0x1234
		mov	bx,0x5678
		mov	cx,0x9ABC
		mov	dx,0xDEF0
		mov	si,0x1234
		mov	di,0x5678
		mov	bp,0x9ABC
		push	ax		; push and pop things to make SP change
		pop	ax

		xor	ax,ax
		mov	es,ax		; make ES change

		mov	ax,0x1234
		mov	ds,ax		; make DS change

		pushf
;		^ NTS: Some CPUs and emulators do NOT trigger the trap interrupt
;		       for this instruction!
;
;                      MS-DOS 6.22 + QEMU i386: No
		cli
		mov	ax,0x5678	; make SS change
		mov	ss,ax
;		^ NTS: This instruction modifies the stack pointer, and therefore
;		       by 8086 convention, the CPU will not issue a trap interrupt
;		       for the next instruction.
		mov	ax,cs
		mov	ss,ax
;		^ NTS: Same issue: we modified SS, so the CPU will not trigger
;		       the trap interrupt for the "NOP" that follows
		nop
		popf
;		^ NTS: The CPU will normally trap for this POPF. however if a
;		       program really wanted to, it could put a MOV SS,AX before
;		       it to give itself a window of opportunity to forcibly turn
;		       off the trap flag. Which is why you are warned that trap
;		       flag logging is not 100% foolproof.

		cli			; make EFLAGS change
		sti
		cli
		clc
		stc
		std
		cld
		clc

; done. exit
		mov	ax,0x4C00
		int	21h

		segment .data

		segment .bss

