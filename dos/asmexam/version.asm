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

		mov	dx,dosver
		call	puts

		mov	ax,0x3000	; AH=0x30 get version AL=0x00 return OEM ID in BH
		int	21h		; returns AL,AH=major,minor version BL:CX 24-bit user serial BH=OEM ID
					; NTS: MS-DOS 1.x does not support this call, but it also does not
					;      change AX. So we can detect MS-DOS 1.0 by whether AX is still 0x3000.

		call	putdec8		; print contents of AL

		mov	al,'.'
		call	putc		; print AL=','

		mov	al,ah
		call	putdec8		; print contents of AH

		mov	dx,crlf		; print newline
		call	puts

		mov	dx,serial
		call	puts
		mov	al,bl
		call	puthex8
		mov	al,ch
		call	puthex8
		mov	al,cl
		call	puthex8
		mov	dx,crlf
		call	puts

		mov	dx,realver
		call	puts

		mov	ax,0x3306	; AH=0x33 AL=0x06 get REAL dos version (MS-DOS 5.0+)
		int	21h		; returns BL,BH=major,minor version DL=revision DH=version flags

		push	dx

		mov	al,bl
		call	putdec8		; print contents of BL

		mov	al,'.'
		call	putc		; print AL=','

		mov	al,bh
		call	putdec8		; print contents of BH

		mov	dx,revstr
		call	puts

		pop	dx

		mov	al,dl
		call	putdec8		; print contents of DL

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

;------------------------------------
puthex8:	push	ax
		push	bx
		xor	bh,bh
		mov	bl,al
		shr	bl,4
		push	ax
		mov	al,[bx+hexes]
		call	putc
		pop	ax
		mov	bl,al
		and	bl,0xF
		mov	al,[bx+hexes];
		call	putc
		pop	bx
		pop	ax
		ret

		segment .data

hexes:		db	'0123456789ABCDEF'
realver:	db	'Real DOS version: $'
serial:		db	'Serial: $'
dosver:		db	'DOS version: $'
revstr:		db	' rev. $'
crlf:		db	13,10,'$'

		segment .bss

