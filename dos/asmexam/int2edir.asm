;--------------------------------------------------------------------------------------
; INT2EDIR.COM
;
; Use INT 2E to execute "DIR" using the resident portion of COMMAND.COM
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		cli
		push	cs
		pop	ss
		push	cs
		pop	ds
		mov	sp,stack_end-2
		sti

		mov	ah,0x4A		; AH=0x4A resize memory block
		push	cs
		pop	es		; EX=COM memory block (also, our PSP)
		mov	bx,ENDOFIMAGE+0xF
		mov	cl,4
		shr	bx,cl		; BX = (BX + this image size + 0xF) >> 4 = number of paragraphs
		int	21h

		mov	si,cmd_dir
		int	0x2E

		cli
		push	cs
		pop	ss
		push	cs		; <- NTS: COMMAND.COM clobbers segment registers
		pop	ds
		mov	sp,stack_end-2
		sti

		mov	si,cmd_echo
		int	0x2E

		mov	ax,0x4C00
		int	21h

		segment .data

cmd_dir:	db	3
		db	'dir',13

cmd_echo:	db	10
		db	'echo Hello',13

		segment .bss

stack_beg:	resb	0x400-1
stack_end:	resb	1

;-----------------------------------
ENDOFIMAGE:	resb	1		; this offset is used by the program to know how large it is

