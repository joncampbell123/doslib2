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
  ;
  ; NOTES: It seems in the Win16 world, the DPMI treats us as a 16-bit client even
  ;        when calling from a 32-bit code segment. It also seems Windows 3.0, 3.1,
  ;        as well as NTVDM.EXE under Windows NT, treat the get/set exception handler
  ;        functions as 16:16 pointers. And when the exception handler is triggered,
  ;        even from a 32-bit code segment, the stack frame is setup for a 16-bit
  ;        exception handler.
  ;
  ;        That's a BIG problem: If Watcom links this code to a location past 64KB,
  ;        this code will not work properly and crash the application.
  ;
  ;        The ONLY reason this code happens to work so far, is because I have yet
  ;        to trigger a scenario where we end up past 64KB-16. But when that happens
  ;        this routine is programmed to show a message box letting you know. That's
  ;        when we spring into action.
  ;
  ;        In the long run we need to transition to a routine that carries out the
  ;        test from a 16-bit code/data segment where we can reliably recover.
  ;        Or at least make the exception handler 16-bit code/data.
  %define doit
 %endif

 %ifdef doit
extern MESSAGEBOX
;=====================================================================
;unsigned int _cdecl cpu_sse_dpmi32win386_test();
;=====================================================================
EXTERN_C_FUNCTION cpu_sse_dpmi32win386_test
	mov		dword [result],0x02	; CPU_SSE_ENABLED(0x02)
	pushad

; is our code anywhere near the 64KB limit?
; for now, this code only warns you if so (for debugging).
	mov		eax,sseins
	cmp		eax,0xFFF0		; if the "sseins" label is at 64K-16 or higher
	jl		.no_64kb_limit_warning
; show a message box to warn the user or developer.
	push		byte 0			; MB_OK
	push		dword _str_danger_text
	push		dword _str_danger_caption
	push		byte 0			; NULL
	call		MESSAGEBOX
.no_64kb_limit_warning:

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
	mov		ax,0x0203
	mov		bl,6
	mov		cx,cs
	mov		dx,our_int6_exception_handler
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

	popad
	mov		eax,dword [result]
	retnative

;=============================================
;OUR INT6 EXCEPTION HANDLER
;=============================================
our_int6_exception_handler:
	int		3
; NOTE:  So here's the bizarre situation: Windows calls this 32-bit exception handler
;        with a 16-bit DPMI exception handler frame. Okay, we can deal with that.
;        The bigger issue is: What happens if sooner or later Watcom assigns this
;        symbol a 32-bit offset into the code segment that a 16-bit stack frame cannot
;        accomodate?
;
;        This also leads to the question: What is Windows DPMI server doing with our
;        exception handler address? Is it taking in the full 32 bits? Or is it taking
;        only the low 16 bits of the address and treating it like a 16:16 pointer?
;
;        Second problem: If we modify the IP return value on the stack [SP+6] to
;        direct the DPMI server to a different address, the DPMI server doesn't actually
;        return to that address. The only way to recover from this case, is to modify
;        the offending instruction.
;
;        The good news is that Watcom's win386 extender creates a 'flat' memory model
;        where code and data pointers are flat (well, from some nonzero linear memory
;        address anyway). So what we can do instead, is make use of the flat memory
;        model to overwrite the offending instruction with NOPs so that when the
;        exception handler returns program execution can proceed normally.
	mov		word [sseins],0x9090
	mov		byte [sseins+2],0x90

; clear SSE enabled, to let this test know SSE instructions don't work
	xor		dword [result],0x02	; CPU_SSE_ENABLED(0x02), clear it

; We have to 16-bit RETF
	db		0x66
	retf

; TODO: Remove this when we have a chance to recreate a scenario where the exception handler
;       is 32-bit and located past a 64KB location.
_str_danger_caption:
	db		'Danger!',0
_str_danger_text:
	db		'Danger! The SSE test subroutine sits close to or past a 64KB offset.',10
	db		'It is currently not known whether the exception handler will return',10
	db		'correctly in this case!'
	db		0

 %endif
%endif

DATA_SEGMENT

 %ifdef doit
int6_oexcept:
	dw		0,0

result:
	dd		0

counter:
	db		0
 %endif

