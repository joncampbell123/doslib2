%include "nasmsegs.inc"
%include "nasm1632.inc"
%include "nasmenva.inc"

; DEBUG: Enable this %define to replace the SSE instruction with a deliberate
;        bad opcode to ensure the exception handler works even on modern CPUs
;        that do in fact support SSE, such as using Windows XP to test this code.
%define TEST_EXCEPTION_HANDLER

CODE_SEGMENT

%if TARGET_BITS == 16
 %ifdef TARGET_WINDOWS_WIN16
  extern GETWINFLAGS
  extern GETVERSION
 %endif
; NOTE: This works from under any 16-bit DPMI server, except from within
;       Windows 95/98/ME (use TOOLHELP.DLL in that case). When targeting
;       Windows 3.0, an alternate exception handler must be used when
;       running in 286 standard mode.
;=====================================================================
;unsigned int _cdecl cpu_sse_dpmi16_test();
;=====================================================================
EXTERN_C_FUNCTION cpu_sse_dpmi16_test
	mov		word [result],0x02	; CPU_SSE_ENABLED(0x02)
	pusha
	push		ds
	mov		ax,seg int6_oexcept
	mov		ds,ax

;=====================================================================
;Save current int 6 exception handler
;=====================================================================
	mov		ax,0x0202
	mov		bl,6
	int		31h
	mov		word [int6_oexcept],dx
	mov		word [int6_oexcept+2],cx

;=====================================================================
;Set our int 6 exception handler
;=====================================================================
	mov		dx,our_int6_exception_handler		; default: DPMI 16-bit handler

 %ifdef TARGET_WINDOWS_WIN16					; Windows 3.0: 286 standard mode exception handler works differently
  %if TARGET_WINDOWS_VERSION < 31				; NTS: We do NOT test for real mode because cpusse.c will not call us in that case
	push		dx
	call far	GETVERSION				; what version of Windows is this?
	pop		dx
	xchg		al,ah					; lo byte has major, swap it
	cmp		ax,0x30A				; is this Windows 3.10 or higher?
	jae		.done1					; skip the test if so
	push		dx
	call far	GETWINFLAGS
	pop		dx
	test		ax,0x0020				; is WF_ENHANCED set?
	jnz		.done1					; if not...
	mov		dx,our_int6_exception_handler_win30_286	; use alternate handler for Win 3.0 286 standard mode
.done1:
  %endif
 %endif

	mov		ax,0x0203
	mov		bl,6
	mov		cx,cs
	int		31h

;=====================================================================
;Execute an SSE instruction
;=====================================================================
%ifdef TEST_EXCEPTION_HANDLER
sseins:	db		0xFF,0xFF,0xFF		; <- 3 bytes long deliberate invalid instruction
%else
sseins:	xorps		xmm0,xmm0		; <- 3 bytes long
%endif

;=====================================================================
;Restore old int 6 exception handler
;=====================================================================
	mov		ax,0x0203
	mov		bl,6
	mov		cx,word [int6_oexcept+2]
	mov		dx,word [int6_oexcept]
	int		31h

	pop		ds
	popa
	mov		ax,word [result]
	retnative

;=============================================
;OUR INT6 EXCEPTION HANDLER
;=============================================
our_int6_exception_handler:
	push		bp
	mov		bp,sp
	xor		word [result],0x02	; CPU_SSE_ENABLED(0x02), clear it
	add		word [bp+6+2],3		; skip XORPS xmm0,xmm0 which is 3 bytes long
	pop		bp
	retf

;=============================================
;OUR INT6 EXCEPTION HANDLER (ALT WINDOWS 3.0 STANDARD MODE)
;=============================================
 %ifdef TARGET_WINDOWS_WIN16
  %if TARGET_WINDOWS_VERSION < 31
our_int6_exception_handler_win30_286:
	push		bp
	mov		bp,sp
	xor		word [result],0x02	; CPU_SSE_ENABLED(0x02), clear it
	add		word [bp+2],3		; skip XORPS xmm0,xmm0 which is 3 bytes long
	pop		bp
	iret
  %endif
 %endif
%endif

DATA_SEGMENT

%if TARGET_BITS == 16
int6_oexcept:
	dw		0,0

result:
	dw		0
%endif

