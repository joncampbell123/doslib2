;--------------------------------------------------------------------------------------
; A20STAT.COM
;
; Display whether or not the A20 gate is enabled using various methods.
;
; FIXME: CompuAdd laptop: Even when A20 is enabled, this code is not able to detect that
;        it is enabled through the keyboard controller.
; 
; FIXME: DOSBox and Virtualbox both return the result of the command at the wrong time,
;        much later. This is visible on your console as the DOS/BIOS acting as if you
;        had pressed '1' or '2'.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

start:		mov	ah,9
		mov	dx,is_a20_str
		int	21h

; keyboard test
keyboard_test:	mov	ah,9
		mov	dx,keyboard_a20
		int	21h
		cli
		mov	dx,no_str	; assume not
		mov	al,0xAD		; disable keyb
		call	keyb_write_command
		call	keyb_drain
		mov	al,0xD0		; command: read output port
		call	keyb_write_command
		call	keyb_read_data
		push	ax
		mov	al,0xAE		; enable keyb
		call	keyb_write_command
		pop	ax
		sti
		test	al,2		; if bit 1 is set, then A20 is enabled
		jz	.not_a20
		mov	dx,yes_str
.not_a20:	mov	ah,9
		int	21h

; port 92h "fast A20" test
fast_test:	mov	ah,9
		mov	dx,fast_a20
		int	21h
		mov	dx,n_a_str	; assume N/A
		in	al,0x92		; NTS: Hack for CompuAdd laptop which doesn't support port 0x92,
		mov	ah,al		;      but the undefined I/O region sometimes returns 0xFD. See GET16M.TXT
		in	al,0x92		;      for details.
		or	ah,al
		in	al,0x92
		or	al,ah		; AL = inp(0x92) | inp(0x92) | inp(0x92)
		cmp	al,0xFF		; if it reads back 0xFF it's not there
		jz	.done
		mov	dx,no_str	; assume NO
		test	al,2
		jz	.done		; if bit 1 not set, then A20 is disabled
		mov	dx,yes_str
.done:		mov	ah,9
		int	21h

; INT 15h BIOS
int15_test:	mov	ah,9
		mov	dx,bios_a20
		int	21h
		mov	dx,n_a_str	; assume N/A
		mov	ax,0x2402
		int	15h
		or	ah,ah		; AH=0 if supported
		jnz	.done
		mov	dx,no_str	; assume NO
		or	al,al		; AL=0 if off, 1 if ON
		jz	.done
		mov	dx,yes_str
.done:		mov	ah,9
		int	21h

; DONE. return to DOS
		ret

%include "comm8042.inc"

is_a20_str:	db		'Is A20 gate enabled?',13,10,'$'
keyboard_a20:	db		'Keyboard: $'
fast_a20:	db		'Fast A20 (92h): $'
bios_a20:	db		'BIOS INT 15h: $'

yes_str:	db		'Yes',13,10,'$'
no_str:		db		'No',13,10,'$'
n_a_str:	db		'N/A',13,10,'$'

		segment .bss

