	 title	 ID386 -- Return Component Identifier From 386 or Later CPU
	 page	 58,122
	 name	 ID386

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-94 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, word-aligned,  stack,  class 'prog'
	       Program segment CODE,  word-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'

Original code by:  Bob Smith, November, 1987.

Modifications by:

Who		 When		What
--------------------------------------------------------------------------------

Bob Smith	 9 Jan 90	Implement BIOS call to request information
Bob Smith	 9 Jan 90	Ensure A20 is disabled to force INT 06h
Bob Smith	21 Feb 90	Allow to be called from Virtual 8086 Mode
Bob Smith	 1 Nov 91	Handle BIOS bug of near vs. far jump
Bob Smith	22 Feb 94	Support CPUID instruction

|

.386p
.xlist
	 include MISC.INC
	 include SYSID.INC
	 include BIOSCONF.INC
	 include CMOS.INC
.list


PGROUP	 group	 STACK,CODE,DATA,DTAIL


BIOSDATA segment use16 at 40h	; Start BIOSDATA segment

	 org	 67h
IO_ROM_VEC dd	 ?		; Pointer to optional I/O ROM init routine

BIOSDATA ends			; End BIOSDATA segment


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 word stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 VERS_H:abs,VERS_T:abs,VERS_U:abs

	 public  RESETSTK_VEC,RESETSTK_OLD,LCLSTKZ_VEC
RESETSTK_VEC dd  00000000h	; Reset stack Seg:Off ending at 0:0
RESETSTK_OLD dw  6 dup (?)	; Save area for old reset stack contents
LCLSTKZ_VEC label dword 	; Seg:Off of local stack top
	 dw	 PGROUP:LCLSTKZ,? ; Define as two words because MASM doesn't
				; support OFFSET16

	 public  MOVE_TAB
	 align	 4		; Ensure GDT is dword-aligned
MOVE_TAB MDTE_STR <>		; BIOS block move DTE structure

	 public  OLDDR0,OLDDR1,OLDDR2,OLDDR3,OLDDR6,OLDDR7
	 public  TOPMEM
OLDDR0	 dd	 ?		; Save area for old DR0
OLDDR1	 dd	 ?		; ...		    DR1
OLDDR2	 dd	 ?		; ...		    DR2
OLDDR3	 dd	 ?		; ...		    DR3
OLDDR6	 dd	 ?		; ...		    DR6
OLDDR7	 dd	 ?		; ...		    DR7
TOPMEM	 dw	 ?		; Target for read from FFEFFFF0

	 public  REALIDTR
REALIDTR df	 4*100h-1	; Limit/base of real mode IDTR

	 public  COMPID_CPU,COMPID_BIOS,COMPID_S0A,COMPID_I06
COMPID_CPU dw	 ?		; Component ID, returned from CPU
COMPID_BIOS dw	 ?		; ...			      BIOS
COMPID_S0A dw	 ?		; ...			      SHUT0A
COMPID_I06 dw	 ?		; ...			      INT 06h value

	 public  OLDINT06_VEC
OLDINT06_VEC dd  ?		; Save area for old INT 06h handler

	 public  INT06_PTR
INT06_PTR dd	 ?		; Save area for INT 06h caller's CS:IP

	 public  XMSDRV_VEC
XMSDRV_VEC dd	 0		; Save area for XMS driver entry point (0=none)

	 public  HEXTABLE
HEXTABLE db	 '0123456789ABCDEF' ; Hex translate table

	 public  NMIPORT,NMIENA,NMIDIS,NMIMASK
NMIPORT  dw	 @CMOS_CMD	; NMI clear I/O port
NMIENA	 db	 @CMOS_ENANMI	; ... enable value
NMIDIS	 db	 @CMOS_DISNMI	; ... disable value
NMIMASK  db	 mask $ATPAR	; ... clear mask

	 public  ROMINT_VEC,ROMINT_PTR,ROMINT_NUM
ROMINT_VEC dd	 ?		; Save area for old ROM INT handler
ROMINT_PTR dw	 ?		; Offset of local routine
ROMINT_NUM db	 ?		; Save area for old ROM INT number

	 public  INTA01,INTB01
INTA01	 db	 ?		; Save value of master IMR
INTB01	 db	 ?		; Save value of slave ...

	 public  SHUT_ORIG
SHUT_ORIG db	 ?		; Save area for original shutdown byte

	 public  LCL_FLAG
	 include ID3_LCL.INC
LCL_FLAG db	 0		; Local flags

	 public  MSG_COPY
MSG_COPY db	 '386ID    -- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
	 db	 ' (C) Copyright 1987-94 Qualitas, Inc.',CR,LF,EOS

	 public  MSG_OKID
MSG_OKID db	 'The component ID is '
MSG_OKID1 db	 '____ from ',EOS

	 public  MSG_INT06,MSG_SHUT0A,MSG_BIOS,MSG_CPU
MSG_INT06 db	 'the INT 06h handler ('
MSG_INT06SEG db  '____:'
MSG_INT06OFF db  '____).',CR,LF,EOS

MSG_SHUT0A db	 'the type 0Ah shutdown.',CR,LF,EOS
MSG_BIOS db	 'the BIOS.',CR,LF,EOS
MSG_CPU  db	 'the CPUID instruction.',CR,LF,EOS

	 public  MSG_NOT386,MSG_NOA20,MSG_NOVM,MSG_NOFTB
