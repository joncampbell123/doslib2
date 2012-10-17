;--------------------------------------------------------------------------------------
; LFNDEL2.COM
;
; Delete file using Windows 95 long filename functions
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
		mov	ax,0x7141	; AH=0x71 AL=0x41 long filename delete
		mov	si,1		; SI=1 wildcard matching
		xor	cx,cx		; CH=0 no search attr CL=0 no must-match attr
		int	21h
		mov	dx,str_ok
		jnc	mkdir_ok	; CF=1 if error
		mov	dx,str_fail
		cmp	ax,0x7100	; AX=0x7100 if functions not available
		jnz	mkdir_ok
		mov	dx,str_na
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

str_ok:		db	'Deleted$'
str_fail:	db	'Failed$'
str_na:		db	'Not available$'
str_need_param:	db	'Need a directory name'
crlf:		db	13,10,'$'

		segment .bss

