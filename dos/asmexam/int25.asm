;--------------------------------------------------------------------------------------
; INT25.COM
;
; INT 25h absolute disk read. Read the first sector.
; This will only work on disks smaller than 32MB. Under MS-DOS reads will fail if the
; disk is 32MB or larger.
;
; WARNING: You can modify this code to write to the disk, but be aware Windows 95/98/ME
;          requires you to "lock" the volume first. If you do not, the DOS kernel will
;          halt the system with an error message.
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ah,0x19
		int	21h		; get current drive

		mov	[segsp],sp	; save SP, int 25h doesn't return properly
					; AL=drive (from AH=0x19)
		mov	cx,2		; two sectors
		mov	dx,0		; from start of partition (sector 0)
		mov	bx,buffer
		int	25h
		mov	sp,[segsp]	; restore SP. INT 25h does not return properly.
		jnc	read_ok

		mov	ah,9
		mov	dx,str_failed
		int	21h
		int	20h

read_ok:	mov	si,buffer

		mov	cx,4		; 2 x 16 x 32 = 1024
l1_0:		push	cx
		mov	cx,16
l1_1:		push	cx
		mov	cx,16
l1_2:		lodsb
		call	puthex8
		mov	al,' '
		call	putc
		loop	l1_2

		push	si
		mov	ah,9
		mov	dx,crlf
		int	21h
		pop	si
		pop	cx
		loop	l1_1

		push	si
		mov	ah,9
		mov	dx,crlf
		int	21h
		xor	ah,ah
		int	16h
		pop	si
		pop	cx
		loop	l1_0

; EXIT to DOS
exit:		int	20h
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
str_failed:	db	'Read failed: ',13,10,'$'
crlf:		db	13,10,'$'

		segment .bss

segsp:		resw	1
buffer:		resb	1024

