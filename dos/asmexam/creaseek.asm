;--------------------------------------------------------------------------------------
; CREASEEK.COM
;
; Create a file, lseek, write
; 
; CAUTION: On an actual DOS install involving the FAT filesystem, the lseek+write will
;          reveal contents from previously deleted clusters. Unlike Windows NT or
;          Linux, DOS makes no attempt to zero clusters when it allocates them to
;          satisfy the lseek() request.
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

; and then NUL-terminate the line
		mov	bl,[0x80]
		xor	bh,bh
		add	bl,0x81
		mov	byte [bx],0

; SI is still the (now ASCIIZ) string
		cmp	byte [si],0	; is it NULL-length?
		jnz	do_mkdir
		mov	dx,str_need_param
		call	puts
		ret			; return to DOS

; do the file creation
do_mkdir:	mov	dx,si		; DS:DX = name of dir to make
		mov	ah,0x3C		; AH=0x3C create or truncate file
		mov	cx,0		; CX=file attributes
		int	21h
		jnc	mkdir_ok	; CF=1 if error

		mov	dx,str_fail
		jmp	short exit_err

mkdir_ok:	mov	[filehandle],ax	; save the file handle returned by DOS

		mov	ah,0x40		; AH=0x40 write to handle
		mov	bx,[filehandle]
		mov	cx,str_msg_len
		mov	dx,str_msg
		int	21h

		mov	ax,0x4200	; AH=0x42 lseek AL=0x00 SEEK_SET
		mov	bx,[filehandle]
		xor	cx,cx
		mov	dx,0x1000	; CX:DX = offset 0x1000
		int	21h

		mov	ah,0x40		; AH=0x40 write to handle
		mov	bx,[filehandle]
		mov	cx,str_msg_len
		mov	dx,str_msg
		int	21h

		mov	ah,0x3E		; AH=0x3E close the file handle
		mov	bx,[filehandle]
		int	21h

; EXIT to DOS
exit:		ret
exit_err:	mov	dx,crlf
		call	puts
		jmp	short exit

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .data

str_ok:		db	'Created$'
str_fail:	db	'Failed$'
str_need_param:	db	'Need a file name'
crlf:		db	13,10,'$'
str_msg:	db	'Hello world',13,10
str_msg_len	equ	13

		segment .bss

filehandle:	resw	1

