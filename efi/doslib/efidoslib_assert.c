
#include <efi.h>
#include <efilib.h>
#include <stdint.h>
#include <efistdarg.h>

#include <efi/doslib/efidoslib_base.h>

void _assert(int c,const char *c_str) {
	if (1 || c == 0) {
		CHAR16 tmp[2];

		/* NTS: If VirtualBox is any indication StdErr isn't really hooked up at all... :( */

		doslib_efisys->ConOut->OutputString(doslib_efisys->ConOut,L"Assertion failed! ");
		while ((*c_str) != 0) {
			tmp[0] = (CHAR16)(*c_str++);
			tmp[1] = 0;
			doslib_efisys->ConOut->OutputString(doslib_efisys->ConOut,tmp);
		}
		doslib_efisys->ConOut->OutputString(doslib_efisys->ConOut,L"\r\n");
		doslib_efisys->BootServices->Exit(doslib_efiimg,EFI_ABORTED,0,NULL);
	}
}

