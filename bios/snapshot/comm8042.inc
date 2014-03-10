; COMMON CODE: 8042 keyboard controller functions

keyb_wait_write:push	ax
.loop:		in	al,0x64
		test	al,2		; is buffer full?
		jnz	.loop
		pop	ax
		ret

keyb_write_data:call	keyb_wait_write
		out	0x60,al
		ret

keyb_write_command:
		call	keyb_wait_write
		out	0x64,al
		ret

keyb_drain:	in	al,0x64
		test	al,3		; is buffer empty OR buffer full?
		jz	.end		; if so, exit
		in	al,0x60		; read and discard data
		jmp	short keyb_drain
.end:		ret

keyb_read_data:	in	al,0x64
		test	al,1		; is buffer empty?
		jz	keyb_read_data
		in	al,0x60
		ret

