;--------------------------------------------------------------------------------------
; INT21_08.COM
;
; Character input without echo. 
;
; Hit ESC to terminate.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

loop1:		mov	ah,0x08		; console input
		int	21h

		cmp	al,27		; ESC?
		jz	loopend		; exit if so
		cmp	al,13		; ENTER?
		jz	loopenter

		mov	ah,0x02		; write it back to output AH=2 DL=char
		mov	dl,al
		int	21h
		jmp	short loop1

loopenter:	mov	ah,0x02
		mov	dl,13
		int	21h
		mov	ah,0x02
		mov	dl,10
		int	21h
		jmp	short loop1

loopend:	ret

