;--------------------------------------------------------------------------------------
; DEVPREFIX.COM
;
; Read or set the MS-DOS DEV prefix usage.
; MS-DOS 2.0 to 3.3 supported a system-wide setting to determine whether to require a
; \DEV\ prefix in the path to access devices. MS-DOS 4.0 and higher ignore the set
; function and signal optional at all times.
;
; Hm... well actually it turns out MS-DOS 3.3 does NOT support this. Does the Ralph
; Brown interrupt list mean PC-DOS 3.3?
;
; It's interesting to note that playing with PC-DOS 2.1, setting the \DEV\ flag to 0
; (mantatory) does not prevent the COPY command from "seeing" the "CON" device, it just
; prevents the copy operation from getting any data.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	si,0x81
ld1:		lodsb
		cmp	al,' '
		jz	ld1
		cmp	al,0x0D
		jz	show_dev_flag

; set the flag state. AL=0 if require, nonzero if optional
		sub	al,'0'
		mov	dl,al		; DL=flag
		mov	ax,0x3703	; set flag
		int	21h

; show the flag. MS-DOS 4.0 and higher always return 0xFF
show_dev_flag:	mov	ax,0x3702	; get flag (0=require \DEV\  1=optional \DEV\)
		int	21h
		cmp	al,0x00
		jz	dev_flag_ok

		mov	dx,str_no_dev_flag
		call	puts
		mov	dx,crlf
		call	puts
		ret

dev_flag_ok:	push	dx
		mov	ah,0x09
		mov	dx,str_dev_flag
		int	21h
		pop	dx

		mov	al,dl		; DL=result of call
		add	al,'0'-0x20
		and	al,0x3F
		add	al,0x20
		call	putc

		mov	dx,crlf
		call	puts	

; EXIT to DOS
exit:		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

;------------------------------------
putc:		push	ax
		push	bx
		push	cx
		push	dx
		mov	ah,0x02
		mov	dl,al
		int	21h
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

		segment .data

str_no_dev_flag:db	'DOS does not provide mandatory \DEV\ prefix option$'
str_dev_flag:db	'\DEV\ is optional: $'
crlf:		db	13,10,'$'

		segment .bss

