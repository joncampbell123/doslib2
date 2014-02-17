;--------------------------------------------------------------------------------------
; SETTIMEX.COM
;
; Set system clock to 1996/04/20 17:30:15.22
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ah,0x2D		; set system time
		mov	cx,(17 << 8) + 30; CH=17  CL=30
		mov	dx,(15 << 8) + 22; DH=15  DL=22
		int	21h

		mov	ah,0x2B		; set system date
		mov	cx,1996		; CX=1996
		mov	dx,(4 << 8) + 20; DH=4  DL=20
		int	21h

; done. exit
exit:		mov	ax,0x4C00
		int	21h

