;--------------------------------------------------------------------------------------
; LFNSNAME.COM
;
; Generate a short 8.3 filename from a long filename
;
; NOTES:
;         - For whatever reason, despite Ralph Brown's list describing the output
;           as DOS 8.3 ASCIIz, the actual string is padded out to 13 bytes with
;           the underscore character '_'. Even when the long name is shorter than
;           8.3. For example:
;
;                "test.txt" -> "test.txt_____"
;    "abcdefghijklmnop.123" -> "abcdefgh.123_"
;
;           So then if your code wants to actually make use of it, you will need to
;           scan to the end of the string and trim off the extra underscores. So if
;           this function ues the same algorithm as the filesystem, then I wonder
;           how well the numerous bits in Windows 9x/ME handle stripping off these
;           underscore characters.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

; clear memory at dstname
		cld
		mov	di,dstname
		mov	cx,32/2
		xor	ax,ax
		rep	stosw

; scan for first name in the command line
		cld
		mov	si,0x81		; PSP segment:command line
l1:		lodsb
		cmp	al,13
		jz	end_not_enuf
		cmp	al,' '
		jz	l1
		dec	si
		mov	[srcname_p],si

; scan past first name
l2:		lodsb
		cmp	al,13		; we're looking for " as delimiter
		jnz	l2
		mov	byte [si-1],0	; ASCIIZ snip the name

; we got two names, now carry out the rename
do_rename:	mov	ax,0x71A8	; get short name
		mov	si,[srcname_p]	; DS:SI = long name
		mov	di,dstname	; ES:DI = buffer for short name
		mov	dx,0x0111	; DH = 0x01 (8.3 ASCIIZ format) DL = 0x11 both are using the current OEM set
		int	21h
		jc	fail		; CF=1 on error

; show it
		cld
		mov	si,dstname
sl1:		lodsb
		or	al,al
		jz	sl1e
		mov	dl,al
		mov	ah,2
		int	21h
		jmp	short sl1
sl1e:

; done. exit
exit:		mov	ax,0x4C00
		int	21h

fail:		mov	ah,0x09
		mov	dx,str_fail
		int	21h
		ret

end_not_enuf:	mov	ah,0x09
		mov	dx,str_not_enuf
		int	21h
		ret

		segment .data

str_fail:	db	'Failed',13,10,'$'
str_not_enuf:	db	'Not enough params',13,10,'$'

		segment .bss

srcname_p:	resw	1
dstname:	resb	14

