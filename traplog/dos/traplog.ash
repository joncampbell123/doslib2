
; include file for NASM assembly language

struc traplog_cpu_state_record_8086
	.r_recid	resw	1		; record ID. set to 0x8086
	.r_reclen	resw	1		; record length
	.r_di		resw	1
	.r_si		resw	1
	.r_bp		resw	1
	.r_sp		resw	1
	.r_bx		resw	1
	.r_dx		resw	1
	.r_cx		resw	1
	.r_ax		resw	1
	.r_flags	resw	1
	.r_ip		resw	1
	.r_cs		resw	1
	.r_ss		resw	1
	.r_ds		resw	1
	.r_es		resw	1
	.r_csip_capture	resd	1		; snapshot of the first 4 bytes at CS:IP
	.r_sssp_capture	resd	1		; snapshot of the first 4 bytes at SS:IP
endstruc

struc traplog_cpu_state_record_286
	.r_recid	resw	1		; record ID. set to 0x8286
	.r_reclen	resw	1		; record length
	.r_di		resw	1
	.r_si		resw	1
	.r_bp		resw	1
	.r_sp		resw	1
	.r_bx		resw	1
	.r_dx		resw	1
	.r_cx		resw	1
	.r_ax		resw	1
	.r_flags	resw	1
	.r_ip		resw	1
	.r_cs		resw	1
	.r_ss		resw	1
	.r_ds		resw	1
	.r_es		resw	1
	.r_csip_capture	resd	1		; snapshot of the first 4 bytes at CS:IP
	.r_sssp_capture	resd	1		; snapshot of the first 4 bytes at SS:IP
	.r_msw		resw	1		; machine status word
	.r_gdtr		resw	3
	.r_idtr		resw	3
	.r_ldtr		resw	1
endstruc

struc traplog_cpu_state_record_386
	.r_recid	resw	1		; record ID. set to 0x8386
	.r_reclen	resw	1		; record length
	.r_edi		resd	1
	.r_esi		resd	1
	.r_ebp		resd	1
	.r_esp		resd	1
	.r_ebx		resd	1
	.r_edx		resd	1
	.r_ecx		resd	1
	.r_eax		resd	1
	.r_eflags	resd	1
	.r_eip		resd	1
	.r_cr0		resd	1
	.r_cr2		resd	1
	.r_cr3		resd	1
	.r_cr4		resd	1
	.r_dr0		resd	1
	.r_dr1		resd	1
	.r_dr2		resd	1
	.r_dr3		resd	1
	.r_dr6		resd	1
	.r_dr7		resd	1
	.r_cs		resw	1
	.r_ss		resw	1
	.r_ds		resw	1
	.r_es		resw	1
	.r_fs		resw	1
	.r_gs		resw	1
	.r_gdtr		resw	3
	.r_idtr		resw	3
	.r_ldtr		resw	1
	.r_csip_capture	resd	1		; snapshot of the first 4 bytes at CS:IP
	.r_sssp_capture	resd	1		; snapshot of the first 4 bytes at SS:IP
endstruc

