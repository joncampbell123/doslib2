; COMMON CODE:
; GET16M.COM
; GET64M.COM
; GET4G.COM
; GET4G_2M.COM
; GET4G_4M.COM
; GET4G_8M.COM

; copy 64kb
copy_64kb:	mov	ah,0x3C		; create file
		xor	cx,cx
		mov	dx,fname
		int	21h
		jc	.copy_exit
		mov	[fhandle],ax

		mov	esi,[rd_seg_whole]
		mov	cx,4		; 4 x 16KB = 64KB
.copy_loop:	push	cx
		push	esi

		cld
		cli
		push	cs
		pop	es
		mov	ecx,16384/4
		xor	ax,ax
		mov	ds,ax
		mov	edi,copy_buf
		a32 rep	movsd
		sti
		push	cs
		pop	ds

		mov	ah,0x40
		mov	bx,[fhandle]
		mov	cx,16384
		mov	dx,copy_buf
		int	21h
		cmp	ax,16384
		jnz	.copy_write_err

		pop	esi
		pop	cx
		add	esi,16384
		loop	.copy_loop

		mov	ah,0x3E
		mov	bx,[fhandle]
		int	21h

.copy_exit:
		ret
.copy_write_err:
		add	sp,4+2		; discard saved ESI+CX
		mov	ah,0x3E
		mov	bx,[fhandle]
		int	21h
		stc
		ret

; pause
pause:		mov	ah,1
		int	21h
		cmp	al,27
		jz	pausee	
		cmp	al,13
		jnz	pause
pausee:		ret

; if the current disk has insufficient room, then prompt the user
; to remove the floppy and move off the data, then re-insert the
; floppy and hit ENTER when ready.
prompt_if_no_room:
		mov	ah,0x36		; GET FREE DISK SPACE
		xor	dl,dl		; default drive
		int	21h
		cmp	ax,0xFFFF
		jnz	.ok
		stc
		ret
; AX = sectors/cluster
; BX = free clusters
; CX = bytes/sector
; DX = total clusters
.ok:		mul	bx		; DX:AX = AX * BX
		or	dx,dx		; assume DX != 0 means enough room
		jnz	.enough_room
		cmp	ax,128+2	; 128 sectors x 512 bytes = 64KB
		jge	.enough_room
; so there's not enough room. print a message saying so and wait for user to hit ENTER
		mov	ah,9
		mov	dx,full_str
		int	21h
		call	pause
		jmp	short prompt_if_no_room ; try again
.enough_room:	clc
		ret

; ensure the CPU is in flat real mode. that means switching to protected mode,
; loading segments with 4GB limits, then jumping back to real mode deliberately
; NOT reloading the segment register limits.
ensure_flatreal:cli
		mov	ax,cs
		mov	ds,ax

		sgdt	[old_gdtr]
		sidt	[old_idtr]

		; load them
		lgdt	[new_gdtr]
		lidt	[new_idtr]

		; modify JMP
		mov	ax,cs
		mov	[.pmode_exvec+1+2],ax

		; switch into pmode
		mov	eax,cr0
		or	eax,1
		mov	cr0,eax

		; jump to confirm
		jmp	0x0008:.pmode_entry
		; OK load the registers
.pmode_entry:	mov	ax,0x10
		mov	ds,ax
		mov	es,ax
		mov	fs,ax
		mov	gs,ax

		; switch off
		mov	eax,cr0
		and	eax,~1
		mov	cr0,eax

		; now jump back
.pmode_exvec:	jmp	0x0000:.pmode_exit
.pmode_exit:

		; reload segment registers. since we're in real mode the limit part is NOT updated
		mov	ax,cs
		mov	ds,ax
		mov	es,ax
		mov	fs,ax
		mov	gs,ax

		; restore them
		lgdt	[old_gdtr]
		lidt	[old_idtr]

		sti
		ret

; enable A20 by whatever means necessary
enable_a20:	mov	ax,0x2401	; enable A20 via INT 15h
		int	15h
		cmp	ah,0x86		; AH=0x86 if not supported
		jnz	.finish
; plan B: fast A20
		in	al,92h
		and	al,0xFE		; make sure we don't hit RESET
		test	al,2		; do we need to set A20?
		jnz	.no_a20_set
		or	al,2
		out	92h,al
.no_a20_set:
; plan C: traditional keyboard A20
		cli
		mov	al,0xAD		; disable keyb
		call	keyb_write_command
		call	keyb_drain
		mov	al,0xD0		; read output port
		call	keyb_write_command
		call	keyb_read_data
		or	al,2		; enable A20
		push	ax
		mov	al,0xD1		; write output port
		call	keyb_write_command
		pop	ax
		call	keyb_write_data
		mov	al,0xAE		; enable keyb
		call	keyb_write_command
		sti
; end
.finish:	clc
		ret

%include "comm8042.inc"

error_str:	db	'An error occured',13,10,'$'

vm_err_str:	db	'This program cannot run in virtual 8086 mode',13,10,'$'
needs_386_str:	db	'This program requires a 386 or higher',13,10,'$'

full_str:	db	'Remove disk and move files off on another computer, re-insert and hit ENTER',13,10,'$'
anykey_str:	db	'Press ENTER to start',13,10,'$'
copying_str:	db	'Writing... ','$'
crlf_str:	db	13,10,'$'

hexes:		db	'0123456789ABCDEF'
gdt:		dw	0x0000,0x0000,0x0000,0x0000			; NULL
		dw	0xFFFF,0x0000,0x9A00,0x008F			; CODE
		dw	0xFFFF,0x0000,0x9200,0x008F			; DATA
