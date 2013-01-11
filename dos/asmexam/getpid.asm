;--------------------------------------------------------------------------------------
; GETPID.COM
;
; Uses INT 21h AH=0x51 to get our "process ID" (in other words, the current Program
; Segment Prefixx). MS-DOS 2.0 or higher. There a MS-DOS 3.0+ version that's documented
; while this version uses the undocumented version.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	dx,str_this_com
		call	puts
		mov	ax,cs
		call	puthex16
		mov	dx,crlf
		call	puts

		mov	dx,str_this_psp
		call	puts
		mov	ah,0x51
		int	21h
		mov	ax,bx
		call	puthex16
		mov	dx,crlf
		call	puts

; EXIT to DOS
exit:		mov	ax,0x4C00	; exit to DOS
		int	21h
		hlt

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
str_this_com:	db	'My segment: $'
str_this_psp:	db	'My PSP: $'
crlf:		db	13,10,'$'

		segment .bss

