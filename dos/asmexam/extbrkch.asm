;--------------------------------------------------------------------------------------
; VERSION.COM
;
; Ask DOS for the version and print it.
; Also asks for the "real" DOS version.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	si,0x81
ld1:		lodsb
		cmp	al,' '
		jz	ld1
		cmp	al,0x0D
		jz	show_flag

; set the flag state. AL=ASCII char
		sub	al,'0'
		mov	dl,al
		mov	ax,0x3301	; set extended break flag
		int	21h

; show the flag state
show_flag:	mov	ax,0x3300	; get extended break flag
		int	21h

		push	dx
		mov	ah,0x09
		mov	dx,str_flag_state
		int	21h
		pop	dx

		mov	al,dl		; DL=result of 0x3300 call
		call	putdec8

		mov	dx,crlf
		call	puts	

; EXIT to DOS
exit:		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
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
putdec8:	push	ax
		push	bx
		push	cx

		xor	ah,ah
		mov	cx,1
		mov	bl,10
		div	bl
		push	ax

putdec8_loop:	test	al,0xFF
		jz	putdec8_pl
		xor	ah,ah
		inc	cx
		div	bl
		push	ax
		jmp	short putdec8_loop

putdec8_pl:	
putdec8_ploop:	pop	ax
		mov	al,ah
		add	al,'0'
		call	putc
		loop	putdec8_ploop

		pop	cx
		pop	bx
		pop	ax
		ret

		segment .data

str_flag_state:	db	'Extended break flag state: $'
crlf:		db	13,10,'$'

		segment .bss

