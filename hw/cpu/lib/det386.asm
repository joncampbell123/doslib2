; CPU detection for 386 -> 486 -> Pentium
%include "nasmsegs.inc"
%include "nasm1632.inc"
%include "nasmenva.inc"

CODE_SEGMENT

%if TARGET_BITS == 16
 %define DOIT
%else
 %if TARGET_BITS == 32
  %define DOIT
 %endif
%endif

%ifdef DOIT
;=====================================================================
;unsigned int _cdecl _probe_basic_cpu_345_86();
;=====================================================================
; return value: 16-bit integer, lower 8 bits are 3, 4, 5 for 386, 486, Pentium.
;               upper 8 bits become cpu_flags. this code will set the bit to
;               indicate CPUID is present. This function is called assuming the
;               CPU is a 386 or higher.
;
;               Notice: We compile the code the same way regardless of 32-bit
;                       or 16-bit targets. We always use the 32-bit form of the
;                       registers even in 16-bit real mode or 16-bit protected mode.
EXTERN_C_FUNCTION probe_basic_cpu_345_86
	push		ebx
	pushfd

	mov		eax,3		; pre-decide a 386

; MS-DOS and Win16: clear interrupts. It is said that in 16-bit real/protected mode
; the 486 AC flag check can fail if an interrupt happens to occur between the
; POPFD and PUSHFD below (since the 16-bit stack frame clears the upper bits of EFLAGS).
; 32-bit environments do not affect the test, in addition to the fact that under Windows
; NT the kernel does not allow Win32 applications to use CLI/STI. Applications that try
; will fault and crash. NTVDM.EXE however allows DOS and Win16 apps to use CLI/STI.
	cli_if_allowed

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

;======================END 16/32-bit================
%endif ; /DOIT