MSG_NOT386 db	 BEL,'様> The CPU is not an 80386 or later.',CR,LF,EOS
MSG_NOA20 db	 BEL,'様> Unable to disable the A20 line.',CR,LF,EOS
MSG_NOVM  db	 BEL,'様> Unable to run from Virtual 8086 Mode.',CR,LF,EOS
MSG_NOFTB db	 BEL,'様> This system does not have a fully-terminated bus,',CR,LF
	  db	     '    so we did not attempt system shutdown.',CR,LF,EOS

DATA	 ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	 segment use16 dword public 'data' ; Start DTAIL segment
	 assume  ds:PGROUP

	 public  LCLSTK,LCLSTKZ
LCLSTK	 label	 word		; Local stack
	 org	 LCLSTK+100h	; Skip over stack
LCLSTKZ  label	 word		; Return offset at top-of-stack

	 public  LOWGDT
LOWGDT	 label	 byte		; Low memory copy of GDT for TR search

DTAIL	 ends			; End DTAIL segment


CODE	 segment use16 word public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 GATEA20:near
	 extrn	 DEGATEA20:near
	 extrn	 PPI_S2K_K2S:near

	 org	 100h		; Skip over PSP area for .COM program

	 NPPROC  ID386 -- Return 386/486 Chip Identifiers
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Determine 386/486 component identifier and revision level.

Three techniques are tried in turn:

1.  Ask the CPU using the CPUID instruction (if supported).
    If that works, display the value and exit.
2.  Ask the BIOS.
    If that works, display the value and exit.
3.  Ask the CPU by shutting down the system and intercepting the
    component ID in DX.  First, we install an INT 06h handler and
    disable the A20 line to encourage the system to signal an Invalid
    Opcode.  Then we shutdown the system.  If the INT 06h handler is
    called, save the value in DX at that time.	Also, save the value
    in DX at the shutdown entry point.	Note we shutdown the system
    twice.  The first time, we shutdown without initializing the 8259
    in order to increase our chances of obtaining a valid value in DX
    on the theory that were the BIOS to initialize the 8259, it might
    clobber DX.  The second time, we shutdown and initialize the 8259.

See the accompanying .DOC file for a complete description.

|

	 mov	 LCLSTKZ_VEC.VSEG,cs ; Setup segment for local stack

	 STROUT  MSG_COPY	; Display the flag

; Ensure we're on a 386 or later processor

	 call	 CHECK_CPUTYP	; Check it out
	 jnc	 short @F	; Jump if OK

	 jmp	 ID386_EXIT	; Jump if something went wrong

@@:
	 lss	 sp,LCLSTKZ_VEC ; Switch to local stack
	 assume  ss:nothing	; Tell the assembler about it

; 1.  Ask the CPU using the CPUID instruction.

	 call	 IZIT_CPUID	; Duzit support the CPUID instruction?
	 jnc	 short ID386_NOCPUID ; Jump if not

	 mov	 eax,1		; Function code to retrieve feature bits
	 CPUID			; Return with EAX = stepping info
				;	      EBX, ECX reserved
				;	      EDX = feature bits
	 mov	 COMPID_CPU,ax	; Save for later use
	 or	 LCL_FLAG,@LCL_CPU ; Mark as coming from CPU
ID386_NOCPUID:

; 2.  Ask the BIOS.

	 mov	 ax,0C910h	; Major/minor function to get info
	 int	 15h		; Request BIOS services
	 jc	 short ID386_NOBIOS ; Jump if not supported

	 mov	 COMPID_BIOS,cx ; Save for later use
	 or	 LCL_FLAG,@LCL_BIOS ; Mark as coming from BIOS
ID386_NOBIOS:
	 test	 LCL_FLAG,@LCL_CPU or @LCL_BIOS ; Do we have a value yet?
	 jnz	 near ptr ID386_NOINT06 ; Jump if so

; Ensure we're in Real Mode (wait until after BIOS and CPU checks)

	 smsw	 ax		; Get low-order word of CR0

	 test	 ax,mask $PE	; Izit Protected Mode (actually Virtual 8086 Mode)?
	 jz	 short @F	; Jump if not

	 STROUT  MSG_NOVM	; Display error message

	 jmp	 ID386_EXIT	; Jump if something went wrong

@@:

; Check for XMS driver

	 mov	 ax,4300h	; Function code to detect XMS driver
	 int	 2Fh		; Request multiplexor service

	 cmp	 al,80h 	; Izit installed?
	 jne	 short @F	; Jump if not

	 mov	 ax,4310h	; Function code to return driver entry point
	 int	 2Fh		; Request multiplexor service
	 assume  es:nothing	; Tell the assembler about it

	 mov	 XMSDRV_VEC.VOFF,bx ; Save for later use
	 mov	 XMSDRV_VEC.VSEG,es ; ...
@@:

; Check for fully-terminated bus at 4GB - 1MB - 16; that is,
; read in the first two bytes there and ensure that they are FF FF.
; If not, then the trick of resetting the system with A20 disabled
; will crash the system as we're relying upon generating an Invalid
; Opcode.

	 call	 CHECK_FTB	; Check for a fully-terminated bus
	 jnc	 short @F	; Jump if OK

	 STROUT  MSG_NOFTB	; Display error message

	 or	 LCL_FLAG,@LCL_XFTB ; Mark as not present
