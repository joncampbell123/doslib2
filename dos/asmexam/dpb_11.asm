;--------------------------------------------------------------------------------------
; DPB_11.COM
;
; Ask DOS for the Disk Parameter Block.
; This assumes the MS-DOS 1.1+ version.
;
; See also:
; http://www.ctyme.com/intr/rb-2594.htm
;
; Known issues:
;    - PC-DOS 1.0
;          Doesn't change DS:BX, which makes our output meaningless. PC-DOS 1.1 and later
;          change DS:BX and this works correctly.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ax,0x3000
		int	21h		; GET DOS VERSION
		cmp	ax,0x3000	; must be DOS 1.x (doesn't change AX)
		je	version_ok

		mov	dx,need_dos_version
		call	common_str_print_crlf

version_ok:	xor	ax,ax
		mov	ds,ax
		xor	bx,bx
		mov	es,bx
		mov	ah,0x1F		; AH=0x1F GET DRIVE PARAM BLOCK
		int	21h
					; <- NTS: DOS 2.0 and later return AL=0 on success.
					;         MS-DOS 1.x however does NOT set AL=0.
					;         I don't know if it's possible to detect failure, if it happens.

		mov	ax,bx
		mov	dx,es
		or	ax,dx		; AX = BX | ES
		jnz	request_ok	; if it's zero, we're running under PC-DOS 1.0

		push	cs
		pop	ds
		mov	dx,no_info_err
		jmp	common_str_error

; it worked! DOS set DS:BX to point at the DPB
request_ok:	push	ds		; move DS to ES
		pop	es
		push	cs		; restore DS == CS
		pop	ds

;----------- UNIT
		mov	dx,str_unit_number
		call	common_str_print

		mov	al,[es:bx]	; +0x00 sequential device id
		xor	ah,ah
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- DRIVE
		mov	dx,str_drive_number
		call	common_str_print

		mov	al,[es:bx+1]	; +0x01 drive number
		add	al,'A'
		call	putc

		mov	dx,crlf
		call	common_str_print

;----------- BYTES PER SECTOR
		mov	dx,str_bytes_per_sector
		call	common_str_print

		mov	ax,[es:bx+2]	; +0x02 bytes per sector
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- Highest sector number in a cluster
		mov	dx,str_highest_sector_num_cl
		call	common_str_print

		mov	al,[es:bx+4]	; +0x04 highest sector in a cluster
		xor	ah,ah
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- Sectors per cluster
		mov	dx,str_sectors_per_cluster_pow2
		call	common_str_print

		mov	cl,[es:bx+5]	; +0x05 shift count to convert clusters to sectors
		mov	ax,1
		shl	ax,cl
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- Reserved sectors
		mov	dx,str_reserved
		call	common_str_print

		mov	ax,[es:bx+6]
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- # of FATs
		mov	dx,str_fats
		call	common_str_print

		xor	ah,ah
		mov	al,[es:bx+8]
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- # of root directory entries
		mov	dx,str_root_dirents
		call	common_str_print

		mov	ax,[es:bx+9]
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- sector number of first user data sector
		mov	dx,str_first_user_sector
		call	common_str_print

		mov	ax,[es:bx+11]
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- highest cluster number
		mov	dx,str_highest_cluster
		call	common_str_print

		mov	ax,[es:bx+13]
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- sectors per fat
		mov	dx,str_sectors_per_fat
		call	common_str_print

		xor	ah,ah
		mov	al,[es:bx+15]
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- first directory sector
		mov	dx,str_first_dir_sector
		call	common_str_print

		mov	ax,[es:bx+16]
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- address of allocation table (FIXME: Disk address? Memory address?)
		mov	dx,str_allocation_table_addr
		call	common_str_print

		mov	ax,[es:bx+18]
		call	putdec16

		mov	dx,crlf
		call	common_str_print

; EXIT to DOS
exit:		mov	ax,0x0000	; exit to DOS
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
str_req_fail:	db	'Request failed$'
need_dos_version:db	'WARNING: This version assumes MS-DOS 1.1$'
str_drive_number:db	'Drive: $'
str_unit_number:db	'Unit: $'
str_bytes_per_sector:db	'Bytes/sector: $'
str_highest_sector_num_cl:db 'Highest sector number in a cluster: $'
str_sectors_per_cluster_pow2:db 'Sectors/cluster: $'
str_reserved:	db	'Reserved sectors: $'
str_fats:	db	'Number of FATs: $'
str_root_dirents:db	'Number of root directory entries: $'
str_first_user_sector:db 'First user sector number: $'
str_highest_cluster:db	'Highest cluster number: $'
str_sectors_per_fat:db	'Sectors per FAT: $'
str_first_dir_sector:db	'First directory sector: $'
str_allocation_table_addr:db 'Allocation table address: $'
no_info_err:	db	'DS:BX was not changed. This means that you are running MS-DOS 1.0',13,10,'which does not implement function AH=0x1F$'
str_cwd:	db	'Current working directory: $'
crlf:		db	13,10,'$'

		segment .bss

