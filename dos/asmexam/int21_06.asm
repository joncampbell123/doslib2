;--------------------------------------------------------------------------------------
; INT21_06.COM
; 
; Uses INT 21h AH=0x06 to output to console directly, and read from console using
; AH=0x06 DL=0xFF.
;
; Hit ESC to terminate. CTRL+C will have no effect.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

loop1:		mov	ah,0x06		; AH=6 DL=0xFF direct console input
		mov	dl,0xFF
		int	21h
		jz	loop1		; ZF=1 if no character

		cmp	al,27		; ESC?
		jz	loopend		; exit if so
		cmp	al,13		; ENTER?
		jz	loopenter

		mov	ah,0x06		; write it back to output AH=6 DL=char
		mov	dl,al
		int	21h
		jmp	short loop1

loopenter:	mov	ah,0x06
		mov	dl,13
		int	21h
		mov	ah,0x06
		mov	dl,10
		int	21h
		jmp	short loop1

loopend:	ret

