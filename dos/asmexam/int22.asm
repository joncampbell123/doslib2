;--------------------------------------------------------------------------------------
; INT22.COM
;
; Demonstrates executing code after DOS has terminated this program by hooking INT 22h.
; Not the actual INT 22h, but the copy in our PSP. Our hook will execute when DOS has
; freed all of our resources and has returned control to the calling program (making this
; a use-after-free bug, but perfectly legitimate in the MS-DOS world).
;
; How this works: under normal circumstances, the old contents of INT 22h are some subroutine
;                 that the calling program has setup to run when this program terminates.
;                 Most DOS programs leave INT 22h the way it was setup, so the vector is
;                 usually some generic DOS kernel routine. This code saves off the pointer
;                 and then replaces the copy in our PSP so that, when DOS terminates this
;                 process and restores INT 22h, our hook is executed instead. Our hook
;                 prints a message, and then passes control to the old INT 22h handler.
;
; Why you would want to do this: Let's say you've got some vital hooks installed and you
;                 want a cleanup routine to run when your program terminates. Most likely
;                 you're running atop a C library that can exit for many reasons, combined
;                 with code that uses assert() or _exit(0) in severe cases. Hooking INT 22h
;                 ensures that even if your program is terminated, your code has a chance
;                 to clean up hooks and modifications that if left unchecked, would eventually
;                 point to invalid data and cause a crash. Just don't count on memory
;                 alloc/free or file handles since they would be given by DOS to whatever
;                 process called us. And I don't think you want COMMAND.COM to be taking on
;                 memory blocks we allocated for ourself, right?
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		push	cs
		pop	ds

		mov	ax,word [0x0A]
		mov	bx,word [0x0C]
		mov	word [old_int22],ax
		mov	word [old_int22+2],bx

		mov	word [0x0A],int22	; take over INT 22h
		mov	word [0x0C],cs

loop1:		mov	ah,0x01
		int	21h
		cmp	al,26		; CTRL+Z?
		jnz	loop1		; if not, keep going

		ret

; execution will get here after DOS has cleaned up our termination.
; we're counting on the fact that DOS will likely NOT erase our executable image from memory
; in order to continue execution post-termination. Technically this makes execution a use-after-free
; memory allocation bug, which is bad programming practice, but it's the only way to easily make this work.
int22:		push	ax
		push	bx
		push	si
		push	ds
		mov	ax,cs
		mov	ds,ax
		mov	si,int22_msg

int22_l1:	lodsb			; print a message using INT 10h to avoid DOS reentrancy issues
		or	al,al
		jz	int22_l1end
		mov	ah,0x0E
		xor	bx,bx
		int	10h
		jmp	short int22_l1

int22_l1end:	pop	ds
		pop	si
		pop	bx
		pop	ax
		jmp far	[cs:old_int22]

old_int22:	dw	0,0		; the original INT 22h vector prior to our hooking it

int22_msg:	db	'INT 22h triggered!',13,10,0

