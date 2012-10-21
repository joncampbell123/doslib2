;--------------------------------------------------------------------------------------
; DPMI16_0.COM
;
; Proof of concept entering DPMI 16-bit protected mode. Prints DPMI server info once
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
		call	common_str_print_crlf
		ret

dpmi_ok:

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
need_dos_version:db	'WARNING: This version assumes MS-DOS 4.0 or higher$'
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
str_device_driver_header:db 'Device driver header location: $'
str_media_id:	db	'Media ID: $'
str_disk_accessed:db	'Disk accessed: $'
str_next_pdb:	db	'Next PDB location: $'
str_cluster_start_free_search:db 'Cluster to start free space search at: $'
str_free_clusters:db	'Free clusters: $'
str_need_dpmi:	db	'DPMI server required: $'
crlf:		db	13,10,'$'

		segment .bss

