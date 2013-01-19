
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
	0			/* +18 dpmi_ss */
				/* =20 */
};

unsigned int dos_dpmi_probe() {
	/*DEBUG: TODO REMOVE WHEN FINISHED*/
	if (sizeof(dos_dpmi_state) != 20) {
		fprintf(stderr,"ERROR: dos_dpmi_state struct is not correct size\n");
		return 0;
	}

	if (!(dos_dpmi_state.flags & DPMI_SERVER_PROBED)) {
		dos_dpmi_state.flags |= DPMI_SERVER_PROBED;

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

unsigned int dos_dpmi_init_server32() {
	return 0;
}

#if 0
# pragma pack(push,1)
struct _dos_dpmi_state {
	unsigned char			flags;
	unsigned short			entry_ip,entry_cs;
	unsigned short			dpmi_private_size;	/* in paragraphs */
	unsigned short			dpmi_version;
	unsigned char			dpmi_processor;
	unsigned short			dpmi_private_segment;
	unsigned short			dpmi_cs;		/* code segment given by DPMI server */
	unsigned short			dpmi_ds;		/* data segment given by DPMI server */
	unsigned short			dpmi_es;		/* ES segment given by DPMI server */
	unsigned short			dpmi_ss;		/* SS segment given by DPMI server */
};
# pragma pack(pop)

extern struct _dos_dpmi_state dos_dpmi_state;

# define DPMI_SERVER_PROBED		0x01
# define DPMI_SERVER_PRESENT		0x02
# define DPMI_SERVER_INIT		0x04
# define DPMI_SERVER_CAN_DO_32BIT	0x08
# define DPMI_SERVER_INIT_32BIT		0x10
#endif

unsigned int dos_dpmi_init_server16() {
	if (!(dos_dpmi_state.flags & DPMI_SERVER_PROBED))
		return 1;
	if (!(dos_dpmi_state.flags & DPMI_SERVER_PRESENT))
		return 2;
	if (dos_dpmi_state.entry_cs == 0) /* if no entry point, fail */
		return 5;

	/* if DPMI is already initialized... */
	if (dos_dpmi_state.flags & DPMI_SERVER_INIT) {
		if (dos_dpmi_state.flags & DPMI_SERVER_INIT_32BIT)
			return 3; /* if initialized as 32-bit, then error out */

		return 0; /* else if inited as 16-bit it's ok, no work to do */
	}

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

	/* TODO: Hook the INT 22h vector in the PSP so that our code can gain control
	 *       and forcibly terminate the DPMI server */

	return 0;
}

#endif

