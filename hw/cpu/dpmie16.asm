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

; copy down the program segment prefix of this program.
; we need this for management purposes and for our INT 22h handler.
	mov		ah,0x51
	int		21h
	mov		[_dos_dpmi_state+s_dos_dpmi_state.my_psp],bx

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
	mov		di,.back_to_real	; DI = return IP
	pop		si			; SI = return CS
	pop		dx			; DX = return SS
	pop		cx			; CX = return ES
	pop		ax			; AX = return DS
	mov		bx,sp			; BX = return SP
	call far	word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry]

.back_to_real:
	or		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x04	; set the INIT bit

; hook INT 22h (through our PSP) so that this code executes after DOS has shutdown our program.
; if the DPMI server is able to catch realmode INT 21h termination (Windows 9x/ME), then skip this step
; because it's likely the DPMI server's selectors are now invalid.
	test		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x20	; Is DPMI_SERVER_NEEDS_PROT_TERM set?
	jz		.skip_int22_hook					; skip this step if not
	push		es
	mov		es,[_dos_dpmi_state+s_dos_dpmi_state.my_psp]
	mov		ax,[es:0xA]
	mov		bx,[es:0xC]
	mov		[cs:old_int22],ax
	mov		[cs:old_int22+2],bx
	mov		word [es:0xA],int22_hook
	mov		[es:0xC],cs
	mov		[cs:saved_ds],ds
	mov		[cs:saved_sp],sp
	mov		[cs:saved_ss],ss
	pop		es
.skip_int22_hook:

	popa
	retnative

fail_entry:
	add		sp,4	; pop ss,cs
	pop		es
	pop		ds
	popa
	retnative

;=====================================================================
;void __cdecl _dos_dpmi_init_server32_enter();
;=====================================================================
;WARNING: This code assumes that you already checked there is a DPMI
;         server with a valid entry point and that you have already
;         allocated the private area
;TODO: Is there any way you can consolidate the 16- and 32- bit versions
;      together?
EXTERN_C_FUNCTION _dos_dpmi_init_server32_enter
	pusha
	push		ds
	push		es
	push		ss
	push		cs

  %ifdef DATA_IS_FAR
	mov		bx,seg _dos_dpmi_state
	mov		ds,bx
  %endif

; copy down the program segment prefix of this program.
; we need this for management purposes and for our INT 22h handler.
	mov		ah,0x51
	int		21h
	mov		[_dos_dpmi_state+s_dos_dpmi_state.my_psp],bx

	mov		ax,1		; AX=1 32-bit app
	mov		es,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_private_segment]

	call far	word [_dos_dpmi_state+s_dos_dpmi_state.entry_ip]
	jc		.fail_entry

; we're in 32-bit protected mode... well... 16-bit code & data with the B bit set.
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
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry+0],di	; SI:DDI prot-to-real entry point
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry+4],si

; jump back into real mode
	mov		edi,.back_to_real	; DI = return IP
	pop		si			; SI = return CS
	pop		dx			; DX = return SS
	pop		cx			; CX = return ES
	pop		ax			; AX = return DS
	mov		ebx,esp			; BX = return SP
	call far	dword [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry]

.back_to_real:
	or		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x14	; set the INIT bit and INIT_32BIT

; hook INT 22h (through our PSP) so that this code executes after DOS has shutdown our program.
; if the DPMI server is able to catch realmode INT 21h termination (Windows 9x/ME), then skip this step
; because it's likely the DPMI server's selectors are now invalid.
	test		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x20	; Is DPMI_SERVER_NEEDS_PROT_TERM set?
	jz		.skip_int22_hook					; skip this step if not
	push		es
	mov		es,[_dos_dpmi_state+s_dos_dpmi_state.my_psp]
	mov		ax,[es:0xA]
	mov		bx,[es:0xC]
	mov		[cs:old_int22],ax
	mov		[cs:old_int22+2],bx
	mov		word [es:0xA],int22_hook
	mov		[es:0xC],cs
	mov		[cs:saved_ds],ds
	mov		[cs:saved_sp],sp
	mov		[cs:saved_ss],ss
	pop		es
.skip_int22_hook:

	popa
	retnative

.fail_entry:
	add		sp,4	; pop ss,cs
	pop		es
	pop		ds
	popa
	retnative

