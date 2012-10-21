;--------------------------------------------------------------------------------------
; DPMI32_0.COM
;
; Proof of concept entering DPMI 32-bit protected mode. Prints DPMI server info once
; in protected mode.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ax,0x1687	; AX=0x1687 get DPMI real-to-prot entry point
		int	2fh
		or	ax,ax
		jz	dpmi_ok

		mov	dx,str_need_dpmi
		jmp	common_str_error

; DPMI server is present. print server info
dpmi_ok:	mov	[dpmi_required_para],si
		mov	word [dpmi_alloc_para],0
		mov	[dpmi_entry],di
		mov	[dpmi_entry+2],es
		mov	[dpmi_support],bx

		push	si		; save SI for later
		push	dx		; save DX for later
;      ------------- 32-bit supported?
		push	cx
		mov	dx,str_32bit_supported
		call	common_str_print
		mov	dx,str_no
		test	bx,1
		jz	.no32
		mov	dx,str_yes
.no32:		call	common_str_print_crlf
		pop	cx
;      ------------- Processor type
		push	cx
		mov	dx,str_processor_type
		call	common_str_print
		pop	cx
		mov	al,cl
		xor	ah,ah
		call	putdec16
		mov	ax,86
		call	putdec16
		mov	dx,crlf
		call	common_str_print
;      ------------- DPMI server version
		mov	dx,str_dpmi_version
		call	common_str_print
		pop	dx		; OK we need DX back (see dpmi_ok)
		mov	al,dh
		xor	ah,ah
		call	putdec16
		mov	al,'.'
		call	putc
		mov	al,dl
		call	putdec16
		mov	dx,crlf
		call	common_str_print
;      ------------- DPMI required memory
		mov	dx,str_required_para
		call	common_str_print
		pop	si		; OK we need SI back (see dpmi_ok)
		mov	ax,si
		call	putdec16
		mov	dx,crlf
		call	common_str_print
;      ------------- DPMI entry point
		mov	dx,str_entry_point
		call	common_str_print
		mov	ax,[dpmi_entry+2]
		call	puthex16
		mov	al,':'
		call	putc
		mov	ax,[dpmi_entry]
		call	puthex16
		mov	dx,crlf
		call	common_str_print
;      ------------- Our real mode segment value
		mov	dx,str_real_cs
		call	common_str_print
		mov	ax,cs
		call	puthex16
		mov	dx,crlf
		call	common_str_print

; the DPMI server MUST support 32-bit mode.
		test	byte [dpmi_support],1
		jnz	dpmi32_ok

		mov	dx,str_dpmi_32_req
		jmp	common_str_error

dpmi32_ok:
; OK, now we need to realloc the COM segment down to only what we need, so that
; we can then allocate memory
		mov	ah,0x4A		; AH=0x4A resize memory block
		lea	bx,[END_OF_IMAGE+15]
		shr	bx,4		; NTS: 16-bit protected mode needs at least a 286, so we can use SHR xxx,<imm> forms we normally can't on an 8086
		push	cs
		pop	es		; ES=segment to resize (our code segment)
		int	21h
		jnc	realloc_ok

		mov	dx,str_cant_realloc_cs
		jmp	common_str_error

; we shrunk our code segment down, now allocate memory for DPMI if needed
realloc_ok:	mov	bx,[dpmi_required_para]
		or	bx,bx
		jz	dpmi_alloc_ok	; skip this step if DPMI does not need to alloc memory

		mov	ah,0x48		; AH=0x48 allocate memory block
					; BX=number of paragraphs
		int	21h
		jnc	dpmi_alloc_ok

		mov	dx,str_cant_alloc_dpmi
		jmp	common_str_error

; DPMI allocation OK or didn't need to. At this point, it's time to enter DPMI protected mode
dpmi_alloc_ok:	mov	[dpmi_alloc_para],ax ; store allocated segment
		mov	es,ax		; and move to ES

