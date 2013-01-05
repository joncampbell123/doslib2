; CPU detection for 386 -> 486 -> Pentium

%if TARGET_BITS == 16
 %ifndef MMODE
  %error You must specify MMODE variable (memory model) for 16-bit real mode code
 %endif

 %ifidni MMODE,l
  %define retnative retf
 %else
  %ifidni MMODE,m
   %define retnative retf
  %else
   %define retnative ret
  %endif
 %endif
%endif
%if TARGET_BITS == 32
 %define retnative ret
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
;unsigned int _cdecl _probe_basic_cpu_345_86();
;=====================================================================
; return value: 16-bit integer, lower 8 bits are 3, 4, 5 for 386, 486, Pentium.
;               upper 8 bits become cpu_flags. this code will set the bit to
;               indicate CPUID is present. This function is called assuming the
;               CPU is a 386 or higher.
%ifdef TARGET_LINUX
global probe_basic_cpu_345_86
probe_basic_cpu_345_86:
%else
global _probe_basic_cpu_345_86
_probe_basic_cpu_345_86:
%endif
	push		ebx
	pushfd

	mov		eax,3		; pre-decide a 386

; do NOT clear interrupts unless a MS-DOS program or Win16 program
%ifdef TARGET_WINDOWS_WIN16
	cli
%endif
%ifdef TARGET_MSDOS
	cli
%endif

;=========================The 386 will NOT allow toggling the AC bit==================
	pushfd				; EFLAGS -> EBX
	pop		ebx

	or		ebx,0x40000	; set AC bit

	push		ebx		; EBX -> EFLAGS
	popfd
	pushfd				; EFLAGS -> EBX
	pop		ebx

	test		ebx,0x40000	; if the AC bit was cleared, then this is a 386
	jz		.done

	mov		al,4		; so then this is a 486

;===========================Toggle the ID bit to detect CPUID=========================
	pushfd				; EFLAGS -> EBX
	pop		ebx

	or		ebx,0x200000	; set ID bit

	push		ebx		; EBX -> EFLAGS
	popfd
	pushfd				; EFLAGS -> EBX
	pop		ebx

	test		ebx,0x200000	; if ID was cleared, then CPUID not present
	jz		.done

	and		ebx,~0x200000	; clear ID bit

	push		ebx		; EBX -> EFLAGS
	popfd
	pushfd				; EFLAGS -> EBX
	pop		ebx

	test		ebx,0x200000	; if ID was set, then CPUID not present
	jnz		.done

	or		ah,0x08		; set CPU_FLAG_CPUID(0x08)

.done:	popfd
	pop		ebx
	retnative

%if TARGET_BITS == 16
segment _DATA class=DATA
%endif
%if TARGET_BITS == 32
section .data
%endif

%if TARGET_BITS == 16
segment _BSS class=BSS
%endif
%if TARGET_BITS == 32
section .bss
%endif

%if TARGET_BITS == 16
group DGROUP _DATA _BSS
%endif