@@:
	 mov	 eax,dr0	; Save debug registers
	 mov	 OLDDR0,eax	; ...to restore later

	 mov	 eax,dr1	; Save debug registers
	 mov	 OLDDR1,eax	; ...to restore later

	 mov	 eax,dr2	; Save debug registers
	 mov	 OLDDR2,eax	; ...to restore later

	 mov	 eax,dr3	; Save debug registers
	 mov	 OLDDR3,eax	; ...to restore later

	 mov	 eax,dr6	; Save debug registers
	 mov	 OLDDR6,eax	; ...to restore later

	 mov	 eax,dr7	; Save debug registers
	 mov	 OLDDR7,eax	; ...to restore later

; Install our own INT 23h and 06h handlers

	 SETINT  23h,INT23	; Install our own Ctrl-Break handler
				; Note no need to save previous handler
				; as DOS restores it when we terminate
	 GETINT  06h		; Get invalid opcode interrupt handler
	 assume  es:nothing	; Tell the assembler about it
				; Return with ES:BX ==> existing handler

	 mov	 OLDINT06_VEC.VOFF,bx ; Save to restore later
	 mov	 OLDINT06_VEC.VSEG,es ; ...

	 SETINT  06h,INT06	; Install our own Invalid Opcode handler

; Determine system type of XT, Micro Channel, or other

	 call	 CHECK_SYSID	; Check on it

	 mov	 ax,cs		; Setup ES again
	 mov	 es,ax		; ...for data references
	 assume  es:PGROUP	; Tell the assembler about it

; Save contents of memory to use as reset stack

	 push	 ds		; Save for a moment

	 lds	 si,RESETSTK_VEC ; DS:SI ==> top of reset stack
	 assume  ds:nothing	; Tell the assembler about it

	 sub	 si,size RESETSTK_OLD ; Back off to start

	 lea	 di,RESETSTK_OLD ; ES:DI ==> local save area
	 mov	 cx,length RESETSTK_OLD ; CX = # words in ...
     rep movs	 RESETSTK_OLD[di],ds:[si].ELO ; Copy contents to local save area

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

; Ensure A20 is disabled in order to force INT 06h exception
; unless we're in Virtual 8086 Mode or there's no FTB

	 cli			; Nobody move

	 test	 LCL_FLAG,@LCL_XFTB ; Izit no FTB?
	 jnz	 short @F	; Jump if so

	 call	 DEGATEA20	; Disable address line A20
	 jc	 near ptr ID386_NOA20 ; Jump if unable to disable
@@:

; Save value for the master and slave IMRs and disable both IMRs

	 call	 DISABLE_IMR	; Disable 'em

; Find INT xxh instruction in ROM at F000:E000 or above

	 call	 SET_ROMINT	; Put ROM INT instruction into IO_ROM_VEC

; Disable watchdog timer in case present

	 call	 DISABLE_WDT	; Disable it

; Save value of shutdown byte

	 mov	 al,@CMOS_SHUT	; Get index of shutdown byte (NMI enabled)
	 out	 @CMOS_CMD,al	; Tell it what index we're programming
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Get from CMOS
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 mov	 SHUT_ORIG,al	; Save to restore later

; Shutdown via type 0Ah first to reduce the chances that the BIOS will
; step on DX before we get to tuck it away.

; Set type 0Ah shutdown address

	 mov	 ROMINT_PTR,offset PGROUP:SHUT0A ; Set shutdown offset

	 mov	 ax,seg BIOSDATA ; Get the BIOS data segment
	 mov	 ds,ax		; Address it
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 test	 LCL_FLAG,@LCL_ROMINT ; Did we find ROM INT instruction?
	 jnz	 short @F	; Jump if so

	 mov	 IO_ROM_VEC.VOFF,offset PGROUP:SHUT0A ; Set shutdown offset
	 mov	 IO_ROM_VEC.VSEG,cs ; ...and segment
@@:

; Set shutdown flag 0Ah (JMP Dword ptr ... without interrupt initialization)
; Note interrupts still disabled

	 mov	 al,@CMOS_SHUT	; Get index of shutdown byte (NMI enabled)
	 out	 @CMOS_CMD,al	; Tell it what index we're programming
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 al,0Ah 	; Shutdown type
	 out	 @CMOS_DATA,al	; Put into CMOS
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 call	 DISABLE_NMI	; Disable NMI

; Shutdown the processor -- note that this method might not work if we're
; in Virtual 8086 Mode and that handler traps system shutdown through
; this I/O port.

	 jmp	 SHUTDOWN	; Shutdown the processor


; Return from type 0Ah shutdown here
; Note interrupts still disabled

	 public  SHUT0A
SHUT0A:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 lss	 sp,LCLSTKZ_VEC ; Switch to local stack
	 assume  ss:nothing	; Tell the assembler about it

	 mov	 ax,cs		; Setup DS for data references
	 mov	 ds,ax		; ...
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 COMPID_S0A,dx	; Save component ID (if it wasn't
				; clobbered by BIOS)

; Now shutdown via type 05h to get the 8259 re-initialized.

