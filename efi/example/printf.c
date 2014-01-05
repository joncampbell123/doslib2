
#include <efi.h>
#include <efilib.h>
#include <stdint.h>
#include <efistdarg.h>

#include <efi/example/efidoslib_base.h>

enum {
	UTF8ERR_INVALID=-1,
	UTF8ERR_NO_ROOM=-2
};

#ifndef UNICODE_BOM
#define UNICODE_BOM 0xFEFF
#endif

typedef char utf8_t;
typedef uint16_t utf16_t;

int utf8_encode(char **ptr,char *fence,uint32_t code) {
	int uchar_size=1;
	char *p = *ptr;

	if (!p) return UTF8ERR_NO_ROOM;
	if (code >= (uint32_t)0x80000000UL) return UTF8ERR_INVALID;
	if (p >= fence) return UTF8ERR_NO_ROOM;

	if (code >= 0x4000000) uchar_size = 6;
	else if (code >= 0x200000) uchar_size = 5;
	else if (code >= 0x10000) uchar_size = 4;
	else if (code >= 0x800) uchar_size = 3;
	else if (code >= 0x80) uchar_size = 2;

	if ((p+uchar_size) > fence) return UTF8ERR_NO_ROOM;

	switch (uchar_size) {
		case 1:	*p++ = (char)code;
			break;
		case 2:	*p++ = (char)(0xC0 | (code >> 6));
			*p++ = (char)(0x80 | (code & 0x3F));
			break;
		case 3:	*p++ = (char)(0xE0 | (code >> 12));
			*p++ = (char)(0x80 | ((code >> 6) & 0x3F));
			*p++ = (char)(0x80 | (code & 0x3F));
			break;
		case 4:	*p++ = (char)(0xF0 | (code >> 18));
			*p++ = (char)(0x80 | ((code >> 12) & 0x3F));
			*p++ = (char)(0x80 | ((code >> 6) & 0x3F));
			*p++ = (char)(0x80 | (code & 0x3F));
			break;
		case 5:	*p++ = (char)(0xF8 | (code >> 24));
			*p++ = (char)(0x80 | ((code >> 18) & 0x3F));
			*p++ = (char)(0x80 | ((code >> 12) & 0x3F));
			*p++ = (char)(0x80 | ((code >> 6) & 0x3F));
			*p++ = (char)(0x80 | (code & 0x3F));
			break;
		case 6:	*p++ = (char)(0xFC | (code >> 30));
			*p++ = (char)(0x80 | ((code >> 24) & 0x3F));
			*p++ = (char)(0x80 | ((code >> 18) & 0x3F));
			*p++ = (char)(0x80 | ((code >> 12) & 0x3F));
			*p++ = (char)(0x80 | ((code >> 6) & 0x3F));
			*p++ = (char)(0x80 | (code & 0x3F));
			break;
	};

	*ptr = p;
	return 0;
}

int utf8_decode(const char **ptr,const char *fence) {
	const char *p = *ptr;
	int uchar_size=1;
	int ret = 0,c;

	if (!p) return UTF8ERR_NO_ROOM;
	if (p >= fence) return UTF8ERR_NO_ROOM;

	ret = (unsigned char)(*p);
	if (ret >= 0xFE) { p++; return UTF8ERR_INVALID; }
	else if (ret >= 0xFC) uchar_size=6;
	else if (ret >= 0xF8) uchar_size=5;
	else if (ret >= 0xF0) uchar_size=4;
	else if (ret >= 0xE0) uchar_size=3;
	else if (ret >= 0xC0) uchar_size=2;
	else if (ret >= 0x80) { p++; return UTF8ERR_INVALID; }

	if ((p+uchar_size) > fence)
		return UTF8ERR_NO_ROOM;

	switch (uchar_size) {
		case 1:	p++;
			break;
		case 2:	ret = (ret&0x1F)<<6; p++;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= c&0x3F;
			break;
		case 3:	ret = (ret&0xF)<<12; p++;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= (c&0x3F)<<6;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= c&0x3F;
			break;
		case 4:	ret = (ret&0x7)<<18; p++;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= (c&0x3F)<<12;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= (c&0x3F)<<6;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= c&0x3F;
			break;
		case 5:	ret = (ret&0x3)<<24; p++;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= (c&0x3F)<<18;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= (c&0x3F)<<12;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= (c&0x3F)<<6;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= c&0x3F;
			break;
		case 6:	ret = (ret&0x1)<<30; p++;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= (c&0x3F)<<24;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= (c&0x3F)<<18;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= (c&0x3F)<<12;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= (c&0x3F)<<6;
			c = (unsigned char)(*p++); if ((c&0xC0) != 0x80) return UTF8ERR_INVALID;
			ret |= c&0x3F;
			break;
	};

	*ptr = p;
	return ret;
}

