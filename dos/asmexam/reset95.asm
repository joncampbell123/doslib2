;--------------------------------------------------------------------------------------
; RESET95.COM
;
; Use INT 21h AX=0x710D to reset a drive under MS-DOS 7/Windows 95
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		xor	cx,cx
; we allow a 0, 1, or 2 on the command line to tell us which reset function to use
		mov	si,0x81		; command line
l1:		lodsb
		cmp	al,' '
		jz	l1
		cmp	al,'0'
		jb	l1e
		cmp	al,'9'
		jae	l1e
		mov	cl,al
		sub	cl,'0'
l1e:
; so at this point: CX = either 0 or the single-digit value read from command line
		stc
		mov	ax,0x710D	; Windows 95 reset drive
		mov	dx,0		; default drive
		int	21h
		jnc	reset_ok	; CF=0 if OK
		; OR.... it seems Windows 95 returns with AX=0x7100 and CF=1
		; when running in pure DOS mode, this function only available
		; when the graphcial part of Windows 95 is actie
		cmp	ax,0x7100
		jz	need_win95_gui

		mov	dx,str_failed
		call	puts
		ret

reset_ok:

; EXIT to DOS
exit:		ret

need_win95_gui:	mov	dx,str_need_win95_gui
		call	puts
		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

		segment .data

str_failed:	db	'Failed: ',13,10,'$'
str_need_win95_gui:db	'This wont work unless from within a Windows 95 DOS box',13,10,'$'

		segment .bss

