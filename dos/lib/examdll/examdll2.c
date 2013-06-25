
/* HACK!!! Open Watcom linker/compiler requires these symbols for some reason */
unsigned char near __cdecl small_code_;
unsigned char far __cdecl big_code_;

/* make a pointer. we WANT relocation data */
const unsigned char far message_box[] = "This is a string of text";
/* NTS: it is VERY important we declare these pointers as being FAR pointers of type FAR */
const unsigned char far * far message = message_box;
const unsigned char far * far message2 = "This is another message";

int far __stdcall hello1() {
	return 0x1234;
}

int far __stdcall hello2(const char far *msg) {
	__asm {
		push	si
		push	ds
		push	ax
		cli
		lds	si,msg
l1:		lodsb
		or	al,al
		jz	l2
		mov	ah,0x0E
		xor	bx,bx
		int	0x10
		jmp	l1
l2:		pop	ax
		pop	ds
		pop	si
	}

	hello1();
	return (int)(0xABCDU);
}

