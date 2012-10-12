;--------------------------------------------------------------------------------------
; CTRLBRK.COM
; 
; Demonstrates using INT 21h AH=01 to read STDIN.
; DOS echoes input when reading this way.
; You can terminate the program using CTRL+C or CTRL+Z (EOF)
;
; What makes THIS version special is that it hooks INT 23h and prints a message when
; that handler is called. You then trigger INT 23h when you type CTRL+C or CTRL+BREAK
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		xor	ax,ax
		mov	es,ax		; set ES=0

		mov	word [es:(0x23*4)+0],int23	; take over INT 23h
		mov	word [es:(0x23*4)+2],cs

loop1:		mov	ah,0x01
		int	21h
		cmp	al,26		; CTRL+Z?
		jnz	loop1		; if not, keep going

		ret

int23:		push	ax
		push	bx
		push	si
		push	ds
		mov	ax,cs
		mov	ds,ax
		mov	si,int23_msg

int23_l1:	lodsb			; print a message using INT 10h to avoid DOS reentrancy issues
		or	al,al
		jz	int23_l1end
		mov	ah,0x0E
		xor	bx,bx
		int	10h
		jmp	short int23_l1

int23_l1end:	pop	ds
		pop	si
		pop	bx
		pop	ax
		iret

int23_msg:	db	'You hit CTRL+C!',13,10,0

