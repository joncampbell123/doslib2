;--------------------------------------------------------------------------------------
; GETLABEL.COM
;
; Read the label from the current disk 
;
; Known issues:
;    Microsoft MS-DOS 6.22:
;        - If Windows 95 long filenames exist in the root directory, and they occur
;          before the actual volume label or the disk never had a volume label, the DOS
;          kernel will return one of the LFN entries instead.
;
;          Ideally we could check the attribute byte for this (look for 0x0F) but MS-DOS
;          seems to leave it set to 0x08 when returning it, so we really don't have any
;          way to workaround the issue.
;
;    Windows NT/2000/XP/Vista/7/etc...:
;        - GETLABEL.COM on an NTFS partition returns nonsense data, usually the first
;          11 characters of the user's home directory path.
;
;    IBM PC-DOS 1.0, 1.1
;        - The kernel does not understand extended FCBs, but will happily return the first
;          file it finds, usually COMMAND.COM
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

; zero memory in FCB
		cld
		mov	di,fcb
		xor	ax,ax
		mov	cx,0x2A/2
		rep	stosw

; make extended FCB
		mov	byte [fcb],0xFF
		mov	byte [fcb+6],0x08; match volume label
		mov	di,fcb+8
		mov	cx,8+3
		mov	al,'?'
		cld
		rep	stosb

; info is returned in the DTA, so set DTA location
		mov	ah,0x1A		; AH=0x1A set DTA
		mov	dx,dta
		int	21h

; carry out the enumeration
		mov	ah,0x11		; AH=0x11 find first file
		mov	dx,fcb
		int	21h
		cmp	al,0x00
		jnz	done

; print what was returned
print_info:	cld
		mov	cx,11		; print name
		mov	si,dta+1+7
		call	putslen

		mov	ah,0x09
		mov	dx,crlf
		int	21h

done:		xor	ah,ah
		int	21h

; entry:
;   CX = number of chars
;   SI = string
putslen:	push	cx
putslenloop1:	lodsb
		cmp	al,' '
		jz	putslenloop2
		mov	dl,al
		mov	ah,0x02
		int	21h
putslenloop2:	loop	putslenloop1
		pop	cx
		ret

		segment .data

crlf:		db	13,10,'$'

		segment .bss

fcb:		resb	0x2A

; WARNING: We don't know how large DOS will make the record size, therefore this must be last!
dta:		resb	0x100

