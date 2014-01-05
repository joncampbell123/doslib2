
#include <efi.h>
#include <efilib.h>
#include <stdint.h>
#include <efistdarg.h>

#include <efi/example/efidoslib_base.h>

EFI_SYSTEM_TABLE*				doslib_efisys = NULL;
EFI_HANDLE					doslib_efiimg = NULL;

void doslib_init(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
	doslib_efisys = SystemTable;
	doslib_efiimg = ImageHandle;
}

