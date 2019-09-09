;--------------------------------------------------------------------------------------
; GETVSER.COM
;
; Read the label and serial number from the current disk 
;
; Known issues:
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
		mov	di,info
		xor	ax,ax
		mov	cx,0x20/2
		rep	stosw

; get the volume serial and other info
        mov ax,0x6900   ; get serial number (AH=69h AL=00h)
        xor bx,bx       ; bl = 0 (default drive)  bh = info level 0
        mov dx,info     ; DS:DX = disk info
        int 21h
        jnc print_info

        mov ah,0x09
        mov dx,no_info_str
        int 21h
        jmp done

; print what was returned
print_info:
        mov ah,0x09
        mov dx,vol_is
        int 21h

        mov ax,word [info+2+2]
        call puthex16
        mov al,'-'
        call putc
        mov ax,word [info+2]
        call puthex16

		mov	ah,0x09
		mov	dx,crlf
		int	21h

done:		xor	ah,ah
		int	21h

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
		mov	al,[bx+hexes];
		call	putc
		pop	bx
		pop	ax
		ret

;-------------------------------------
puthex16:   push    ax
        xchg al,ah
        call puthex8
        xchg al,ah
        call puthex8
        pop ax
        ret

		segment .data

hexes:		db	'0123456789ABCDEF'
no_info_str:db  'Unable to get info',13,10,'$'
vol_is:     db  'Volume serial is: $'
crlf:		db	13,10,'$'

		segment .bss

info:       resb    0x20

