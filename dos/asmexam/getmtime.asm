;--------------------------------------------------------------------------------------
; GETMTIME.COM
;
; Get a file's last modified time
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

; scan for first name in the command line
		cld
		mov	si,0x81		; PSP segment:command line
l1:		lodsb
		cmp	al,13
		jz	end_not_enuf
		cmp	al,' '
		jz	l1
		dec	si
		mov	[srcname_p],si

; scan past first name
l2:		lodsb
		cmp	al,13
		jz	l2e
		cmp	al,' '
		jnz	l2
l2e:		mov	byte [si-1],0	; ASCIIZ snip the name

; open
		mov	ax,0x3D00	; open file
		mov	dx,[srcname_p]
		int	21h
		jnc	step3
		mov	dx,str_cant_open
		jmp	end_err_dx

; ok, get date/time
step3:		mov	[handle],ax
		mov	ax,0x5700
		mov	bx,[handle]
		int	21h
		jnc	step4
		mov	dx,str_cant_get_dt
		jmp	short end_err_dx

; print the date/time
step4:		mov	[ptime],cx
		mov	[pdate],dx

		; MM/DD/YYYY

		; month field bits 8-5
		mov	cl,5
		mov	ax,[pdate]
		shr	ax,cl
		and	ax,0xF
		call	putdec16

		mov	al,'/'
		call	putc

		; day field bits 4-0
		mov	ax,[pdate]
		and	ax,0x1F
		call	putdec16

		mov	al,'/'
		call	putc

		; year field bits 15-9
		mov	cl,9
		mov	ax,[pdate]
		shr	ax,cl
		add	ax,1980
		call	putdec16

		; CRLF
		mov	ah,0x09
		mov	dx,crlf
		int	21h

		; HH:MM:SS

		; hour field bits 15-11
		mov	cl,11
		mov	ax,[ptime]
		shr	ax,cl
		call	putdec16

		mov	al,':'
		call	putc

		; minute field bits 10-5
		mov	cl,5
		mov	ax,[ptime]
		shr	ax,cl
		and	ax,0x3F
		call	putdec16

		mov	al,':'
		call	putc

		; (second/2) field bits 4-0
		mov	ax,[pdate]
		and	ax,0x1F
		add	ax,ax
		call	putdec16

		; CRLF
		mov	ah,0x09
		mov	dx,crlf
		int	21h

; close the handle
		mov	ah,0x3E
		mov	bx,[handle]
		int	21h

; done. exit
exit:		mov	ax,0x4C00
		int	21h

end_not_enuf:	mov	dx,str_not_enuf
end_err_dx:	mov	ah,0x09
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
putdec16:	push	ax
		push	bx
		push	cx
		push	dx

		xor	dx,dx
		mov	cx,1
		mov	bx,10
		div	bx
		push	dx

putdec16_loop:	test	ax,0xFFFF
		jz	putdec16_pl
		xor	dx,dx
		inc	cx
		div	bx
		push	dx
		jmp	short putdec16_loop

putdec16_pl:	xor	bh,bh
putdec16_ploop:	pop	ax
		mov	bl,al
		mov	al,[bx+hexes]
		call	putc
		loop	putdec16_ploop

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

		segment .data

hexes:		db	'0123456789ABCDEF'
str_fail:	db	'Failed',13,10,'$'
str_cant_open:	db	'Cant open',13,10,'$'
str_not_enuf:	db	'Not enough params',13,10,'$'
str_cant_get_dt:db	'Cant get date/time',13,10,'$'
crlf:		db	13,10,'$'

		segment .bss

srcname_p:	resw	1
handle:		resw	1
pdate:		resw	1
ptime:		resw	1

