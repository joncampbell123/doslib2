;--------------------------------------------------------------------------------------
; EXEC.COM
;
; Execute another MS-DOS program. In this case, we run COMMAND.COM.
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

; OK proceed
		cld
		xor	ax,ax
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

		cli			; DOS 2.x is said to screw up the stack pointer.
		mov	bx,cs		; just in case restore it proper.
		mov	ss,bx
		mov	sp,stack_end - 2
		sti

		jc	exec_err	; if it failed, say so

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
exec_cmdtail:	db	' /K echo hello',13,0
str_fail:	db	'Failed',13,10,'$'
str_ok:		db	'Exec OK',13,10,'$'

		segment .bss

stack_beg:	resb	0x400-1
stack_end:	resb	1

exec_fcb:	resb	24
exec_pblk:	resb	0x14

;-----------------------------------
ENDOFIMAGE:	resb	1		; this offset is used by the program to know how large it is

