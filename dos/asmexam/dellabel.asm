;--------------------------------------------------------------------------------------
; DELLABEL.COM
;
; Delete the label from the current disk.
;
; Known issues:
;    Microsoft MS-DOS 6.22:
;        - A bug in the MS-DOS kernel prevents anyone (whether it's this program or it's
;          own LABEL utility) from deleting the volume label if Windows 95 long filenames
;          exist in the root directory.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

; zero memory in FCB
		cld
		mov	di,fcb
		xor	ax,ax
		mov	cx,0x2A/2
		rep	stosw

; make extended FCB
		mov	byte [fcb],0xFF
		mov	byte [fcb+6],0x08; match volume label
		mov	di,fcb+8
		mov	cx,8+3
		mov	al,'?'
		cld
		rep	stosb

; info is returned in the DTA, so set DTA location
		mov	ah,0x1A		; AH=0x1A set DTA
		mov	dx,dta
		int	21h

; carry out the enumeration
		mov	ah,0x11		; AH=0x11 find first file
		mov	dx,fcb
		int	21h
		mov	dx,str_no_label
		cmp	al,0x00
		jnz	short common_str_error

; then delete the label
		mov	ah,0x13		; AH=0x13 delete
		mov	dx,fcb
		int	21h
		mov	dx,str_deleted
		cmp	al,0x00
		jz	common_str_error
		mov	dx,str_del_fail

common_str_error:mov	ah,0x09
		int	21h
		mov	ah,0x09
		mov	dx,str_crlf
		int	21h
		ret

		segment .data

str_deleted:	db	'Deleted$'
str_del_fail:	db	'Delete fail$'
str_no_label:	db	'No label$'
str_crlf:	db	13,10,'$'

		segment .bss

fcb:		resb	0x2A

; WARNING: We don't know how large DOS will make the record size, therefore this must be last!
dta:		resb	0x100

