; COMMON CODE: 8042 keyboard controller functions

keyb_write_data:push	ax
.kloop:		in	al,0x64
		test	al,2		; is buffer full?
		jnz	.kloop
		pop	ax
		out	0x60,al
		ret

keyb_write_command:
		push	ax
.kloop:		in	al,0x64
		test	al,2		; is buffer full?
		jnz	.kloop
		pop	ax
		out	0x64,al
		ret

keyb_drain:	in	al,0x60		; read and discard data
		in	al,0x64
		test	al,1		; is buffer empty?
		jnz	keyb_drain	; if not, repeat
		ret

keyb_read_data:	in	al,0x64
		test	al,1		; is buffer empty?
		jz	keyb_read_data
		ret

