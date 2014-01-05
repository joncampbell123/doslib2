
#include <efi.h>
#include <efilib.h>
#include <stdint.h>
#include <efistdarg.h>

typedef struct _printf_t {
	unsigned char				*buf,*fence;
	SIMPLE_TEXT_OUTPUT_INTERFACE		*eftop;
	va_list					va;
} _printf_t;

int puts(const char *str);
int printf(const char *format,...);
	