; Set type 05h shutdown address

	 mov	 ROMINT_PTR,offset PGROUP:SHUT05 ; Set shutdown offset

	 mov	 ax,seg BIOSDATA ; Get the BIOS data segment
	 mov	 ds,ax		; Address it
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 test	 LCL_FLAG,@LCL_ROMINT ; Did we find ROM INT instruction?
	 jnz	 short @F	; Jump if so

	 mov	 IO_ROM_VEC.VOFF,offset PGROUP:SHUT05 ; Set shutdown offset
	 mov	 IO_ROM_VEC.VSEG,cs ; ...and segment
@@:

; Set shutdown flag 05h (JMP Dword ptr ... with interrupt initialization)
; Note interrupts still disabled

	 mov	 al,@CMOS_SHUT or @CMOS_NMIOFF ; Get index of shutdown byte (NMI disabled)
	 out	 @CMOS_CMD,al	; Tell it what index we're programming
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 al,05h 	; Shutdown type
	 out	 @CMOS_DATA,al	; Put into CMOS
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

; Shutdown the processor

	 jmp	 SHUTDOWN	; Shutdown the processor


; Return from type 05h shutdown here
; Note interrupts still disabled

	 public  SHUT05
SHUT05:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 lss	 sp,LCLSTKZ_VEC ; Switch to local stack
	 assume  ss:nothing	; Tell the assembler about it

	 mov	 ax,cs		; Setup DS for data references
	 mov	 ds,ax		; ...
	 assume  ds:PGROUP	; Tell the assembler about it

; Restore original ROMINT address

	 test	 LCL_FLAG,@LCL_ROMINT ; Izit in effect?
	 jz	 short @F	; Jump if not

	 xor	 ax,ax		; Get segment of interrupt vector table
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 movzx	 eax,ROMINT_NUM ; Get the interrupt #
	 mov	 ebx,ROMINT_VEC ; Get the original interrupt handler
	 mov	 es:[eax*4],ebx ; Restore
@@:

; Restore shutdown byte to original value

	 mov	 al,@CMOS_SHUT or @CMOS_NMIOFF ; Get index of shutdown byte (NMI disabled)
	 out	 @CMOS_CMD,al	; Tell it what index we're programming
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 al,SHUT_ORIG	; Get original value
	 out	 @CMOS_DATA,al	; Put into CMOS
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

; Restore original master and slave IMRs

	 call	 ENABLE_IMR	; Enable 'em
	 call	 ENABLE_NMI	; Enable NMI

; Restore contents of memory used as reset stack

	 mov	 ax,cs		; Setup DS for data references
	 mov	 ds,ax		; ...
	 assume  ds:PGROUP	; Tell the assembler about it

	 les	 di,RESETSTK_VEC ; ES:DI ==> top of reset stack
	 assume  es:nothing	; Tell the assembler about it

	 sub	 di,size RESETSTK_OLD ; Back off to start

	 lea	 si,RESETSTK_OLD ; DS:SI ==> local save area
	 mov	 cx,length RESETSTK_OLD ; CX = # words in ...
     rep movs	 es:[di].ELO,RESETSTK_OLD[si] ; Copy contents from local save area

	 sti			; Allow interrupts

; Restore original debug registers

	 mov	 eax,OLDDR0	; Get original value
	 mov	 dr0,eax	; Restore

	 mov	 eax,OLDDR1	; Get original value
	 mov	 dr1,eax	; Restore

	 mov	 eax,OLDDR2	; Get original value
	 mov	 dr2,eax	; Restore

	 mov	 eax,OLDDR3	; Get original value
	 mov	 dr3,eax	; Restore

	 mov	 eax,OLDDR6	; Get original value
	 mov	 dr6,eax	; Restore

	 mov	 eax,OLDDR7	; Get original value
	 mov	 dr7,eax	; Restore

; Restore original INT 06h handler

	 lds	 dx,OLDINT06_VEC ; DS:DX ==> previous handler
	 assume  ds:nothing	; Tell the assembler about it

	 SETINT  06h		; Restore old INT 06h handler

	 mov	 ax,cs		; Setup DS for data references
	 mov	 ds,ax		; ...
	 assume  ds:PGROUP	; Tell the assembler about it

;;;;;;;; mov	 ax,cs		; Setup ES for data references
	 mov	 es,ax		; ...
	 assume  es:PGROUP	; Tell the assembler about it

; Give the keyboard a kick in the pants (some BIOSs leave it disabled)

	 mov	 ah,@S2K_ENABLE ; Enable command
	 call	 PPI_S2K_K2S	; Send command AH to keyboard, response in AL
				; Ignore error return

