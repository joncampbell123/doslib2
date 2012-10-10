;--------------------------------------------------------------------------------------
; SVERIFY.COM
; 
; Set the verify flag flag
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		mov	si,0x81
l1:		lodsb
		cmp	al,' '
		jz	l1
		sub	al,'0'
		and	al,1

		mov	ah,0x2E
		xor	dl,dl		; DOS 1/2.x needs this?
		int	21h

		ret

