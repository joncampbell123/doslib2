; CPU detection for 386 -> 486 -> Pentium
%include "nasmsegs.inc"
%include "nasm1632.inc"

CODE_SEGMENT

;=====================================================================
;unsigned int _cdecl _probe_basic_cpu_345_86();
;=====================================================================
; return value: 16-bit integer, lower 8 bits are 3, 4, 5 for 386, 486, Pentium.
;               upper 8 bits become cpu_flags. this code will set the bit to
;               indicate CPUID is present. This function is called assuming the
;               CPU is a 386 or higher.
EXTERN_C_FUNCTION probe_basic_cpu_345_86
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

