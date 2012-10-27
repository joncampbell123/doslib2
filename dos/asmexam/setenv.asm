;--------------------------------------------------------------------------------------
; SETENV.COM
;
; Replace the environment block, then execute another MS-DOS program. In this case, we
; run COMMAND.COM.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es
		mov	sp,stack_end-2

; ========================================================
; DOS gives this COM image all free memory (or the largest
; block). EXEC will always fail with "insufficient memory"
; unless we reduce our COM image block down to free up memory.
; ========================================================
		mov	ah,0x4A		; AH=0x4A resize memory block
		push	cs
		pop	es		; EX=COM memory block (also, our PSP)
		mov	bx,ENDOFIMAGE+0xF
		mov	cl,4
		shr	bx,cl		; BX = (BX + this image size + 0xF) >> 4 = number of paragraphs
		int	21h

; next: free the environment block given to us by DOS
		mov	ah,0x49
		mov	bx,[0x2C]
		or	bx,bx
		jz	no_free_env
		push	es
		mov	es,bx
		int	21h
		pop	es
		mov	word [0x2C],0

; and allocate another one
no_free_env:	mov	ah,0x48
		mov	bx,2		; 2 x 16 = 32 bytes
		int	21h
		jnc	new_env_ok
		mov	ax,0x4C01
		int	21h
		hlt			; return if failed
new_env_ok:	mov	word [0x2C],ax	; store the new segment into the env block pointer in the PSP
		push	es
		cld
		xor	di,di
		mov	si,test_env
		mov	cx,32/2		; 32 bytes
		mov	es,ax
		rep	movsw
		pop	es

; OK proceed
		cld
		mov	cx,12
		mov	di,exec_fcb
		rep	stosw

		mov	word [exec_pblk+0],0	; environ. segment to copy
		mov	word [exec_pblk+2],exec_cmdtail	; command tail to pass to child
		mov	word [exec_pblk+4],cs
		mov	word [exec_pblk+6],exec_fcb ; first FCB
		mov	word [exec_pblk+8],cs
		mov	word [exec_pblk+10],exec_fcb ; second FCB
		mov	word [exec_pblk+12],cs
		mov	word [exec_pblk+14],0

		push	si		; DOS is said to corrupt the TOP word of the stack
		mov	ax,0x4B00	; AH=0x4B AL=0x00 Load and execute
		mov	dx,exec_path
		mov	bx,exec_pblk
		int	21h		; do it
		pop	si		; discard possibly corrupted WORD
		jc	exec_err

		cli			; DOS 2.x is said to screw up the stack pointer.
		mov	ax,cs		; just in case restore it proper.
		mov	ss,ax
		mov	sp,stack_end - 2
		sti

		push	cs
		pop	ds
		mov	ah,0x09
		mov	dx,str_ok
		int	21h

exit:		mov	ax,0x4C00
		int	21h

exec_err:	mov	ax,cs
		mov	ds,ax
		mov	ah,0x09
		mov	dx,str_fail
		int	21h
		jmp	short exit

		segment .data

exec_path:	db	'COMMAND.COM',0
exec_cmdtail:	db	'',13,0
str_fail:	db	'Failed',13,10,'$'
str_ok:		db	'Exec OK',13,10,'$'

; this is copied into the new env block. must be 32 bytes
test_env:	db	'TESTING=123',0		; +12 = 12
		db	'HELLO=World',0         ; +12 = 24
		db	'AB=CD',0,0,0		; +8  = 32

		segment .bss

stack_beg:	resb	0x400-1
stack_end:	resb	1

exec_fcb:	resb	24
exec_pblk:	resb	0x14

;-----------------------------------
ENDOFIMAGE:	resb	1		; this offset is used by the program to know how large it is

