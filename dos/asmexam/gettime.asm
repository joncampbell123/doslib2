;--------------------------------------------------------------------------------------
; GETTIME.COM
;
; Read system clock
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ah,0x2A		; get system date
		int	21h		; returns CX=year  DH=month  DL=day  AL=day of week (v1.10+)
					;   CX=year value (1980 or higher)
					;   DH=month (1-12)
					;   DL=day (1-31)

		mov	ax,cx		; print in YYYY/MM/DD format
		call	putdec16
		mov	al,'/'
		call	putc
		xor	ah,ah
		mov	al,dh
		call	putdec16
		mov	al,'/'
		call	putc
		mov	al,dl
		call	putdec16

		mov	al,' '
		call	putc

		mov	ah,0x2C		; get system time
		int	21h		; returns CH=hour  CL=minute  DH=second  DL=1/100 seconds
					;   CH=hour (0-23)
					;   CL=minute (0-59)
					;   DH=second (0-59)
					;   DK=centisecond (0-99) some systems may just return 0

		xor	ah,ah
		mov	al,ch
		call	putdec16
		mov	al,':'
		call	putc
		mov	al,cl
		call	putdec16
		mov	al,':'
		call	putc
		mov	al,dh
		call	putdec16
		mov	al,'.'
		call	putc
		mov	al,dl
		call	putdec16

		mov	dx,crlf
		call	puts

; done. exit
exit:		mov	ax,0x4C00
		int	21h

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

;-----------------------------------------------------------
; WARNING: This version of the function has been modified to
;          print a minimum of 2 digits instead of 1. 
putdec16:	push	ax
		push	bx
		push	cx
		push	dx

		xor	dx,dx
		mov	cx,1
		mov	bx,10
		div	bx
		push	dx

putdec16_loop:	cmp	cx,2
		jl	.keepgoing		; must print at least 2 digits
		test	ax,0xFFFF
		jz	putdec16_pl
.keepgoing:	xor	dx,dx
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
crlf:		db	13,10,'$'

		segment .bss

srcname_p:	resw	1
handle:		resw	1
pdate:		resw	1
ptime:		resw	1

