;--------------------------------------------------------------------------------------
; LFNDIR.COM
; 
; Enumerate files and folders in current directory using Windows 95 long filenames
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

; carry out the enumeration
		mov	ax,0x714E	; find first matching file
		mov	cx,0x0017	; allowed=0x17 required=0
		mov	si,0		; 64-bit date format
		mov	dx,scan_pat	; DS:DX filespec
		mov	di,dta		; ES:DI find data record
		int	21h
		jnc	scan

		mov	dx,str_del_fail
		mov	ah,0x09
		int	21h
		ret

; print what was returned
scan:		mov	[findhandle],ax	; store "find handle"
scan_again:	mov	si,dta+0x130	; short name
scan_l1:	lodsb
		or	al,al
		jz	scan_l1e
		mov	ah,0x02
		mov	dl,al
		int	21h
		jmp	short scan_l1
scan_l1e:	

		mov	dx,str_sep
		mov	ah,0x09
		int	21h

scan2:		mov	si,dta+0x2C	; long name
scan2_l1:	lodsb
		or	al,al
		jz	scan2_l1e
		mov	ah,0x02
		mov	dl,al
		int	21h
		jmp	short scan2_l1
scan2_l1e:	

		mov	dx,crlf
		mov	ah,0x09
		int	21h

; next?
		mov	ax,0x714F	; find next
		mov	bx,[findhandle]	; give back file handle
		mov	si,0		; 64-bit date format
		mov	di,dta		; ES:DI find data record
		int	21h
		jnc	scan_again

; close find handle
		mov	ax,0x71A1	; find close
		mov	bx,[findhandle]	; find handle
		int	21h

; done
exit:		mov	ax,0x4C00
		int	21h
		ret

		segment .data

scan_pat:	db	'*.*',0
str_sep:	db	' / $';
str_del_fail:	db	'Fail'
crlf:		db	13,10,'$'

		segment .bss

findhandle:	resw	1

; WARNING: We don't know how large DOS will make the record size, therefore this must be last!
dta:		resb	0x100

