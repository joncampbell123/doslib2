%include "nasmsegs.inc"
%include "nasm1632.inc"
%include "nasmenva.inc"
%include "dpmi.inc"

CODE_SEGMENT

%if TARGET_BITS == 16
 %ifidni MMODE,l
  %define callnative call far
 %else
  %ifidni MMODE,m
   %define callnative call far
  %else
   %define callnative call
  %endif
 %endif
%endif

%if TARGET_BITS == 16
 %ifdef TARGET_MSDOS
extern _dos_dpmi_protcall16
;=====================================================================
;unsigned int _cdecl cpu_sse_vm86_dpmi16_test();
;=====================================================================
EXTERN_C_FUNCTION cpu_sse_vm86_dpmi16_test
	push		ds
	push		es

	mov		ax,seg result
	mov		ds,ax

	push		cs					; <- dos_dpmi_protcall16((void far*)test_protmode)
	push		cpu_sse_vm86_dpmi16_test_protmode
	callnative	_dos_dpmi_protcall16
	add		sp,4
	mov		ax,word [result]

	pop		es
	pop		ds
	retnative

cpu_sse_vm86_dpmi16_test_protmode:
	pusha
	push		ds
	; NTS: The protmode call puts our remapped DS in ES here
	mov		ax,es
	mov		ds,ax
	; Aaannnd for whatever weird reason we have to adjust (E)BP
	; or else on INT 3 Windows 3.1 DPMI will corrupt the stack just
	; below it for whatever fucking reason.
	mov		bp,sp
	; OK. set the result
	mov		word [result],0x02	; CPU_SSE_ENABLED(0x02)

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
	mov		dx,our_int6_exception_handler16	; default: DPMI 16-bit handler
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
; WARNING WARNING!!!
; Do NOT insert an INT 3h ANYWHERE IN THIS PART OF THE CODE.
; The Windows 3.1 kernel for whatever fucking reason will corrupt the stack on return
; from INT 3h. Unfortunately it likes to corrupt the very part of the stack containing the
; return address.
; Even weirder: NTVDM.EXE under Windows XP faithfully emulates this corruption!
	pop		ds
	popa
	retf

;=============================================
;OUR INT6 EXCEPTION HANDLER
;=============================================
our_int6_exception_handler16:
	push		bp
	mov		bp,sp
	xor		word [result],0x02	; CPU_SSE_ENABLED(0x02), clear it
	add		word [bp+6+2],3		; skip XORPS xmm0,xmm0 which is 3 bytes long
	pop		bp
	retf

int6_oexcept:
	dw		0,0

result:
	dw		0
 %endif
%endif

