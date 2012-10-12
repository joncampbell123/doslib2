;--------------------------------------------------------------------------------------
; INT29STR.COM
;
; INT 29h "fast" console output
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		mov	si,str1
l1:		lodsb
		or	al,al
		jz	l1e
		int	29h
		jmp	short l1
l1e:

		mov	ax,0x4C00
		int	21h

		segment .data

str1:		db	'Hello world',13,10,0

		segment .bss

