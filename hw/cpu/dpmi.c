
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <hw/cpu/cpu.h>
#include <hw/cpu/cpusse.h>
#include <misc/useful.h>
#include <hw/cpu/dpmi.h>

#if defined(TARGET_MSDOS) && TARGET_BITS == 16

void __cdecl _dos_dpmi_init_server16_enter();
void __cdecl _dos_dpmi_init_server32_enter();

struct _dos_dpmi_state		dos_dpmi_state = {
	0,			/* +0 flags */
	0,0,			/* +1 IP:CS */
	0,			/* +5 dpmi_private_size */ 
	0,			/* +7 dpmi_version */
	0,			/* +9 dpmi_cpu */
	0,			/* +10 dpmi_private_segment */
	0,			/* +12 dpmi_cs */
	0,			/* +14 dpmi_ds */
	0,			/* +16 dpmi_es */
	0,			/* +18 dpmi_ss */
	0,0,			/* +20 real-to-prot entry */
	0,0,0,			/* +24 prot-to-real entry */
	0			/* +30 program segment prefix */
				/* =32 */
};

unsigned int dos_dpmi_probe() {
	/*DEBUG: TODO REMOVE WHEN FINISHED*/
	if (sizeof(dos_dpmi_state) != 32) {
		fprintf(stderr,"ERROR: dos_dpmi_state struct is not correct size\n");
		return 0;
	}

	if (!(dos_dpmi_state.flags & DPMI_SERVER_PROBED)) {
		/* most DPMI servers require protected-mode INT 21h termination */
		dos_dpmi_state.flags |= DPMI_SERVER_PROBED | DPMI_SERVER_NEEDS_PROT_TERM;

		__asm {
			push		ax
			push		bx
			push		si
			push		di
			push		ds
			push		es

			mov		ax,0x1687
			int		0x2F
			or		ax,ax
			jnz		nodpmi

			; NTS: We access the structure in this way because Watcoms inline assembler
			;      offers no way to directly refer to structure members, apparently.
			mov		ax,bx					; save BX
#  if defined(__LARGE__) || defined(__COMPACT__) || defined(__HUGE__)
			mov		bx,seg dos_dpmi_state
			mov		ds,bx
#  endif
			mov		bx,offset dos_dpmi_state
			or		byte ptr [bx],DPMI_SERVER_PRESENT	; .flags |= PRESENT
			mov		word ptr [bx+1],di			; .entry_ip = DI
			mov		word ptr [bx+3],es			; .entry_cs = ES
			mov		word ptr [bx+5],si			; .dpmi_private_size = SI
			mov		word ptr [bx+7],dx			; .dpmi_version = DX (DH,DL)
			mov		byte ptr [bx+9],cl			; .dpmi_processor = CL

			test		ax,1					; does the DPMI server support 32-bit?
			jz		no32bit
			or		byte ptr [bx],DPMI_SERVER_CAN_DO_32BIT
no32bit:

			; check: is this Windows? TODO This should eventually become part of the DOS lib
			; NTS: This system call will only succeed under Windows 3.1/95/98/ME. It cannot be
			; used to detect Windows 3.0 or Windows XP. However Windows 3.x and XP require the
			; protected mode INT 21h exit anyway, were only concerned with Windows 95/98/ME
			; who do NOT need the protected mode exit hack. In fact, attempting the hack under
			; those versions of Windows will cause a GPF because the DPMI shutdown will have
			; invalidated the protected mode selectors we obtained.
			mov		si,bx			; the call will obliterate BX
			mov		ax,0x160A
			int		2Fh
			or		ax,ax			; on return: AX=0 BX=version CX=mode (2=standard or 3=enhanced)
			jnz		not_windows_9x
			cmp		bx,0x400		; Windows 95 or higher? (v4.00 or higher)
			jl		not_windows_9x
			and		byte ptr [si],(0xFF - DPMI_SERVER_NEEDS_PROT_TERM) ; Its Win9x/ME. Do NOT do the protmode hack
not_windows_9x:		

nodpmi:			pop		es
			pop		ds
			pop		di
			pop		si
			pop		bx
			pop		ax
		}
	}

	return dos_dpmi_state.flags;
}

static unsigned int _dos_dpmi_initcomm_check1() {
	if (!(dos_dpmi_state.flags & DPMI_SERVER_PROBED))
		return 1;
	if (!(dos_dpmi_state.flags & DPMI_SERVER_PRESENT))
		return 2;
	if (dos_dpmi_state.entry_cs == 0) /* if no entry point, fail */
		return 5;

	return 0;
}

static unsigned int _dos_dpmi_initcomm_alloc_private() {
	/* if the DPMI server needs a private area, then allocate one */
	if (dos_dpmi_state.dpmi_private_size != 0 && dos_dpmi_state.dpmi_private_segment == 0) {
		__asm {
			.286
			push	ds
			pusha
#  if defined(__LARGE__) || defined(__COMPACT__) || defined(__HUGE__)
			mov	si,seg dos_dpmi_state
			mov	ds,si
#  endif
			mov	si,offset dos_dpmi_state
			mov	ah,0x48
			mov	bx,word ptr [si+5] ; dpmi_private_size
			int	21h
			jc	errout1
			mov	word ptr [si+10],ax ; dpmi_private_segment

errout1:		popa
			pop	ds
		}

		if (dos_dpmi_state.dpmi_private_size == 0)
			return 4;
	}

	return 0;
}

unsigned int dos_dpmi_init_server16() {
	unsigned int r;

	if ((r=_dos_dpmi_initcomm_check1()) != 0)
		return r;

	/* if DPMI is already initialized... */
	if (dos_dpmi_state.flags & DPMI_SERVER_INIT) {
		if (dos_dpmi_state.flags & DPMI_SERVER_INIT_32BIT)
			return 3; /* if initialized as 32-bit, then error out */

		return 0; /* else if inited as 16-bit it's ok, no work to do */
	}

	if ((r=_dos_dpmi_initcomm_alloc_private()) != 0)
		return r;

	_dos_dpmi_init_server16_enter();
	if (!(dos_dpmi_state.flags & DPMI_SERVER_INIT))
		return 5;

	/* TODO: Hook the INT 22h vector in the PSP so that our code can gain control
	 *       and forcibly terminate the DPMI server */

	return 0;
}

unsigned int dos_dpmi_init_server32() {
	unsigned int r;

	if ((r=_dos_dpmi_initcomm_check1()) != 0)
		return r;

	/* if DPMI is already initialized... */
	if (dos_dpmi_state.flags & DPMI_SERVER_INIT) {
		if (!(dos_dpmi_state.flags & DPMI_SERVER_INIT_32BIT))
			return 3; /* if not initialized as 32-bit, then error out */

		return 0; /* else if inited as 16-bit it's ok, no work to do */
	}

	if ((r=_dos_dpmi_initcomm_alloc_private()) != 0)
		return r;

	_dos_dpmi_init_server32_enter();
	if (!(dos_dpmi_state.flags & DPMI_SERVER_INIT))
		return 5;

	/* TODO: Hook the INT 22h vector in the PSP so that our code can gain control
	 *       and forcibly terminate the DPMI server */

	return 0;
}

#endif

