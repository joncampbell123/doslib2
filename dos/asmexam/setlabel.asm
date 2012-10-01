;--------------------------------------------------------------------------------------
; SETLABEL.COM
;
; Set the label from the current disk 
;
; Known issues:
;    Microsoft MS-DOS 6.22, 3.3:
;        - If Windows 95 long filenames exist in the root directory, and they occur
;          before the actual volume label or the disk never had a volume label, the DOS
;          kernel will return on enumeration that LFN entry. Unfortunately, it will not
;          allow this program to rename or delete the volume label.
;
;          In prior versions of this program, renaming would happen to work because we
;          used the ????????.??? filename in the FCB rename block, but of course that's
;          not wise to do because obviously we are then corrupting part of a long file
;          name directory entry!
;
;    Microsoft MS-DOS 3.30:
;        - If the volume label already exists, this code fails to attempt renaming it,
;          and will fail to change it. You must delete the volume label then create it.
;
;    Windows NT/2000/XP/Vista/7/etc...:
;        - This code will always announce that it created the volume label. Because
;          NTVDM.EXE apparently does not allow renaming the volume label as true DOS
;          dos.
;
;    DOSBox 0.74 emulator:
;        - DOSBox ignores the volume bit, except to support returning the volume label.
;          Attempting to create a volume label will instead create an empty file of that
;          name.
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
		mov	cx,(0x2A+0x2A)/2
		rep	stosw

; make extended FCB
		cld
		mov	al,' '
		mov	byte [fcb],0xFF
		mov	byte [fcb+6],0x08; will be volume label
		mov	di,fcb+7+1
		mov	cx,8+3
		rep	stosb

		mov	byte [fcbren],0xFF
		mov	byte [fcbren+6],0x08; match volume label
		mov	di,fcbren+7+1
		mov	cx,8+3
		mov	al,'?'
		rep	stosb

; copy the new label from the command line
		mov	di,fcb+8
		mov	si,0x81
l1:		lodsb
		cmp	al,' '
		jz	l1
		cmp	al,0x0D
		jz	l1e
		stosb
		mov	cx,8+3-1
l1main:		lodsb
		cmp	al,' '
		jz	l1e
		cmp	al,0x0D
		jz	l1e
		stosb
		loop	l1main
l1e:

; make sure the create FCB's name is the same as the rename FCB's target
		mov	si,fcb+8
		mov	di,fcbren+7+0x11
		mov	cx,8+3
		rep	movsb

; info is returned in the DTA, so set DTA location
		mov	ah,0x1A		; AH=0x1A set DTA
		mov	dx,dta
		int	21h

; enumerate to read the current volume label
		cld
		mov	si,fcbren
		mov	di,fcbchk
		mov	cx,0x2A/2
		rep	movsw

		mov	ah,0x11
		mov	dx,fcbchk
		int	21h			; find first
fcb_scan:	cmp	al,0x00
		jnz	not_rename		; on error, go to creation
		cmp	byte [dta+6],0x08	; did we actually get a volume label?
		jz	found_it		; if so, go to the renaming stage

		mov	ah,0x12
		mov	dx,fcbchk
		int	21h			; find next. keep searching
		jmp	short fcb_scan

; we found the existing volume label. copy the name we found into the
; rename FCB to ensure that's the only entry we change.
found_it:	cld
		mov	si,dta+7+1
		mov	di,fcbren+7+1
		mov	cx,11
		rep	movsb

; start by trying to rename the volume label
not_delete:	mov	ah,0x17
		mov	dx,fcbren
		int	21h
		mov	dx,str_renamed
		cmp	al,0x00
		jz	short common_str_err

; OK, then try to create
not_rename:	mov	ah,0x16
		mov	dx,fcb
		int	21h
		mov	dx,str_created
		cmp	al,0x00
		jz	short common_str_err
		mov	dx,str_create_fail

common_str_err:	mov	ah,0x09
		int	21h
		mov	ah,0x09
		mov	dx,str_crlf
		int	21h
		ret

		segment .data

str_renamed:	db	'Renamed$'
str_created:	db	'Created$'
str_create_fail:db	'Create failed$'
str_crlf:	db	13,10,'$'

		segment .bss

fcb:		resb	0x30		; for creation
fcbren:		resb	0x80		; for renaming
fcbchk:		resb	0x30		; for checking

; WARNING: We don't know how large DOS will make the record size, therefore this must be last!
dta:		resb	0x100

