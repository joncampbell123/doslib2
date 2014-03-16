;--------------------------------------------------------------------------------------
; SANITY4.COM
;
; Tests whether or not the trap logger traces into exceptions (it doesn't) and whether
; or not we are able to catch exceptions while TF'd by hooking the vector.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		nop			; placeholder in case CPU skips first instruction before TRAP

; take INT 06h
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

; execute an invalid opcode.
; 8086/8088: it will execute POP CS followed by OR DX,[BX+SI-0x6F70], which is why we PUSH CS first
; 286 or higher: INT 6h will trigger
		push	cs
		db	0x0F,0x0B	; invalid opcode UD2
		nop
		nop
		nop
		nop

; load invalop value to make the counter visible
		mov	ax,word [cs:invalop]

; restore INT 06h
		push	es
		xor	ax,ax
		mov	es,ax
		mov	bx,word [old_06h]
		mov	cx,word [old_06h+2]
		mov	word [es:(0x06*4)+0],bx
		mov	word [es:(0x06*4)+2],cx
		pop	es

; done. exit
		mov	ax,0x4C00
		int	21h

; int 06h vector
new_06h:	inc	word [cs:invalop]
		mov	bp,sp
		add	word [bp],2		; skip the invalid opcode (IP += 2)
		iret

invalop:	dw	0

		segment .data

		segment .bss

old_06h:	resw	2

