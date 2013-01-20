;--------------------------------------------------------------------------------------
; W95SYSRS.COM
;
; Ask Windows to change the location of the System registry hive.
; Muahahahah be careful with this program!
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

		mov	bx,0x81
		add	bl,[0x80]	; locate the trailing CR and erase it
		mov	byte [bx],0

		mov	ax,0x1614
		mov	di,0x82
		int	2fh
		or	ax,ax
		jz	req_ok

		mov	dx,unable_to
		call	puts
		mov	dx,crlf
		call	puts

		ret

req_ok:		

; EXIT to DOS
exit:		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .data

unable_to:	db	'Unable to set location$'

crlf:		db	13,10,'$'

		segment .bss

