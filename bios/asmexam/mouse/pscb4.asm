;--------------------------------------------------------------------------------------
; PSCB4.COM
; 
; Call to set INT 15h device hook, enable, watch, disable. Print out stack.
; This version tests whether or not you can get the BIOS to return the incoming
; PS/2 data byte-at-a-time. This time, we tell the BIOS 0 bytes at a time (Win98 style)
;--------------------------------------------------------------------------------------
		segment	.code

		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		push	cs
		pop	ds

		mov	ax,0x1234
		call	putc_hex16

		mov	dx,str_crlf
		mov	ah,9
		int	21h

		mov	word [out_buf_i],out_buf
		mov	word [out_buf_o],out_buf

		mov	ax,0xC201	; reset (also ensures the PS/2 mouse is taken out of Intellimouse mode)
		int	15h		; NTS: apparently though this also puts the BIOS into a byte-at-a-time callback mode?
		call	int15_print_err

		mov	ax,0xC205	; initialize
		xor	bh,bh		; 0 bytes at a time (apparently Win98 calls this BIOS this way?). May fail.
		int	15h		; But, if this fails, we get byte-at-a-time anyway because of how most BIOSes set up after the reset call anyway.
		call	int15_print_err

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

loop1:		cli
		mov	di,[out_buf_i]
		mov	si,[out_buf_o]
		cmp	di,si
		jz	.nothing
		mov	bx,si
		add	si,UNIT_SIZE
		cmp	si,out_buf_end
		jb	.nowrap
		mov	si,out_buf
.nowrap:	mov	[out_buf_o],si

		mov	ax,[bx]
		call	putc_hex16
		mov	al,' '
		call	putc

		mov	ax,[bx+2]
		call	putc_hex16
		mov	al,' '
		call	putc

		mov	ax,[bx+4]
		call	putc_hex16
		mov	al,' '
		call	putc

		mov	ax,[bx+6]
		call	putc_hex16
		mov	al,' '
		call	putc

		mov	ax,[bx+8]
		call	putc_hex16

		mov	dx,str_crlf
		mov	ah,9
		int	21h

.nothing:	sti

		mov	ah,1
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
		push	si
		push	di
		push	dx
		push	cx
		push	bx
		push	ax
		push	bp

		; VGA
		mov	bx,0xB800
		mov	ds,bx
		xor	bx,bx
		inc	byte [bx]

		; Okay, store it
		push	cs
		pop	ds
		mov	si,[out_buf_i]
		mov	bp,sp
		add	bp,(10*2)	; point just beyond the stack (8 regs + RETF)
					; WORD 4 0x0000 [bp+0]
					; WORD 3 Y data [bp+2]
					; WORD 2 X data [bp+4]
					; WORD 1 status [bp+6]
		mov	ax,[bp+8]
		mov	[si+0],ax
		mov	ax,[bp+6]
		mov	[si+2],ax
		mov	ax,[bp+4]
		mov	[si+4],ax
		mov	ax,[bp+2]
		mov	[si+6],ax
		mov	ax,[bp+0]
		mov	[si+8],ax
		add	si,UNIT_SIZE
		cmp	si,out_buf_end
		jb	.nowrap
		mov	si,out_buf
.nowrap:	mov	[out_buf_i],si

		; VGA
		mov	bx,0xB800
		mov	ds,bx
		mov	bx,2
		sub	si,out_buf
		add	si,0x0700
		mov	[bx],si

.skipit:	pop	bp
		pop	ax
		pop	bx
		pop	cx
		pop	dx
		pop	di
		pop	si
		pop	ds
		retf

; putc AL=char
putc:		push	ax
		push	dx
		mov	ah,0x02
		mov	dl,al
		int	21h
		pop	dx
		pop	ax
		ret

; putc_hex16 AX=hex
putc_hex16:	push	ax
		push	bx
		push	cx
		push	di
		cld
		mov	cl,4
		rol	ax,cl
		mov	cx,4
.loop:		push	ax
		and	ax,0xF
		mov	bx,ax
		add	bx,str_hex
		mov	al,[bx]
		call	putc
		pop	ax
		push	cx
		mov	cl,4
		rol	ax,cl
		pop	cx
		loop	.loop
		pop	di
		pop	cx
		pop	bx
		pop	ax
		ret

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

		segment	.data

str_hex:	db	"0123456789ABCDEF"
str_ok:		db	"OK",13,10,"$"
str_crlf:	db	13,10,"$"

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

		segment .bss

UNIT_SIZE	EQU	10

str_tmp:	resb	64

out_buf_i:	resw	1
out_buf_o:	resw	1
out_buf:	resb	(UNIT_SIZE * 100)
out_buf_end:

