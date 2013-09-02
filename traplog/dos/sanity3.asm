;--------------------------------------------------------------------------------------
; SANITY3.COM
;
; Tests whether or not the trap logger is able to follow interrupts.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		nop			; placeholder in case CPU skips first instruction before TRAP

; take INT 49h
		push	es
		xor	ax,ax
		mov	es,ax
		mov	bx,[es:(0x49*4)+0]
		mov	cx,[es:(0x49*4)+2]
		mov	word [old_49h],bx
		mov	word [old_49h+2],cx
		mov	word [es:(0x49*4)+0],new_49h
		mov	word [es:(0x49*4)+2],cs
		pop	es

; call int 49h
		int	49h		; Under normal circumstances, the trap flag is cleared upon INT xx it seems.
		nop			; <- Some CPUs and emulators: The CPU skips the first instruction following INT xx

; restore INT 49h
		push	es
		xor	ax,ax
		mov	es,ax
		mov	bx,word [old_49h]
		mov	cx,word [old_49h+2]
		mov	word [es:(0x49*4)+0],bx
		mov	word [es:(0x49*4)+2],cx
		pop	es

; done. exit
		mov	ax,0x4C00
		int	21h

; int 49h vector
new_49h:	mov	ax,0x1234
		mov	bx,0x5678
		iret

		segment .data

		segment .bss

old_49h:	resw	2

