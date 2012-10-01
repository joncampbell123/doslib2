;--------------------------------------------------------------------------------------
; DISKCP95.COM
;
; Ask for free disk space the Windows 95 FAT32 way.
; 
; CAUTION: This code requires a 386 or higher. This is a reasonable requirement when
;          you consider Windows 95 requires a 386 or higher anyway even in pure DOS mode.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

		mov	di,fat32info	; clear the fat32info data area.
		mov	cx,0x30/2	; note that Windows 95 will fail the next call
		xor	ax,ax		; if we don't do this!
		cld
		rep	stosw

		mov	ah,0x19		; AH=0x19 get current default drive
		int	21h
		add	al,'A'		; convert 0..25 to A..Z
		mov	[drive_str],al	; change the drive_str to (for example) "C:\"

		mov	ax,0x7303	; Get FAT32 free disk space
		mov	dx,drive_str	; DS:DX = string to drive path (ex. "C:\")
		mov	di,fat32info	; ES:DI = buffer to hold FAT32 info
		mov	cx,0x30		; CX = length of buffer
		stc			; set carry just in case
		int	21h		; do it!
		jnc	drive_ok	; if no error, then proceed to print out info

		mov	dx,str_invalid_drv
		call	puts
		ret

; drive is OK, print out the contents
; NOTE: We use the success of this call as a sign that, yes, we're under Windows 95
;       and therefore we're free to use 386 32-bit registers as needed to do our job.
;       If that assumption is wrong, your 286 or older system will probably crash at
;       this point of the program and you will need to CTRL+ALT+DEL to restart.
drive_ok:

; EXIT to DOS
exit:		ret

;------------------------------------
puts:		push	ax
		push	bx
		push	cx
		mov	ah,0x09
		int	21h
		pop	cx
		pop	bx
		pop	ax
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

;------------------------------------
putdec16:	push	ax
		push	bx
		push	cx
		push	dx

		xor	dx,dx
		mov	cx,1
		mov	bx,10
		div	bx
		push	dx

putdec16_loop:	test	ax,0xFFFF
		jz	putdec16_pl
		xor	dx,dx
		inc	cx
		div	bx
		push	dx
		jmp	short putdec16_loop

putdec16_pl:	xor	bh,bh
putdec16_ploop:	pop	ax
		add	al,'0'
		call	putc
		loop	putdec16_ploop

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

		segment .data

str_invalid_drv:db	'Invalid drive',13,10,'$'
str_ex_free:	db	' free',13,10,'$'
str_ex_total:	db	' total',13,10,'$'
str_suf_bytes:	db	' bytes$'
str_suf_kbytes:	db	'KB$'
str_suf_mbytes:	db	'MB$'
crlf:		db	13,10,'$'

; this will be overwritten with the drive letter
drive_str:	db	'?:\',0

		segment .bss

fat32info:	resb	0x30

