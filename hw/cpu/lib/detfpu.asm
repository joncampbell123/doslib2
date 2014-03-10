; FPU detection
%include "nasmsegs.inc"
%include "nasm1632.inc"

CODE_SEGMENT

%if TARGET_BITS == 16
 %ifdef TARGET_WINDOWS_WIN16
  extern GETWINFLAGS
 %endif
%endif

;=====================================================================
;unsigned int _cdecl _probe_basic_fpu_287_387();
;=====================================================================
; return value: 2 if 287, else 3. this function assumes you already
;               detected the CPU is a 386 and that FPU is present.
EXTERN_C_FUNCTION probe_basic_fpu_287_387
	push		nbx
	push		stackbase
	sub		stackpointer,4
	mov		stackbase,stackpointer

; test, part 1
	mov		ax,2			; assume 386+287 combo
	fstcw		word [stackbase]
	and		word [stackbase],0xFF7F
	fldcw		word [stackbase]
	fdisi
	fstcw		word [stackbase]
	fwait
	mov		bx,word [stackbase]
	and		bx,0x80
	jnz		.done

; test, part 2
	finit
	fld1
	fldz
	fdiv
	fld		st0
	fchs
	fcompp
	push		ax
	fstsw		ax
	mov		bx,ax
	pop		ax
	fwait
	and		bh,0x40
	jnz		.done		; if its zero, then a 387

	mov		al,3		; it's a 387

.done:	add		stackpointer,4
	pop		stackbase
	pop		nbx
	retnative

;=====================================================================
;unsigned int _cdecl _probe_basic_has_fpu();
;=====================================================================
; return value: whether or not the FPU is present. uses the traditional 8087
;               test. this function will not be called if CPUID is present
;               because we can then use the CPUID information to detect FPU.
EXTERN_C_FUNCTION probe_basic_has_fpu
	push		nbx
	push		stackbase
	sub		stackpointer,4
	mov		stackbase,stackpointer

 %ifdef TARGET_WINDOWS_WIN16
	call far	GETWINFLAGS		; Windows can tell us if it sees the FPU (FIXME: If it later turns out Win95 lies, remove this code)
	test		ax,0x400		; WF_80x87(0x400)
	jz		.do_tradtest		; if not set, then move on to the traditional test
	mov		ax,1
	jmp		.done
 %endif

; do the traditional test of asking the FPU to write status words
.do_tradtest:
	xor		ax,ax			; assume no FPU
	fninit
	mov		word [stackbase],0x5A5A
	fnstsw		word [stackbase]
	cmp		word [stackbase],0
	jnz		.no_fpu

	fnstcw		word [stackbase]
	mov		bx,word [stackbase]
	and		bx,0x103F
	cmp		bx,0x003F
	jnz		.no_fpu

	inc		al			; set AX=1

.no_fpu:
.done:	add		stackpointer,4
	pop		stackbase
	pop		nbx
	retnative

