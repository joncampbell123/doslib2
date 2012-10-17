;--------------------------------------------------------------------------------------
; LFNCR4GB.COM
;
; Create a file, lseek, write. This one creates a file that is just under 4GB on
; FAT32 drives, where standard (older) DOS APIs limit the file size to 2GB.
;
; Please note that the lseek() will fail and you will get a 13-byte file anyway
; if you do not have sufficient free disk space for a 0xF000'0000 byte long file.
; If you run it on MS-DOS 7.0 or earlier (without FAT32) the file will be 13 bytes
; long because pre-FAT32 kernels treat the SEEK_SET offset as a signed 32-bit
; integer, which is clamped to zero internally.
;
; Running this program will cause a LOT of disk activity because the DOS kernel must
; allocate a lot of clusters to satisfy the lseek request due to the fact that FAT/FAT32
; does not support sparse files.
;
; Also note that within a Windows 9x/ME DOS box this API call is the ONLY way for a
; DOS program to open/create files up to 4GB. For whatever reason INT 21h AH=0x6C only
; permits a 4GB limit from pure DOS mode. This means that if you intend for your code
; to work in either environment and you want 4GB file size FAT32 support, your code must
; use INT 21h AX=0x716C in a Windows DOS box and INT 21h AH=0x6C in pure DOS mode, which
; of course means your code has to go about detecting whether Windows is running.
;
; Also note that like any Long Filename API call the function is not available in pure
; DOS mode, you must start Windows and bring up a DOS box to use the API call used here.
; 
; CAUTION: On an actual DOS install involving the FAT filesystem, the lseek+write will
;          reveal contents from previously deleted clusters. Unlike Windows NT or
;          Linux, DOS makes no attempt to zero clusters when it allocates them to
;          satisfy the lseek() request.
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
		mov	ax,0x716C	; AH=0x716C extended create file using long filename
		mov	bl,0x02		; BL=read/write compatible sharing
		mov	bh,0x30		; BH=return error rather than INT 24h, enable FAT32 4GB file size (bit 4)
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

		mov	ax,0x4201	; AH=0x42 lseek AL=0x02 SEEK_END
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

