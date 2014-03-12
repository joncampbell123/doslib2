;--------------------------------------------------------------------------------------
; TFL8086.COM
;
; WARNING: This makes use of INT 21h AH=0x4B AL=0x01 to LOAD BUT NOT EXECUTE the program.
;          A quick test reveals DOSBox 0.74 does not support this INT 21h call 100%
;          correctly. It will initially work, but DOSBox does not maintain accounting
;          to know that the first INT 21h will come from the sub-program, so when the
;          sub-program exits, we do NOT regain control!
;
; KNOWN LIMITATIONS:
;   - MS-DOS 6.22: If the program we are tracing uses INT 21h AH=0x4B to execute another
;                  program, this code will not trace into that program, because somewhere
;                  along the way DOS manages to clear the trap flag. Example: MS-DOS's
;                  EDIT.COM uses INT 21h AH=0x4B to exec to QBASIC.EXE. This trap logging
;                  utility is only able to trace up to the point where EDIT.COM made the
;                  INT 21h call to run QBASIC.EXE.
;
;   - Everything: There's something our EXEC code is not doing right that causes DOS to
;                 crash if EXE files are involved (COM files are OK). It's not just this
;                 code, the EXEC, EXEC2 and EXECLOAD samples in dos/asmexam are crashing
;                 the same way for some reason. It seems to worsen when this program
;                 uses a larger log buffer.
;
;                 So I guess until this mystery is solved, you can't use this program
;                 reliably on EXE files (or COM files with an EXE signature).
;
; #defines usable here
;   PARANOID=1         If set, flushes buffer to disk after EVERY log entry. Use it for
;                      cases where the program crashes or hangs the system.
;
;   EVERYTHING=1       Log everything, even BIOS and DOS calls. WARNING: THIS CAN CAUSE
;                      PROBLEMS DUE TO REENTRANCY ISSUES. USE AS A LAST RESORT!
;
;   PLACEBO=1          Go through the motions but don't actually enable the trap flag
;                      or hook INT 1.
;
;   TF_INTERRUPT=1     Look for software interrupt instructions and trace into the
;                      interrupt vector.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

%ifndef CPU286
%define CPU286 0
%endif

%ifndef CPU386
%define CPU386 0
%endif

; structs
%if CPU386
REC_CPU_ID	EQU			0x8386
REC_LENGTH	EQU			118
%elif CPU286
REC_CPU_ID	EQU			0x8286
REC_LENGTH	EQU			56
%else
REC_CPU_ID	EQU			0x8086
REC_LENGTH	EQU			40
%endif

; trap LMSW
%if CPU386
 %define TF_LMSW
%elif CPU286
 %define TF_LMSW
%endif

		struc cpu_state_record_8086
%if CPU386
			.r_recid	resw	1		; record ID. set to REC_CPU_ID
			.r_reclen	resw	1		; record length
			.r_edi		resd	1
			.r_esi		resd	1
			.r_ebp		resd	1
			.r_esp		resd	1
			.r_ebx		resd	1
			.r_edx		resd	1
			.r_ecx		resd	1
			.r_eax		resd	1
			.r_eflags	resd	1
			.r_eip		resd	1
			.r_cr0		resd	1
			.r_cr2		resd	1
			.r_cr3		resd	1
			.r_cr4		resd	1
			.r_dr0		resd	1
			.r_dr1		resd	1
			.r_dr2		resd	1
			.r_dr3		resd	1
			.r_dr6		resd	1
			.r_dr7		resd	1
			.r_cs		resw	1
			.r_ss		resw	1
			.r_ds		resw	1
			.r_es		resw	1
			.r_fs		resw	1
			.r_gs		resw	1
			.r_gdtr		resw	3
			.r_idtr		resw	3
			.r_ldtr		resw	1
			.r_csip_capture	resd	1		; snapshot of the first 4 bytes at CS:IP
			.r_sssp_capture	resd	1		; snapshot of the first 4 bytes at SS:IP
