;--------------------------------------------------------------------------------------
; BOOTDRV.COM
;
; Read from the DOS kernel the drive we booted from.
; See: http://www.ctyme.com/intr/rb-2729.htm 
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		push	cs
		pop	ds

		xor	dx,dx
		mov	ax,0x3305	; GET BOOT DRIVE
		int	21h
		cmp	dl,0		; DL=boot drive, 1=A, 2=B, etc.
		jz	not_available

		push	dx
		mov	ah,0x09
		mov	dx,drv_is
		int	21h
		pop	dx

		mov	ah,0x02
		add	dl,'A' - 1
		int	21h

		mov	ah,0x09
		mov	dx,crlf
		int	21h

		ret

not_available:	mov	ah,0x09
		mov	dx,drv_na
		int	21h
		ret

drv_is:		db	'Boot drive is $';
crlf:		db	13,10,'$'
drv_na:		db	'Boot drive N/A',13,10,'$'

