;--------------------------------------------------------------------------------------
; 32MUL16.COM
; 
; Demonstrates how to multiply a 32-bit integer by a 16-bit integer.
;
; We use it here to scan a 32-bit number from the command line, and print it back out.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		xor	ax,ax
		mov	[user_val],ax
		mov	[user_val+2],ax
		mov	[user_val+4],ax
		mov	[user_val+6],ax	; set 64-bit value to 0

		cld
		mov	si,0x81		; DS:SI = command line
scan:		lodsb
		cmp	al,' '
		jz	scan
		cmp	al,0x0D
		jz	scan_end
		sub	al,'0'
		jb	scan
		cmp	al,'9'
		ja	scan
		xor	ah,ah

		; DX:CX:BX:AX *= 10
		push	ax
		push	si
		mov	ax,[user_val]
		mov	bx,[user_val+2]
		mov	cx,[user_val+4]
		mov	dx,[user_val+6]	; DX:CX:BX:AX = 64-bit current value
		mov	si,10		; SI = what to multiply by
		call	dx_cx_bx_ax_mul
		mov	[user_val],ax
		mov	[user_val+2],bx
		mov	[user_val+4],cx
		mov	[user_val+6],dx
		pop	si
		pop	ax
		; DX:CX:BX:AX += digit
		add	[user_val],ax
		adc	word [user_val+2],0
		adc	word [user_val+4],0
		adc	word [user_val+6],0

		jmp	short scan

scan_end:	mov	dx,[user_val+6]	; DX:CX:BX:AX = LARGE_VALUE
		mov	cx,[user_val+4]
		mov	bx,[user_val+2]
		mov	ax,[user_val]
		call	putdec64

		ret

;------------------------------------
putc:		push	ax
		push	bx
		push	cx
		push	dx
		mov	ah,0x02
		mov	dl,al
		int	21h
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;------------------------------------
; entry: DX:CX:BX:AX = 32-bit value to print
putdec64:	push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di

		mov	di,1
		mov	si,10
		call	dx_cx_bx_ax_div
		push	si

putdec64_loop:	mov	si,ax
		or	si,bx
		or	si,cx
		or	si,dx		; SI = DX|CX|BX|AX
		jz	putdec64_ploop	; if SI == 0 (which means DX:CX:AX:AX == 0) then stop
		inc	di
		mov	si,10
		call	dx_cx_bx_ax_div
		push	si
		jmp	short putdec64_loop

putdec64_ploop:	pop	ax
		add	al,'0'
		call	putc
		dec	di
		jnz	putdec64_ploop

		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;------------------------------------
; entry: DX:CX:BX:AX = 64-bit value
;        SI = 16-bit value to divide by
; exit: DX:CX:BX:AX = result
;       SI = remainder
;
;        __________
;     SI ) DX:CX:BX:AX     => DX:CX:BX:AX remainder SI
;
dx_cx_bx_ax_div:push	dx
		push	ax
		push	bx
		push	cx
		mov	ax,dx		; divide topmost word by SI
		xor	dx,dx
		div	si		; result => DX=remainder AX=result
		mov	[dx_cx_bx_ax_div_tmp+4],ax ; result becomes upper WORD of output

		pop	ax		; AX = next highest WORD (was CX), DX = remainder of last
		div	si		; result => DX=remainder AX=result
		mov	[dx_cx_bx_ax_div_tmp+2],ax ; result becomes next highest WORD of output

		pop	ax		; AX = next highest WORD (was BX), DX = remainder of last
		div	si		; result => DX=remainder AX=result
		mov	[dx_cx_bx_ax_div_tmp],ax ; result becomes next highest WORD of output

		pop	ax		; AX = lower WORD (was AX), DX = remainder of last
		div	si		; result => DX=remainder AX=result

		mov	si,dx		; store remainder too
		pop	dx
		mov	dx,[dx_cx_bx_ax_div_tmp+4]
		mov	cx,[dx_cx_bx_ax_div_tmp+2]
		mov	bx,[dx_cx_bx_ax_div_tmp]
		ret

;----------------------------------------
; entry: DX:CX:BX:AX = 64-bit value
;        BX = 16-bit value to multiply by
; exit: DX:CX:BX:AX = result
dx_cx_bx_ax_mul:push	dx
		push	cx
		push	bx
		mul	si		; DX:AX = input AX * SI
		mov	[dx_cx_bx_ax_mul_tmp],ax
		mov	[dx_cx_bx_ax_mul_tmp+2],dx
		xor	ax,ax
		mov	[dx_cx_bx_ax_mul_tmp+4],ax
		mov	[dx_cx_bx_ax_mul_tmp+6],ax
		pop	ax
		mul	si		; DX:AX = input BX * SI
		add	[dx_cx_bx_ax_mul_tmp+2],ax
		adc	word [dx_cx_bx_ax_mul_tmp+4],dx
		pop	ax
		mul	si		; DX:AX = input CX * SI
		add	[dx_cx_bx_ax_mul_tmp+4],ax
		adc	word [dx_cx_bx_ax_mul_tmp+6],dx
		pop	ax
		mul	si		; DX:AX = input DX * SI
		add	ax,[dx_cx_bx_ax_mul_tmp+6]
		mov	dx,[dx_cx_bx_ax_mul_tmp]
		xchg	ax,dx
		mov	bx,[dx_cx_bx_ax_mul_tmp+2]
		mov	cx,[dx_cx_bx_ax_mul_tmp+4]
		ret

		section .data

		section .bss

dx_cx_bx_ax_div_tmp:	resw	3
dx_cx_bx_ax_mul_tmp:	resw	4

user_val:		resd	2

