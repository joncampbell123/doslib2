%define DPMIE16_ASM

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

  %ifdef DATA_IS_FAR
	mov		bx,seg _dos_dpmi_state
	mov		ds,bx
	push		ds
  %endif

	push		es
	push		ss
	push		cs

; copy down the program segment prefix of this program.
; we need this for management purposes and for our INT 22h handler.
	mov		ah,0x51
	int		21h
	mov		[_dos_dpmi_state+s_dos_dpmi_state.my_psp],bx

	xor		ax,ax		; AX=0 16-bit app
	mov		es,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_private_segment]

	call far	word [_dos_dpmi_state+s_dos_dpmi_state.entry_ip]
	jc		fail_entry

; next, we need the raw entry points for jumping back and forth between real and protected mode
	mov		ax,0x0306
	int		31h
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.r2p_entry_ip],cx	; BX:CX real-to-prot entry point
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.r2p_entry_cs],bx
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry+0],di	; SI:DI prot-to-real entry point
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry+2],si
	mov		word [_dos_dpmi_p2r_call],_dos_dpmi_p2r_call16
	mov		word [_dos_dpmi_call16_zero_upper32],_dos_dpmi_call16_zero_upper32_none

; other common code
	call		_common_prot16_initial_entry_setup

; jump back into real mode
	mov		di,.back_to_real	; DI = return IP
	pop		si			; SI = return CS
	pop		dx			; DX = return SS
	pop		cx			; CX = return ES
	pop		ax			; AX = return DS
	mov		bx,sp			; BX = return SP
	jmp far		word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry]

.back_to_real:
	or		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x04	; set the INIT bit

; other common code: INT 22h hook
	call		_common_prot16_initial_int22_hook

  %ifdef DATA_IS_FAR
	pop		ds
  %endif

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

  %ifdef DATA_IS_FAR
	mov		bx,seg _dos_dpmi_state
	mov		ds,bx
	push		ds
  %endif

	push		es
	push		ss
	push		cs

; copy down the program segment prefix of this program.
; we need this for management purposes and for our INT 22h handler.
	mov		ah,0x51
	int		21h
	mov		[_dos_dpmi_state+s_dos_dpmi_state.my_psp],bx

	mov		ax,1		; AX=1 32-bit app
	mov		es,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_private_segment]

	call far	word [_dos_dpmi_state+s_dos_dpmi_state.entry_ip]
	jc		.fail_entry

; next, we need the raw entry points for jumping back and forth between real and protected mode
	mov		ax,0x0306
	int		31h
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.r2p_entry_ip],cx	; BX:CX real-to-prot entry point
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.r2p_entry_cs],bx
	mov		dword [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry+0],edi ; SI:EDI prot-to-real entry point
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry+4],si
	mov		word [_dos_dpmi_p2r_call],_dos_dpmi_p2r_call32
	mov		word [_dos_dpmi_call16_zero_upper32],_dos_dpmi_call16_zero_upper32_doit

; other common code
	call		_common_prot16_initial_entry_setup

; jump back into real mode
	mov		edi,.back_to_real	; DI = return IP
	pop		si			; SI = return CS
	pop		dx			; DX = return SS
	pop		cx			; CX = return ES
	pop		ax			; AX = return DS
	mov		ebx,esp			; BX = return SP
	jmp far		dword [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry]

.back_to_real:
	or		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x14	; set the INIT bit and INIT_32BIT

; other common code: INT 22h hook
	call		_common_prot16_initial_int22_hook

  %ifdef DATA_IS_FAR
	pop		ds
  %endif

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
caller_sp:
	dw		0
caller_ss:
	dw		0
int22_hook:
; NTS: We change the stack pointer to our own. But we have to restore it before
;      passing on because some programs seriously get confused otherwise
	cli

	push		ax
	push		bx
	mov		ax,[cs:caller_sp]
	mov		bx,[cs:caller_ss]
	mov		[cs:caller_sp],sp
	mov		[cs:caller_ss],ss

	lss		sp,[cs:saved_sp]

	push		ds
	push		bx
	push		ax
	mov		ds,[cs:saved_ds]

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
	or		bx,bx
	jz		.continue
	mov		ah,0x50			; set current PSP address
	int		21h

