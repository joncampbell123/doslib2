;--------------------------------------------------------------------------------------
; GET16286.COM
;
; Write to disk anything visible in the 0xF00000 to 0xFFFFFF area.
; The 1MB region just under the 16MB limit on the 286 processor.
; Requires a 286 or higher.
;
; This program is provided for completeness. Very likely, the data captured from
; 0xFE0000-0xFFFFFF is the same data visible at 0xE0000-0xFFFFF.
;
; DISK UTILIZATION NOTICE:
;
; This program captures 1MB of data, as 16 files 64KB each. If the program detects that
; there is insufficient disk space for the next 64KB block, it will pause and prompt
; you to hit ENTER to continue so that you have the chance to remove the floppy disk
; and move the files off on another machine to make room.
;
; Not compatible with:
; MS-DOS 1.x
; 
; Compatible with:
; MS-DOS/PC-DOS 2.0 or higher.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

init_detect:
; Autodetect and reject MS-DOS 1.x
		mov	ax,0x3000
		int	21h
		cmp	ax,0x3000	; MS-DOS 1.x does not support the call, and doesn't change AX
		jnz	.not_dos1
		ret			; quiet exit
.not_dos1:

; are we running on an 8086?
		cli
		pushf
		pop	bx
		and	bx,0x0FFF	; clear [15:12]
		push	bx
		popf
		pushf
		pop	bx
		sti
		and	bx,0xF000	; check [15:12]
		cmp	bx,0xF000	; are they all set?
		jnz	.not_8086
.is_not_386:	mov	ah,9
		mov	dx,needs_286_str
		int	21h
		ret
; it's a 286
.not_8086:
		; zero the IDT
		xor	ax,ax
		mov	[idt],ax
		mov	[idt+2],ax
		mov	[idt+4],ax
		mov	[idt+6],ax

		mov	ax,cs
		mov	bx,ax
		shl	ax,4
		shr	bx,12

		; setup GDT
		mov	word [gdt+8+2],ax		; base[15:0]
		mov	byte [gdt+8+4],bl		; base[23:16]
		mov	byte [gdt+8+7],bh		; base[31:24]

		; setup GDT
		mov	word [gdt+16+2],ax		; base[15:0]
		mov	byte [gdt+16+4],bl		; base[23:16]
		mov	byte [gdt+16+7],bh		; base[31:24]

		push	ax
		push	bx
		add	ax,gdt
		adc	bx,0
		mov	word [new_gdtr],32 - 1
		mov	word [new_gdtr+2],ax
		mov	word [new_gdtr+2+2],bx
		pop	bx
		pop	ax

		add	ax,idt
		adc	bx,0
		mov	word [new_idtr],8 - 1
		mov	word [new_idtr+2],ax
		mov	word [new_idtr+2+2],bx

; make sure A20 is on
		call	enable_a20

; print our hello message
print_hello:
		push	cs
		pop	ds
		mov	ah,9
		mov	dx,hello_str
		int	21h

; prompt
		mov	ah,9
		mov	dx,anykey_str
		int	21h
		call	pause
		cmp	al,27		; if the user hit ESC, then exit
		jnz	.did_not_hit_esc
		ret
.did_not_hit_esc:

; the user didn't CTRL+C, so get started
.again:		mov	bl,[rd_seg]
		xor	bh,bh
		and	bl,0xF
		mov	al,[hexes+bx]
		mov	[fname+3],al

		call	prompt_if_no_room
		jc	.finished

		mov	ah,9
		mov	dx,copying_str
		int	21h

		mov	ah,9
		mov	dx,fname
		int	21h

		mov	ah,9
		mov	dx,crlf_str
		int	21h

		call	copy_64kb
		jc	.error

		inc	byte [rd_seg]
		jz	.finished

		jmp	short .again

.finished:	ret

.error:		mov	ah,9
		mov	dx,error_str
		int	21h
		ret

; copy 64kb
copy_64kb:	mov	ah,0x3C		; create file
		xor	cx,cx
		mov	dx,fname
		int	21h
		jc	.copy_exit
		mov	[fhandle],ax

		xor	si,si
		mov	cx,4		; 4 x 16KB = 64KB
