; do_cpuid() function
%include "nasmsegs.inc"
%include "nasm1632.inc"

%if TARGET_BITS == 16
 %define cdecl_ofs (retnative_stack_size+pusha_stack_size+2)	; RETF + PUSHA + DS
%endif
%if TARGET_BITS == 32
 %define cdecl_ofs (retnative_stack_size+pusha_stack_size)	; RETF + PUSHA
%endif

CODE_SEGMENT

;=====================================================================
;=====================================================================
EXTERN_C_FUNCTION do_cpuid ; void _cdecl do_cpuid(uint32_t regid,cpuid_info *s)
	push_if_far_argv(ds) ; if the memory model makes data pointers FAR, save DS
	pushan
	mov	nbp,nsp

	mov	eax,[nbp+cdecl_ofs]
	stack_argv_ptr_load(ds,nsi,nbp+cdecl_ofs+4) ; DS:SI (16-bit far data ptr) or SI (16-bit near dataptr) or ESI (32-bit flat)
	xor	ebx,ebx
	xor	ecx,ecx
	xor	edx,edx
	cpuid
	mov	[nsi],eax
	mov	[nsi+4],ebx
	mov	[nsi+8],ecx
	mov	[nsi+12],edx

	popan
	pop_if_far_argv(ds)
	retnative