; now, jump into protected mdoe
	mov		di,.final_r2p		; DI = return IP
	mov		si,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_cs]; SI = return CS
	mov		dx,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_ss]; DX = return SS
	mov		cx,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_es]; CX = return ES
	mov		ax,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_ds]; AX = return DS
	mov		bx,sp			; BX = return SP
	jmp far		word [_dos_dpmi_state+s_dos_dpmi_state.r2p_entry_ip]
.final_r2p:
; we're in protected mode where the DPMI server is paying attention, do INT 21h AH=0x4C.
; note that this routine is probably still in the PSP as the INT 22h termination handler,
; so this code will be called again. But since we cleared the INIT bit, we don't carry
; out the termination procedure twice.
	mov		ax,0x4C00
	int		21h
.continue:
	pop		ax
	pop		bx
	pop		ds
	cli
	mov		sp,[cs:caller_sp]
	mov		ss,[cs:caller_ss]
	mov		[cs:caller_sp],ax
	mov		[cs:caller_ss],bx
	pop		bx
	pop		ax
	sti
	jmp far		[cs:old_int22]

;===================================================================
;void __cdecl dos_dpmi_protcall16(void far *proc);
;===================================================================
;WARNING: This call assumes you initialized the DPMI server.
;WARNING: This code also assumes that you will be using the same stack segment
;         when calling this code. If your stack segment changes, you are in BIG TROUBLE.
;
;      <DWORD void far *>
;      <return address>  <- SS:SP [at start]
;      <PUSHA>
;      <PUSH DS>
EXTERN_C_FUNCTION dos_dpmi_protcall16
	pusha
	push		ds

  %ifdef DATA_IS_FAR
	mov		bx,seg _dos_dpmi_state
	mov		ds,bx
  %endif

	push		ds
	push		es
	push		ss
	push		cs

	test		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x04	; is the INIT set?
	jz		.exitout						; skip if not

	test		word [_dos_dpmi_state+s_dos_dpmi_state.call_cs],0xFFFF	; if call_cs == 0 skip
	jz		.exitout

	test		word [_dos_dpmi_state+s_dos_dpmi_state.call_ds],0xFFFF	; if call_ds == 0 skip
	jz		.exitout

; jump to protected mode
	call		word [_dos_dpmi_call16_zero_upper32]			; if 32-bit server MAKE SURE the upper half of the 16-bit registers are clear
	mov		ax,word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_ds]	; AX = DS
	mov		cx,word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_es]	; CX = ES
	mov		dx,word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_ss]	; DX = SS
	mov		si,word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_cs]	; SI = CS
	mov		di,.enter_prot16					; DI = IP
; HACK!!!! It turns out the Windows DPMI kernel has a weird bug when it comes to the stack.
;          If we enter protected mode with a specific SP value, then when Windows handles
;          an interrupt it will always use that stack value EVEN IF WE LATER CHANGE THE VALUE.
;          For example if we enter protected mode with SP=0x1234, then push some values onto
;          the stack, even though OUR stack pointer becomes 0x1230 the Windows kernel
;          interrupt handler will still push it's stack values to SP=0x1234 thus corrupting
;          our data!
;
;          It's interesting to note that whatever our SP stack pointer was set to, becomes
;          the memory address used in this manner, even though BX is supposed to (by DPMI
;          standards) become the stack pointer.
;
; WORKAROUND: subtract SP by 0x100 prior to entering to allow for plenty of stack space, jump
;             to protected mode, and then immediately bump SP up by 0x100 to use the stack
;             normally. Return to real mode afterwards with no stack adjustment at all.
;
; Yuck. Ready? Do it.
	sub		sp,0x100						; SP -= 0x100
	mov		bx,sp							; BX = SP
