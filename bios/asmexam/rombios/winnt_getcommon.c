/* common capture code. do NOT compile as standalone! */

#include <windows.h>
#include <unistd.h>
//#include <stdlib.h>
//#include <string.h>
//#include <stddef.h>
//#include <limits.h>
//#include <errno.h>
#include <stdio.h>
#include <fcntl.h>

/* FIXME: Someone tell the Open Watcom devs their NT DDK headers are fucked up
 *        in that they redefine basically the same value but in a different enough
 *        way to throw compiler errors */
#define OBJ_INHERIT 2L
#define OBJ_PERMANENT 16L
#define OBJ_EXCLUSIVE 32L
#define OBJ_CASE_INSENSITIVE 64L
#define OBJ_OPENIF 128L
#define OBJ_OPENLINK 256L
#define OBJ_VALID_ATTRIBUTES 498L

#define NT_SUCCESS( x )     (((NTSTATUS)(x)) >= 0)

#define InitializeObjectAttributes(p,n,a,r,s) { \
  (p)->Length = sizeof(OBJECT_ATTRIBUTES); \
  (p)->RootDirectory = (r); \
  (p)->Attributes = (a); \
  (p)->ObjectName = (n); \
  (p)->SecurityDescriptor = (s); \
  (p)->SecurityQualityOfService = NULL; \
}

typedef enum _SECTION_INHERIT {
  ViewShare = 1,
  ViewUnmap = 2
} SECTION_INHERIT;

typedef struct _UNICODE_STRING {
	USHORT  Length;
	USHORT  MaximumLength;
	PWSTR   Buffer;
} UNICODE_STRING;
typedef UNICODE_STRING  *PUNICODE_STRING;

typedef struct _OBJECT_ATTRIBUTES {
  ULONG Length;
  HANDLE RootDirectory;
  PUNICODE_STRING ObjectName;
  ULONG Attributes;                      
  PVOID SecurityDescriptor;              
  PVOID SecurityQualityOfService;
} OBJECT_ATTRIBUTES, *POBJECT_ATTRIBUTES;

NTSTATUS __stdcall ZwOpenSection(
  /*OUT*/ PHANDLE  SectionHandle,
  /*IN*/ ACCESS_MASK  DesiredAccess,
  /*IN*/ POBJECT_ATTRIBUTES  ObjectAttributes);

NTSTATUS __stdcall ZwUnmapViewOfSection(
  /*IN*/ HANDLE  ProcessHandle,
  /*IN*/ PVOID  BaseAddress);

NTSTATUS __stdcall ZwMapViewOfSection(
  /*IN*/ HANDLE  SectionHandle,
  /*IN*/ HANDLE  ProcessHandle,
  /*IN OUT*/ PVOID  *BaseAddress,
  /*IN*/ ULONG  ZeroBits,
  /*IN*/ ULONG  CommitSize,
  /*IN OUT*/ PLARGE_INTEGER  SectionOffset  /*OPTIONAL*/,
  /*IN OUT*/ PSIZE_T  ViewSize,
  /*IN*/ SECTION_INHERIT  InheritDisposition,
  /*IN*/ ULONG  AllocationType,
  /*IN*/ ULONG  Protect);


NTSYSAPI VOID NTAPI RtlInitUnicodeString( PUNICODE_STRING, PCWSTR );
/* END FIXME */

static HANDLE mem_fd = INVALID_HANDLE_VALUE;
static unsigned char *ROM;

/* we really only care about whether at least 64KB is available.
 * if more than 4GB is present then clamp return value to 4GB */
static size_t freespace() {
	/* TODO */
	return ~((size_t)0);
}

static void waitforenter() {
	int c;

	do {
		c=fgetc(stdin);
		if (c < 0) return;
	} while (!(c == 13 || c == 10));
}