%else
			.r_recid	resw	1		; record ID. set to REC_CPU_ID
			.r_reclen	resw	1		; record length
			.r_di		resw	1
			.r_si		resw	1
			.r_bp		resw	1
			.r_sp		resw	1
			.r_bx		resw	1
			.r_dx		resw	1
			.r_cx		resw	1
			.r_ax		resw	1
			.r_flags	resw	1
			.r_ip		resw	1
			.r_cs		resw	1
			.r_ss		resw	1
			.r_ds		resw	1
			.r_es		resw	1
			.r_csip_capture	resd	1		; snapshot of the first 4 bytes at CS:IP
			.r_sssp_capture	resd	1		; snapshot of the first 4 bytes at SS:IP
 %if CPU286
			.r_msw		resw	1		; machine status word
			.r_gdtr		resw	3
			.r_idtr		resw	3
			.r_ldtr		resw	1
 %endif
%endif
		endstruc
		; 8086 =40 bytes
		;  286 =42 bytes

; code

		segment .text

		push	cs
		pop	ds
		push	cs
		pop	es

		cld
		mov	di,ENDOFFILE+1
		mov	cx,ENDOFIMAGE
		sub	cx,di
		shr	cx,1
		xor	ax,ax
		rep	stosw

		mov	[intstack_seg],cs
		mov	word [vga_seg],0xB800		; TODO: Autodetect mono/color segment
		mov	word [logfd],0

; read the command line, skip leading whitespace
		mov	si,0x81
ld1:		lodsb
		cmp	al,' '
		jz	ld1
		dec	si
		mov	[exec_path],si
		mov	word [record_buf_write],0

; and then NUL-terminate the line
		mov	bl,[0x80]
		xor	bh,bh
		add	bl,0x81
		mov	byte [bx],0

; SI is still the (now ASCIIZ) string
		cmp	byte [si],0	; is it NULL-length?
		jnz	param_ok
		mov	dx,str_need_param
		call	puts
		ret			; return to DOS
param_ok:

; skip non-whitespace
ld2:		lodsb
		or	al,al
		jz	ld2e
		cmp	al,' '
		jnz	ld2
ld2e:

; ASCIIZ cut at the whitespace
		mov	byte [si-1],0

; then whitespace
ld3:		lodsb
		cmp	al,' '
		jz	ld3
		dec	si

; then copy the command line, inserting an extra space ' ' at the start to make it a valid DOS command line
		mov	di,exec_cmdtail
		mov	al,' '
		stosb
ld4:		lodsb
		stosb
		or	al,al
		jnz	ld4

; ========================================================
; DOS gives this COM image all free memory (or the largest
; block). EXEC will always fail with "insufficient memory"
; unless we reduce our COM image block down to free up memory.
; ========================================================
		mov	ah,0x4A		; AH=0x4A resize memory block
		push	cs
		pop	es		; EX=COM memory block (also, our PSP)
		mov	bx,ENDOFIMAGE+0xF
		mov	cl,4
		shr	bx,cl		; BX = (BX + this image size + 0xF) >> 4 = number of paragraphs
		int	21h

; open the log file
		mov	ah,0x3C		; AH=0x3C create file
		xor	cx,cx
		mov	dx,logfilename
		int	21h
		mov	word [logfd],ax
		jc	.creat_err
.creat_err:

; OK proceed
		cld
		xor	ax,ax
		mov	cx,12
		mov	di,exec_fcb
		rep	stosw

		mov	word [exec_pblk+0],0	; environ. segment to copy
		mov	word [exec_pblk+2],exec_cmdtail	; command tail to pass to child
		mov	word [exec_pblk+4],cs
		mov	word [exec_pblk+6],exec_fcb ; first FCB
		mov	word [exec_pblk+8],cs
		mov	word [exec_pblk+10],exec_fcb ; second FCB
		mov	word [exec_pblk+12],cs
		mov	word [exec_pblk+14],0

		push	si		; DOS is said to corrupt the TOP word of the stack
		mov	ax,0x4B01	; AH=0x4B AL=0x01 Load but don't execute
		mov	dx,[exec_path]
		mov	bx,exec_pblk
		int	21h		; do it

		cli			; DOS 2.x is said to screw up the stack pointer.
		mov	bx,cs		; just in case restore it proper.
		mov	ss,bx
		mov	sp,stack_end - 2
		sti

		jc	exec_err