.copy_loop:	push	cx
		push	si

		call	ensure_flatreal

		push	cs
		pop	ds
		mov	ah,0x40
		mov	bx,[fhandle]
		mov	cx,16384
		mov	dx,copy_buf
		int	21h
		cmp	ax,16384
		jnz	.copy_write_err

		pop	si
		pop	cx
		add	si,16384
		loop	.copy_loop

		mov	ah,0x3E
		mov	bx,[fhandle]
		int	21h

.copy_exit:
		ret
.copy_write_err:
		add	sp,2+2		; discard saved SI+CX
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
		mov	ax,sp
		mov	[recovery_sp],ax		; save SP, the reset vector destroys the CPU state

		; save PIC mask
		in	al,0xA1
		mov	ah,al
		in	al,0x21
		mov	[recovery_pic],ax

		; set BIOS reset vector
		push	ds
		mov	ax,0x40
		mov	ds,ax
		mov	word [0x67],.pmode_exit
		mov	word [0x69],cs
		pop	ds

		; make sure the BIOS knows we want that path taken on reset
		mov	al,0x0F
		out	0x70,al
		mov	al,0x0A
		out	0x71,al

		; NTS: caller sets SI to the offset within the 64KB
		mov	bl,[rd_seg]
		mov	word [gdt+24+2],si		; base[15:0]
		mov	byte [gdt+24+4],bl		; base[23:16]

		sgdt	[old_gdtr]
		sidt	[old_idtr]

		; load them
		lgdt	[new_gdtr]
		lidt	[new_idtr]

		; modify JMP
		mov	ax,cs
		mov	[.pmode_exvec+1+2],ax

		; switch into pmode
		smsw	ax
		or	ax,1
		lmsw	ax

		; jump to confirm
		jmp	0x0008:.pmode_entry
		; OK load the registers and copy 16KB to our code segment
.pmode_entry:	mov	ax,0x10		; 0x10 = our data segment
		mov	es,ax
		mov	ax,0x18		; 0x18 = the segment to copy from
		mov	ds,ax
		mov	fs,ax
		mov	gs,ax

		; copy
		cld
		mov	cx,16384/2
		xor	si,si
		mov	di,copy_buf
		rep	movsw

		; switch off protected mode.
		; this will cleanly exit pmode on the 386, and crudely exit pmode
		; on the 286 by causing an invalid opcode -> double fault -> triple fault -> reset.
		xor	eax,eax
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
		mov	ss,ax

		mov	ax,[recovery_sp]
		mov	sp,ax

		; restore them
		lgdt	[old_gdtr]
		lidt	[old_idtr]

		; restore PIC mask
		mov	ax,[recovery_pic]
		out	0x21,al
		mov	al,ah
		out	0xA1,al

		; reset reset flag
		mov	al,0x0F
		out	0x70,al
		mov	al,0x00
		out	0x71,al

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

needs_286_str:	db	'This program requires a 286 or higher',13,10,'$'

full_str:	db	'Remove disk and move files off on another computer, re-insert and hit ENTER',13,10,'$'
anykey_str:	db	'Press ENTER to start',13,10,'$'
copying_str:	db	'Writing... ','$'
crlf_str:	db	13,10,'$'

hexes:		db	'0123456789ABCDEF'
gdt:		dw	0x0000,0x0000,0x0000,0x0000			; NULL
		dw	0xFFFF,0x0000,0x9A00,0x000F			; CODE
		dw	0xFFFF,0x0000,0x9200,0x000F			; DATA
		dw	0xFFFF,0x0000,0x9200,0x000F			; DATA

hello_str:	db	'This program will write the 15-16MB ROM region to disk in',13,10
		db	'64KB fragments. Disk space required: 1MB. Please read GET16M.TXT.',13,10
		db	13,10,'$'

rd_seg_whole:	db	0x00,0x00		; NTS: see what I did here? rd_seg points to rd_seg_whole+2
rd_seg:		db	0xF0
fname:		db	'PCF00000.ROM',0,'$'
		;	    ^
		;        012345678901

		segment .bss

recovery_pic:	resw	1
recovery_sp:	resw	1
idt:		resw	8			; one interrupt
old_gdtr:	resw	3
old_idtr:	resw	3
new_gdtr:	resw	3
new_idtr:	resw	3
fhandle:	resw	1
copy_buf:	resb	16384

