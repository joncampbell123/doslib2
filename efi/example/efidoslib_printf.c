
#include <efi.h>
#include <efilib.h>
#include <stdint.h>
#include <efistdarg.h>

#include <efi/example/efidoslib_base.h>
#include <efi/example/efidoslib_utf.h>
#include <efi/example/efidoslib_printf.h>

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

