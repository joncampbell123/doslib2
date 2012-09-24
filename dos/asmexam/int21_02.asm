;--------------------------------------------------------------------------------------
; INT21_02.COM
; 
; Reads keyboard using INT 16h BIOS, and outputs using INT 21h AH=0x02.
; Hit ESC to terminate.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

loop1:		xor	ah,ah
		int	16h
		cmp	al,27		; ESC?
		jz	loopend		; if so, exit
		cmp	al,13		; ENTER?
		jz	loopenter
		mov	ah,0x02		; INT 21h AH=0x02 write char to STDOUT
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