; it worked. we still have control, but the program to execute is now in memory.
; not very well documented: the Terminate address in the PSP segment (the now-active
; one representing the program we EXECd) points to just after the INT 21h instruction
; above. To better handle termination, we need to redirect that down to our "on program
; exit" termination code.
		mov	ah,0x51		; DOS 2.x compatible get PSP segment
		int	21h
		mov	es,bx		; load PSP segment
		mov	word [es:0xA],on_program_exit ; tweak offset field of Terminate Address

; print str_ok to show we got it
		push	cs
		pop	ds
		mov	ah,0x09
		mov	dx,str_ok
		int	21h

; jump (IRET) to the program and let it execute using the SS:SP and CS:IP pointers given by DOS.
; NTS: Remember according to DOS accounting, we're executing in the context of the program we
;      EXEC LOADed. Everything we do right now is done in the context of that process, including
;      INT 21h termination. So at this point, to exit normally, we must either run the program
;      and let it INT 21h terminate normally, or we must INT 21h terminate on it's behalf (while
;      we're in the program's context) and then when execution returns, INT 21h AGAIN to terminate
;      ourself normally.
		cli

%ifndef PLACEBO
; save INT 01 vector and write our own into place
		push	es
		xor	ax,ax
		mov	es,ax
		mov	ax,[es:(0x01*4)]
		mov	[cs:old_int01],ax
		mov	ax,[es:(0x01*4)+2]
		mov	[cs:old_int01+2],ax
		mov	word [es:(0x01*4)],on_int1_trap
		mov	word [es:(0x01*4)+2],cs
		pop	es
%endif

; most DOS programs expect the segment registers configured in a certain way (DS=ES=PSP segment)
		mov	ah,0x51		; DOS 2.x compatible get PSP segment
		int	21h
		mov	ds,bx
		mov	es,bx

		mov	word [cs:min_seg],bx		; minimum segment
		mov	word [cs:max_seg],0xA000	; maximum segment

; build IRET stack frame. I hope the DOS program doesn't rely on the stack contents at SS:SP!
		mov	ss,[cs:exec_pblk+0x0E+2]
		mov	sp,[cs:exec_pblk+0x0E]
		pushf					; load FLAGS into AX
%ifndef PLACEBO
		pop	ax
		or	ax,0x300			; set trap flag (TF) and interrupt flag (IF)
		push	ax				; EFLAGS
%endif
		push	word [cs:exec_pblk+0x12+2]	; CS
		push	word [cs:exec_pblk+0x12]	; IP
		xor	ax,ax
		mov	bx,ax
		mov	cx,ax
		mov	dx,ax
		mov	si,ax
		mov	di,ax
		mov	bp,ax
		iret					; IRET to program (with interrupts disabled)

; execution begins here when program returns
on_program_exit:
		cli			; DOS 2.x is said to screw up the stack pointer.
		mov	byte [cs:stop_trap],1
		mov	bx,cs		; just in case restore it proper.
		mov	ss,bx
		mov	sp,stack_end - 2
		sti

%ifndef PLACEBO
; restore INT 01 vector
		push	es
		xor	ax,ax
		mov	es,ax
		mov	ax,[cs:old_int01]
		mov	[es:(0x01*4)],ax
		mov	ax,[cs:old_int01+2]
		mov	[es:(0x01*4)+2],ax
		pop	es
%endif

; print str_ok_exit to show we regained control
		push	cs
		pop	ds
		mov	ah,0x09
		mov	dx,str_ok_exit
		int	21h

; flush remaining buffer
%ifndef PLACEBO
		call	flush_record