; Display the component identifier

	 mov	 ax,COMPID_S0A	; Check value on returned from shutdown
	 lea	 di,MSG_OKID1	; ES:DI ==> output area
	 call	 FMT_WORD	; Convert the word in AX to hex at ES:DI

	 STROUT  MSG_OKID	; Display the chip ID
	 STROUT  MSG_SHUT0A	; ...from shutdown type 0Ah

	 test	 LCL_FLAG,@LCL_I06 ; Was INT 06h invoked?
	 jz	 short ID386_NOINT06  ; Jump if not

	 mov	 ax,COMPID_I06	; Check value returned from INT 06h handler
	 lea	 di,MSG_OKID1	; ES:DI ==> output area
	 call	 FMT_WORD	; Convert the word in AX to hex at ES:DI

	 STROUT  MSG_OKID	; Display the chip ID

	 lea	 di,MSG_INT06SEG ; ES:DI ==> save area
	 mov	 ax,INT06_PTR.VSEG ; Get INT 06h caller's segment
	 call	 FMT_WORD	; Convert the word in AX to hex at ES:DI

	 lea	 di,MSG_INT06OFF ; ES:DI ==> save area
	 mov	 ax,INT06_PTR.VOFF ; Get INT 06h caller's offset
	 call	 FMT_WORD	; Convert the word in AX to hex at ES:DI

	 STROUT  MSG_INT06	; The information came from INT 06h handler
ID386_NOINT06:
	 test	 LCL_FLAG,@LCL_CPU ; Get anything from the CPU?
	 jz	 short @F	; Jump if not

	 mov	 ax,COMPID_CPU	; Check value returned from CPU
	 lea	 di,MSG_OKID1	; ES:DI ==> output area
	 call	 FMT_WORD	; Convert the word in AX to hex at ES:DI

	 STROUT  MSG_OKID	; Display the chip ID
	 STROUT  MSG_CPU	; The information came from the CPU
@@:
	 test	 LCL_FLAG,@LCL_BIOS ; Get anything from the BIOS?
	 jz	 short @F	; Jump if not

	 mov	 ax,COMPID_BIOS ; Check value returned from BIOS
	 lea	 di,MSG_OKID1	; ES:DI ==> output area
	 call	 FMT_WORD	; Convert the word in AX to hex at ES:DI

	 STROUT  MSG_OKID	; Display the chip ID
	 STROUT  MSG_BIOS	; The information came from the BIOS
@@:
	 jmp	 short ID386_EXIT ; Join common exit code

ID386_NOA20:
	 STROUT  MSG_NOA20	; Tell 'em the bad news
ID386_EXIT:
	 mov	 ax,4C00h	; Return to DOS with zero return code
	 int	 21h		; Request DOS service

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ID386	 endp			; End ID386 procedure
	 NPPROC  CHECK_SYSID -- Check on System Identity
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on system identity of XT, Micro Channel, or other.

|

	 REGSAVE <ax,bx,es>	; Save registers

; Determine whether or not the system is an XT

	 mov	 ax,seg BIOS_SEG ; Get segment of BIOS (w/system ID)
	 mov	 es,ax		; Address it
	 assume  es:BIOS_SEG	; Tell the assembler about it

	 mov	 al,SYSID	; Get the system ID

	 cmp	 al,@SYS_PC	; Izit an original PC?
	 je	 short CHECK_SYSID_XT ; Yes, treat as an XT

	 cmp	 al,@SYS_XT	; Izit an original XT?
	 je	 short CHECK_SYSID_XT ; Yes, treat as an XT

	 cmp	 al,@SYS_XT2	; Izit an original XT/2?
	 jne	 short CHECK_SYSID_MC ; Jump if not
CHECK_SYSID_XT:
	 or	 LCL_FLAG,@LCL_XT ; Mark as an XT

	 mov	 NMIPORT,0A0h	; NMI clear I/O port
	 mov	 NMIENA,80h	; ... enable value
	 mov	 NMIDIS,00h	; ... disable value
	 mov	 NMIMASK,mask $XTPAR ; ... clear mask

	 jmp	 short CHECK_SYSID_EXIT ; Join common exit code

CHECK_SYSID_MC:
	 mov	 ah,0C0h	; Get code for BIOS configuration
	 int	 15h		; Request BIOS services
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_SYSID_NOMC ; Jump if function not available

	 cmp	 ah,0		; Ensure correct return code
	 jne	 short CHECK_SYSID_NOMC ; Jump if not

	 test	 es:[bx].CFG_PARMS,@CFG_MCA ; Izit Micro Channel?
	 jz	 short CHECK_SYSID_NOMC ; Jump if not

	 or	 LCL_FLAG,@LCL_MC ; Mark as Micro Channel
CHECK_SYSID_NOMC:
CHECK_SYSID_EXIT:
	 REGREST <es,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SYSID endp		; End CHECK_SYSID procedure
	 FPPROC  INT06 -- Invalid Opcode Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Invalid opcode handler (INT 06h).

Save the value of DX, re-enable A20, and reset the system.

Note that SS = 0 upon entry from the reset.
SP technically is undefined, but we expect it to be set to zero
from just before the reset which is why RESETSTK_VEC.VOFF is zero.

|

INT06_STR struc

INT06_IP dw	 ?		; Caller's IP
INT06_CS dw	 ?		; ...	   CS
INT06_FL dw	 ?		; ...	   FL

