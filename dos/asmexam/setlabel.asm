;--------------------------------------------------------------------------------------
; SETLABEL.COM
;
; Set the label from the current disk 
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
		mov	cx,(0x2A+0x2A)/2
		rep	stosw

; make extended FCB
		cld
		mov	al,' '
		mov	byte [fcb],0xFF
		mov	byte [fcb+6],0x08; will be volume label
		mov	di,fcb+7+1
		mov	cx,8+3
		rep	stosb

		mov	byte [fcbren],0xFF
		mov	byte [fcbren+6],0x08; match volume label
		mov	di,fcbren+7+1
		mov	cx,8+3
		mov	al,'?'
		rep	stosb

; copy the new label from the command line
		mov	di,fcb+8
		mov	si,0x81
l1:		lodsb
		cmp	al,' '
		jz	l1
		cmp	al,0x0D
		jz	l1e
		stosb
		mov	cx,8+3-1
l1main:		lodsb
		cmp	al,' '
		jz	l1e
		cmp	al,0x0D
		jz	l1e
		stosb
		loop	l1main
l1e:

; make sure the create FCB's name is the same as the rename FCB's target
		mov	si,fcb+8
		mov	di,fcbren+7+0x11
		mov	cx,8+3
		rep	movsb

; start by trying to rename the volume label
not_delete:	mov	ah,0x17
		mov	dx,fcbren
		int	21h
		mov	dx,str_renamed
		cmp	al,0x00
		jz	short common_str_err

; OK, then try to create
not_rename:	mov	ah,0x16
		mov	dx,fcb
		int	21h
		mov	dx,str_created
		cmp	al,0x00
		jz	short common_str_err
		mov	dx,str_create_fail

common_str_err:	mov	ah,0x09
		int	21h
		mov	ah,0x09
		mov	dx,str_crlf
		int	21h
		ret

		segment .data

str_renamed:	db	'Renamed$'
str_created:	db	'Created$'
str_create_fail:db	'Create failed$'
str_crlf:	db	13,10,'$'

		segment .bss

fcb:		resb	0x2A		; for creation
fcbren:		resb	0x2A		; for renaming

; WARNING: We don't know how large DOS will make the record size, therefore this must be last!
dta:		resb	0x100

