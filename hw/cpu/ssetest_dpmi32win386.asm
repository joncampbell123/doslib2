%include "nasmsegs.inc"
%include "nasm1632.inc"
%include "nasmenva.inc"

; DEBUG: Enable this %define to replace the SSE instruction with a deliberate
;        bad opcode to ensure the exception handler works even on modern CPUs
;        that do in fact support SSE, such as using Windows XP to test this code.
;%define TEST_EXCEPTION_HANDLER

CODE_SEGMENT

%if TARGET_BITS == 32
 %ifdef TARGET_WINDOWS_WIN386
  ; REMINDER: This test uses DPMI exception handlers. It is intended primarily for
  ;           Windows 3.0/3.1 or from within NTVDM.EXE under Windows NT/2000/XP/etc.
  ;           This test will NOT work under Windows 95/98/ME because they ignore
  ;           DPMI exception handlers.
  %define doit
 %endif

; TODO: This is very important: This is 32-bit code and sooner or later Watcom's
;       linker will place this code at or beyond 64KB. This code needs to check for
;       that scenario and refuse to carry out the test if that is the case (or
;       in future revisions: jmp to an alternate test routine that creates or uses
;       16-bit code/data segments to do the same test).
 %ifdef doit
;=====================================================================
;unsigned int _cdecl cpu_sse_dpmi32win386_test();
;=====================================================================
EXTERN_C_FUNCTION cpu_sse_dpmi32win386_test
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
; NOTE:  So here's the bizarre situation: Windows calls this 32-bit exception handler
;        with a 16-bit DPMI exception handler frame. Okay, we can deal with that.
;        The bigger issue is: What happens if sooner or later Watcom assigns this
;        symbol a 32-bit offset into the code segment that a 16-bit stack frame cannot
;        accomodate? Does that happen, or does Watcom silently segment the code into
;        64KB chunks to prevent that?
;
;        Second problem: If we modify the IP return value on the stack [SP+6] to
;        direct the DPMI server to a different address, the DPMI server doesn't actually
;        return to that address. The only way to recover from this case, is to modify
;        the offending instruction.
;
;        Well, so far it seems, Watcom's flat memory model matches code and data into
;        one flat memory address. So what we can do it seems, is just use the code
;        address directly and write over it through the data segment.
;
;        So we do the same thing we did with the Linux SIGILL signal handler: we can't
;        force the kernel to return to a different address so we overwrite the XORPS
;        instruction with 3 NOPs.
	mov		word [sseins],0x9090
	mov		byte [sseins+2],0x90

; clear SSE enabled, to let this test know SSE instructions don't work
	xor		dword [result],0x02	; CPU_SSE_ENABLED(0x02), clear it

; We have to 16-bit RETF
	db		0x66
	retf
 %endif
%endif

DATA_SEGMENT

int6_oexcept:
	dd		0
	dw		0

result:
	dd		0

counter:
	db		0

cs_ds_alias:
	dw		0

