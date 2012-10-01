;--------------------------------------------------------------------------------------
; SWITCHR.COM
;
; Read or set the MS-DOS switch character.
; MS-DOS 2.0 to 3.3 supported a system-wide setting to determine the ASCII char that
; you use to start a switch. MS-DOS 4.0 and higher ignores any attempt to change it,
; but still returns a switch char for compatibility.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	si,0x81
ld1:		lodsb
		cmp	al,' '
		jz	ld1
		cmp	al,0x0D
		jz	show_switch_char

; set the flag state. AL=ASCII char
		mov	dl,al		; DL=switch char
		mov	ax,0x3701	; set char
		int	21h

; show the switch char
show_switch_char:mov	ax,0x3700	; get switch char
		int	21h
		cmp	al,0x00
		jz	switch_char_ok

		mov	dx,str_no_switch_char
		call	puts
		mov	dx,crlf
		call	puts
		ret

switch_char_ok:	push	dx
		mov	ah,0x09
		mov	dx,str_switch_char
		int	21h
		pop	dx

		mov	al,dl		; DL=result of call
		call	putc

		mov	dx,crlf
		call	puts	

; EXIT to DOS
exit:		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

;------------------------------------
putc:		push	ax
		push	bx
		push	cx
		push	dx
		mov	ah,0x02
		mov	dl,al
		int	21h
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

		segment .data

str_no_switch_char:db	'DOS does not provide a switch char$'
str_switch_char:db	'Current switch char: $'
crlf:		db	13,10,'$'

		segment .bss

