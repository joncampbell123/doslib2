;--------------------------------------------------------------------------------------
; GET16M.COM
;
; Write to disk anything visible in the 0xF00000 to 0xFFFFFF area.
; The 1MB region just under the 16MB limit on old 386SX systems.
; Requires a 386 or higher.
;
; This program is provided for completeness. In reality because of aliasing through
; 24-bit addressing the same data can be obtained using GET4G.COM (reading the last 1MB
; just under the 4GB limit).
;
; Note that on most early 386SX systems the BIOS data visible at 0xF00000-0xFFFFFF is
; the same ROM data visible at 0xE0000-0xFFFFF anyway. You might use this program just
; to be sure that the entire ROM is captured.
;
; On newer systems this program will likely end up grabbing system memory, or whatever
; newer PCI chipsets see through the ISA hole if enabled.
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
		mov	dx,needs_386_str
		int	21h
		ret
; is it a 286?
.not_8086:	smsw	bx		; assume SMSW is valid
		test	bx,1		; is protected mode active?
		jz	.not_386_vm
		mov	ah,9
		mov	dx,vm_err_str
		int	21h
		ret
.not_386_vm:	cli
		pushf
		pop	bx
		or	bx,0xF000	; set [15:12]
		push	bx
		popf
		pushf
		pop	bx
		and	bx,0xF000	; are bits [15:12] zero?
		jz	.is_not_386
; it's a 386

		; zero the IDT
		xor	eax,eax
		mov	[idt],eax
		mov	[idt+4],eax

		xor	eax,eax
		mov	ax,cs
		shl	eax,4

		; setup GDT
		mov	word [gdt+8+2],ax		; base[15:0]
		ror	eax,16
		mov	byte [gdt+8+4],al		; base[23:16]
		mov	byte [gdt+8+7],ah		; base[31:24]

		; setup GDT
		mov	word [gdt+16+2],ax		; base[15:0]
		ror	eax,16
		mov	byte [gdt+16+4],al		; base[23:16]
		mov	byte [gdt+16+7],ah		; base[31:24]

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

		call	ensure_access
		jc	.error

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

; the purpose of this function is to ensure the CPU is in Flat Real mode and that A20 is enabled
ensure_access:	call	enable_a20
		call	ensure_flatreal
		ret

; ensure the CPU is in flat real mode. that means switching to protected mode,
; loading segments with 4GB limits, then jumping back to real mode deliberately
; NOT reloading the segment register limits.
ensure_flatreal:cli
		mov	ax,cs
		mov	ds,ax

		sgdt	[old_gdtr]
		sidt	[old_idtr]

		xor	eax,eax
		mov	ax,cs
		shl	eax,4
		add	eax,gdt
		mov	word [new_gdtr],24 - 1
		mov	dword [new_gdtr+2],eax

		xor	eax,eax
		mov	ax,cs
		shl	eax,4
		add	eax,idt
		mov	word [new_idtr],8 - 1
		mov	dword [new_idtr+2],eax

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
; end
.finish:	clc
		ret

error_str:	db	'An error occured',13,10,'$'

vm_err_str:	db	'This program cannot run in virtual 8086 mode',13,10,'$'
needs_386_str:	db	'This program requires a 386 or higher',13,10,'$'

hello_str:	db	'This program will write the 15-16MB ROM region to disk in',13,10
		db	'64KB fragments. Disk space required: 1MB. Please read GET16M.TXT.',13,10
		db	13,10,'$'

full_str:	db	'Remove disk and move files off on another computer, re-insert and hit ENTER',13,10,'$'
anykey_str:	db	'Press ENTER to start',13,10,'$'
copying_str:	db	'Writing... ','$'
crlf_str:	db	13,10,'$'

rd_seg_whole:	db	0x00,0x00		; NTS: see what I did here? rd_seg points to rd_seg_whole+2
rd_seg:		db	0xF0,0x00
hexes:		db	'0123456789ABCDEF'
fname:		db	'PCF00000.ROM',0,'$'
		;	    ^
		;        012345678901

gdt:		dw	0x0000,0x0000,0x0000,0x0000			; NULL
		dw	0xFFFF,0x0000,0x9A00,0x008F			; CODE
		dw	0xFFFF,0x0000,0x9200,0x008F			; DATA

		segment .bss

idt:		resw	8			; one interrupt
old_gdtr:	resw	3
old_idtr:	resw	3
new_gdtr:	resw	3
new_idtr:	resw	3
fhandle:	resw	1
copy_buf:	resb	16384

