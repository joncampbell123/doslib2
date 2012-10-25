;--------------------------------------------------------------------------------------
; 80TEXT1.COM
; 
; Use the BIOS to set mode 3 (80x25 alphanumeric) and draw something on the screen
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		push	cs
		pop	ds

		mov	ax,3
		int	10h

		; we might be on MDA, or EGA/VGA with mono setup, whatever.
		; it changes what video segment we write to: mono at 0xB000, color at 0xB800.
		; this isn't specific to the MDA/Hercules, it can happen even on VGA if the
		; VGA BIOS is that kind from the early to mid 1990's that likes to autodetect
		; monochrome monitors and enforce mono setup (also mapping registers to 0x3B0).
		; it can also happen with late 1990's BIOSes if they fail to detect a VGA monitor.
		int	11h		; equipment detect
		and	al,0x30		; get bits 4-5
		cmp	al,0x30		; are they both set?
		jne	not_mono	; if not, then segment is 0xB800
		mov	byte [vseg+1],0xB0 ; change B800h to B000h
not_mono:

		; draw a message onscreen
		cld
		mov	es,[vseg]
		mov	si,str_msg
		mov	di,(80*2*4)+(10*2)	; start at row 4, column 10 in VRAM
		mov	ah,0x1E
wrloop:		lodsb
		or	al,al
		jz	.loopend
		stosw
		jmp	short wrloop
.loopend:

		ret

		segment .data

vseg:		dw	0xB800
str_msg:	db	'This message was written directly to video RAM',0

		segment .bss

