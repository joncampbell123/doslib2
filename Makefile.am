SUBDIRS = test windows hw ext dos bios graphics autoinst efi traplog unittest
ACLOCAL_AMFLAGS = -I m4 -I m4fixed

library_includedir = $(includedir)/doslib2
library_include_HEADERS = config_public.h

testiso:
	mkisofs -o testiso.iso -J build

