;--------------------------------------------------------------------------------------
; CHATTR_S.COM
;
; Set system attribute bit of a file
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

; read file attribute
do_mkdir:	push	si
		mov	dx,si		; DS:DX = name of dir to make
		mov	ax,0x4300	; AH=0x43 AL=0x00 get file attributes
		int	21h		; returns CX=file attributes
		pop	si
		mov	dx,str_fail_get
		jc	exit_err	; CF=1 if error

		mov	dx,str_already
		test	cx,4		; if already set, then don't do anything
		jnz	exit_err

		push	si
		mov	dx,si		; DS:DX = name of file
		or	cx,4		; set hidden attribute
		mov	ax,0x4301	; AH=0x43 AL=0x01 set file attributes
		int	21h
		pop	si
		mov	dx,str_fail_set
		jc	exit_err
		mov	dx,str_ok

; EXIT to DOS
exit_err:	call	puts
		mov	dx,crlf
		call	puts
		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .data

str_ok:		db	'Attribute changed$'
str_fail_set:	db	'Failed to set$'
str_fail_get:	db	'Failed to get$'
str_already:	db	'Already set$'
str_need_param:	db	'Need a file name'
crlf:		db	13,10,'$'

		segment .bss

filehandle:	resw	1

