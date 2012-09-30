;--------------------------------------------------------------------------------------
; TSRNULL.COM
;
; Terminate and stay resident. It doesn't do anything other than leave a signature in
; memory you can see with a debugger or memory dumping tool.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		mov	ax,0x3100	; AH=0x31 terminate and stay resident AL=0x00 return code
		lea	dx,[end_of_image+15] ; DX = number of paragraphs to keep resident
		mov	cl,4
		shr	dx,cl
		int	21h

signature:	db	'TSR null is resident'
end_of_image:	equ	$

