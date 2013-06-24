; DOS shared object manager
; (C) 2013 Jonathan Campbell, Hackipedia.org
;
; Assemble with NASM
; Execution environment: 16-bit real mode

			bits	16		; 16-bit real mode
			org	0x100		; DOS .COM executable starts at 0x100 in memory

;--------------------------------------------------------
; nondiscardable resident section
;--------------------------------------------------------
			segment .text
; DOS BEGINS EXECUTING HERE
			jmp	_entry_point

old_int2f:		dw	0,0
runtime_flags:		dw	0
FLAG_REMOVE		equ	0x0001

; INT 2Fh hook
int2f:			cmp	ax,0x7BFF		; AX must be 0x7BFF
			jnz	int2f_pass
			cmp	bx,0xABCD		; BX must be 0xABCD
			jnz	int2f_pass
			cmp	ch,0x05			; CX must be 0x05xx (CL=function)
			jz	int2f_take
int2f_pass:		jmp	far [cs:old_int2f]
; INT 2Fh hook: process it. CX contains the function
int2f_take:		mov	ax,bx
			mov	bx,cs
			cmp	cl,0x2			; make sure function is in range
			jb	.function_in_range
; it's out of range. return error code
			xor	cx,cx
			dec	cx			; CX=0xFFFF
			mov	bx,cx
			iret
; it's in range: jump to function
.function_in_range:	xor	ch,ch
			add	cx,cx			; CX = (CL * 2)
			mov	si,int2f_jumptable
			add	si,cx
			jmp	word [si]

int2f_jumptable:	dw	int2f_CL_00_test
			dw	int2f_CL_01_remove

; CL=0x00 test
int2f_CL_00_test:	xor	cx,cx			; AX & BX are already set, zero CX
			iret

; CX=0x01 remove
int2f_CL_01_remove:	push	ax
			push	es
			push	ds

			push	cs
			pop	ds

			mov	bx,[old_int2f]
			mov	cx,[old_int2f+2]

			xor	ax,ax		; restore INT 2F vector
			mov	ds,ax
			mov	si,(0x2F*4)
			xchg	bx,[si]
			xchg	cx,[si+2]

			push	cs
			pop	es		; ES=our code segment
			pop	ds
			mov	ah,0x49		; AH=0x49 free memory
			int	21h

			pop	es
			pop	ax
			xor	bx,bx		; signal release by setting BX == 0
			iret

;--------------------------------------------------------
; nondiscardable resident section: utility functions
;--------------------------------------------------------

; puts_dos_cr: print DOS-style string ending in '$', then print newline
;        scope:
;                 NEAR function
;        input:
;                 DS:DX = String address
;        output:
;                 (none)
puts_dos_cr:		push	ax
			mov	ah,9
			int	21h
			mov	ah,9
			mov	dx,str_crlf
			push	cs
			pop	ds
			int	21h
			pop	ax
			ret

self_service_call:	mov	ax,0x7BFF
			mov	bx,0xABCD
			mov	ch,0x05
			int	2Fh
			ret

;--------------------------------------------------------
; end nondiscardable section
;--------------------------------------------------------
			align	16
_end_of_resident_portion equ	$

;--------------------------------------------------------
; discardable section
;--------------------------------------------------------

; PROGRAM EXECUTION BEGINS HERE
_entry_point:		push	cs
			pop	ds

; CHECK DOS VERSION. WE ONLY SUPPORT MS-DOS 4.0 OR HIGHER
; NTS: As I improve this program, we may be able to support down to MS-DOS 2.0.
; NTS: MS-DOS 1.0 does not support returning a version number, but we can detect
;      it anyway because it won't change the contents of AX either.
			mov	ax,0x3000
			int	21h
			cmp	ax,0x3000
			jz	.version_bad		; AX=0x3000 means this is MS-DOS 1.x
			cmp	al,4
			jae	.version_ok		; We require at least MS-DOS 4.x
; We don't support this DOS
.version_bad:		mov	al,1
			mov	dx,str_bad_dos_ver
			jmp	puts_dos_cr_and_exit
; -> Version checks out
.version_ok:	
%if DEBUG == 1
			mov	dx,strD_dos_version_ok
			call	puts_dos_cr
%endif

; process the command line
			cld
			mov	si,0x81
.cmdline_proc:		lodsb
			or	al,al
			jz	.cmdline_end
			cmp	al,13
			jz	.cmdline_end
			cmp	al,10
			jz	.cmdline_end
			cmp	al,' '
			jz	.cmdline_proc
			cmp	al,'/'
			jz	.cmdline_switch
			cmp	al,'-'
			jz	.cmdline_switch

			mov	dx,str_invalid_cmdline_char
			jmp	puts_dos_cr_and_exit
.cmdline_switch:	lodsb
			cmp	al,'?'
			jz	.cmdline_help
			cmp	al,'U'
			jz	.cmdline_remove
			cmp	al,'D'
			jz	.cmdline_keep_discardable
			cmp	al,'B'
			jz	.cmdline_keep_bss

			mov	dx,str_invalid_cmdline_char
			jmp	puts_dos_cr_and_exit
