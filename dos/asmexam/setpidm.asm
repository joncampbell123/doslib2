;--------------------------------------------------------------------------------------
; SETPIDM.COM
;
; Same effective hack as SETPID.COM except that instead of calling INT 21h AH=0x50,
; we instead directly modify the "parent PSP" field of the allocated block's
; Memory Control Block. MS-DOS 2.0 or higher.
;
; WARNING: This will increase the parent process's memory footprint by 8K. Repeatedly
;          running the program will drain 8K per run. Since the parent process has no
;          recollection of that allocation, the memory will stay lost until that process
;          terminates. That means that if you run this program from your main
;          COMMAND.COM shell, you may as well consider that memory gone until you either
;          reboot your system or force COMMAND.COM to terminate somehow.
;
;          The recommended way to test this program is to run COMMAND.COM again,
;          effectively spawning a shell within your main shell, and then running this
;          program repeatedly (along with MEM.EXE to show that the available memory
;          has decreased). When you are satisfied with the test, exit the sub-shell
;          process, which will free it and the 8K blocks this program allocated on it's
;          behalf.
;
;          Finally: I have no guarantees or assumptions what will happen if you replace
;          COMMAND.COM with this program. Maybe IO.SYS considers itself a process, or
;          perhaps whatever sentinel value DOS considers a "no parent" process ID will
;          cause erratic behavior---I don't really know. So whatever you do: don't make
;          this program your root command shell!
;
; NOTES:
;    - IBM PC-DOS 2.1 -> Works
;    - MS-DOS 6.22 -> Works
;    - Windows 95/98/ME -> Works (pure DOS or in a DOS Box)
;    - Windows XP -> Works (from within NTVDM.EXE)
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
		jmp	exit_err_str

; ========================================================
; print our block's segment on the console
; ========================================================
com_resize_ok:	mov	dx,str_this_com
		call	puts
		mov	ax,cs
		call	puthex16
		mov	dx,crlf
		call	puts

; ========================================================
; Allocate block #1
; ========================================================
		mov	ah,0x48
		mov	bx,256		; allocate 256 paragraphs (4096 bytes)
		int	21h
		jnc	com_alloc1_fail
		xor	ax,ax
com_alloc1_fail:mov	[block1],ax

; ========================================================
; print our block's segment on the console
; ========================================================
		mov	dx,str_block1
		call	puts
		mov	ax,[block1]
		call	puthex16
		mov	dx,crlf
		call	puts

; ========================================================
; print our block's owner on the console (read it from the MCB that preceeds it)
; ========================================================
		mov	dx,str_owner
		call	puts
		mov	ax,[block1]
		dec	ax		; refer to MCB header, not the block itself
		mov	es,ax
		mov	ax,[es:1]	; read owner
		call	puthex16
		mov	dx,crlf
		call	puts

; ========================================================
; print the parent process's PSP segment
; ========================================================
		mov	dx,str_parent
		call	puts
		mov	ax,[cs:0x16]
		call	puthex16
		mov	dx,crlf
		call	puts

; ========================================================
; Allocate block #2
; ========================================================
		mov	ah,0x48
		mov	bx,512		; allocate 512 paragraphs (8192 bytes)
		int	21h
		jnc	com_alloc2_fail
		xor	ax,ax
com_alloc2_fail:mov	[block2],ax

; ========================================================
; Change the allocate blocks' owner directly in the MCB
; ========================================================
		mov	bx,[cs:0x16]
		mov	ax,[block2]
		dec	ax
		mov	es,ax
		mov	[es:1],bx

; ========================================================
; print our block's segment on the console
; ========================================================
		mov	dx,str_block2
		call	puts
		mov	ax,[block2]
		call	puthex16
		mov	dx,crlf
		call	puts

; ========================================================
; print the block's owner on the console (read it from the MCB that preceeds it)
; ========================================================
		mov	dx,str_owner
		call	puts
		mov	ax,[block2]
		dec	ax		; refer to MCB header, not the block itself
		mov	es,ax
		mov	ax,[es:1]	; read owner
		call	puthex16
		mov	dx,crlf
		call	puts

; EXIT to DOS
exit:		mov	ah,0x50		; restore "current process ID" to ourself
		mov	bx,cs
		int	21h
		mov	ax,0x4C00	; exit to DOS
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
str_block1:	db	'Block 1: $'
str_block2:	db	'Block 2: $'
str_parent:	db	'Parent: $'
str_owner:	db	' owner: $'
crlf:		db	13,10,'$'

		segment .bss

block1:		resw	1
block2:		resw	1

;-----------------------------------
ENDOFIMAGE:	resb	1		; this offset is used by the program to know how large it is