; Now we can enter protected mode
	jmp far		word [_dos_dpmi_state+s_dos_dpmi_state.r2p_entry_ip]

; we're in protected mode
.enter_prot16:
; HACK!!! See workaround described just before the jump to protmode. Hopefully if Windows
; handles an interrupt it's stack pointer will stomp on the area 0x100 bytes below our stack
; and leave our stack data alone.
	add		sp,0x100

; OK. Set the call_cs descriptor to be a 16-bit code segment
	mov		ax,0x0009
	mov		bx,word [_dos_dpmi_state+s_dos_dpmi_state.call_cs]
	mov		cx,cs
	and		cx,3
	shl		cx,5			; bits 6:5 = our CPL
	or		cx,0x009A		; (CPL << 5) | 16-bit byte granular present code readable
	int		31h

; OK. Set the call_ds descriptor to be a 16-bit data segment
	mov		ax,0x0009
	mov		bx,word [_dos_dpmi_state+s_dos_dpmi_state.call_ds]
	mov		cx,cs
	and		cx,3
	shl		cx,5			; bits 6:5 = our CPL
	or		cx,0x0092		; (CPL << 5) | 16-bit byte granular present data writeable
	int		31h

; Set call_cs limit to 0xFFFF
	mov		ax,0x0008
	mov		bx,word [_dos_dpmi_state+s_dos_dpmi_state.call_cs]
	xor		cx,cx
	mov		dx,cx
	dec		dx			; CX:DX = 0x0000:0xFFFF
	int		31h

; Set call_cs limit to 0xFFFF
	mov		ax,0x0008
	mov		bx,word [_dos_dpmi_state+s_dos_dpmi_state.call_ds]
	xor		cx,cx
	mov		dx,cx
	dec		dx			; CX:DX = 0x0000:0xFFFF
	int		31h

; in the following code we monkey with the stack. 16-bit code cannot directly use [sp+...]
	mov		bp,sp

; Set call_cs base to the realmode code segment value on stack (given to us as the func ptr)
	mov		ax,0x0007
	mov		bx,word [_dos_dpmi_state+s_dos_dpmi_state.call_cs]
	mov		cx,[bp+26+retnative_stack_size+2] ; push cs+ds+ss+es+ds + pusha + retnative -> reach into segment value of far ptr
	mov		dx,cx
	shr		cx,12
	shl		dx,4			; CX:DX = segment << 4
	int		31h

; Set call_ds base to the realmode data segment value on stack
	mov		ax,0x0007
	mov		bx,word [_dos_dpmi_state+s_dos_dpmi_state.call_ds]
	mov		cx,[bp+8]		; first saved DS value on the stack
	mov		dx,cx
	shr		cx,12
	shl		dx,4			; CX:DX = segment << 4
	int		31h

	mov		ax,[bp+26+retnative_stack_size] ; push cs+ds+ss+es+ds + pusha + retnative -> reach into offset value of far ptr
	mov		word [_dos_dpmi_farcall+0],ax
	mov		ax,word [_dos_dpmi_state+s_dos_dpmi_state.call_cs]
	mov		word [_dos_dpmi_farcall+2],ax
	mov		es,word [_dos_dpmi_state+s_dos_dpmi_state.call_ds]

; make the FAR call
	push		ds			; save DS
	call far	word [_dos_dpmi_farcall]
	pop		ds			; restore DS

; jump back into real mode
	mov		di,.back_to_real	; DI = return IP
	pop		si			; SI = return CS
	pop		dx			; DX = return SS
	pop		cx			; CX = return ES
	pop		ax			; AX = return DS
	mov		bx,sp			; BX = return SP
	jmp		word [_dos_dpmi_p2r_call]
.back_to_real:
	pop		ds
	popa
	retnative
.exitout:
	add		sp,2			; we can't "pop cs" nor would we want to
	pop		ss
	pop		es
	pop		ds
	pop		ds
	popa
	retnative