INT06_STR ends

	 mov	 bp,sp		; Address the stack

	 mov	 ax,cs		; Setup DS for data references
	 mov	 ds,ax		; ...
	 assume  ds:PGROUP	; Tell the assembler about it

	 bts	 LCL_FLAG,$LCL_I06 ; Mark as saved
	 jc	 short INT06_IRET ; Jump if we've been here before

	 mov	 COMPID_I06,dx	; Save component ID

	 mov	 ax,[bp].INT06_IP ; Get caller's IP
	 mov	 INT06_PTR.VOFF,ax ; Save for later use

	 mov	 ax,[bp].INT06_CS ; Get caller's CS
	 mov	 INT06_PTR.VSEG,ax ; Save for later use

	 lss	 sp,LCLSTKZ_VEC ; Switch to local stack
	 assume  ss:nothing	; Tell the assembler about it

	 call	 GATEA20	; Enable address line A20
				; for extended memory access
				; Ignore error return

	 jmp	 SHUTDOWN	; Shutdown the processor

INT06_IRET:
	 iret			; Try again at F000:FFF0

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT06	 endp			; End INT06 procedure
	 FPPROC  INT23 -- Ctrl-Break Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ctrl-break interrupt handler.
Avoid user breaking out during critical sections.

|

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT23	 endp			; End INT23 procedure
	 NPPROC  CHECK_CPUTYP -- Check On CPU Identifier
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're running on an 386 or later processor.
Note we must use only 8088 instructions here as well
as on return if CF=1.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,dx>	; Save registers

; Distinguish 286 and later processors
; These CPUs handle PUSH SP differently from the earlier CPUs

	 push	 sp		; First test for earlier than a 286
	 pop	 ax

	 cmp	 ax,sp		; Same value?
	 jne	 short CHECK_CPUTYP_ERR ; No, it's too early

; Now distinguish 286 from 386/486
; Note that a 286 processor does not allow the IOPL bits to be set
; in the flags register from real mode

	 pushf			; Save flags for a moment

	 push	 mask $IOPL	; Place IOPL bits onto the stack
	 popf			; ...and then into flags

	 pushf			; Get flags back
	 pop	 ax

	 popf			; Restore original flags

	 test	 ax,mask $IOPL	; Any bits set?
	 jnz	 short CHECK_CPUTYP_EXIT ; Yes, so continue on (note CF=0)
CHECK_CPUTYP_ERR:
	 STROUT  MSG_NOT386	; Tell 'em the bad news

	 stc			; Indicate we have a problem
CHECK_CPUTYP_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPUTYP endp		; End CHECK_CPUTYP procedure
	 NPPROC  CHECK_FTB -- Check for Fully-terminated Bus
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for fully-terminated bus at 4GB - 1MB - 16; that is,
read in the first two bytes there and ensure that it's FF FF.
If not, then the trick of resetting the system with A20 disabled
will crash the system as we're relying upon generating an invalid
opcode.

On exit:

CF	 =	 1 if not fully-terminated
	 =	 0 if OK

|

	 REGSAVE <eax,ecx,si>	; Save registers

; Set up GDT entry for BIOS block move

	 mov	 eax,0FFEFFFF0h ; Get source base value
	 mov	 ecx,2-1	; ...	     limit in bytes
	 lea	 si,MOVE_TAB.MDTE_DS ; ES:SI ==> GDT entry
	 call	 SET_GDT	; Set GDT entry ES:SI to base EAX, limit ECX

; Setup BIOS block move destin DTE

	 xor	 eax,eax	; Clear entire register
	 mov	 ax,cs		; Copy current segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,offset PGROUP:TOPMEM ; Plus offset of low memory destin
				; Use same previous limit
	 lea	 si,MOVE_TAB.MDTE_ES ; ES:SI ==> GDT entry
	 call	 SET_GDT	; Set GDT entry ES:SI to base EAX, limit ECX

; Perform the BIOS block move several times to ensure it's fully-terminated

	 mov	 cx,5		; An arbitrary count
CHECK_FTB_NEXT:
	 mov	 TOPMEM,0	; Put non-FFFF value there

	 push	 cx		; Save for a moment

	 lea	 si,MOVE_TAB	; ES:SI ==> block move descriptor tables
	 mov	 cx,1		; CX = # words to move
	 mov	 ah,87h 	; Function to move data to/from ext mem
	 int	 15h		; Request BIOS service

	 pop	 cx		; Restore

; As some BIOSes don't bother setting AH to zero upon successful return
; we don't bother checking it.  Instead, we test the data in TOPMEM; if
; it's FF FF, that's good enough for me.

	 cmp	 TOPMEM,0FFFFh	; Izit fully-terminated bus?
	 jne	 short CHECK_FTB_EXIT ; Jump if not (note CF=1)

	 loop	 CHECK_FTB_NEXT ; Jump if more checks
				; Fall through if done (note CF=0)
CHECK_FTB_EXIT:
	 REGREST <si,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_FTB endp			; End CHECK_FTB procedure
	 NPPROC  SHUTDOWN -- Shutdown the Processor
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Shutdown the processor.

|

	 lss	 sp,RESETSTK_VEC ; SS:SP ==> safe area for stack pushes
	 assume  ss:nothing	; Tell the assembler about it

	 cli			; Ensure nobody interrupts us

	 mov	 al,@S2C_SHUT	; Shutdown by pulsing 8042 bits low
	 out	 @8042_ST,al	; Bye

	 hlt			; Stop the presses

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SHUTDOWN endp			; End SHUTDOWN procedure
	 NPPROC  FMT_WORD -- Format AX to Hex at ES:DI
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AX to hex at ES:DI

On entry:

