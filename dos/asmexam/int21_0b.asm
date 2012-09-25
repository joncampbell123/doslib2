;--------------------------------------------------------------------------------------
; INT21_0B.COM
;
; STDIN status
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory
		section .text

loop1:		mov	ah,0x0B		; get STDIN status
		int	21h
		or	al,al		; is AL=0?
		jz	loop1		; loop if so
					; else assume AL=0xFF

		mov	ah,0x08		; direct input w/o echo
		int	21h
		cmp	al,27		; was it ESC?
		jz	loopend

		mov	ah,0x02		; write '.' to console
		mov	dl,'.'
		int	21h
		jmp	short loop1

loopend:	ret

