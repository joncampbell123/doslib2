;--------------------------------------------------------------------------------------
; RENAME.COM
;
; Rename a file using AH=0x56
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

; scan for first name in the command line
		cld
		mov	si,0x81		; PSP segment:command line
l1:		lodsb
		cmp	al,13
		jz	end_not_enuf
		cmp	al,' '
		jz	l1
		dec	si
		mov	[srcname_p],si

; scan past first name
l2:		lodsb
		cmp	al,13
		jz	end_not_enuf
		cmp	al,' '
		jnz	l2
		mov	byte [si-1],0	; ASCIIZ snip the name

; skip whitespace between first and second
l3:		lodsb
		cmp	al,' '
		jz	l3
		cmp	al,13
		jz	end_not_enuf
		dec	si

; note second name
		mov	[dstname_p],si

; scan past second name
l4:		lodsb
		cmp	al,13
		jz	end_of_name
		cmp	al,' '
		jnz	l4

end_of_name:	dec	si
		mov	byte [si],0	; ASCIIZ snip the name

; we got two names, now carry out the rename
do_rename:	mov	ah,0x56
		mov	dx,[srcname_p]
		mov	di,[dstname_p]
		int	21h
		jnc	exit		; CF=1 on error

		mov	ah,0x09
		mov	dx,str_fail
		int	21h

; done. exit
exit:		mov	ax,0x4C00
		int	21h

end_not_enuf:	mov	ah,0x09
		mov	dx,str_not_enuf
		int	21h
		ret

		segment .data

str_fail:	db	'Failed',13,10,'$'
str_not_enuf:	db	'Not enough params',13,10,'$'

		segment .bss

srcname_p:	resw	1
dstname_p:	resw	1