AX	 =	 word to format
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 (updated)

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 lea	 bx,HEXTABLE	; DS:BX ==> translate table
	 mov	 cx,4		; # hex digits in a word
	 mov	 dx,ax		; Copy to test
FMT_WORD1:
	 rol	 dx,4		; Copy the high-order digit
	 mov	 al,dl		; Copy to XLAT register
	 and	 al,0Fh 	; Isolate hex digit
	 xlat	 HEXTABLE[bx]	; Translate to ASCII
	 stos	 es:[di].LO	; Save into output area

	 loop	 FMT_WORD1	; Jump if more digits to convert

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_WORD endp			; End FMT_WORD procedure
	 NPPROC  ENABLE_IMR -- Enable the 8259 Interrupt Mask Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable the 8259 interrupt mask register

|

	 REGSAVE <ax>		; Save register

	 mov	 al,INTA01	; Get original master interrupt mask
	 out	 @IMR,al	; Reset in master 8259

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jnz	 short ENABLE_IMR_EXIT ; Yes, so there's no slave controller

	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 al,INTB01	; Get original slave interrupt mask
	 out	 @IMR2,al	; Reset in slave 8259
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
ENABLE_IMR_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_IMR endp 		; End ENABLE_IMR procedure
	 NPPROC  DISABLE_IMR -- Disable the 8259 Interrupt Mask Register
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable the 8259 interrupt mask register

This routine is called from real mode only.

|

	 REGSAVE <ax>		; Save register

	 in	 al,@IMR	; Get current value
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 INTA01,al	; Save to restore later

	 mov	 al,0FFh	; Disable all interrupts
	 out	 @IMR,al	; Send to 8259

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jnz	 short DISABLE_IMR_EXIT ; Yes, so there's no slave controller

	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@IMR2	; Get current value
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 INTB01,al	; Save to restore later

	 mov	 al,0FFh	; Disable all interrupts
	 out	 @IMR2,al	; Reset in slave 8259
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
DISABLE_IMR_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_IMR endp		; End DISABLE_IMR procedure
	 NPPROC  OUTCMOS -- Out To CMOS, Conditional Read
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Out to CMOS, conditional read.

Note that this routine is bimodal.

This routine should not be interrupted between the OUT and IN.

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 out	 dx,al		; Send to CMOS

	 cmp	 dx,@CMOS_CMD	; Izit an AT?
	 jne	 short @F	; Jump if not

	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Ensure OUT is followed by IN
@@:
	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OUTCMOS  endp			; End OUTCMOS procedure
	 NPPROC  ENABLE_NMI -- Enable NMI, Clear Parity Latches
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable NMI, clear parity latches.

Note that this routine is bimodal.

|

	 pushf			; Save flags
	 cli			; Ensure interrupts disabled

	 REGSAVE <ax,dx>	; Save for a moment

; Clear the parity latches

	 call	 CLR_PARITY	; Clear any parity errors

; Enable the NMI latch

	 mov	 dx,NMIPORT	; Get NMI clear I/O port
	 mov	 al,NMIENA	; ...	  enable value
	 call	 OUTCMOS	; Out to CMOS, conditional read

	 REGREST <dx,ax>	; Restore
	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_NMI endp 		; End ENABLE_NMI procedure
	 NPPROC  DISABLE_NMI -- Disable NMI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable NMI

Note that this routine is bimodal.

|

	 pushf			; Save flags
	 cli			; Ensure interrupts disabled

	 REGSAVE <ax,dx>	; Save for a moment

; Disable NMI

	 mov	 dx,NMIPORT	; Get NMI clear I/O port
	 mov	 al,NMIDIS	; ...	  disable value
	 call	 OUTCMOS	; Out to CMOS, conditional read

	 REGREST <dx,ax>	; Restore
	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_NMI endp		; End DISABLE_NMI procedure
	 NPPROC  CLR_PARITY -- Clear Parity Latches
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the parity latches

Note that this routine is bimodal.

|

	 REGSAVE <ax>		; Save register

	 mov	 ah,NMIMASK	; Get parity mask
	 in	 al,@8255_B	; Get the parity latches
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 or	 al,ah		; Toggle parity check latches off
	 out	 @8255_B,al	; Tell the system about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 xor	 al,ah		; Toggle parity check latches on
	 out	 @8255_B,al	; Tell the system about it
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLR_PARITY endp 		; End CLR_PARITY procedure
	 NPPROC  DISABLE_WDT -- Disable Watchdog Timer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable watchdog timer.
Unfortunately, there is no documented way of saving the current state
and restoring it later.

|

	 REGSAVE <ax>		; Save register

	 mov	 ax,0C300h	; Get major/minor function code to disable
	 int	 15h		; Request BIOS service

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_WDT endp		; End DISABLE_WDT procedure
	 NPPROC  SET_GDT -- Set GDT Entry
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set GDT entry.

On entry:

ES:SI	 ==>	 GDT entry to set
EAX	 =	 base value
ECX	 =	 limit and flags

|

	 mov	 es:[si].DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 es:[si].DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 es:[si].DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 es:[si].DESC_SEGLM1,cl ; Save size & flags
	 ror	 ecx,16 	; Swap back
	 mov	 es:[si].DESC_ACCESS,CPL0_DATA

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_GDT  endp			; End SET_GDT procedure
	 FPPROC  ROMINT_FN -- Local ROM INT Instruction Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local ROM INT instruction routine

