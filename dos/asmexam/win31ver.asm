;--------------------------------------------------------------------------------------
; WIN31VER.COM
;
; Ask Windows for the version and print it.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	dx,winver
		call	puts

		mov	ax,0x160A
		int	2fh
		or	ax,ax
		jz	windows_running

		mov	dx,win_not_running
		call	puts

		mov	dx,crlf		; print newline
		call	puts

		ret

windows_running:mov	al,bh
		call	putdec8		; print contents of AL

		mov	al,'.'
		call	putc		; print AL=','

		mov	al,bl
		call	putdec8		; print contents of AH

		mov	dx,crlf		; print newline
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

putdec8_pl:	xor	bh,bh
putdec8_ploop:	pop	ax
		mov	bl,ah
		mov	al,[bx+hexes]
		call	putc
		loop	putdec8_ploop

		pop	cx
		pop	bx
		pop	ax
		ret

		segment .data

hexes:		db	'0123456789ABCDEF'
win_not_running:db	'Windows is not running$'
winver:		db	'Windows version: $'
crlf:		db	13,10,'$'

		segment .bss

