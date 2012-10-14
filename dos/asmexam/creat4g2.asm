;--------------------------------------------------------------------------------------
; CREAT4G2.COM
;
; Create a file, lseek, write. This one creates a file that is just under 4GB on
; FAT32 drives, where standard (older) DOS APIs limit the file size to 2GB. This
; version deliberately leaves the "FAT32 extended file size" flag unset to show
; that the DOS kernel will limit file sizes to 2GB unless newer programs explicitly
; indicate they support FAT32 4GB file sizes.
;
; In fact the file created by this program will only be 13 bytes large because, for
; legacy compatability, the DOS 7.0 kernel will treat it as signed even for SEEK_SET
; and will seek back to 0 instead, and we'll only end up writing "Hello world" twice
; over itself at the start of the file.
; 
; CAUTION: On an actual DOS install involving the FAT filesystem, the lseek+write will
;          reveal contents from previously deleted clusters. Unlike Windows NT or
;          Linux, DOS makes no attempt to zero clusters when it allocates them to
;          satisfy the lseek() request.
;
; Bugs & Issues:
;     MS-DOS 7.0 (Windows 95)
;     MS-DOS 6.22
;     MS-DOS 5.0
;         - The DOS kernel correctly prevents this program from seeking to 0xF0000000
;           on the hard drive (220MB) capacity, yet allows this program to apparently
;           create a 4GB file on a floppy disk?!?. SCANDISK.EXE doesn't seem to have
;           a problem with it either. CHKDSK.EXE however, correctly detects the problem
;           and will truncate it down to 512 bytes if run with the /F (fix) switch.
;
;           It seems Microsoft corrected this bug starting with Windows 95 OSR2, and
;           will correctly prevent creating such files on FAT12 and FAT16 drives while
;           allowing it for FAT32 drives. However since this program deliberately does
;           NOT use the FAT32 enable flag, Windows 95 OSR2 will still not allow us to
;           lseek to 0xF000'0000 to create a 4GB file.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

; read the command line, skip leading whitespace
		mov	si,0x81
ld1:		lodsb
		cmp	al,' '
		jz	ld1
		dec	si

; and then NUL-terminate the line
		mov	bl,[0x80]
		xor	bh,bh
		add	bl,0x81
		mov	byte [bx],0

; SI is still the (now ASCIIZ) string
		cmp	byte [si],0	; is it NULL-length?
		jnz	do_mkdir
		mov	dx,str_need_param
		call	puts
		ret			; return to DOS

; do the file creation
do_mkdir:				; DS:SI = name of dir to make
		mov	ax,0x6C00	; AH=0x6C extended create file
		mov	bl,0x02		; BL=read/write compatible sharing
		mov	bh,0x20		; BH=return error rather than INT 24h
		xor	dh,dh
		mov	dl,0x10		; DL=create if not exist, fail if exist
		mov	cx,0		; CX=file attributes
		int	21h
		jnc	mkdir_ok	; CF=1 if error

		mov	dx,str_fail
		jmp	short exit_err

mkdir_ok:	mov	[filehandle],ax	; save the file handle returned by DOS

		mov	ah,0x40		; AH=0x40 write to handle
		mov	bx,[filehandle]
		mov	cx,str_msg_len
		mov	dx,str_msg
		int	21h

		mov	ax,0x4201	; AH=0x42 lseek AL=0x02 SEEK_END. This will fail
		mov	bx,[filehandle]
		mov	cx,0xF000
		mov	dx,0x0000	; CX:DX = offset 0xF000'0000
		int	21h		; result = 0x1000 + 13

		mov	ah,0x40		; AH=0x40 write to handle
		mov	bx,[filehandle]
		mov	cx,str_msg_len
		mov	dx,str_msg
		int	21h

		mov	ah,0x3E		; AH=0x3E close the file handle
		mov	bx,[filehandle]
		int	21h

; EXIT to DOS
exit:		ret
exit_err:	mov	ah,0x09
		int	21h
		mov	dx,crlf
		call	puts
		jmp	short exit

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .data

str_ok:		db	'Created$'
str_fail:	db	'Failed$'
str_need_param:	db	'Need a file name'
crlf:		db	13,10,'$'
str_msg:	db	'Hello world',13,10
str_msg_len	equ	13

		segment .bss

filehandle:	resw	1