static int OpenPhysMem() {
	NTSTATUS status;
	UNICODE_STRING name;
	OBJECT_ATTRIBUTES attr;

	RtlInitUnicodeString(&name,L"\\device\\physicalmemory");
	InitializeObjectAttributes(&attr,&name,OBJ_CASE_INSENSITIVE,NULL,NULL);
	status = ZwOpenSection(&mem_fd,SECTION_MAP_READ,&attr);

	if (!NT_SUCCESS(status))
		return 1;

	return 0;
}

static void ClosePhysMem() {
	if (mem_fd != INVALID_HANDLE_VALUE) {
		CloseHandle(mem_fd);
		mem_fd = INVALID_HANDLE_VALUE;
	}
}

int main() {
	unsigned long long segmnt;
	LARGE_INTEGER viewbase;
	size_t vaddress,maplen;
	WCHAR ppath[PATH_MAX];
	NTSTATUS status;
	char tmp[64];
	int fd;

	if (OpenPhysMem()) {
		fprintf(stderr,"Unable to open physical memory device\n");
		return 1;
	}

	memset(&viewbase,0,sizeof(viewbase));
	viewbase.QuadPart = (ULONGLONG)ROM_offset;
	maplen = ROM_size-1;
	vaddress = 0;

	status = ZwMapViewOfSection(mem_fd,(HANDLE)-1,(PVOID*)(&vaddress),0UL,
		ROM_size-1,&viewbase,(PDWORD)(&maplen),ViewShare,0,PAGE_READONLY);
	if (!NT_SUCCESS(status)) {
		fprintf(stderr,"Failed to map view of section for %08llx status=0x%08lx\n",viewbase.QuadPart,(unsigned long)status);
		return 1;
	}
	ROM = (unsigned char*)((size_t)vaddress);

#if 1/*DEBUG*/
	fprintf(stderr,"Mapped 0x%08llx + 0x%08llX => VMA 0x%08llX + 0x%08llX\n",
		(unsigned long long)ROM_offset,
		(unsigned long long)ROM_size,
		(unsigned long long)vaddress,
		(unsigned long long)maplen);
#endif

	printf(HELLO);
	printf("Press ENTER to start\n");
	waitforenter();

	/* write it out */
	for (segmnt=ROM_offset;segmnt < (ROM_offset+(unsigned long long)ROM_size);segmnt += (unsigned long long)ROM_blocksize) {
		while (freespace() < (66UL << 10UL)) {
			if (GetCurrentDirectoryW(sizeof(ppath),ppath) == 0) {
				fprintf(stderr,"Unable to get current directory\n");
				return 1;
			}

			/* Linux counts the mountpoint as being in use if a file is open there or
			 * a program has it as it's current working directory. so to allow the user
			 * to remove the floppy (or whatever) we have to change our working directory */
			if (SetCurrentDirectoryW(L"C:\\"/*FIXME*/) == 0) {
				fprintf(stderr,"Unable to bail out to root\n");
				return 1;
			}

			printf("Unmount and remove disk, move files off on another computer,\n");
			printf("re-mount and re-insert and hit ENTER\n");
			waitforenter();

			/* assuming the user has reloaded the disk/flash drive/whatever and remounted
			 * at the same point, jump back into the directory and try to resume our work */
			if (SetCurrentDirectoryW(ppath) == 0) {
				fprintf(stderr,"Unable to reenter capture dir\n");
				return 1;
			}
		}

		sprintf(tmp,CAPTURE_SPRINTF,segmnt);
		printf("Writing ... %s\n",tmp);
		fd = open(tmp,O_WRONLY|O_CREAT|O_TRUNC|O_BINARY,0644);
		if (fd < 0) {
			fprintf(stderr,"Unable to open file, %s\n",strerror(errno));
			return 1;
		}
		if ((size_t)write(fd,ROM+segmnt-ROM_offset,ROM_blocksize) != ROM_blocksize) {
			fprintf(stderr,"Unable to write ROM block\n");
			return 1;
		}
		close(fd);
	}

	ZwUnmapViewOfSection((HANDLE)-1,(PVOID)vaddress);
	ClosePhysMem();
	return 0;
}