%endif

exit:		mov	ax,4C00h
		int	21h

exec_err:	mov	ax,cs
		mov	ds,ax
		mov	ah,0x09
		mov	dx,str_fail
		int	21h
		jmp	short exit

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

%ifndef PLACEBO
; INT 0x01 TRAP HANDLER
on_int1_trap:	cli

		cmp	byte [cs:stop_trap],0
		jz	.do_trap
		iret
.do_trap:

		; save the stack pointer off and switch to our own stack.
		; we cannot make any assumptions about the stack we're on.
		; for all we know, the program code may rely on stack data
		; above the stack pointer as well as below. If we just "push"
		; data onto the stack we'll obliterate that data.
		mov	word [cs:intstack_save],sp
		mov	word [cs:intstack_save+2],ss
		mov	ss,word [cs:intstack_seg]
		mov	sp,intstack_end - 2

%if CPU386
		push	eax		; +0x20
		push	ebx		; +0x1C
		push	ecx		; +0x18
		push	edx		; +0x14
		push	esi		; +0x10
		push	edi		; +0x0C
		push	ebp		; +0x08
		push	ds		; +0x06
		push	es		; +0x04
		push	fs		; +0x02
		push	gs		; +0x00
%else
		push	ax		; +0x10
		push	bx		; +0x0E
		push	cx		; +0x0C
		push	dx		; +0x0A
		push	si		; +0x08
		push	di		; +0x06
		push	bp		; +0x04
		push	ds		; +0x02
		push	es		; +0x00
%endif

.check_again:

		mov	ax,cs
		mov	ds,ax
		mov	es,word [cs:intstack_save+2]	; our ES = caller's SS
		mov	si,word [cs:intstack_save]	; our SI = caller's SP

		mov	ax,word [es:si+2]		; read segment from IRET frame

		mov	bp,sp				; SS:BP = pointer to saved CPU register state on stack
							;         ES,DS,BP,DI,SI,DX,CX,BX,AX = 18 bytes

%ifndef EVERYTHING
		; if the trap occured below the PSP segment, or above system memory,
		; then do not log the CPU state. we are not interested in tracing
		; the DOS or the BIOS. in fact, we call into DOS to write the CPU
		; state log to disk, so NOT tracing DOS avoids reentrancy issues.
		cmp	ax,[min_seg]
		jb	.return
		cmp	ax,[max_seg]
		jae	.return
%endif

		cmp	word [record_buf_write],record_buf_size - REC_LENGTH
		jbe	.no_flush
		call	flush_record
.no_flush:

; record CPU state
		mov	bx,[record_buf_write]
		lea	di,[record_buf+bx]
		mov	word [di + cpu_state_record_8086.r_recid],REC_CPU_ID
		mov	word [di + cpu_state_record_8086.r_reclen],REC_LENGTH
