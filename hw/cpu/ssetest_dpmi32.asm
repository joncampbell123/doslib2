%include "nasmsegs.inc"
%include "nasm1632.inc"
%include "nasmenva.inc"

CODE_SEGMENT

%if TARGET_BITS == 32
 %ifdef TARGET_MSDOS
  %define doit
 %endif
%endif

%ifdef doit
;=====================================================================
;unsigned int _cdecl cpu_sse_dpmi32_test();
;=====================================================================
EXTERN_C_FUNCTION cpu_sse_dpmi32_test
	mov		dword [result],0x02	; CPU_SSE_ENABLED(0x02)
	pushad

;=====================================================================
;Save current int 6 exception handler
;=====================================================================
	mov		ax,0x0202
	mov		bl,6
	int		31h
	mov		dword [int6_oexcept],edx
	mov		word [int6_oexcept+4],cx

;=====================================================================
;Set our int 6 exception handler
;=====================================================================
	mov		ax,0x0203
	mov		bl,6
	mov		cx,cs
	mov		edx,our_int6_exception_handler
	int		31h

;=====================================================================
;Execute an SSE instruction
;=====================================================================
	xorps		xmm0,xmm0		; <- 3 bytes long

;=====================================================================
;Restore old int 6 exception handler
;=====================================================================
	mov		ax,0x0203
	mov		bl,6
	mov		cx,word [int6_oexcept+4]
	mov		edx,dword [int6_oexcept]
	int		31h

	popad
	mov		eax,dword [result]
	retnative

;=============================================
;OUR INT6 EXCEPTION HANDLER
;=============================================
our_int6_exception_handler:
	xor		dword [result],0x02	; CPU_SSE_ENABLED(0x02), clear it
	add		dword [esp+12],3	; skip XORPS xmm0,xmm0 which is 3 bytes long
	retf
%endif

DATA_SEGMENT

%ifdef doit
int6_oexcept:
	dd		0
	dw		0

result:
	dd		0
%endif