; handy function to use correct prot-to-real call (PRIVATE)
_dos_dpmi_p2r_call:
	dw		0
_dos_dpmi_p2r_call16:
	jmp far		word [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry]
_dos_dpmi_p2r_call32:
	jmp far		dword [_dos_dpmi_state+s_dos_dpmi_state.p2r_entry]

; handy function to ensure 16-bit calls on a 32-bit server zero the upper registers
_dos_dpmi_call16_zero_upper32:
	dw		0
_dos_dpmi_call16_zero_upper32_doit:
	and		eax,0xFFFF
	and		ebx,0xFFFF
	and		ecx,0xFFFF
	and		edx,0xFFFF
	and		esi,0xFFFF
	and		edi,0xFFFF
_dos_dpmi_call16_zero_upper32_none:
	ret

; COMMON CODE (PRIVATE): Hook INT 22h if the DPMI server does not catch real-mode termination cases
_common_prot16_initial_int22_hook:
; hook INT 22h (through our PSP) so that this code executes after DOS has shutdown our program.
; if the DPMI server is able to catch realmode INT 21h termination (Windows 9x/ME), then skip this step
; because it's likely the DPMI server's selectors are now invalid.
	test		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x20	; Is DPMI_SERVER_NEEDS_PROT_TERM set?
	jz		.skip_int22_hook					; skip this step if not
	test		byte [_dos_dpmi_hooked_int22],0x01			; did we already hook?
	jnz		.skip_int22_hook					; skip if so
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
	or		byte [_dos_dpmi_hooked_int22],0x01
	pop		es
.skip_int22_hook:
	ret

; COMMON CODE (PRIVATE): Called by both 16-bit and 32-bit entry
_common_prot16_initial_entry_setup:
; we're in 16-bit protected mode.
; the DPMI server has created protected mode aliases of the real mode segments we entered by
; save off those segments.
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_cs],cs
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_ds],ds
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_es],es
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_ss],ss

; selector increment
	mov		ax,0x0003
	int		31h
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.selector_increment],ax

; two selectors for the call CS & DS
	xor		ax,ax			; AX=0x0000 allocate LDT descriptors
	mov		cx,2			; two of them please
	int		31h
	jc		.fail_alloc
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.call_cs],ax
	add		ax,word [_dos_dpmi_state+s_dos_dpmi_state.selector_increment]
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.call_ds],ax
.fail_alloc:
	ret

; test subroutine.
; note that the subroutine is always called with DS = segment/selector containing DPMI call data.
; ES is set to a translated selector of what DS was on entry.
global dos_dpmi_protcall16_test_
dos_dpmi_protcall16_test_:
	inc		byte [_dos_dpmi_protcall_test_flag]	; <- WARNING: This works because on entry DS = this data segment
	retf

;======================================================
;void __cdecl dos_dpmi_shutdown();
;======================================================
EXTERN_C_FUNCTION dos_dpmi_shutdown
	pusha
	push		ds
	push		es
  %ifdef DATA_IS_FAR
	mov		ax,seg _dos_dpmi_state
	mov		ds,ax
  %endif
	test		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],0x04	; is the INIT bit still set?
	jz		.continue						; skip if not

; FIX: This hack DOESN'T WORK in the NTVDM.EXE DOS Box provided by Windows XP.
;      In that situation the caller is stuck with whatever way the DPMI is setup and no way to change.
	mov		ax,0x3306
	xor		bx,bx
	xor		dx,dx
	int		21h
	cmp		bx,0x3205						; Windows NT returns version 5.50
	jz		.continue

; OK
	and		byte [_dos_dpmi_state+s_dos_dpmi_state.flags],~0x04	; clear INIT bit

; clear interrupts
	cli

; hook INT 21h
	xor		ax,ax
	mov		es,ax
	mov		ax,word [es:(0x21*4)+0]
	mov		bx,word [es:(0x21*4)+2]
	mov		word [cs:.old_int21+0],ax
	mov		word [cs:.old_int21+2],bx
	mov		word [es:(0x21*4)+0],.int21_hook
	mov		word [es:(0x21*4)+2],cs