int utf16le_encode(char **ptr,char *fence,uint32_t code) {
	char *p = *ptr;

	if (!p) return UTF8ERR_NO_ROOM;
	if (code > 0x10FFFF) return UTF8ERR_INVALID;
	if (code > 0xFFFF) { /* UTF-16 surrogate pair */
		uint32_t lo = (code - 0x10000) & 0x3FF;
		uint32_t hi = ((code - 0x10000) >> 10) & 0x3FF;
		if ((p+2+2) > fence) return UTF8ERR_NO_ROOM;
		*p++ = (char)( (hi+0xD800)       & 0xFF);
		*p++ = (char)(((hi+0xD800) >> 8) & 0xFF);
		*p++ = (char)( (lo+0xDC00)       & 0xFF);
		*p++ = (char)(((lo+0xDC00) >> 8) & 0xFF);
	}
	else if ((code&0xF800) == 0xD800) { /* do not allow accidental surrogate pairs (0xD800-0xDFFF) */
		return UTF8ERR_INVALID;
	}
	else {
		if ((p+2) > fence) return UTF8ERR_NO_ROOM;
		*p++ = (char)( code       & 0xFF);
		*p++ = (char)((code >> 8) & 0xFF);
	}

	*ptr = p;
	return 0;
}

int utf16le_decode(const char **ptr,const char *fence) {
	const char *p = *ptr;
	int ret,b=2;

	if (!p) return UTF8ERR_NO_ROOM;
	if ((p+1) >= fence) return UTF8ERR_NO_ROOM;

	ret = (unsigned char)p[0];
	ret |= ((unsigned int)((unsigned char)p[1])) << 8;
	if (ret >= 0xD800 && ret <= 0xDBFF)
		b=4;
	else if (ret >= 0xDC00 && ret <= 0xDFFF)
		{ p++; return UTF8ERR_INVALID; }

	if ((p+b) > fence)
		return UTF8ERR_NO_ROOM;

	p += 2;
	if (ret >= 0xD800 && ret <= 0xDBFF) {
		/* decode surrogate pair */
		int hi = ret & 0x3FF;
		int lo = (unsigned char)p[0];
		lo |= ((unsigned int)((unsigned char)p[1])) << 8;
		p += 2;
		if (lo < 0xDC00 || lo > 0xDFFF) return UTF8ERR_INVALID;
		lo &= 0x3FF;
		ret = ((hi << 10) | lo) + 0x10000;
	}

	*ptr = p;
	return ret;
}

typedef struct _printf_t {
	unsigned char				*buf,*fence;
	SIMPLE_TEXT_OUTPUT_INTERFACE		*eftop;
	va_list					va;
} _printf_t;

int _ofputs(int (*_oc)(int,_printf_t*),_printf_t *t,const char *str) {
	int uchar;
	int ret=0;

	while ((uchar=utf8_decode(&str,str+16)) > 0)
		ret += _oc((uint16_t)uchar,t);

	return ret;
}

int _printf(int (*_oc)(int,_printf_t*),_printf_t *t,const char *format,va_list va) {
	int ret = 0;
	int uchar; /* <- TODO: Eventually parse format as UTF-8 */

	while ((uchar=utf8_decode(&format,format+16)) > 0) {
		if (uchar == '%') {
			do {
				uchar = utf8_decode(&format,format+16);
				if (uchar <= 0) break;
				else if (uchar == 's') {
					const char *str = va_arg(va,const char*);
					_ofputs(_oc,t,str);
					break;
				}
				else {
					format--;
					break;
				}
			} while (1);
		}
		else {
			ret += _oc((uint16_t)uchar,t);
		}
	}

	return ret;
}

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

#define assert(x) _assert(((int)(x)) != 0,__STRING(x))

int _fprint(int c,_printf_t *t) {
	CHAR16 tmp[3]; /* large enough for UTF-16 surrogate pairs + NUL */
	int sz;

	{
		char *d = (char*)tmp;

		if (utf16le_encode(&d,(char*)tmp+sizeof(tmp),(uint32_t)c) != 0)
			return 0;

		*d = 0;
		sz = (int)(d - (char*)tmp);
	}

	t->eftop->OutputString(t->eftop,tmp);
	return sz/2;
}

int puts(const char *str) {
	_printf_t t;

	t.buf = NULL;
	t.eftop = doslib_efisys->ConOut;
	return _ofputs(_fprint,&t,str);
}

int printf(const char *format,...) {
	_printf_t t;
	va_list va;
	int ret;

	t.buf = NULL;
	t.eftop = doslib_efisys->ConOut;
	va_start(va,format);
	ret = _printf(_fprint,&t,format,va);
	va_end(va);
	return ret;
}

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
	InitializeLib(ImageHandle,SystemTable);
	doslib_init(ImageHandle,SystemTable);
	Print(L"Hello world (gnu-efi Print)\r\n");
	SystemTable->ConOut->OutputString(SystemTable->ConOut,L"Hello world (direct ConOut call)\r\n");
	puts("Hello world (puts)\r\n");
	printf("Hello world (printf) %s\r\n","Hello world string");
	return EFI_SUCCESS;
}

