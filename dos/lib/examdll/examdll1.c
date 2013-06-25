
/* HACK!!! Open Watcom linker/compiler requires these symbols for some reason */
unsigned char near __cdecl small_code_;
unsigned char far __cdecl big_code_;

/* NTS: Must be unsigned char[] not unsigned char * to avoid creating a pointer, and
 *      therefore causing the creation of relocation data */
const unsigned char far message[] = "This is a string of text";

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

	return (int)0xABCD;
}

