;--------------------------------------------------------------------------------------
; FCB_DEL.COM
; 
; Delete a file using FCBs.
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
		mov	cx,0x25/2
		rep	stosw

; read the command line starting at CS:0x81 and copy into the FCB fields
		mov	si,0x81
		mov	bx,fcb+0x01
		call	cmdline2fcb

; carry out the delete
		mov	ah,0x13		; AH=0x13 delete using FCB
		mov	dx,fcb
		int	21h
		cmp	al,0x00
		jz	close_ok
		mov	dx,str_del_fail

common_err_exit:mov	ah,0x09
		int	21h
close_ok:	xor	ah,ah
		int	21h

; entry:
;   SI = command line ptr
;   BX = FCB 8.3 area to write
; exit:
;   SI = command line ptr after scan
; exit on error:
;   does not return
cmdline2fcb:	mov	di,bx
		mov	cx,8+1
scan1pre:	lodsb
		cmp	al,' '
		jz	scan1pre
		jmp	short scan1proc
scan1:		lodsb				; loop: copy up to 8 chars for file name
		cmp	al,' '
		jz	scanstop
scan1proc:	cmp	al,0x0D
		jz	scanstop
		cmp	al,'.'
		jz	scan1_ext_begin
		stosb				; store char

		dec	cx			; keep going unless we've done 8 chars
		jnz	scan1
scan_err_too_many_chars:
		mov	dx,str_too_many_chars
		jmp	common_err_exit

scan1_ext_begin:dec	cx			; we need to pad out to 8 chars
		mov	al,' '
		rep	stosb
		mov	cx,3+1
scan1_ext:	lodsb				; loop: copy up to 3 chars for file extension
		cmp	al,' '
		jz	scanstop
		cmp	al,0x0D
		jz	scanstop
		cmp	al,'.'
		jz	scan_err_too_many_chars
		stosb

		dec	cx
		jnz	scan1_ext
		jmp	short scan_err_too_many_chars

scanstop:	cmp	di,bx
		jnz	step2

; no file name was given, error out
		mov	dx,str_no_file
		jmp	short common_err_exit

; need to pad-fill the rest of the name
step2:		lea	cx,[bx+11]
		sub	cx,di
		jle	step2_skip_fill		; CX <= 0 don't fill
		mov	al,' '
		rep	stosb
step2_skip_fill:ret

		segment .data

str_no_file:	db	'No file given',13,10,'$'
str_too_many_chars: db	'Too many chars',13,10,'$'
str_del_fail:	db	'Delete fail',13,10,'$'

		segment .bss

fcb:		resb	0x25

; WARNING: We don't know how large DOS will make the record size, therefore this must be last!
dta:		resb	0x100