%if CPU386
		mov	ax,[bp+0]
		mov	word [di + cpu_state_record_8086.r_gs],ax
		mov	ax,[bp+2]
		mov	word [di + cpu_state_record_8086.r_fs],ax
		mov	ax,[bp+4]
		mov	word [di + cpu_state_record_8086.r_es],ax
		mov	ax,[bp+6]
		mov	word [di + cpu_state_record_8086.r_ds],ax
		mov	eax,[bp+8]
		mov	dword [di + cpu_state_record_8086.r_ebp],eax
		mov	eax,[bp+12]
		mov	dword [di + cpu_state_record_8086.r_edi],eax
		mov	eax,[bp+16]
		mov	dword [di + cpu_state_record_8086.r_esi],eax
		mov	eax,[bp+20]
		mov	dword [di + cpu_state_record_8086.r_edx],eax
		mov	eax,[bp+24]
		mov	dword [di + cpu_state_record_8086.r_ecx],eax
		mov	eax,[bp+28]
		mov	dword [di + cpu_state_record_8086.r_ebx],eax
		mov	eax,[bp+32]
		mov	dword [di + cpu_state_record_8086.r_eax],eax
		movzx	esi,word [intstack_save]		; our SI = caller's SP
		add	esi,6					; minus the IRET stack frame
		mov	dword [di + cpu_state_record_8086.r_esp],esi
		sub	esi,6
		movzx	eax,word [es:si]
		mov	dword [di + cpu_state_record_8086.r_eip],eax
		mov	ax,word [es:si+2]
		mov	dword [di + cpu_state_record_8086.r_cs],eax
		pushfd
		pop	eax
		mov	ax,word [es:si+4]			; combine current EFLAGS with FLAGS saved on stack, assuming CPU does not change upper bits on trap interrupt
		mov	dword [di + cpu_state_record_8086.r_eflags],eax
		mov	ax,word [intstack_save+2]		; caller's SS
		mov	word [di + cpu_state_record_8086.r_ss],ax
		mov	eax,cr0
		mov	dword [di + cpu_state_record_8086.r_cr0],eax
		mov	eax,cr2
		mov	dword [di + cpu_state_record_8086.r_cr2],eax
		mov	eax,cr3
		mov	dword [di + cpu_state_record_8086.r_cr3],eax
		mov	eax,cr4
		mov	dword [di + cpu_state_record_8086.r_cr4],eax
		mov	eax,dr0
		mov	dword [di + cpu_state_record_8086.r_dr0],eax
		mov	eax,dr1
		mov	dword [di + cpu_state_record_8086.r_dr1],eax
		mov	eax,dr2
		mov	dword [di + cpu_state_record_8086.r_dr2],eax
		mov	eax,dr3
		mov	dword [di + cpu_state_record_8086.r_dr3],eax
		mov	eax,dr6
		mov	dword [di + cpu_state_record_8086.r_dr6],eax
		mov	eax,dr7
		mov	dword [di + cpu_state_record_8086.r_dr7],eax
		sgdt	[di + cpu_state_record_8086.r_gdtr]
		sidt	[di + cpu_state_record_8086.r_idtr]
		xor	ax,ax							; NTS: SLDT is not recognized in real mode. LDT has no meaning anyway.
		mov	word [di + cpu_state_record_8086.r_ldtr],ax		;      Someday when this code traces protected mode
										;      we will make use of this field.
%else
		mov	ax,[bp+0]
		mov	word [di + cpu_state_record_8086.r_es],ax
		mov	ax,[bp+2]
		mov	word [di + cpu_state_record_8086.r_ds],ax
		mov	ax,[bp+4]
		mov	word [di + cpu_state_record_8086.r_bp],ax
		mov	ax,[bp+6]
		mov	word [di + cpu_state_record_8086.r_di],ax
		mov	ax,[bp+8]
		mov	word [di + cpu_state_record_8086.r_si],ax
		mov	ax,[bp+10]
		mov	word [di + cpu_state_record_8086.r_dx],ax
		mov	ax,[bp+12]
		mov	word [di + cpu_state_record_8086.r_cx],ax
		mov	ax,[bp+14]
		mov	word [di + cpu_state_record_8086.r_bx],ax
		mov	ax,[bp+16]
		mov	word [di + cpu_state_record_8086.r_ax],ax
		mov	si,word [intstack_save]			; our SI = caller's SP
		add	si,6					; minus the IRET stack frame
		mov	word [di + cpu_state_record_8086.r_sp],si
		sub	si,6
		mov	ax,word [es:si]
		mov	word [di + cpu_state_record_8086.r_ip],ax
		mov	ax,word [es:si+2]
		mov	word [di + cpu_state_record_8086.r_cs],ax
		mov	ax,word [es:si+4]
		mov	word [di + cpu_state_record_8086.r_flags],ax
		mov	ax,word [intstack_save+2]		; caller's SS
		mov	word [di + cpu_state_record_8086.r_ss],ax

 %if CPU286
		smsw	ax
		mov	word [di + cpu_state_record_8086.r_msw],ax
		sgdt	[di + cpu_state_record_8086.r_gdtr]
		sidt	[di + cpu_state_record_8086.r_idtr]
		xor	ax,ax							; NTS: SLDT is not recognized in real mode. LDT has no meaning anyway.
		mov	word [di + cpu_state_record_8086.r_ldtr],ax		;      Someday when this code traces protected mode
										;      we will make use of this field.
 %endif
