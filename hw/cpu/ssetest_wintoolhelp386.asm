%include "nasmsegs.inc"
%include "nasm1632.inc"
%include "nasmenva.inc"

; DEBUG: Enable this %define to replace the SSE instruction with a deliberate
;        bad opcode to ensure the exception handler works even on modern CPUs
;        that do in fact support SSE, such as using Windows XP to test this code.
%define TEST_EXCEPTION_HANDLER

CODE_SEGMENT

%if TARGET_BITS == 32
 %ifdef TARGET_WINDOWS_WIN386
__call16_wp:
	db		'wd',0		; <- NTS: don't use 'p', pass the 16:16 pointer on without translation
__call16_w:
	db		'w',0

  extern __InterruptRegisterSSETEST
  extern __InterruptUnregisterSSETEST
  extern _Call16
; WARNING: For unknown reasons, this code works perfectly, but then when the
;          host application exits, Windows 3.1 dumps itself to the DOS prompt
;          with no explanation. Debugging in DOSBox shows it happens from
;          within the protected mode version of INT 21h AH=0x4C.
;
;          Windows 95 and 98 seem to run this code perfectly fine with no ill
;          effects. Windows XP NTVDM.EXE does not have any issues with this
;          code either.

; NOTE: This test, using TOOLHELP.DLL to catch the exception, is the
;       recommended way to carry out the test. In fact under Windows 95/98/ME
;       it is the ONLY way we can catch exceptions because Windows 9x/ME
;       appears to silently ignore DPMI exception handlers.
;
;       To keep the complexity of this assembly language down, it is the
;       C/C++ caller's responsibility to load TOOLHELP.DLL and GetProcAddress()
;       the InterruptRegister and InterruptUnRegister functions.
;=====================================================================
;unsigned int _cdecl cpu_sse_wintoolhelp386_test();
;=====================================================================
EXTERN_C_FUNCTION cpu_sse_wintoolhelp386_test
	mov		word [result],0x02	; CPU_SSE_ENABLED(0x02)
	pushad
	push		ds

;=====================================================================
;Allocate a descriptor, make it a 32-bit code segment DPL=3
;=====================================================================
; NTS: We WOULD create an alias of our code segment but Windows doesn't
;      seem to make it a valid code segment...
	mov		ax,0x0000	; allocate LDT descriptor
	mov		cx,1		; only 1 please
	int		31h
	jc		fail
	mov		[alias_cs],ax

	mov		ax,0x0008	; set selector limit
	mov		bx,[alias_cs]
	xor		cx,cx
	dec		cx
	mov		dx,cx		; CX:DX = FFFF:FFFF
	int		31h

	mov		bx,cs
	mov		ax,0x0006	; get segment base address
	int		31h
	mov		esi,our_int6_exception_handler
	mov		edi,esi
	shr		esi,16
	add		dx,di		; CX:DX += SI:DI
	adc		cx,si
	mov		ax,0x0007
	mov		bx,[alias_cs]
	int		31h		; set segment base address

	mov		ax,cs		; get the CPL we're running on. we COULD assume ring 3, but 
	and		ax,3		; Windows 3.0 apparently runs Win16 apps on ring 1 and
	shl		ax,5		; we'll hard-crash Windows if we don't account for that.
	mov		bx,[alias_cs]
	mov		cx,0xC09A	; 32-bit code CPL=0 | (DPL << 5)
	or		cl,al
	mov		ax,0x0009	; set descriptor access rights
	int		31h

; Win16: BOOL WINAPI InterruptRegister(HTASK, FARPROC)
; Win386: DWORD _watcall _Call16(FARPROC, char *, ...)
	; FARPROC
	mov		ax,[alias_cs]
	shl		eax,16
	push		eax			; CS ALIAS:0000
	; HTASK
	push		dword 0
	; char *
	push		dword __call16_wp
	; FARPROC
	push		dword [__InterruptRegisterSSETEST]
	; call
	call		_Call16
	; WE clean up after the call
	add		esp,4*4

	int		3

	; our hack-fuckery with TOOLHELP.DLL seems to cause TOOLHELP.DLL
	; to swap our stack for it's stack. be prepared to put it back
	; where it belongs (YUCK). it also resolves the fact that Watcom's
	; _Call16() function uses the stack pointer directly when it's
	; parsing the param list... but it only works if ESP stays below
	; 64KB.
	mov		[saved_ss],ss
	mov		[saved_esp],esp

;=====================================================================
;Execute an SSE instruction
;=====================================================================
%ifdef TEST_EXCEPTION_HANDLER
sseins:	db		0xFF,0xFF,0xFF		; <- 3 bytes long deliberate invalid instruction
%else
sseins:	xorps		xmm0,xmm0		; <- 3 bytes long
%endif

	mov		ss,[saved_ss]
	mov		esp,[saved_esp]

	int		3

; exception handler may have changes ES. ES == DS normally.
	push		ds
	pop		es

; Win16: BOOL WINAPI InterruptUnRegister(HTASK)
; Win386: DWORD _watcall _Call16(FARPROC, char *, ...)
	; HTASK
	push		dword 0
	; char *
	push		dword __call16_w
	; FARPROC
	push		dword [__InterruptUnregisterSSETEST]
	; call
	call		_Call16
	; WE clean up after the call
	add		esp,3*4

;=====================================================================
;Free our code segment alias
;=====================================================================
	mov		ax,0x0001
	mov		bx,[alias_cs]
	int		31h

	pop		ds
	popad
	movzx		eax,word [result]
	retnative

fail:	pop		ds
	popad
	xor		eax,eax
	retnative

;==============================================
;Exception handler
;==============================================
our_int6_exception_handler:
	and		esp,0xFFFF
	; look at the interrupt number on the stack.
	cmp		byte [esp+6],6		; NTS: because TOOLHELP.DLL seems to be calling us with this value set to 0x8006
	jnz		.not_udexception	; if it's NOT the invalid opcode exception, then RETF and let toolhelp pass it on
	; overwrite the XORPS instruction with NOPs
	mov		word [sseins],0x9090
	mov		byte [sseins+2],0x90
	; zero the result
	mov		word [result],0
	; HACK: Unlike the DPMI version of this check, we cannot safely return
	;       to the 16:16 address on the stack because sooner or later the
	;       sseins address might be >= 64KB. It seems TOOLHELP.DLL is eventually
	;       able to return safely if we RETF though, but that's taken as
	;       a sign to pass the exception on. Our compromise: we RETF as if
	;       passing on the exception, but we change the value to trick TOOLHELP.DLL
	;       and other exception handlers into treating it like a harmless INT 3
	;       debug exception, which it will ignore and safely return to what
	;       is now 3 harmless NOPs.
	mov		byte [esp+6],3		; NTS: Do not change high byte. If bit 15
						;      was set leave it set so it can cleanup
						;      the stack swap.
.not_udexception:
; return to TOOLHELP.DLL and let it pass the exception on
	db		0x66
	retf
 %endif
%endif

DATA_SEGMENT

%if TARGET_BITS == 32
 %ifdef TARGET_WINDOWS_WIN386
result:
	dw		0

alias_cs:
	dw		0

saved_ss:
	dw		0

saved_esp:
	dd		0
 %endif
%endif

