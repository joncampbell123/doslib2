;--------------------------------------------------------------------------------------
; TFL8086.COM
;
; WARNING: This makes use of INT 21h AH=0x4B AL=0x01 to LOAD BUT NOT EXECUTE the program.
;          A quick test reveals DOSBox 0.74 does not support this INT 21h call 100%
;          correctly. It will initially work, but DOSBox does not maintain accounting
;          to know that the first INT 21h will come from the sub-program, so when the
;          sub-program exits, we do NOT regain control!
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

; structs

REC_8086	EQU			0x8086
REC_LENGTH	EQU			36

		struc cpu_state_record_8086
			.r_recid	resw	1		; record ID. set to REC_8086
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
		endstruc ; =36 bytes

; code

		segment .text

		push	cs
		pop	ds

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
		mov	sp,[cs:exec_pblk+0x0E]
		mov	ss,[cs:exec_pblk+0x10]

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

; most DOS programs expect the segment registers configured in a certain way (DS=ES=PSP segment)
		mov	ah,0x51		; DOS 2.x compatible get PSP segment
		int	21h
		mov	ds,bx
		mov	es,bx

		mov	word [cs:min_seg],bx		; minimum segment
		mov	word [cs:max_seg],0xA000	; maximum segment

; build IRET stack frame. I hope the DOS program doesn't rely on the stack contents at SS:SP!
		pushf					; load FLAGS into AX
		pop	ax
		or	ax,0x100			; set trap flag (TF)
		push	ax				; EFLAGS
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
		mov	bx,cs		; just in case restore it proper.
		mov	ss,bx
		mov	sp,stack_end - 2
		sti

; print str_ok_exit to show we regained control
		push	cs
		pop	ds
		mov	ah,0x09
		mov	dx,str_ok_exit
		int	21h

; flush remaining buffer
		call	flush_record

; restore INT 01 vector
		push	es
		xor	ax,ax
		mov	es,ax
		mov	ax,[cs:old_int01]
		mov	[es:(0x01*4)],ax
		mov	ax,[cs:old_int01+2]
		mov	[es:(0x01*4)+2],ax
		pop	es

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

; INT 0x01 TRAP HANDLER
on_int1_trap:	cli

		; save the stack pointer off and switch to our own stack.
		; we cannot make any assumptions about the stack we're on.
		; for all we know, the program code may rely on stack data
		; above the stack pointer as well as below. If we just "push"
		; data onto the stack we'll obliterate that data.
		mov	word [cs:intstack_save],sp
		mov	word [cs:intstack_save+2],ss
		mov	ss,word [cs:intstack_seg]
		mov	sp,intstack_end - 2

		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	bp
		push	ds
		push	es

		mov	ax,cs
		mov	ds,ax
		mov	ax,word [cs:intstack_save+2]
		mov	es,ax				; our ES = caller's SS
		mov	si,word [cs:intstack_save]	; our SI = caller's SP

		mov	ax,word [es:si+2]		; read segment from IRET frame

		mov	bp,sp				; SS:BP = pointer to saved CPU register state on stack
							;         ES,DS,BP,DI,SI,DX,CX,BX,AX = 18 bytes

		; if the trap occured below the PSP segment, or above system memory,
		; then do not log the CPU state. we are not interested in tracing
		; the DOS or the BIOS. in fact, we call into DOS to write the CPU
		; state log to disk, so NOT tracing DOS avoids reentrancy issues.
		cmp	ax,[min_seg]
		jb	.return
		cmp	ax,[max_seg]
		jae	.return

		cmp	word [record_buf_write],record_buf_size - REC_LENGTH
		jbe	.no_flush
		call	flush_record
.no_flush:

; record CPU state
		mov	bx,[record_buf_write]
		lea	di,[record_buf+bx]
		mov	word [di + cpu_state_record_8086.r_recid],REC_8086
		mov	word [di + cpu_state_record_8086.r_reclen],REC_LENGTH
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
		mov	word [di + cpu_state_record_8086.r_sp],si
		mov	ax,word [es:si]
		mov	word [di + cpu_state_record_8086.r_ip],ax
		mov	ax,word [es:si+2]
		mov	word [di + cpu_state_record_8086.r_cs],ax
		mov	ax,word [es:si+4]
		mov	word [di + cpu_state_record_8086.r_flags],ax
		mov	ax,word [intstack_save+2]		; caller's SS
		mov	word [di + cpu_state_record_8086.r_ss],ax

		push	ds
		mov	bx,word [es:si]				; BX = IP
		mov	ds,word [es:si+2]			; DS = CS
		mov	cx,[bx]					; first 4 bytes at CS:IP
		mov	dx,[bx+2]
		pop	ds
		mov	word [di + cpu_state_record_8086.r_csip_capture],cx
		mov	word [di + cpu_state_record_8086.r_csip_capture + 2],dx

; increment record
		add	word [record_buf_write],REC_LENGTH

; animate something on the VGA display to show we're still executing
		push	es
		mov	es,word [cs:vga_seg]
		inc	word [es:158]
		pop	es

.return:	pop	es
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

; write record to disk
flush_record:	cmp	word [record_buf_write],0
		jz	.exit				; nothing to write, return

		cmp	word [logfd],0
		jz	.exit				; no valid file descriptor, return

		push	ax
		push	bx
		push	cx
		push	dx
		mov	ah,0x40
		mov	bx,word [logfd]
		mov	cx,word [record_buf_write]
		mov	dx,record_buf
		int	21h
		pop	dx
		pop	cx
		pop	bx
		pop	ax

		mov	word [record_buf_write],0
.exit		ret

		segment .data

str_fail:	db	'Failed',13,10,'$'
str_ok:		db	'Exec OK. Now executing program.',13,10,'$'
str_ok_exit:	db	'Exec OK. Sub-program terminated normally.',13,10,'$'
str_need_param:	db	'Need a program to run'
crlf:		db	13,10,'$'

logfilename:	db	'TF8086.LOG',0

		segment .bss

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

min_seg:	resw	1		; minimum segment to trace
max_seg:	resw	1		; maximum segment to trace
vga_seg:	resw	1

record_buf_write:resw	1
record_buf:	resb	record_buf_size
record_buf_end	equ	$
record_buf_size equ	4096

ENDOFIMAGE:	resb	1		; this offset is used by the program to know how large it is

