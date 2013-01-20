%include "nasmsegs.inc"
%include "nasm1632.inc"
%include "nasmenva.inc"
%include "dpmi.inc"

CODE_SEGMENT

%if TARGET_BITS == 16
 %ifidni MMODE,l
  %define DATA_IS_FAR
 %endif
 %ifidni MMODE,c
  %define DATA_IS_FAR
 %endif
 %ifidni MMODE,h
  %define DATA_IS_FAR
 %endif

 %ifdef TARGET_MSDOS
;=====================================================================
;void __cdecl _dos_dpmi_init_server16_enter();
;=====================================================================
;WARNING: This code assumes that you already checked there is a DPMI
;         server with a valid entry point and that you have already
;         allocated the private area
EXTERN_C_FUNCTION _dos_dpmi_init_server16_enter
	pusha
	push		ds
	push		es
	push		ss
	push		cs

  %ifdef DATA_IS_FAR
	mov		bx,seg _dos_dpmi_state
	mov		ds,bx
  %endif

	xor		ax,ax		; AX=0 16-bit app
	mov		es,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_private_segment]

	call far	word [_dos_dpmi_state+s_dos_dpmi_state.entry_ip]
	jc		fail_entry

; we're in 16-bit protected mode.
; the DPMI server has created protected mode aliases of the real mode segments we entered by
; save off those segments.
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_cs],cs
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_ds],ds
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_es],es
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_ss],ss

; next, we need the raw entry points for jumping back and forth between real and protected mode
	mov		ax,0x0306
	int		31h
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.r2p_entry_ip],cx	; BX:CX real-to-prot entry point
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.r2p_entry_cs],bx
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry+0],di	; SI:DI prot-to-real entry point
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry+2],si

; jump back into real mode
	mov		di,back_to_real		; DI = return IP
	pop		si			; SI = return CS
	pop		dx			; DX = return SS
	pop		cx			; CX = return ES
	pop		ax			; AX = return DS
	mov		bx,sp			; BX = return SP
	call far	word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry]

back_to_real:
	or		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x04	; set the INIT bit
	popa
	retnative

fail_entry:
	add		sp,4	; pop ss,cs
	pop		es
	pop		ds
	popa
	retnative
 %endif
%endif

DATA_SEGMENT

%if TARGET_BITS == 16
 %ifdef TARGET_MSDOS
 %endif
%endif

