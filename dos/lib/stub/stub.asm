bits 16			; 16-bit real mode

segment code

..start:	push	cs
		pop	ds
		mov	dx,message
		mov	ah,0x9
		int	0x21
		mov	ax,0x4c01
		int	0x21

message:	db	"This is an MS-DOS shared object",13,10,'$'

segment stack class=stack

		resb	8192

