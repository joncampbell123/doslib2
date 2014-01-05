
#include <efi.h>
#include <efilib.h>
#include <stdint.h>
#include <efistdarg.h>

#include <efi/example/efidoslib_base.h>
#include <efi/example/efidoslib_utf.h>
#include <efi/example/efidoslib_printf.h>
#include <efi/example/efidoslib_assert.h>

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
	InitializeLib(ImageHandle,SystemTable);
	doslib_init(ImageHandle,SystemTable);
	Print(L"Hello world (gnu-efi Print)\r\n");
	SystemTable->ConOut->OutputString(SystemTable->ConOut,L"Hello world (direct ConOut call)\r\n");
	puts("Hello world (puts)\r\n");
	printf("Hello world (printf) %s\r\n","Hello world string");
	return EFI_SUCCESS;
}