%endif

		push	ds
		mov	bx,word [es:si]				; BX = IP
		mov	ds,word [es:si+2]			; DS = CS
		mov	cx,[bx]					; first 4 bytes at CS:IP
		mov	dx,[bx+2]
		pop	ds
		mov	word [di + cpu_state_record_8086.r_csip_capture],cx
		mov	word [di + cpu_state_record_8086.r_csip_capture + 2],dx

		push	ds
		mov	bx,word [cs:intstack_save]		; BX = SP
		add	bx,6					; minus the IRET stack frame
		mov	ds,word [cs:intstack_save+2]		; DS = SS
		mov	cx,[bx]					; first 4 bytes at SS:SP
		mov	dx,[bx+2]
		pop	ds
		mov	word [di + cpu_state_record_8086.r_sssp_capture],cx
		mov	word [di + cpu_state_record_8086.r_sssp_capture + 2],dx

; increment record
		add	word [record_buf_write],REC_LENGTH

; animate something on the VGA display to show we're still executing
		push	es
		mov	es,word [cs:vga_seg]
		inc	word [es:158]
		pop	es

; we're going to return
.return:

%ifdef PARANOID
		call	flush_record
%endif

; but before we do, we can catch many attempts to reset the TF bit
; by setting it again on the FLAGS image of the stack. in some emulators
; and some CPUs, the CPU will issue one more TRAP interrupt following
; an instruction that clears TF (such as attempting to clear TF using POPF).
		mov	es,word [cs:intstack_save+2]	; our ES = caller's SS
		mov	si,word [cs:intstack_save]	; our SI = caller's SP
		or	word [es:si+4],0x100		; set TF in the FLAGS image on the stack

; opcode-specific hacks
		mov	bx,word [es:si]				; BX = IP
		mov	ds,word [es:si+2]			; DS = CS
		mov	ax,[bx]					; first 2 bytes at CS:IP

%ifdef TF_INTERRUPT
		cmp	al,0xCD					; INT xx    0xCD 0xxx
		jz	.op_int_xx
%endif
		cmp	ax,0x010F				; 0x0F 0x01
		jz	.op_010F
		jmp	.finish_opcode

.op_010F:	mov	al,[bx+2]				; load the 3rd byte
		and	al,(7 << 3)				; we want "reg" of mod/reg/rm
		cmp	al,(6 << 3)				; LMSW /6 ?
		jz	.op_lmsw
		jmp	.finish_opcode

.op_lmsw:	
%ifdef TF_LMSW
		call	flush_record				; any attempt to call LMSW means we must flush buffers
		call	disable_tf				; and stop tracing. this code does not yet support protected mode.
%endif
		jmp	.finish_opcode

%ifdef TF_INTERRUPT
; INT xx     0xCD 0xxx (AH=interrupt AL=0xCD)
.op_int_xx:	xor	bh,bh
		mov	bl,ah
		add	bx,bx
		add	bx,bx					; BX=offset of vector

		; load interrupt vector into DX:CX
		push	ds
		xor	ax,ax
		mov	ds,ax
		mov	cx,[bx]
		mov	dx,[bx+2]				; DX:CX = vector
		pop	ds

		; allocate 6 bytes on the stack
		sub	word [cs:intstack_save],6		; caller's SP -= 6
		mov	word [es:si-6],cx			; offset of int vector
		mov	word [es:si-4],dx			; segment of int vector
		mov	ax,word [es:si+4]			; FLAGS from caller
		mov	word [es:si-2],ax			; flags

		; move instruction pointer 2 bytes ahead to skip over INT xx
		add	word [es:si],2				; caller IP += 2

		; jump back and log CPU state again to reflect entering
		; the interrupt vector. if we don't do this, the trap log
		; will miss the first instruction of the interrupt vector.
		jmp	.check_again
