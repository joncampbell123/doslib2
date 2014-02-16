;--------------------------------------------------------------------------------------
; INDOS.COM
;
; Show the contents of the INDOS flag
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

;--------------------------------------
		mov	dx,str_indos
		call	puts

		xor	ax,ax
		mov	es,ax		; HACK: Set ES:BX prior to call to detect cases where DOS fails to implement (such as DOSBox)
		mov	bx,ax
		mov	ah,34h		; get address of INDOS flag
		int	21h
		push	es
		mov	ax,es
		call	puthex16
		mov	al,':'
		call	putc
		pop	es
		mov	ax,bx
		call	puthex16

		mov	dx,crlf
		call	puts

;--------------------------------------
		mov	dx,str_criterr
		call	puts

		xor	si,si
		mov	ax,5D06h	; get address of SDA
		int	21h
		push	ds
		pop	es		; mov DS -> ES and restore our DS
		push	cs
		pop	ds
		push	es
		mov	ax,es
		call	puthex16
		mov	al,':'
		call	putc
		pop	es
		mov	ax,si
		call	puthex16

		mov	dx,crlf
		call	puts

; EXIT to DOS
exit:		mov	ax,0x4C00	; exit to DOS
		int	21h

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

;------------------------------------
puthex8:	push	ax
		push	bx
		xor	bh,bh
		mov	bl,al
		shr	bl,4
		push	ax
		mov	al,[bx+hexes]
		call	putc
		pop	ax
		mov	bl,al
		and	bl,0xF
		mov	al,[bx+hexes]
		call	putc
		pop	bx
		pop	ax
		ret

;------------------------------------
puthex16:	push	ax
		xchg	al,ah
		call	puthex8
		pop	ax
		call	puthex8
		ret

		segment .data

hexes:		db	'0123456789ABCDEF'
str_indos:	db	'INDOS: $'
str_criterr:	db	'CritErr: $'
crlf:		db	13,10,'$'

		segment .bss

block1:		resw	1
block2:		resw	1

;-----------------------------------
ENDOFIMAGE:	resb	1		; this offset is used by the program to know how large it is