.cmdline_help:		mov	dx,str_help
			jmp	puts_dos_cr_and_exit
.cmdline_remove:	or	word [runtime_flags],FLAG_REMOVE
			jmp	.cmdline_proc
.cmdline_keep_discardable:mov	word [leave_resident],_end_of_discardable_portion
			jmp	.cmdline_proc		
.cmdline_keep_bss:	mov	word [leave_resident],_end_of_bss_portion
			jmp	.cmdline_proc
.cmdline_end:

; release our environment block, we don't need it anymore
%if DEBUG == 1
			mov	dx,strD_released_env_block
			call	puts_dos_cr
%endif
			mov	es,[0x2C]	; load ENV segment
			mov	ah,0x49		; AH=0x49 free memory
			int	21h
			xor	ax,ax		; and write 0x0000 over the segment value in our PSP
			mov	[0x2C],ax	; to prevent memory analysis tools from trying to use an invalid segment

; were we asked to remove ourself?
			test	word [runtime_flags],FLAG_REMOVE
			jz	.no_remove
; okay then, use the multiplex to remove ourself
			call	are_we_resident
			jc	.not_resident
; we're resident. make the call to remove
			mov	cl,0x01				; remove DSOMGR16 and cue the accordian music
			call	self_service_call
			or	bx,bx				; will return BX == 0 if successful
			jnz	.failed_to_flag_remove
%if DEBUG == 1
			mov	dx,strD_resident_image_removed
			jmp	puts_dos_cr_and_exit
%else
			jmp	exit_to_dos
%endif
.failed_to_flag_remove:
			mov	dx,str_failed_to_remove
			jmp	puts_dos_cr_and_exit
.not_resident:
%if DEBUG == 1
			mov	dx,strD_not_already_resident
			jmp	puts_dos_cr_and_exit
%else
			jmp	exit_to_dos
%endif
.no_remove:		

; are we already there?
			call	are_we_resident
			jc	.not_already_resident
			mov	dx,str_already_resident
			jmp	puts_dos_cr_and_exit
.not_already_resident:

; hook INT 2Fh
			cli
			push	ds
			xor	ax,ax
			mov	ds,ax
			mov	si,(0x2F*4)
			mov	ax,int2f
			xchg	ax,word [si]
			mov	bx,cs
			xchg	bx,word [si+2]
			pop	ds
			mov	di,old_int2f
			mov	word [di],ax
			mov	word [di+2],bx
			sti

; setup complete. terminate and stay resident
			mov	ax,0x3100
			mov	dx,[leave_resident]	; <- NTS: Our constants make sure to round up by alignment
			mov	cl,4
			shr	dx,cl
			int	21h

leave_resident:		dw		_end_of_resident_portion

str_crlf:		db		13,10,'$'
str_bad_dos_ver:	db		"Unsupported DOS version$"
str_already_resident:	db		"DSOMGR16 is already resident$"
str_invalid_cmdline_char:db		"Invalid command line char$"
str_failed_to_remove:	db		"Unable to remove resident image$"
str_help:		db		"DOS shared object manager v0.1 beta",13,10
			db		"(C) 2013 Jonathan Campbell Hackipedia.org",13,10
			db		13,10
			db		" /?         This help",13,10
			db		" /U         Remove from memory",13,10
%if DEBUG == 1
; NTS: In the non-debug builds, these switches are meant to be present, but undocumented
			db		" /D         Keep discardable section",13,10
			db		" /B         Keep BSS section",13,10
%endif
			db		"$"

%if DEBUG == 1
strD_dos_version_ok:	db		"DOS version OK$"
strD_released_env_block:db		"OK: Released ENV block$"
strD_not_already_resident:db		"/U: Not resident anyway$"
strD_resident_image_removed:db		"Resident image removed$"
%endif

;--------------------------------------------------------
; discardable section: utility functions
;--------------------------------------------------------

are_we_resident:	mov	cl,0x00		; check resident copy
			call	self_service_call
			cmp	ax,0xABCD	; AX=0xABCD if resident responds
			jnz	.no
			or	bx,bx		; BX is nonzero (in fact, contains segment of resident image)
			jz	.no
.yes:			clc
			ret
.no:			stc
			ret

; exit_to_dos: exit to DOS with error == 0 (but not remain resident)
exit_to_dos:		mov	ax,0x4C00
			int	21h

; puts_dos_cr_and_exit: print DOS-style string ending in '$', then print newline, then exit with error code
;        scope:
;                 NEAR function
;        input:
;                 AL = error code
;                 DS:DX = String address
;        output:
;                 (does not return)
puts_dos_cr_and_exit:	call	puts_dos_cr
			mov	ah,0x4C
			int	21h

			align	16
_end_of_discardable_portion equ	$

;--------------------------------------------------------
; BSS segment (does not exist in COM image)
;--------------------------------------------------------
			segment .bss

			align	16
_end_of_bss_portion	equ	$

