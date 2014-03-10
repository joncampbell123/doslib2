%include "nasmsegs.inc"
%include "nasm1632.inc"
%include "nasmenva.inc"
%include "dpmi.inc"

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
  ;        This code works around the issue by using DPMI to create an alias of our
  ;        code segment, then changing the base to point right at the exception
  ;        handler, then passing CS:0 as the exception handler. This ensures the
  ;        exception handler is well within the first 64KB of the segment and able
  ;        to work as 32-bit code within the 16-bit world offered by Windows.
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
	mov		cx,[alias_cs]
	xor		dx,dx
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

;=====================================================================
;Free our code segment alias
;=====================================================================
	mov		ax,0x0001
	mov		bx,[alias_cs]
	int		31h

	popad
	mov		eax,dword [result]
	retnative

fail:
	popad
	xor		eax,eax
	retnative

;=============================================
;OUR INT6 EXCEPTION HANDLER
;=============================================
our_int6_exception_handler:
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

 %endif
%endif

DATA_SEGMENT

 %ifdef doit
int6_oexcept:
	dw		0,0

result:
	dd		0

alias_cs:
	dw		0
 %endif

