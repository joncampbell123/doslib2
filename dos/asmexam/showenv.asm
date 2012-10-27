;--------------------------------------------------------------------------------------
; SHOWENV.COM
;
; Read the environment block given to this program and display it. MS-DOS 2.0 or higher.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		mov	ax,[cs:0x2C]	; get env segment
		or	ax,ax
		jz	exit		; don't print anything if segment is zero
		mov	ds,ax
		xor	si,si

; print out each variable, one by one
envloop:	cmp	byte [si],0
		jz	exit
		call	puts
		push	si
		push	ds
		push	cs
		pop	ds
		mov	si,crlf
		call	puts
		pop	ds
		pop	si
		jmp	short envloop

; EXIT to DOS
exit:		int	20h
		hlt

puts:		push	ax
		push	dx
		cld
.l1:		lodsb
		or	al,al
		jz	.le
		mov	dl,al
		mov	ah,2
		int	21h
		jmp	short .l1
.le:		pop	dx
		pop	ax
		ret

		segment .data

crlf:		db	13,10,0

		segment .bss

