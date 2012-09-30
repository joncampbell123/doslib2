;--------------------------------------------------------------------------------------
; TSRNULL2.COM
;
; Terminate and stay resident. It doesn't do anything other than leave a signature in
; memory you can see with a debugger or memory dumping tool. This version also takes
; the effort to free it's environment block.
;
; Notes
;     MS-DOS 6.22
;         - I noticed while debugging this program that INT 21h AH=0x49 FREE MEMORY
;           will return, if successful, CF=0 and AX=segment of DOS memory control
;           block associated with the memory we just freed.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		mov	es,[0x2C]	; load ENV segment
		mov	ah,0x49		; AH=0x49 free memory
		int	21h
		xor	ax,ax		; and write 0x0000 over the segment value in our PSP
		mov	[0x2C],ax	; to prevent memory analysis tools from trying to use an invalid segment

		mov	ax,0x3100	; AH=0x31 terminate and stay resident AL=0x00 return code
		lea	dx,[end_of_image+15] ; DX = number of paragraphs to keep resident
		mov	cl,4
		shr	dx,cl
		int	21h

signature:	db	'TSR null is resident'
end_of_image:	equ	$

