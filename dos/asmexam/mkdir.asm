;--------------------------------------------------------------------------------------
; MSDOS.COM
;
; Create a directory
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

; do the mkdir
do_mkdir:	mov	dx,si		; DS:DX = name of dir to make
		mov	ah,0x39		; AH=0x39 make directory
		int	21h
		mov	dx,str_ok
		jnc	mkdir_ok	; CF=1 if error
		mov	dx,str_fail
mkdir_ok:	call	puts
		mov	dx,crlf
		call	puts

; EXIT to DOS
exit:		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .data

str_ok:		db	'Created$'
str_fail:	db	'Failed$'
str_need_param:	db	'Need a directory name'
crlf:		db	13,10,'$'

		segment .bss

