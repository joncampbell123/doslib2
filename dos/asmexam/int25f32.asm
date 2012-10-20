;--------------------------------------------------------------------------------------
; INT25f32.COM
;
; INT 21h AX=7305 FAT32 equivalent of INT 25h absolute disk read offered by
; Windows 95 OSR2, Windows 98 & ME. It also works from pure DOS mode.
;
; WARNING: You can modify this code to write to the disk, but be aware Windows 95/98/ME
;          requires you to "lock" the volume first. If you do not, the DOS kernel will
;          halt the system with an error message.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ah,0x19
		int	21h		; get current drive

		; notice: this is the same packet format used by INT 25h CX=0xFFFF
		mov	word [packet+0],0 ; sector number (DWORD), set to 0
		mov	word [packet+2],0 
		mov	word [packet+4],2 ; number of sectors (WORD), set to 2
		mov	word [packet+6],buffer ; SEG:OFF transfer address
		mov	word [packet+8],cs

		mov	dl,al		; DL = drive number (1=A, 2=B, where AH=0x19 returned 0=A, 1=B)
		inc	dl
		mov	ax,0x7305
		mov	cx,0xFFFF	; >= 32MB partition version
		mov	bx,packet	; DS:BX = packet
		mov	si,0		; we're reading data (set bit 0 to 1 to write, see docs!!!)
		int	21h
		jnc	read_ok

		mov	ah,9
		mov	dx,str_failed
		int	21h
		int	20h

read_ok:	mov	si,buffer

		mov	cx,4		; 2 x 16 x 32 = 1024
l1_0:		push	cx
		mov	cx,16
l1_1:		push	cx
		mov	cx,16
l1_2:		lodsb
		call	puthex8
		mov	al,' '
		call	putc
		loop	l1_2

		push	si
		mov	ah,9
		mov	dx,crlf
		int	21h
		pop	si
		pop	cx
		loop	l1_1

		push	si
		mov	ah,9
		mov	dx,crlf
		int	21h
		xor	ah,ah
		int	16h
		pop	si
		pop	cx
		loop	l1_0

; EXIT to DOS
exit:		int	20h
		hlt

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

		segment .data

hexes:		db	'0123456789ABCDEF'
str_failed:	db	'Failed',13,10,'$'
crlf:		db	13,10,'$'

		segment .bss

packet:		resw	5
segsp:		resw	1
buffer:		resb	1024

