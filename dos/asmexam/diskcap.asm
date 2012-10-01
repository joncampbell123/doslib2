;--------------------------------------------------------------------------------------
; DISKCAP.COM
;
; Ask for free disk space & capacity. Uses the original FAT16 of the function,
; which is limited to 2GB or less and will not be accurate for FAT32.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ah,0x36		; get free disk space
		mov	dl,0		; 0=default
		int	21h
		cmp	ax,0xFFFF	; check for invalid drive
		jnz	drive_ok

		mov	dx,str_invalid_drv
		call	puts
		ret

; drive is OK, print out the contents
drive_ok:	call	print_capacity
		push	dx
		mov	dx,str_ex_free
		call	puts
		pop	dx

		mov	bx,dx		; now print total capacity
		call	print_capacity
		mov	dx,str_ex_total
		call	puts

; EXIT to DOS
exit:		ret

;------------------------------------
print_capacity:	push	ax		; <- save all regs
		push	bx
		push	cx
		push	dx

		mul	bx		; DX:AX = AX * BX (sectors/cluster x number of free clusters) =
					;      number of free sectors
		mov	word [tempsum],ax	; save DX:AX away
		mov	word [tempsum+2],dx

		mul	cx		; DX:AX = CX * AX (lo-word of free sectors x bytes/sector)
		mov	word [tempsum2],ax
		mov	word [tempsum2+2],dx

		mov	ax,word [tempsum+2] ; DX:AX = CX * AX (hi-word of free sectors x bytes/sector)
		mul	cx
		add	word [tempsum2+2],ax

		mov	ax,word [tempsum2] ; load back into DX:AX result of 32x16 multiply
		mov	dx,word [tempsum2+2]

		; NTS: This converts the 32-bit result in DX:AX to a 16-bit value with a unit suffix,
		;      rather than printing out a byte value, because I'm too lazy to write a full
		;      32-bit divide by 10 print routine in 16-bit real mode DOS at this time.
		mov	si,str_suf_bytes; default to SI suffix " bytes" and remain so if DX:AX < 65536
		test	dx,dx
		jz	freespc_ok	; if DX == 0 then DX:AX < 65536

		call	dx_ax_shr10
		mov	si,str_suf_kbytes
		test	dx,dx
		jz	freespc_ok

		call	dx_ax_shr10
		mov	si,str_suf_mbytes

; we're ready to print the value in AX using suffix in SI
freespc_ok:	call	putdec16
		mov	dx,si
		call	puts

		pop	dx		; we printed free space, now restore the regs we saved
		pop	cx
		pop	bx
		pop	ax

		ret

;------------------------------------
dx_ax_shr10:	mov	cl,10		; shift DX:AX to the right 10 bits to convert to KB
		shr	ax,cl		; AX = (AX >> 10) + (DX << 6), DX >>= 10
		mov	bx,dx
		shr	dx,cl
		mov	cl,6
		shl	bx,cl
		add	ax,bx
		ret

;------------------------------------
puts:		push	ax
		push	bx
		push	cx
		mov	ah,0x09
		int	21h
		pop	cx
		pop	bx
		pop	ax
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
		add	al,'0'
		call	putc
		loop	putdec16_ploop

		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

		segment .data

str_invalid_drv:db	'Invalid drive',13,10,'$'
str_ex_free:	db	' free',13,10,'$'
str_ex_total:	db	' total',13,10,'$'
str_suf_bytes:	db	' bytes$'
str_suf_kbytes:	db	'KB$'
str_suf_mbytes:	db	'MB$'
crlf:		db	13,10,'$'

		segment .bss

tempsum:	resd	1
tempsum2:	resd	1