;====================================
;INT 22h hook
;====================================
;This hook is necessary because most DPMI servers expect to be terminated
;from INT 21h AH=0x4C in protected mode. The program using this library
;runs primarily in real mode and will most likely terminate from real mode.
;Most DPMI servers will not catch real-mode termination, therefore we must
;catch termination and do what it takes to INT 21h AH=0x4C from protected
;mode. Symptoms of DPMI servers left hanging are not fatal but they can
;result in resource leaks, especially from within Windows as the DPMI server
;will most likely leak descriptors.
;
;NTS: We do NOT bother saving registers because DOS INT 21h docs explicitly
;state the program who EXEC'd us should expect almost all registers to be
;destroyed.
;
;NTS: I consider this a FAR cleaner solution to catching shutdown than the
;INT 21h hook technique I used in the original DOSLIB, because it uses a
;callback mechanism offered by DOS instead of hooking INT 21h which could
;get ugly if this program were to be terminated in ways OTHER than INT 21h!
old_int22:
	dd		0
saved_ds:
	dw		0
saved_sp:
	dw		0
saved_ss:
	dw		0
int22_hook:
	cli
	mov		ds,[cs:saved_ds]
	lss		sp,[cs:saved_sp]

; TODO: By this point we're executing in the context of the parent process. We got here
; because we overwrote the old copy of INT 22h that was in our PSP, which DOS has likely
; restored back into the actual INT 22h vector.

; Logically, since we represent freed memory, there is a risk that if the vector is not
; unhooked that eventually DOS overwrite this hook and sooner or later we'll crash the
; system!

; and yet, at least with MS-DOS 5.0-6.22, Windows 3.1/9x, and Windows XP, not restoring the
; prior INT 22h vector seems to have no effect. I have yet to see COMMAND.COM act erratic
; or hang even after running lots of other stuff to fill memory after running this code.
; But I'm deeply concerned this will result in a false sense that we don't have to restore
; the vector, until someday someone manages to run this under something like FreeDOS or
; MS-DOS 3.3 or 2.0 or some version of DR-DOS and BAM----eventual system crash!

; So the question is: Do we need to restore the INT 22h vector? If we do, do we write it
; back into the actual INT 22h vector, or write it back into what was once our PSP, or
; both?

; do not carry out the restore function unless we initialized the DPMI server
; (but: this hook should not have been installed unless we initialized the DPMI server!)
	test		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x04	; is the INIT bit still set?
	jz		.continue						; skip if not
	and		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],~0x04	; clear INIT bit

; we have to convince the DPMI server to exit. to do that, we must jump into
; protected mode and carry out INT 21 AH=0x4C.
; but before we do that, we have to convince DOS that we are the "current process".
; it seems that by the time execution gets to INT 22h, DOS has already changed the
; current PSP segment to that of the parent. if we instruct the DPMI to INT 21h AH=0x4C
; without doing this, both the DPMI server and the parent process will terminate
; which is harmless, annoying, and illogical.
; NTS: Apparently the DOS kernel doesn't mind terminating our process twice, which is
;      why we are able to get away with doing it this way.
	mov		bx,[_dos_dpmi_state+s_dos_dpmi_state.my_psp]
	mov		ah,0x50			; set current PSP address
	int		21h

; now, jump into protected mdoe
	mov		di,.final_r2p		; DI = return IP
	mov		si,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_cs]; SI = return CS
	mov		dx,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_ss]; DX = return SS
	mov		cx,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_es]; CX = return ES
	mov		ax,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_ds]; AX = return DS
	mov		bx,sp			; BX = return SP
	call far	word [_dos_dpmi_state+s_dos_dpmi_state.r2p_entry_ip]
.final_r2p:
; we're in protected mode where the DPMI server is paying attention, do INT 21h AH=0x4C.
; note that this routine is probably still in the PSP as the INT 22h termination handler,
; so this code will be called again. But since we cleared the INIT bit, we don't carry
; out the termination procedure twice.
	mov		ax,0x4C00
	int		21h
.continue:
	sti
	jmp far		[cs:old_int22]

 %endif
%endif

DATA_SEGMENT

%if TARGET_BITS == 16
 %ifdef TARGET_MSDOS
 %endif
%endif

