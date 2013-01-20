;--------------------------------------------------------------------------------------
; W95SYSRG.COM
;
; Ask Windows for the location of the System registry hive
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

		cld
		mov	di,strbuf
		mov	al,'$'
		mov	cx,192/2
		rep	stosw

		mov	ax,0x1613
		mov	cx,192
		mov	di,strbuf
		int	2fh
		or	ax,ax
		jz	req_ok

		mov	dx,unable_to
		call	puts
		mov	dx,crlf
		call	puts

		ret

req_ok:		mov	dx,strbuf
		call	puts

		mov	dx,crlf		; print newline
		call	puts

; EXIT to DOS
exit:		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .data

unable_to:	db	'Unable to determine location$'

crlf:		db	13,10,'$'

		segment .bss

strbuf:		resb	192

