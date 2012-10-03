;--------------------------------------------------------------------------------------
; OPENREAD.COM
;
; Open a file, read it, and print the contents to standard output
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

; do the file open
do_mkdir:	mov	dx,si		; DS:DX = name of dir to make
		mov	ax,0x3D00	; AH=0x3D open file AL=access mode (00000000 -> 000=compat. sharing xx 000=read only)
		mov	cx,0		; CX=file attributes
		int	21h
		jnc	mkdir_ok	; CF=1 if error

		mov	dx,str_fail
		mov	dx,crlf
		call	puts
		jmp	short exit

mkdir_ok:	mov	[filehandle],ax	; save the file handle returned by DOS

read_loop:	mov	ah,0x3F		; AH=0x3F read from handle
		mov	bx,[filehandle]
		mov	cx,4096		; <- WARNING must match tempdata resb 4096
		mov	dx,tempdata
		int	21h
		jc	read_done	; stop reading if error (CF=1)
		or	ax,ax		; if AX == 0
		jz	read_done	; stop reading
		mov	[tempread],ax	; store away how much was returned

; write the contents to STDOUT, then loop back for more data
		mov	ah,0x40		; AH=0x40 write to handle
		mov	bx,1		; BX=1 write to STDOUT
		mov	cx,[tempread]
		mov	dx,tempdata
		int	21h

		jmp	short read_loop	; jump back for more reading

read_done:	mov	ah,0x3E		; AH=0x3E close the file handle
		mov	bx,[filehandle]
		int	21h

; EXIT to DOS
exit:		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .data

str_fail:	db	'Failed$'
str_need_param:	db	'Need a file name'
crlf:		db	13,10,'$'

		segment .bss

filehandle:	resw	1
tempread:	resw	1

tempdata:	resb	4096

