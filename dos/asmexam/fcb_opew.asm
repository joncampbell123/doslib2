;--------------------------------------------------------------------------------------
; FCB_OPEW.COM
; 
; Open a file given on the command line using FCBs, writes over the first logical
; record with a string, and closes it
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

NEWTEXT_LENGTH	EQU	15

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
		mov	di,fcb+1
		mov	cx,8+1
scan1:		lodsb				; loop: copy up to 8 chars for file name
		cmp	al,' '
		jz	scan1
		cmp	al,0x0D
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
		jz	scan1_ext
		cmp	al,0x0D
		jz	scanstop
		cmp	al,'.'
		jz	scan_err_too_many_chars
		stosb

		dec	cx
		jnz	scan1_ext
		jmp	short scan_err_too_many_chars

scanstop:	cmp	di,fcb+1
		jnz	step2

; no file name was given, error out
		mov	dx,str_no_file
		jmp	short common_err_exit

; need to pad-fill the rest of the name
step2:		mov	cx,fcb+1+11
		sub	cx,di
		jle	step2_skip_fill		; CX <= 0 don't fill
		mov	al,' '
		rep	stosb
step2_skip_fill:

; open using FCB
		mov	ah,0x0F			; AH=0x0F open file using FCB
		mov	dx,fcb
		int	21h
		cmp	al,0x00			; did it succeed?
		jz	step3_begin

		mov	dx,str_open_fail
		jmp	short common_err_exit

; start reading with it
step3_begin:	mov	ah,0x1A			; AH=0x1A set disk transfer address
		mov	dx,dta			; point it at "dta"
		int	21h

; read one record
		mov	ah,0x21			; AH=0x21 random read using FCB
		mov	dx,fcb
		int	21h
		cmp	al,0x00			; if full read successful, then jump immediately to printing
		jz	step4_begin

		mov	dx,str_read_fail
		jmp	short common_err_exit

; overwrite the text
step4_begin:	cld
		mov	si,newtext
		mov	cx,NEWTEXT_LENGTH
		mov	di,dta
		rep	movsb

; write it back
		mov	ah,0x22			; AH=0x22 random write using FCB
		mov	dx,fcb
		int	21h
		cmp	al,0x00
		jz	step_close

		mov	dx,str_write_fail
		jmp	short common_err_exit

; close the file
step_close:	mov	ah,0x10			; AH=0x10 close file using FCB
		mov	dx,fcb
		int	21h
		cmp	al,0x00
		jz	close_ok
		mov	dx,str_close_fail
common_err_exit:mov	ah,0x09
		int	21h
close_ok:	ret

		segment .data

str_no_file:	db	'No file given',13,10,'$'
str_too_many_chars: db	'Too many chars',13,10,'$'
str_open_fail:	db	'Open err',13,10,'$'
str_close_fail:	db	'Close err',13,10,'$'
str_write_fail:	db	'Write err',13,10,'$'
str_read_fail:	db	'Read err',13,10,'$'

newtext:	db	'Hello world',13,10,13,10

		segment .bss

fcb:		resb	0x25

; WARNING: We don't know how large DOS will make the record size, therefore this must be last!
dta:		resb	0x100

