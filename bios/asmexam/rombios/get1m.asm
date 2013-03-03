;--------------------------------------------------------------------------------------
; GET1M.COM
;
; Write to disk anything visible in the 0xC0000 to 0xFFFFF area.
; 
; Recommended for older 8088/286/386 systems that map the BIOS into 0xE0000-0xFFFFF.
; For most accurate results, make sure you disable ROM shadowing.
;
; Not recommended for: newer 486/Pentium and newer systems where the BIOS image at
; 0xE0000-0xFFFFF is not the actual ROM contents but is instead a read-only decompressed
; image of ROM extracted to RAM at boot-up time. For these systems, you will need to
; use the GET4G.COM program to copy off the BIOS from the 0xFFF00000-0xFFFFFFFF region
; (1MB just below 4GB). Note that some 386 systems may not offer the entire ROM either
; at 0xF0000, on these systems you will need to use GET16M to read from
; 0xF00000-0xFFFFFF (1MB below 16MB----the average 386SX of the time only offered an
; external 24-bit address bus).
;
; DISK UTILIZATION NOTICE:
;
; The program creates 4 files: PC_C0000.ROM, PC_D0000.ROM, etc... (you get the idea).
; Each one is 64KB in size. If there is insufficient room for the next file, the program
; will pause and wait for you to remove the disk, move off the files, then re-insert the
; disk for more fragments.
;
; Not compatible with:
; MS-DOS 1.x
; 
; Compatible with:
; MS-DOS/PC-DOS 2.0 or higher.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

init_detect:
; Autodetect and reject MS-DOS 1.x
		mov	ax,0x3000
		int	21h
		cmp	ax,0x3000	; MS-DOS 1.x does not support the call, and doesn't change AX
		jnz	.not_dos1
		ret			; quiet exit
.not_dos1:

; print our hello message
print_hello:
		push	cs
		pop	ds
		mov	ah,9
		mov	dx,hello_str
		int	21h
; prompt
		mov	ah,9
		mov	dx,anykey_str
		int	21h
		call	pause
		cmp	al,27		; if the user hit ESC, then exit
		jnz	.did_not_hit_esc
		ret
.did_not_hit_esc:

; the user didn't CTRL+C, so get started
.again:		mov	al,[rd_seg+1]
		mov	cl,4
		shr	al,cl
		add	al,'A' - 10
		mov	[fname+3],al

		call	prompt_if_no_room
		jc	.finished

		mov	ah,9
		mov	dx,copying_str
		int	21h

		mov	ah,9
		mov	dx,fname
		int	21h

		mov	ah,9
		mov	dx,crlf_str
		int	21h

		call	copy_64kb
		jc	.error

		add	word [rd_seg],0x1000
		jz	.finished
		jmp	short .again

.finished:	ret

.error:		mov	ah,9
		mov	dx,error_str
		int	21h
		ret

; copy 64kb
copy_64kb:	mov	ah,0x3C		; create file
		xor	cx,cx
		mov	dx,fname
		int	21h
		jc	.copy_exit
		mov	[fhandle],ax

		xor	si,si
		mov	cx,4		; 4 x 16KB = 64KB
.copy_loop:	push	cx
		push	si

		cld
		cli
		push	cs
		pop	es
		mov	cx,16384/2
		mov	ds,[rd_seg]
		mov	di,copy_buf
		rep	movsw
		sti
		push	cs
		pop	ds

		mov	ah,0x40
		mov	bx,[fhandle]
		mov	cx,16384
		mov	dx,copy_buf
		int	21h
		cmp	ax,16384
		jnz	.copy_write_err

		pop	si
		pop	cx
		add	si,16384
		loop	.copy_loop

		mov	ah,0x3E
		mov	bx,[fhandle]
		int	21h

.copy_exit:
		ret
.copy_write_err:
		add	sp,2+2		; discard saved SI+CX
		mov	ah,0x3E
		mov	bx,[fhandle]
		int	21h
		stc
		ret

; pause
pause:		mov	ah,1
		int	21h
		cmp	al,27
		jz	pausee	
		cmp	al,13
		jnz	pause
pausee:		ret

; if the current disk has insufficient room, then prompt the user
; to remove the floppy and move off the data, then re-insert the
; floppy and hit ENTER when ready.
prompt_if_no_room:
		mov	ah,0x36		; GET FREE DISK SPACE
		xor	dl,dl		; default drive
		int	21h
		cmp	ax,0xFFFF
		jnz	.ok
		stc
		ret
; AX = sectors/cluster
; BX = free clusters
; CX = bytes/sector
; DX = total clusters
.ok:		mul	bx		; DX:AX = AX * BX
		or	dx,dx		; assume DX != 0 means enough room
		jnz	.enough_room
		cmp	ax,128+2	; 128 sectors x 512 bytes = 64KB
		jge	.enough_room
; so there's not enough room. print a message saying so and wait for user to hit ENTER
		mov	ah,9
		mov	dx,full_str
		int	21h
		call	pause
		jmp	short prompt_if_no_room ; try again
.enough_room:	clc
		ret

error_str:	db	'An error occured',13,10,'$'

hello_str:	db	'This program will write the 1MB adapter ROM region to disk in',13,10
		db	'64KB fragments. Disk space required: 256KB',13,10
		db	13,10,'$'

full_str:	db	'Remove disk and move files off on another computer, re-insert and hit ENTER',13,10,'$'
anykey_str:	db	'Press ENTER to start',13,10,'$'
copying_str:	db	'Writing... ','$'
crlf_str:	db	13,10,'$'

rd_seg:		dw	0xC000
fname:		db	'PC_C0000.ROM',0,'$'
		;	    ^
		;        012345678901

		segment .bss

fhandle:	resw	1
copy_buf:	resb	16384

