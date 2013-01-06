; do_cpuid() function

%if TARGET_BITS == 16
 %ifndef MMODE
  %error You must specify MMODE variable (memory model) for 16-bit real mode code
 %endif

; # if defined(__LARGE__) || defined(__COMPACT__) || defined(__HUGE__)

 %ifidni MMODE,l
  %define retnative retf
  %define cdecl_ofs (6+16)	; RETF + PUSHA + DS
 %else
  %ifidni MMODE,m
   %define retnative retf
   %define cdecl_ofs (6+16)	; RETF + PUSHA + DS
  %else
   %define retnative ret
   %define cdecl_ofs (4+16)	; RET + PUSHA + DS
  %endif
 %endif
 %define nsi si
 %define nbp bp
 %define nsp sp
 %define pushan pusha
 %define popan popa
%endif
%if TARGET_BITS == 32
 %define retnative ret
 %define cdecl_ofs (4+32)	; RET + PUSHA
 %define nsi esi
 %define nbp ebp
 %define nsp esp
 %define pushan pushad
 %define popan popad
%endif

%if TARGET_BITS == 16
segment _TEXT class=CODE
use16
%endif
%if TARGET_BITS == 32
section .text
use32
%endif

;=====================================================================
;=====================================================================
%ifdef TARGET_LINUX
global do_cpuid
do_cpuid:
%else
global _do_cpuid
_do_cpuid:
%endif
%if TARGET_BITS == 16
	push	ds
%endif
	pushan
	mov	nbp,nsp

	mov	eax,[nbp+cdecl_ofs]
%if TARGET_BITS == 32
	mov	esi,[nbp+cdecl_ofs+4]
%else
 %ifidni MMODE,l
	lds	si,[nbp+cdecl_ofs+4]
 %endif
 %ifidni MMODE,c
	lds	si,[nbp+cdecl_ofs+4]
 %endif
 %ifidni MMODE,h
	lds	si,[nbp+cdecl_ofs+4]
 %endif
 %ifidni MMODE,m
	mov	si,[nbp+cdecl_ofs+4]
 %endif
 %ifidni MMODE,s
	mov	si,[nbp+cdecl_ofs+4]
 %endif
%endif
	xor	ebx,ebx
	xor	ecx,ecx
	xor	edx,edx
	cpuid
	mov	[nsi],eax
	mov	[nsi+4],ebx
	mov	[nsi+8],ecx
	mov	[nsi+12],edx

	popan
%if TARGET_BITS == 16
	pop	ds
%endif
	retnative

%if TARGET_BITS == 16
segment _DATA class=DATA
use16
%endif
%if TARGET_BITS == 32
section .data
use32
%endif

%if TARGET_BITS == 16
segment _BSS class=BSS
use16
%endif
%if TARGET_BITS == 32
section .bss
use32
%endif

%if TARGET_BITS == 16
group DGROUP _DATA _BSS
%endif

