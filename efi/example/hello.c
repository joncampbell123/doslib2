
#include <efi.h>
#include <efilib.h>

/* NTS: Do NOT mark your efi_main as type EFIAPI, because the EFI BIOS does not
 *      directly call your function, the gnu-efi stub does */
EFI_STATUS efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
	InitializeLib(ImageHandle,SystemTable);
	Print(L"Hello world\r\n");
	return EFI_SUCCESS;
}