;      ------------- Our real mode dpmi segment
		push	es
		mov	dx,str_real_dpmiseg
		call	common_str_print
		mov	ax,[dpmi_alloc_para]
		call	puthex16
		mov	dx,crlf
		call	common_str_print
		pop	es

		mov	ax,0x0001	; bit 0 set: 32-bit application
					; ES=DPMI segment
		call	far [dpmi_entry]; GO!
		jnc	dpmi_prot16_ok

		mov	dx,str_cant_enter_prot
		jmp	common_str_error

; DPMI 16-bit protected mode entry worked, we are now in 32-bit protected mode.
; BUT: Note that while our data and stack is 32-bit the code segment is still 16-bit.
;      We have to change the code segment to 32-bit ourself.
; NTS: INT AH=9 DS:EDX=string is NOT translated properly by CWSDPMI, don't use
; Note that DPMI servers allow us to INT 21h directly and do a bit of translation
; to make it work, so we can use the same string print routines as before.
dpmi_prot16_ok:	mov	esi,str_entry_ok16	; print this message ourself, INT AH=9 doesn't work properly under CWSDPMI.EXE
		call	common_str_print_1632

		mov	ax,0x0009		; AX=0x0009 DPMI set descriptor access rights
		mov	bx,cs			; BX=our code selector
		mov	cx,bx
		and	cx,3
		shl	cl,5			; CX=(code selector DPL << 5)
		or	cx,0xC09A		; CX |= Present code readable granular 32-bit
		int	31h
		jnc	code32_ok

		mov	esi,str_failed_to_set_cs_32bit
		call	common_str_print_1632
		mov	ax,0x4C00
		int	21h
		hlt

; OK now our code segment is 32-bit everything past this point must be 32-bit!
		bits	32
code32_ok:	mov	esi,str_entry_ok
		call	common_str_print32_crlf

;      ------------- Our protected mode segment value
		mov	esi,str_prot_cs
		call	common_str_print32
		mov	ax,cs
		call	put32hex16
		mov	esi,crlf
		call	common_str_print32

;      ------------- Ask the segment base of our code segment
		mov	ax,0x0006
		mov	bx,cs
		int	31h
		jc	.base_na
		push	dx			; CX:DX 32-bit base
		push	cx
		mov	esi,str_prot_cs_base
		call	common_str_print32
		pop	ax			; pop CX => AX
		call	put32hex16
		pop	ax			; pop DX => AX
		call	put32hex16
		mov	esi,crlf
		call	common_str_print32
.base_na:

; exit to DOS, 32 bit!
exit32:		mov	ax,0x4C00
		int	21h
		hlt

; ------------------- 32-BIT copy of lib ----------------

common_str_print32:push	eax			; NTS: We can't rely on INT 21h AH=9 because some DPMI servers
		push	ebx			; like CWSDPMI.EXE fail to translate the call properly
		push	edx
		push	esi
		cld
.l1:		lodsb
		cmp	al,'$'
		jz	.l1e
		mov	dl,al
		mov	ah,2			; AH=2 print char
		int	21h
		jmp	short .l1
.l1e:		pop	esi
		pop	edx
		pop	ebx
		pop	eax
		ret

common_str_print32_crlf:
		push	esi
		call	common_str_print32
		mov	esi,crlf
		call	common_str_print32
		pop	esi
		ret

;------------------------------------
putc32:		push	eax
		push	ebx
		push	ecx
		push	edx
		mov	ah,0x02
		mov	dl,al
		int	21h
		pop	edx
		pop	ecx
		pop	ebx
		pop	eax
		ret

;------------------------------------
put32hex8:	push	eax
		push	ebx
		xor	bh,bh
		mov	bl,al
		shr	bl,4
		push	ax
		mov	al,[bx+hexes]
		call	putc
		pop	ax
		mov	bl,al
		and	bl,0xF
		mov	al,[bx+hexes]
		call	putc
		pop	ebx
		pop	eax
		ret

;------------------------------------
put32hex16:	push	eax
		xchg	al,ah
		call	put32hex8
		pop	eax
		call	put32hex8
		ret

