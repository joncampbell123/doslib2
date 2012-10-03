;--------------------------------------------------------------------------------------
; 64DIV16.COM
; 
; Demonstrates how to divide a 64-bit number from 16-bit real mode using 8086
; instructions, which are limited to 16-bit quantities. This implementation is limited
; to dividing a 64-bit number by a 16-bit number.
;
; We use it here to print a 64-bit unsigned integer.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		mov	dx,0xAB54	; DX:CX:DX:AX = 12345678901234567890 = 0xAB54'A98C'EB1F'0AD2
		mov	cx,0xA98C	; It's likely NASM can't handle constants that large,
		mov	bx,0xEB1F	; so don't try!
		mov	ax,0x0AD2
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

		section .data

		section .bss

dx_cx_bx_ax_div_tmp:resw	3