%endif
.finish_opcode:

; now return
%if CPU386
		; before we return, we need to convert the 16-bit IRET stack
		; frame to a 32-bit IRETD stack frame. else, some non-Intel
		; CPUs and emulators (like DOSBox) will zero the upper 16 bits
		; of EFLAGS and lose some state.
		cli
		mov	ds,word [cs:intstack_save+2]
		mov	si,word [cs:intstack_save]

		; load 16-bit IRET frame
		movzx	eax,word [si]	; IP
		movzx	ebx,word [si+2]	; CS
		pushfd
		pop	ecx
		mov	cx,[si+4]	; EFLAGS (upper 16 bits) + host program FLAGS

		; make more space on the stack
		sub	si,6		; 6 additional bytes

		; write 32-bit IRET frame
		mov	dword [si],eax	; EIP
		mov	dword [si+4],ebx; CS
		mov	dword [si+8],ecx; EFLAGS

		; update SP
		mov	word [cs:intstack_save],si

		pop	gs
		pop	fs
		pop	es
		pop	ds
		pop	ebp
		pop	edi
		pop	esi
		pop	edx
		pop	ecx
		pop	ebx
		pop	eax

		cli
		mov	ss,word [cs:intstack_save+2]
		mov	sp,word [cs:intstack_save]
		iretd
%else
		pop	es
		pop	ds
		pop	bp
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax

		cli
		mov	ss,word [cs:intstack_save+2]
		mov	sp,word [cs:intstack_save]
		iret
%endif

; disable TF flag (assuming we're within the trap handler)
disable_tf:	mov	es,word [cs:intstack_save+2]	; our ES = caller's SS
		mov	si,word [cs:intstack_save]	; our SI = caller's SP
		and	word [es:si+4],~0x100		; clear TF in the FLAGS image on the stack
		ret

; write record to disk
flush_record:	cmp	word [record_buf_write],0
		jz	.exit				; nothing to write, return

		cmp	word [logfd],0
		jz	.exit				; no valid file descriptor, return

		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		mov	ah,0x40				; write file
		mov	bx,word [logfd]
		mov	cx,word [record_buf_write]
		mov	dx,record_buf
		int	21h

		mov	ah,0x68				; flush/commit file
		mov	bx,word [logfd]
		int	21h

		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax

		mov	word [record_buf_write],0
.exit		ret
%endif

		segment .data

str_fail:	db	'Failed',13,10,'$'
str_ok:		db	'Exec OK. Now executing program.',13,10,'$'
str_ok_exit:	db	'Exec OK. Sub-program terminated normally.',13,10,'$'
str_need_param:	db	'Need a program to run'
crlf:		db	13,10,'$'

%if CPU386
logfilename:	db	'TF386.LOG',0
%elif CPU286
logfilename:	db	'TF286.LOG',0
%else
logfilename:	db	'TF8086.LOG',0
%endif

		segment .bss

ENDOFFILE	equ	$		; this offset is where the COM file ends

logfd:		resw	1

old_int01:	resd	1

exec_path:	resw	1
stack_beg:	resb	0x400-1
stack_end:	resb	1

intstack_save:	resd	1
intstack_beg:	resb	0x400-1
intstack_end:	resb	1
intstack_seg:	resw	1

exec_fcb:	resb	24
exec_pblk:	resb	0x14

exec_cmdtail:	resb	130

stop_trap:	resb	1

min_seg:	resw	1		; minimum segment to trace
max_seg:	resw	1		; maximum segment to trace
vga_seg:	resw	1

record_buf_write:resw	1
record_buf:	resb	record_buf_size

%ifdef PARANOID
record_buf_size equ	256
%else
record_buf_size equ	32768
%endif

ENDOFIMAGE:	resb	1		; this offset is used by the program to know how large it is

