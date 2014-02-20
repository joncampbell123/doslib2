;--------------------------------------------------------------------------------------
; DRVEN.COM
;
; Disable a drive (MS-DOS 5.0)
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

; read the command line, skip leading whitespace
		mov	si,0x81
ld1:		lodsb
		cmp	al,' '
		jz	ld1
		dec	si

		clc
		mov	dl,[si]		; get drive letter from command line
		sub	dl,'A'		; DL = DL - 'A'
		and	dl,0x1F
		mov	ax,0x5F07	; AX=5F07
		int	21h
		jnc	info_ok		; error?

		mov	dx,str_failed
		call	puts
		mov	dx,crlf
		call	puts
		ret

info_ok: 	mov	dx,str_ok
		call	puts
		mov	dx,crlf
		call	puts

; EXIT to DOS
exit:		mov	ax,0x4C00	; exit to DOS
		int	21h
		ret			; in case 0x4C fails

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .data

hexes:		db	'0123456789ABCDEF'
str_failed:	db	'Failed$'
str_ok:		db	'OK$'
crlf:		db	13,10,'$'

		segment .bss

