;--------------------------------------------------------------------------------------
; DEFDRIVE.COM
; 
; View/set the default drive in MS-DOS.
; If nothing given on the command line, shows the current default drive.
; If A-Z is given on the command line, then sets the default drive.
;
; For more information on the Program Segment Prefix, see:
; http://en.wikipedia.org/wiki/Program_Segment_Prefix
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		push	cs
		pop	ds

		cld
		mov	si,81h		; DS:SI = command line
scan1:		lodsb
		cmp	al,' '
		jz	scan1

		and	al,~0x20	; quick and dirty uppercase conversion
		cmp	al,'A'
		jl	print_def
		cmp	al,'Z'
		ja	print_def

		sub	al,'A'		; convert A-Z to 0-25
		mov	dl,al
		mov	ah,0x0E		; AH=0x0E set default drive
		int	21h

print_def:	mov	ah,0x19		; AH=0x19 get current default drive
		int	21h
		add	al,'A'		; convert 0-25 to A-Z
		mov	[drv_letter],al

		mov	ah,0x09		; AH=0x09 write string to STDOUT
		mov	dx,drv_is
		int	21h

		ret

drv_is:		db	'Current drive is '
drv_letter:	db	'?'
		db	':',13,10,'$'

