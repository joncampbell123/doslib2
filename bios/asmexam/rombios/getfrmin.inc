; COMMON INIT CODE:
; GET16M.COM
; GET64M.COM
; GET4G.COM
; GET4G_2M.COM
; GET4G_4M.COM
; GET4G_8M.COM

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