|

	 jmp	 ROMINT_PTR	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMINT_FN endp			; End ROMINT_FN procedure
	 NPPROC  SET_ROMINT -- Put ROM INT Instruction Into IO_ROM_VEC
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find INT xxh in ROM at F000:E000 or higher and put its
address into IO_ROM_VEC.

We use this artifice as there are BIOSes which don't implement the
IO_ROM_VEC mechanism properly and use a JMP Near Ptr IO_ROM_VEC
instead of JMP Far Ptr IO_ROM_VEC.  Thus by finding an INT instruction
within the same segment as the BIOS, the error of using a mistaken
near jump vs. the correct far jump is eliminated.

If we don't find a suitable INT instruction, we can only hope that the
system BIOS works correctly.

|

	 REGSAVE <eax,ecx,di,es> ; Save registers

	 mov	 ax,seg BIOS_SEG ; Get segment of BIOS
	 mov	 es,ax		; Address it
	 assume  es:BIOS_SEG	; Tell the assembler about it

	 mov	 di,0E000h	; Start here as some BIOSes might be cached
				; below this point
	 mov	 cx,di		; Get starting address
	 neg	 cx		; Subtract from 64KB to get remaining length
	 sub	 cx,16		; Less last paragraph in case it's cached
SET_ROMINT_NEXT:
	 jcxz	 SET_ROMINT_ERR ; Jump if nothing remains
	 mov	 al,@OPCOD_INT	; Get opcode for INT instruction
   repne scas	 es:[di].LO	; Search for it
	 jne	 short SET_ROMINT_ERR ; Jump if not found

	 movzx	 eax,es:[di].LO ; Get the interrupt #, and
				; zero extend to use as dword

; Filter out ones we don't want to mess with

	 cmp	 al,01h 	; Izit single-step?
	 je	 short SET_ROMINT_NEXT ; Jump if so

	 cmp	 al,03h 	; Izit single-skip?
	 je	 short SET_ROMINT_NEXT ; Jump if so

	 cmp	 al,06h 	; Izit invalid opcode?
	 je	 short SET_ROMINT_NEXT ; Jump if so

	 cmp	 al,08h 	; Izit below master PIC base?
	 jb	 short @F	; Jump if so

	 cmp	 al,08h+8	; Izit below master PIC end?
	 jb	 short SET_ROMINT_NEXT ; Jump if so
@@:
	 cmp	 al,70h 	; Izit below slave PIC base?
	 jb	 short @F	; Jump if so

	 cmp	 al,70h+8	; Izit below slave PIC end?
	 jb	 short SET_ROMINT_NEXT ; Jump if so
@@:
	 xor	 cx,cx		; Get segment of interrupt vector table
	 mov	 es,cx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ROMINT_NUM,al	; Save for later use
	 mov	 cx,cs		; Get our code segment
	 shl	 ecx,16 	; Shift to high-order word
	 lea	 cx,ROMINT_FN	; Get offset of local handler
	 xchg	 ecx,es:[eax*4] ; Swap 'em
	 mov	 ROMINT_VEC,ecx ; Save to restore later

	 mov	 ax,seg BIOSDATA ; Get the BIOS data segment
	 mov	 es,ax		; Address it
	 assume  es:BIOSDATA	; Tell the assembler about it

	 dec	 di		; Point back to INT instruction
	 mov	 IO_ROM_VEC.VOFF,di ; Set shutdown offset
	 mov	 IO_ROM_VEC.VSEG,seg BIOS_SEG ; ...and segment

	 or	 LCL_FLAG,@LCL_ROMINT ; Mark as found
SET_ROMINT_ERR:
	 REGREST <es,di,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_ROMINT endp 		; End SET_ROMINT procedure
	 NPPROC  IZIT_CPUID -- Determine Support of CPUID Instruction
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The test for the CPUID instruction is done by attempting to set the ID
bit in the high-order word of the extended flag dword.	If that's
successful, the CPUID instruction is supported; otherwise, it's not.

On exit:

CF	 =	 1 if it's supported
	 =	 0 otherwise

|

	 push	 bp		; Save to address the stack
	 clc			; Assume it's not supported
	 pushfd 		; Save original flags
	 pushfd 		; Save temporary flags

IZIT_CPUID_STR struc

IZIT_CPUID_TMPEFL dd ?		; Temporary EFL
IZIT_CPUID_RETEFL dd ?		; Return EFL
	 dw	 ?		; Caller's BP

IZIT_CPUID_STR ends

	 mov	 bp,sp		; Address the stack
	 or	 [bp].IZIT_CPUID_TMPEFL,mask $ID ; Set ID bit
	 popfd			; Put into effect

	 pushfd 		; Put back onto the stack to test

	 test	 [bp].IZIT_CPUID_TMPEFL,mask $ID ; Izit still set?
	 jz	 short @F	; No, so it's not supported

	 or	 [bp].IZIT_CPUID_RETEFL,mask $CF ; Indicate it's supported
@@:
	 popfd			; Restore temporary flags
	 popfd			; Restore original flags
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_CPUID endp 		; End IZIT_CPUID procedure

CODE	 ends			; End CODE segment

	 MEND	 ID386		; End 386ID module
