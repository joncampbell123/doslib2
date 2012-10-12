;--------------------------------------------------------------------------------------
; DIR20.COM
; 
; Enumerate files and folders in current directory using AH=0x4E/0x4F. Uses ????????.???
; instead of *.*.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

; zero out DTA
		cld
		mov	di,dta
		xor	ax,ax
		mov	cx,0x100/2
		rep	stosw

; info is returned in the DTA, so set DTA location
		mov	ah,0x1A		; AH=0x1A set DTA
		mov	dx,dta
		int	21h

; carry out the enumeration
		mov	ax,0x4E00	; AH=0x4E find first file
		mov	cx,0xF7		; match anything
		mov	dx,scan_pat
		int	21h
		jnc	scan

		mov	dx,str_del_fail
		mov	ah,0x09
		int	21h
		ret

; print what was returned
scan:		mov	si,dta+0x1E
scan_l1:	lodsb
		or	al,al
		jz	scan_l1e
		mov	ah,0x02
		mov	dl,al
		int	21h
		jmp	short scan_l1
scan_l1e:	mov	dx,crlf
		mov	ah,0x09
		int	21h

; next?
		mov	ah,0x4F
		mov	dx,scan_pat
		int	21h
		jnc	scan

; done
exit:		mov	ax,0x4C00
		int	21h
		ret

		segment .data

scan_pat:	db	'????????.???',0
str_del_fail:	db	'Fail'
crlf:		db	13,10,'$'

		segment .bss

fcb:		resb	0x25

; WARNING: We don't know how large DOS will make the record size, therefore this must be last!
dta:		resb	0x100

