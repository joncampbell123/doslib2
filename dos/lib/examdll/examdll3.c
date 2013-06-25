
#include <dos.h>

/* HACK!!! Open Watcom linker/compiler requires these symbols for some reason */
unsigned char near __cdecl small_code_;
unsigned char far __cdecl big_code_;

/* external symbol */
int far __stdcall hello1();
int far __stdcall hello2(const char far *msg);
/* NTS: it is VERY important we declare these pointers as being FAR pointers of type FAR */
extern const unsigned char far * far message;

int far __stdcall hello3(const char far *msg) {
	if (hello1() == 0x1234) hello2("1 2 3 4\r\n");
	hello2("hello3!\r\n");
	hello2(message);
	hello2("\r\n");
	hello2(msg);
	return (int)(0xABCDU);
}

