;--------------------------------------------------------------------------------------
; ALLOCMEM.COM
;
; Shows how a COM program can use alloc/free/resize memory block calls.
; Note that a COM program is loaded into memory as if it occupies the rest of free
; memory, to actually allocate blocks the COM program must resize it's block down first.
; EXE programs usually don't have this problem, because the header indicates the amount
; of memory needed for the EXE.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

; ========================================================
; DOS gives this COM image all free memory (or the largest
; block). If we want to allocate blocks, we have to shrink
; this COM image's block down.
; ========================================================
		mov	ah,0x4A		; AH=0x4A resize memory block
		push	cs
		pop	es		; EX=COM memory block (also, our PSP)
		mov	bx,ENDOFIMAGE+0xF
		mov	cl,4
		shr	bx,cl		; BX = (BX + this image size + 0xF) >> 4 = number of paragraphs
		int	21h
		jnc	com_resize_ok
		mov	dx,str_com_resize_fail
		jmp	short exit_err_str

; ========================================================
; print our block's segment on the console
; ========================================================
com_resize_ok:	mov	dx,str_this_com
		call	puts
		mov	ax,cs
		call	puthex16
		mov	dx,crlf
		call	puts

; EXIT to DOS
exit:		mov	ax,0x4C00	; exit to DOS
		int	21h
exit_err_str:	mov	ah,0x09
		int	21h
		mov	ah,0x09
		mov	dx,crlf
		int	21h
		jmp	short exit

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
str_com_resize_fail:db	'COM resize fail$'
str_this_com:	db	'This COM: $'
crlf:		db	13,10,'$'

		segment .bss


;-----------------------------------
ENDOFIMAGE:	resb	1		; this offset is used by the program to know how large it is

