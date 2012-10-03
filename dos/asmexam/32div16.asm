;--------------------------------------------------------------------------------------
; 32DIV16.COM
; 
; Demonstrates how to divide a 32-bit number from 16-bit real mode using 8086
; instructions, which are limited to 16-bit quantities. This implementation is limited
; to dividing a 32-bit number by a 16-bit number.
;
; We use it here to print a 32-bit unsigned integer.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

LARGE_VALUE	equ	1234567890

		mov	dx,(LARGE_VALUE >> 16)	; DX:AX = LARGE_VALUE
		mov	ax,(LARGE_VALUE & 0xFFFF)
		call	putdec32

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
; entry: DX:AX = 32-bit value to print
putdec32:	push	ax
		push	bx
		push	cx
		push	dx

		mov	cx,1
		mov	bx,10
		call	dx_ax_div	; returns result in DX:AX and remainder in BX
		push	bx

putdec32_loop:	mov	bx,ax
		or	bx,dx		; BX = DX|AX
		jz	putdec32_ploop	; if BX == 0 (which means DX:AX == 0) then stop
		inc	cx
		mov	bx,10
		call	dx_ax_div	; returns result in DX:AX and remainder in BX
		push	bx
		jmp	short putdec32_loop

putdec32_ploop:	pop	ax
		add	al,'0'
		call	putc
		loop	putdec32_ploop

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;------------------------------------
; entry: DX:AX = 32-bit value
;        BX = 16-bit value to divide by
; exit: DX:AX = result
;       BX = remainder
;
;          [1][2]
;        __________
;     BX ) DX:AX     => DX:AX remainder BX
;
;       [1] = first WORD of dx_ax_div_res1
;       [2] = second WORD of dx_ax_div_res1
dx_ax_div:	push	dx
		push	ax		; step #1: save DX:AX, then compute DX / BX
		mov	ax,dx
		xor	dx,dx
		div	bx		; result => DX=remainder AX=result
		mov	[dx_ax_div_tmp],ax	; result becomes upper WORD of output
		pop	ax		; AX = original lower WORD, DX = remainder of first division
		div	bx		; result => DX=remainder AX=result
		mov	bx,dx		; store remainder too
		pop	dx
		mov	dx,[dx_ax_div_tmp]
		ret

		section .data

		section .bss

dx_ax_div_tmp:	resw	2

