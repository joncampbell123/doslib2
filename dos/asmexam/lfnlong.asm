;--------------------------------------------------------------------------------------
; LFNLONG.COM
;
; Convert short file/path to "long name" using Windows 95 long filenames
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

; clear truname buf
		cld
		mov	cx,262/2
		mov	di,truname
		xor	ax,ax
		rep	stosw

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

; do it
do_mkdir:				; DS:SI = name of dir to convert
		mov	di,truname	; ES:DI = 261-byte buffer to put truename into
		mov	cx,0x0002	; CH=subst expansion CL=function 0x02
		mov	ax,0x7160	; Truename - get short 8.3 name
		int	21h
		jnc	mkdir_ok	; CF=1 if error

		mov	dx,str_fail
		jmp	short exit_err

mkdir_ok:	mov	si,truname
		call	putsz
		mov	dx,crlf
		call	puts

; EXIT to DOS
exit:		ret
exit_err:	mov	ah,0x09
		int	21h
		mov	dx,crlf
		call	puts
		jmp	short exit

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

;------------------------------------
putsz:		push	si
		push	ax
		push	dx
		cld
putsz1:		lodsb
		or	al,al
		jz	putsz1e
		mov	dl,al
		mov	ah,0x02
		int	21h
		jmp	short putsz1
putsz1e:	pop	dx
		pop	ax
		pop	si
		ret

		segment .data

str_ok:		db	'Created$'
str_fail:	db	'Failed$'
str_need_param:	db	'Need a file name'
crlf:		db	13,10,'$'
str_msg:	db	'Hello world',13,10
str_msg_len	equ	13

		segment .bss

truname:	resb	262

