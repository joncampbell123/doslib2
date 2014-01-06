
#include <efi.h>
#include <efilib.h>
#include <efistdarg.h>

extern EFI_SYSTEM_TABLE*				doslib_efisys;
extern EFI_HANDLE					doslib_efiimg;

void doslib_init(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable);

