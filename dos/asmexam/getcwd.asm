;--------------------------------------------------------------------------------------
; GETCWD.COM
;
; Display current working directory
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ah,0x47		; AH=0x47 get current directory
		xor	dl,dl		; DL=0 current drive
		mov	si,cwd_path
		int	21h
		jc	fail

		mov	si,cwd_path
l1:		mov	dl,[si]
		or	dl,dl
		jz	l1e
		inc	si
		mov	ah,2
		int	21h
		jmp	short l1
l1e:		mov	dx,str_crlf
		mov	ah,0x09
		int	21h
		ret

fail:		mov	dx,str_fail
		mov	ah,0x09
		int	21h
		ret

		segment .data

str_crlf:	db	13,10,'$'
str_fail:	db	'Failed$'

		segment .bss

cwd_path:	resb	64+1

