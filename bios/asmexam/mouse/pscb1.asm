;--------------------------------------------------------------------------------------
; PSCB1.COM
; 
; Call to set INT 15h device hook, enable, watch, disable
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		push	cs
		pop	ds

		mov	ax,0xC207	; set device handler addr
		mov	bx,cs
		mov	es,bx
		mov	bx,ps2_dev_cb	; ES:BX = PS/2 device callback
		int	15h
		call	int15_print_err

		mov	ax,0xC200	; enable/disable
		mov	bh,0x01		; enable
		int	15h
		call	int15_print_err

loop1:		xor	ah,ah
		int	16h
		cmp	al,13
		jnz	loop1

		mov	ax,0xC200	; enable/disable
		mov	bh,0x00		; disable
		int	15h
		call	int15_print_err

		mov	ax,0xC207	; set device handler addr
		xor	bx,bx
		mov	es,bx		; ES:BX = 0x0000:0x0000 disable CB
		int	15h
		call	int15_print_err

		ret

; PS/2 device callback:
ps2_dev_cb:	push	ds
		push	bx
		mov	bx,0xB800
		mov	ds,bx
		xor	bx,bx
		inc	byte [bx]
		pop	bx
		pop	ds
		retf

; print INT 15h error
int15_print_err:pushf
		jc	failed		; carry set if error
		or	ah,ah
		jnz	failed		; AH != 0 if error
		mov	ah,9
		mov	dx,str_ok
		int	21h
		popf
		ret
failed:		mov	bl,ah		; BX = (AH * 2)
		cmp	bl,6		; if BX > 6 then BX = 6 (range-check)
		jbe	.bl_range
		mov	bl,6
.bl_range:	xor	bh,bh
		add	bx,bx
		mov	dx,[strtbl+bx-2]
		mov	ah,9
		int	21h
		popf
		ret

str_ok:		db	"OK",13,10,"$"

str_e01:	db	"invalid function",13,10,"$"
str_e02:	db	"invalid input",13,10,"$"
str_e03:	db	"interface error",13,10,"$"
str_e04:	db	"need to resend",13,10,"$"
str_e05:	db	"no device handler installed (expected)",13,10,"$"
str_e06:	db	"?? unknown return value (please use DEBUG.COM to diagnose)",13,10,"$"

strtbl:		dw	str_e01
		dw	str_e02
		dw	str_e03
		dw	str_e04
		dw	str_e05
		dw	str_e06

