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
		mov	[user_val+2],ax	; set 32-bit value to 0

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

		; DX:AX *= 10
		push	ax
		mov	ax,[user_val]
		mov	dx,[user_val+2]	; DX:AX = 32-bit current value
		mov	bx,10		; BX = what to multiply by
		call	dx_ax_mul
		mov	[user_val],ax
		mov	[user_val+2],dx
		pop	ax
		; DX:AX += digit
		add	[user_val],ax
		adc	word [user_val+2],0

		jmp	short scan

scan_end:	mov	dx,[user_val+2]	; DX:AX = LARGE_VALUE
		mov	ax,[user_val]
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

;----------------------------------------
; entry: DX:AX = 32-bit value
;        BX = 16-bit value to multiply by
; exit: DX:AX = result
dx_ax_mul:	push	dx
		mul	bx		; DX:AX = input AX * BX
		mov	[dx_ax_mul_tmp],ax
		mov	[dx_ax_mul_tmp+2],dx
		pop	ax
		mul	bx		; DX:AX = input DX * BX
		add	ax,[dx_ax_mul_tmp+2]
		mov	dx,[dx_ax_mul_tmp]
		xchg	ax,dx
		ret

;------------------------------------
; entry: DX:AX = 32-bit value
;        BX = 16-bit value to divide by
; exit: DX:AX = result
;       BX = remainder
;
;        __________
;     BX ) DX:AX     => DX:AX remainder BX
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

dx_ax_div_tmp:	resw	1
dx_ax_mul_tmp:	resw	2

user_val:	resd	1

