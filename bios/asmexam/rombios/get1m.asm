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
; Each one is 64KB in size. If the program knows that it's running on a 360KB disk it
; will pause once per 64KB so that you have a chance to remove the disk and move off
; the contents to make more room.
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

; Is the current drive (that we'll be writing to) a 360KB 5.25" floppy or smaller?
; Since DPB fields shift around prior to MS-DOS 4.0 it's more reliable to check the media ID
		mov	ah,0x32
		xor	dl,dl		; AH=0x32 get DPB from current drive
		int	21h
		or	al,al
		jz	.dpb_ok
		ret			; quiet exit
.dpb_ok:	mov	al,[bx+0x16]	; INT 21h will return with DS:BX set to the DPB
		cmp	al,0xFD		; read the media ID byte which will be:
					;   FFh    floppy, double-sided, 8 sectors per track (320K)
					;   FEh    floppy, single-sided, 8 sectors per track (160K)
					;   FDh    floppy, double-sided, 9 sectors per track (360K)
					;   FCh    floppy, single-sided, 9 sectors per track (180K)
		jb	.not_360
		inc	byte [cs:pause_360] ; note it
.not_360:

; print our hello message
print_hello:
		push	cs
		pop	ds
		mov	ah,9
		mov	dx,hello_str
		int	21h

; if 360KB detected, then say sp
		test	byte [pause_360],1
		jz	.not_360
		mov	ah,9
		mov	dx,notice_360
		int	21h
.not_360:

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
		
		test	byte [pause_360],1
		jz	.next_loop
		mov	ah,9
		mov	dx,anykey_str
		int	21h
		call	pause
.next_loop:	jmp	short .again

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

error_str:	db	'An error occured',13,10,'$'

hello_str:	db	'This program will write the 1MB adapter ROM region to disk in',13,10
		db	'64KB fragments. Disk space required: 256KB',13,10
		db	13,10,'$'

notice_360:	db	'The copy operation will pause every 64KB because the target',13,10
		db	'disk is 360KB or smaller.',13,10
		db	13,10,'$'

anykey_str:	db	'Press ENTER to start the copy operation',13,10,'$'
copying_str:	db	'Writing... ','$'
crlf_str:	db	13,10,'$'

rd_seg:		dw	0xC000
pause_360:	db	0
fname:		db	'PC_C0000.ROM',0,'$'
		;	    ^
		;        012345678901

		segment .bss

fhandle:	resw	1
copy_buf:	resb	16384

