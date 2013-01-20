;--------------------------------------------------------------------------------------
; WINOLVER.COM
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

		mov	ax,0x1600	; first check for Windows enhanced mode
		int	2fh
		or	al,al
		jnz	enhanced_mode

; FIXME: Unfortunately DOS 5.0 DOSSHELL will also trigger this check
		mov	ax,0x4680	; OK. check for Windows 3.0 standard/real mode
		int	2fh
		or	ax,ax
		jz	win30_stdreal

		mov	dx,win_not_running
		call	puts

		mov	dx,crlf		; print newline
		call	puts

		ret

win30_stdreal:	mov	dx,winver_win30_stdreal
		call	puts

		ret

enhanced_mode:	cmp	al,1
		jz	win386_2x
		cmp	al,0x80
		jz	xms_v1
		cmp	al,0xFF
		jz	win386_2x_FF

		call	putdec8		; print contents of AL

		mov	al,'.'
		call	putc		; print AL=','

		mov	al,ah
		call	putdec8		; print contents of AH

		mov	dx,crlf		; print newline
		call	puts

; EXIT to DOS
exit:		ret

win386_2x:	mov	dx,winver_win386_2x
		jmp	short common_pr
win386_2x_FF:	mov	dx,winver_win386_2x_FF
		jmp	short common_pr
xms_v1:		mov	dx,winver_xms_v1
common_pr:	call	puts
		mov	dx,crlf
		call	puts
		ret

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
winver_win386_2x:db	'Windows/386 2.x$'
winver_win386_2x_FF:db	'Windows/386 2.x FF$'
winver_xms_v1:	db	'XMS v1.x$'
winver_win30_stdreal:db	'Windows 3.0 standard/real mode$'

crlf:		db	13,10,'$'

		segment .bss