; now, jump into protected mode
	call		word [_dos_dpmi_call16_zero_upper32]
	push		word [cs:saved_ds]
	push		word [cs:saved_ss]
	push		word [cs:saved_sp]
	mov		[cs:saved_ds],ds
	mov		[cs:saved_sp],sp
	mov		[cs:saved_ss],ss
	mov		di,.final_r2p		; DI = return IP
	mov		si,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_cs]; SI = return CS
	mov		dx,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_ss]; DX = return SS
	mov		cx,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_es]; CX = return ES
	mov		ax,[_dos_dpmi_state+s_dos_dpmi_state.dpmi_ds]; AX = return DS
	mov		bx,sp			; BX = return SP
	jmp far		word [_dos_dpmi_state+s_dos_dpmi_state.r2p_entry_ip]
.final_r2p:
	mov		ax,0x4C00
	int		21h
; execution will jump here when the DPMI server has called INT 21h AH=4C
.int21_exit:
	add		sp,6			; dump stack frame
; we cannot assume our data segment is intact, and we cannot assume the stack is ours
	mov		ds,[cs:saved_ds]
	lss		sp,[cs:saved_sp]
	pop		word [cs:saved_sp]
	pop		word [cs:saved_ss]
	pop		word [cs:saved_ds]
; restore INT 21h vector
	xor		ax,ax
	mov		es,ax
	mov		ax,word [cs:.old_int21+0]
	mov		bx,word [cs:.old_int21+2]
	mov		word [es:(0x21*4)+0],ax
	mov		word [es:(0x21*4)+2],bx
; if a memory block is involved then free it (assuming DPMI has not done so already)
	mov		ax,word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_private_segment]
	or		ax,ax
	jz		.no_private
	mov		es,ax
	mov		ah,0x49
	int		21h
	mov		word [_dos_dpmi_state+s_dos_dpmi_state.dpmi_private_segment],0
.no_private:
; zero the DPMI information struct. The reason we do this is that most DPMI servers like
; CWSDPMI.EXE are programmed to unload themselves from memory when a DPMI client terminates.
; We can't assume the DPMI server will be there again, doing this forces the support code
; to probe for DPMI again.
	cld
	xor		ax,ax
	mov		cx,38/2		; zero all (FIXME: hardcoded)
	mov		es,[cs:saved_ds]
	mov		di,_dos_dpmi_state
	rep		stosb
; enable interrupts
	sti
; now return
.continue:
	pop		es
	pop		ds
	popa
	retnative
.old_int21:
	dw		0,0
.int21_hook:
	cmp		ah,0x4C
	jz		.int21_exit
	cmp		ah,0x00
	jz		.int21_exit
	jmp far		[cs:.old_int21]

segment _DATA class=DATA

global _dos_dpmi_hooked_int22
_dos_dpmi_hooked_int22:
	db		0

global _dos_dpmi_protcall_test_flag
_dos_dpmi_protcall_test_flag:
	db		0

_dos_dpmi_farcall:
	dw		0,0,0

global _dos_dpmi_state
_dos_dpmi_state:
	db		0	;    0 flags
	dw		0,0	;    1 IP, CS
	dw		0	;    5 dpmi_private_size
	dw		0	;    7 dpmi_version
	db		0	;    9 dpmi_cpu
	dw		0	;   10 dpmi_private_segment
	dw		0	;   12 dpmi_cs
	dw		0	;   14 dpmi_ds
	dw		0	;   16 dpmi_es
	dw		0	;   18 dpmi_ss
	dw		0,0	;   20 real-to-prot entry
	dw		0,0,0	;   24 prot-to-real entry
	dw		0	;   30 program segment prefix
	dw		0	;   32 selector increment
	dw		0	;   34 call_cs
	dw		0	;   36 call_ds
				;  =38 total

 %endif
%endif

