;--------------------------------------------------------------------------------------
; DPB_2.COM
;
; Ask DOS for the Disk Parameter Block.
; This assumes the MS-DOS 2.x version.
;
; See also:
; http://www.ctyme.com/intr/rb-2724.htm
;--------------------------------------------------------------------------------------
		bits 16			; 16-bit real mode
		org 0x100		; DOS .COM executable starts at 0x100 in memory

		segment .text

		push	cs
		pop	ds

		mov	ah,0x30
		int	21h		; GET DOS VERSION
		cmp	al,2		; must be DOS 2.x
		je	version_ok

		mov	dx,need_dos_version
		call	common_str_print_crlf

version_ok:	mov	ah,0x32		; AH=0x32 GET DOS DRIVE PARAM BLOCK
		xor	dl,dl		; DL=0 default drive
		int	21h
		cmp	al,0		; did it succeed?
		jz	request_ok

		mov	dx,str_req_fail
		jmp	common_str_error

; it worked! DOS set DS:BX to point at the DPB
request_ok:	push	ds		; move DS to ES
		pop	es
		push	cs		; restore DS == CS
		pop	ds

;----------- DRIVE
		mov	dx,str_drive_number
		call	common_str_print

		mov	al,[es:bx]	; +0x00 drive number
		add	al,'A'
		call	putc

		mov	dx,crlf
		call	common_str_print

;----------- UNIT WITHIN DRIVER
		mov	dx,str_unit_number
		call	common_str_print

		mov	al,[es:bx+1]	; +0x01 unit within device driver
		xor	ah,ah
		call	putdec16

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
		mov	ax,0x200
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

;----------- device driver header
		mov	dx,str_device_driver_header
		call	common_str_print

		mov	ax,[es:bx+18+2]
		call	puthex16
		mov	al,':'
		call	putc
		mov	ax,[es:bx+18]
		call	puthex16

		mov	dx,crlf
		call	common_str_print

;----------- media ID
		mov	dx,str_media_id
		call	common_str_print

		mov	al,[es:bx+22]
		call	puthex8

		mov	dx,crlf
		call	common_str_print

;----------- disk accessed
		mov	dx,str_disk_accessed
		call	common_str_print

		mov	al,[es:bx+23]
		call	puthex8

		mov	dx,crlf
		call	common_str_print

;----------- next PDB
		mov	dx,str_next_pdb
		call	common_str_print

		mov	ax,[es:bx+24+2]
		call	puthex16
		mov	al,':'
		call	putc
		mov	ax,[es:bx+24]
		call	puthex16

		mov	dx,crlf
		call	common_str_print

;----------- starting cluster of current working directory
		mov	dx,str_start_cluster_of_cwd
		call	common_str_print

		mov	ax,[es:bx+28]
		call	putdec16

		mov	dx,crlf
		call	common_str_print

;----------- ASCIIZ pathname of current working directory
		mov	dx,str_cwd
		call	common_str_print

		lea	si,[bx+30]
cwdl1:		es
		lodsb
		or	al,al
		jz	cwdl1e
		call	putc
		jmp	short cwdl1
cwdl1e:		mov	dx,crlf
		call	common_str_print

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
need_dos_version:db	'WARNING: This version assumes MS-DOS 2.x$'
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
str_start_cluster_of_cwd:db 'Current working directory starts at cluster: $'
str_cwd:	db	'Current working directory: $'
crlf:		db	13,10,'$'

		segment .bss

