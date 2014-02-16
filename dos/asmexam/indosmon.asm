;--------------------------------------------------------------------------------------
; INDOSMON.COM
;
; Show the contents of the INDOS flag as a TSR.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

; get INDOS flag
		xor	bx,bx		; clear ES:BX to detect failure of the API to return a pointer
		mov	es,bx
		mov	ah,34h		; get address of INDOS flag
		int	21h		; returns ptr in ES:BX
		mov	word [ptr_indos],bx
		mov	word [ptr_indos+2],es

; get Critical Error flag
		push	ds
		xor	dx,dx		; Ralph Brown notes Novell DOS can crash for some values of DX here
		xor	si,si
		mov	ax,5D06h	; get address of SDA
		int	21h		; returns ptr in DS:SI
		mov	word [cs:ptr_criterr],si
		mov	word [cs:ptr_criterr+2],ds
		pop	ds

; hook INT 08h (IRQ 0)
		cli
		xor	ax,ax
		mov	es,ax
		mov	ax,[es:(0x08*4)+0]
		mov	word [old_int8+0],ax
		mov	ax,[es:(0x08*4)+2]
		mov	word [old_int8+2],ax
		mov	word [es:(0x08*4)+0],int8_hook
		mov	word [es:(0x08*4)+2],cs
		sti

;-----------------------------------
		mov	dx,str_resident
		call	puts

; EXIT as TSR
		mov	ax,0x3100	; exit to DOS and stay resident
		int	21h

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

int8_hook:	push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es

		mov	ax,0xB800
		mov	es,ax

		lds	si,[cs:ptr_indos]
		mov	al,[si]
		or	al,al
		jz	.indosz
		mov	al,1
.indosz:	add	al,'0'
		mov	ah,0x1E
		mov	word [es:0],ax

		lds	si,[cs:ptr_criterr]
		mov	al,[si]
		or	al,al
		jz	.critz
		mov	al,1
.critz:		add	al,'0'
		mov	ah,0x1E
		mov	word [es:2],ax

		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		jmp far	word [cs:old_int8]

		segment .data

ptr_indos:	dd	0
ptr_criterr:	dd	0
old_int8:	dd	0

str_resident:	db	'I am now resident',13,10,'$'

		segment .bss

