;--------------------------------------------------------------------------------------
; DUNLOK32.COM
;
; Windows 95/MS-DOS 7.0 FAT32 unlock volume command.
; If you code anything under DOS that requires direct I/O bypassing the filesystem
; (including INT 13h) you must use this command or DOS/Windows will block it.
;
; Note that you can call UNLOCK as many times as you want, it will always return OK.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ah,0x19
		int	21h		; get current drive

		mov	bl,al		; drive letter + 1
		inc	bl
		mov	cx,0x486A	; IOCTL request 0x086A for FAT12/FAT16
		mov	ax,0x440D	; IOCTL generic block device
		int	21h
		jnc	read_ok

		mov	ah,9
		mov	dx,str_failed
		int	21h
		int	20h

read_ok:	mov	ah,9
		mov	dx,str_ok
		int	21h

; EXIT to DOS
exit:		int	20h
		hlt

		segment .data

str_failed:	db	'Failed: ',13,10,'$'
str_ok:		db	'OK',13,10,'$'

		segment .bss

segsp:		resw	1
buffer:		resb	1024

