;--------------------------------------------------------------------------------------
; DELLABEL.COM
;
; Delete the label from the current disk.
;
; Known issues:
;    Microsoft MS-DOS 6.22:
;        - If Windows 95 "long filenames" exist in the root directory the DOS kernel
;          will return the first long filename dirent as the volume label. For whatever
;          reason, SETLABEL.COM is able to change the true volume label, and afterwards
;          GETLABEL.COM sees the change, but deleting the volume label doesn't work.
;          Neither this program nor MS-DOS's LABEL program is able to do it.
;          Deleting the volume label works normally if the volume label is first in
;          the root directory or Windows 95 long filenames are not present at all.
;
;    IBM PC-DOS 1.0
;        - The kernel does not understand extended FCBs, but will happily delete the
;          first file it finds---ironically, that is usually COMMAND.COM on our test
;          disks.
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

; copy the result of enumeration into the FCB
		cld
		mov	si,dta
		mov	di,fcb
		mov	cx,11+1		; 8.3 name + drive byte
		rep	movsb

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

