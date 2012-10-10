;--------------------------------------------------------------------------------------
; GVERIFY.COM
; 
; Show the current verify flag flag (MS-DOS 2.0+)
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		push	cs
		pop	ds

		mov	ah,0x54
		int	21h
		add	al,'0'
		mov	dl,al
		mov	ah,0x02
		int	21h
		mov	ah,0x09
		mov	dx,crlf
		int	21h

		ret

crlf:		db	13,10,'$'

