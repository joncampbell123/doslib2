;--------------------------------------------------------------------------------------
; GET4G_2M.COM
;
; Write to disk anything visible in the 0xFFE00000 to 0xFFFFFFFF area.
; Write to disk the 2MB visible just under 4GB.
;
; If the system you run this on has more than 1MB of ROM, please use alternate versions
; of this program:
;
;   GET4G_2M.COM        4GB - 2MB
;   GET4G_4M.COM        4GB - 4MB
;   GET4G_8M.COM        4GB - 8MB
;
; DISK UTILIZATION NOTICE:
;
; This program captures 2MB of data, as 32 files 64KB each. If the program detects that
; there is insufficient disk space for the next 64KB block, it will pause and prompt
; you to hit ENTER to continue so that you have the chance to remove the floppy disk
; and move the files off on another machine to make room.
;
; Not compatible with:
; MS-DOS 1.x
; 
; Compatible with:
; MS-DOS/PC-DOS 2.0 or higher.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

%include "getfrmin.inc"

; the user didn't CTRL+C, so get started
.again:		mov	bl,[rd_seg]
		xor	bh,bh
		and	bl,0xF
		mov	al,[hexes+bx]
		mov	[fname+3],al

		mov	bl,[rd_seg]
		xor	bh,bh
		shr	bl,4
		mov	al,[hexes+bx]
		mov	[fname+2],al

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

		call	ensure_flatreal
		jc	.error

		call	copy_64kb
		jc	.error

		inc	byte [rd_seg]
		jz	.finished

		jmp	short .again

.finished:	ret

.error:		mov	ah,9
		mov	dx,error_str
		int	21h
		ret

%include "getfrmcm.inc"

hello_str:	db	'This program will write the 4GB-2MB ROM region to disk in',13,10
		db	'64KB fragments. Disk space required: 2MB. Please read GET4G.TXT.',13,10
		db	13,10,'$'

rd_seg_whole:	db	0x00,0x00		; NTS: see what I did here? rd_seg points to rd_seg_whole+2
rd_seg:		db	0xE0,0xFF
fname:		db	'FFE00000.ROM',0,'$'
		;	    ^
		;        012345678901

		segment .bss

idt:		resw	8			; one interrupt
old_gdtr:	resw	3
old_idtr:	resw	3
new_gdtr:	resw	3
new_idtr:	resw	3
fhandle:	resw	1
copy_buf:	resb	16384