; ------------------- END OF 32-BIT ---------------------
		bits	16

; EXIT to DOS
exit:		mov	ax,0x4C00	; exit to DOS
		int	21h
		hlt

; print error message in DS:DX and then exit to DOS
common_str_error:mov	ah,0x09
		int	21h
		mov	ah,0x09
		mov	dx,crlf
		int	21h
		jmp	exit

common_str_print:push	ax
		push	bx
		push	dx
		mov	ah,0x09
		int	21h
		pop	dx
		pop	bx
		pop	ax
		ret

common_str_print_crlf:push	ax
		push	bx
		push	dx
		mov	ah,0x09
		int	21h
		mov	ah,0x09
		mov	dx,crlf
		int	21h
		pop	dx
		pop	bx
		pop	ax
		ret

common_str_print_1632:
		cld
.l1:		lodsb
		cmp	al,'$'
		jz	.l1e
		mov	dl,al
		mov	ah,2			; AH=2 print char
		int	21h
		jmp	short .l1
.l1e:		ret

;------------------------------------
puts:		mov	ah,0x09
		int	21h
		ret

;------------------------------------
putc:		push	ax
		push	bx
		push	cx
		push	dx
		mov	ah,0x02
		mov	dl,al
		int	21h
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;------------------------------------
putdec16:	push	ax
		push	bx
		push	cx
		push	dx

		xor	dx,dx
		mov	cx,1
		mov	bx,10
		div	bx
		push	dx

putdec16_loop:	test	ax,0xFFFF
		jz	putdec16_pl
		xor	dx,dx
		inc	cx
		div	bx
		push	dx
		jmp	short putdec16_loop

putdec16_pl:	xor	bh,bh
putdec16_ploop:	pop	ax
		mov	bl,al
		mov	al,[bx+hexes]
		call	putc
		loop	putdec16_ploop

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;------------------------------------
puthex8:	push	ax
		push	bx
		xor	bh,bh
		mov	bl,al
		shr	bl,4
		push	ax
		mov	al,[bx+hexes]
		call	putc
		pop	ax
		mov	bl,al
		and	bl,0xF
		mov	al,[bx+hexes]
		call	putc
		pop	bx
		pop	ax
		ret

;------------------------------------
puthex16:	push	ax
		xchg	al,ah
		call	puthex8
		pop	ax
		call	puthex8
		ret

		segment .data

hexes:		db	'0123456789ABCDEF'

str_no:		db	'No$'
str_yes:	db	'Yes$'
str_32bit_supported:db	'32-bit supported: $'
str_need_dpmi:	db	'DPMI server required$'
str_processor_type:db	'Processor: $'
str_dpmi_version:db	'DPMI server v$'
str_required_para:db	'Required paragraphs: $'
str_entry_point:db	'Entry point: $'
str_cant_realloc_cs:db	'Cannot realloc code segment$'
str_cant_alloc_dpmi:db	'Cannot alloc DPMI segment$'
str_real_cs:	db	'Real mode CS: $'
str_prot_cs:	db	'Protected mode CS: $'
str_prot_cs_base:db	'CS segment base: $'
str_cant_enter_prot:db	'Cannot enter DPMI protected mode$'
str_real_dpmiseg:db	'Real mode DPMI segment: $'
str_entry_ok:	db	'DPMI 32-bit protected mode now active$'
str_entry_ok16:	db	'DPMI 32-bit protected mode w/ 16-bit active',13,10,'$'
str_dpmi_32_req:db	'A 32-bit capable DPMI server is required$'
str_failed_to_set_cs_32bit:db 'Failed to change code segment to 32-bit',13,10,'$'
crlf:		db	13,10,'$'

		segment .bss

dpmi_required_para:resw	1
dpmi_entry:	resw	2
dpmi_alloc_para:resw	1	; segment we allocated for DPMI server
dpmi_support:	resw	1

END_OF_IMAGE:	resb	1	; this extra byte is used by the code to realloc the COM file down

