;--------------------------------------------------------------------------------------
; TF_PREFIX.COM
; Test CPU prefixes and how it reacts to them, including combined prefixes and over-long
; prefix sequences.
; Meant to run from within TFL8086.COM to log each instruction.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		cli			; clear interrupts (will be skipped by TF log mechanism)

; take INT 06h. our prefix tests might trigger invalid opcodes
		push	es
		xor	ax,ax
		mov	es,ax
		mov	bx,[es:(0x06*4)+0]
		mov	cx,[es:(0x06*4)+2]
		mov	word [old_06h],bx
		mov	word [old_06h+2],cx
		mov	word [es:(0x06*4)+0],new_06h
		mov	word [es:(0x06*4)+2],cs
		pop	es

; =================== plain NOP
		nop

; =================== NOP with prefixes
nop_prefix:	mov	word [cs:ret_06h],.fault_seg_nop

		es
		nop

		ds
		nop

		cs
		nop

		ss
		nop

		stc			; NO FAULT MARKER
.fault_seg_nop:	clc			; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------
		mov	word [cs:ret_06h],.fault_rep_nop

		rep
		nop

		stc			; NO FAULT MARKER
.fault_rep_nop:	clc			; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------
		mov	word [cs:ret_06h],.fault_repnz_nop

		repz
		nop

		repnz
		nop

		stc			; NO FAULT MARKER
.fault_repnz_nop:clc			; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------
		mov	word [cs:ret_06h],.fault_lock_nop

; LOCK NOP. Works fine on 8086 and emulators. Modern CPUs will trigger an invalid opcode exception here
		db	0xF0		; lock, written directly so NASM doesn't state the obvious "the instruction is not lockable"
		nop

		stc			; NO FAULT MARKER
.fault_lock_nop:clc			; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------
		mov	word [cs:ret_06h],.fault_lock_xchg

; LOCK NOP. Works fine on 8086 and emulators. Modern CPUs will trigger an invalid opcode exception here
		db	0xF0		; lock, written directly so NASM doesn't state the obvious "the instruction is not lockable"
		xchg	ax,bx		; LOCK XCHG reg,reg. might work. might be unsupported

		stc			; NO FAULT MARKER
.fault_lock_xchg:clc			; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------
		mov	word [cs:ret_06h],.fault_lock_xchg_mem

		push	cs
		pop	ds
		mov	si,junk		; do the XCHG with the "junk" data in our segment
		db	0xF0		; lock, written directly so NASM doesn't state the obvious "the instruction is not lockable"
		xchg	ax,[si]		; LOCK XCHG reg,mem. this is supposedly the only legal LOCKable instruction supported.

		stc			; NO FAULT MARKER
.fault_lock_xchg_mem:clc		; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------

; =================== NOP with 2 prefixes
nop_2prefix:	mov	word [cs:ret_06h],.fault_seg_nop

		es
		es
		nop

		ds
		ds
		nop

		cs
		cs
		nop

		ss
		ss
		nop

		stc			; NO FAULT MARKER
.fault_seg_nop:	clc			; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------
		mov	word [cs:ret_06h],.fault_rep_nop

		rep
		rep
		nop

		stc			; NO FAULT MARKER
.fault_rep_nop:	clc			; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------
		mov	word [cs:ret_06h],.fault_repnz_nop

		repz
		repz
		nop

		repnz
		repnz
		nop

		stc			; NO FAULT MARKER
.fault_repnz_nop:clc			; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------
		mov	word [cs:ret_06h],.fault_lock_nop

; LOCK NOP. Works fine on 8086 and emulators. Modern CPUs will trigger an invalid opcode exception here
		db	0xF0		; lock, written directly so NASM doesn't state the obvious "the instruction is not lockable"
		db	0xF0
		nop

		stc			; NO FAULT MARKER
.fault_lock_nop:clc			; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------

; =================== NOP with overlong prefixes
nop_lprefix:	mov	word [cs:ret_06h],.fault_seg_long

		es
		es
		es
		nop			; ES x 3

		es
		es
		es
		es
		nop			; ES x 4

		es
		es
		es
		es
		es
		nop			; ES x 5

		es
		es
		es
		es
		es
		es
		nop			; ES x 6

		es
		es
		es
		es
		es
		es
		es
		nop			; ES x 7

		es
		es
		es
		es
		es
		es
		es
		es
		nop			; ES x 8

		es
		es
		es
		es
		es
		es
		es
		es
		es
		nop			; ES x 9

		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		nop			; ES x 10

		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		nop			; ES x 11

		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		nop			; ES x 12

		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		nop			; ES x 13

		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		es
		nop			; ES x 14

		; <- NTS: We stop at 15 ES's and a NOP because Sun/Oracle VirtualBox will "hang" re-executing the
		;         over-long prefix sequence without advancing.

		stc			; NO FAULT MARKER
.fault_seg_long:clc			; END OF TEST (CLC used to mark this)
; ---------------------------------------------------------

; restore INT 06h
		push	es
		xor	ax,ax
		mov	es,ax
		mov	bx,word [old_06h]
		mov	cx,word [old_06h+2]
		mov	word [es:(0x06*4)+0],bx
		mov	word [es:(0x06*4)+2],cx
		pop	es

; =================== END
		ret

; int 06h vector.
; NTS: TFL8086.COM cannot trap-flag log execution during this fault handler.
;      Logging the fault handler happens to work for SANITY4.COM apparently because
;      UD2 (0x0F 0x0B) causes the CPU to single-step the INT 6 fault handler. A real
;      case of invalid opcode does not trigger that behavior and this handler would
;      not be logged at all.
new_06h:	add	sp,2		; discard offset
		mov	bp,.fault_jmp	; replace offset
		push	bp		; load it as the offset
		iret			; IRET to .fault_jmp
.fault_jmp:	jmp	word [cs:ret_06h] ; jump to fault routine.
		; NTS: Because of the way trap flags work, the CPU will execute this JMP
		;      first after the fault handler THEN log the first instruction at CS:IP.
		;      This JMP will not show up in the trap flag log.

		segment .data

junk:		db			"This program is meant to run in TRAPLOG"

		segment .bss

old_06h:	resw	2
ret_06h:	resw	1

