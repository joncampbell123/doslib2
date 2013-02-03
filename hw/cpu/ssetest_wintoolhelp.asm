%include "nasmsegs.inc"
%include "nasm1632.inc"
%include "nasmenva.inc"
%include "dpmi.inc"

CODE_SEGMENT

%if TARGET_BITS == 16
 %ifdef TARGET_WINDOWS_WIN16
  extern __InterruptRegisterSSETEST
  extern __InterruptUnregisterSSETEST
; NOTE: This test, using TOOLHELP.DLL to catch the exception, is the
;       recommended way to carry out the test. In fact under Windows 95/98/ME
;       it is the ONLY way we can catch exceptions because Windows 9x/ME
;       appears to silently ignore DPMI exception handlers.
;
;       To keep the complexity of this assembly language down, it is the
;       C/C++ caller's responsibility to load TOOLHELP.DLL and GetProcAddress()
;       the InterruptRegister and InterruptUnRegister functions.
;=====================================================================
;unsigned int _cdecl cpu_sse_wintoolhelp_test();
;=====================================================================
EXTERN_C_FUNCTION cpu_sse_wintoolhelp_test
	mov		word [result],0x02	; CPU_SSE_ENABLED(0x02)
	pusha
	push		ds

; BOOL WINAPI InterruptRegister(HTASK, FARPROC)
	mov		si,seg __InterruptRegisterSSETEST
	mov		ds,si
	; HTASK
	push		word 0
	; FARPROC
	push		cs
	push		word our_exception_handler
	; call
	call far	[__InterruptRegisterSSETEST]

; OK, cause an exception
%ifdef TEST_EXCEPTION_HANDLER
sseins:	db		0xFF,0xFF,0xFF		; <- 3 bytes long deliberate invalid instruction
%else
sseins:	xorps		xmm0,xmm0		; <- 3 bytes long
%endif

; BOOL WINAPI InterruptUnRegister(HTASK)
	mov		si,seg __InterruptUnregisterSSETEST
	mov		ds,si
	; HTASK
	push		word 0
	; call
	call far	[__InterruptUnregisterSSETEST]

	pop		ds
	popa
	mov		ax,word [result]
	retnative

fail:	pop		ds
	popa
	xor		ax,ax
	retnative

;==============================================
;Exception handler
;==============================================
our_exception_handler:
	; look at the interrupt number on the stack.
	push		bp
	mov		bp,sp
	cmp		byte [bp+2+6],6
	jnz		.not_udexception	; if it's NOT the invalid opcode exception, then RETF and let toolhelp pass it on
	; it's an invalid opcode exception. so what we need to do is modify the instruction pointer on the stack
	add		word [bp+2+10],3	; skip 3-byte XORPS xmm,xmm instruction
	; zero the result
	push		ds
	mov		ax,seg result
	mov		ds,ax
	mov		word [result],0
	pop		ds
	; return directly to the routine
	pop		bp
	add		sp,10		; throw away TOOLHELP.DLL's additional stack
	iret				; and return
.not_udexception:
	pop		bp
	retf				; return to TOOLHELP.DLL and let it pass the exception on
 %endif
%endif

DATA_SEGMENT

%if TARGET_BITS == 16
 %ifdef TARGET_WINDOWS_WIN16
result:
	dw		0
 %endif
%endif

