;--------------------------------------------------------------------------------------
; FCB_DIR.COM
; 
; Enumerate files and folders in current directory using FCBs
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

; info is returned in the DTA, so set DTA location
		mov	ah,0x1A		; AH=0x1A set DTA
		mov	dx,dta
		int	21h

; carry out the enumeration
		mov	ah,0x11		; AH=0x11 find first file
		mov	dx,fcb
		int	21h
		cmp	al,0x00
		jnz	done

; print what was returned
print_info:	cmp	byte [dta+0x0C],0xF	; skip Win95 long filename entries
		jz	go_next

		cld
		mov	cx,8		; print name
		mov	si,dta+1
		call	putslen
		mov	dl,'.'
		call	putcd
		mov	cx,3
		mov	si,dta+1+8
		call	putslen
		mov	dl,' '
		call	putcd

		mov	al,byte [dta+0x0C]
		call	puthex

		mov	ah,0x09
		mov	dx,crlf
		int	21h

; get next entry
go_next:	mov	ah,0x12		; AH=0x12 find next file
		mov	dx,fcb
		int	21h
		cmp	al,0x00
		jz	print_info
		jmp	short done

common_err_exit:mov	ah,0x09
		int	21h
done:		xor	ah,ah
		int	21h

; entry:
;   CX = number of chars
;   SI = string
putslen:	push	cx
putslenloop1:	lodsb
		cmp	al,' '
		jz	putslenloop2
		mov	dl,al
		mov	ah,0x02
		int	21h
putslenloop2:	loop	putslenloop1
		pop	cx
		ret

; entry:
;   DL = char
putcd:		mov	ah,0x02
		int	21h
		ret

; entry:
;   AL = single-digit binary to print as hexadecimal
puthex:		and	al,0xF
		cmp	al,10
		jb	puthexr
		add	al,'A' - 10 - '0'
puthexr:	add	al,'0'
		mov	dl,al
		call	putcd
		ret

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

; no file name was given, fill FCB with '?'
		cld
		mov	cx,8+3
		mov	al,'?'
		rep	stosb

; need to pad-fill the rest of the name
step2:		lea	cx,[bx+11]
		sub	cx,di
		jle	step2_skip_fill		; CX <= 0 don't fill
		mov	al,' '
		rep	stosb
step2_skip_fill:ret

		segment .data

str_too_many_chars: db	'Too many chars',13,10,'$'
str_del_fail:	db	'Delete fail'
crlf:		db	13,10,'$'

		segment .bss

fcb:		resb	0x25

; WARNING: We don't know how large DOS will make the record size, therefore this must be last!
dta:		resb	0x100

