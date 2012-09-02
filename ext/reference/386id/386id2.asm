	 title	 ID386PPI -- PPI Subroutines to 386ID
	 page	 58,122
	 name	 ID386PPI

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-94 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Program segment CODE,  word-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'

Original code by:  Bob Smith, November, 1987.

|

.386
.xlist
	 include MISC.INC
.list


PGROUP	 group	 CODE,DATA


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 LCL_FLAG:word
	 include ID3_LCL.INC

	 extrn	 XMSDRV_VEC:dword

@XMS_LCLENA equ  05h		; Local Enable A20
@XMS_LCLDIS equ  06h		; Local Disable A20

ACTA20_STR struc

ACTA20_MC  dw	 ?
ACTA20_ISA dw	 ?
ACTA20_XMS dw	 ?

ACTA20_STR ends

	 public  ACTA20_ENA
ACTA20_ENA ACTA20_STR <PGROUP:A20ENA_MC,PGROUP:A20ENA_ISA,PGROUP:A20ENA_XMS>

	 public  ACTA20_DIS
ACTA20_DIS ACTA20_STR <PGROUP:A20DIS_MC,PGROUP:A20DIS_ISA,PGROUP:A20DIS_XMS>

DATA	 ends			; End DATA segment


CODE	 segment use16 word public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 NPPROC  A20ENA_MC -- A20 Enable for MC Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for Micro Channel Systems

On entry:

AL	 =	 @PS2_A port value

On exit:

AL	 =	 (updated to enable A20)

|

	 or	 al,mask $PS2_GATE ; Enable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_MC endp			; End A20ENA_MC procedure
	 NPPROC  A20ENA_ISA -- A20 Enable for ISA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for ISA

On entry:

AL	 =	 output port byte

On exit:

AL	 =	 (updated to enable A20)

|

	 or	 al,mask $S2O_OBFUL ; Ensure output buffer marked as full
	 or	 al,mask $S2O_GATE ; Enable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_ISA endp 		; End A20ENA_ISA procedure
	 NPPROC  A20ENA_XMS -- A20 Enable for XMS Drivers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for XMS drivers

On exit:

AH	 =	 XMS function code to enable A20

|

	 mov	 ah,@XMS_LCLENA ; Enable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_XMS endp 		; End A20ENA_XMS procedure
	 NPPROC  GATEA20 -- Enable Address Line A20
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable address line A20.
Different systems require different techniques.  Here we
differentiate MC systems from non-MC systems only.

On exit:

CF	 =	 0 if all went well
	 =	 1 if we couldn't enable A20

|

	 push	 bx		; Save register

	 lea	 bx,ACTA20_ENA	; CS:BX ==> enable A20 actions

	 jmp	 short ACTA20_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GATEA20  endp			; End GATEA20 procedure
	 NPPROC  A20DIS_MC -- A20 Disable for MC Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for Micro Channel systems

On entry:

AL	 =	 @PS2_A port value

On exit:

AL	 =	 (updated to disable A20)

|

	 and	 al,not (mask $PS2_GATE) ; Disable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_MC endp			; End A20DIS_MC procedure
	 NPPROC  A20DIS_ISA -- A20 Disable for ISA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for ISA

On entry:

AL	 =	 output port byte

On exit:

AL	 =	 (updated to disable A20)

|

	 or	 al,mask $S2O_OBFUL ; Ensure output buffer marked as full
	 and	 al,not (mask $S2O_GATE) ; Disable A20 gate

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_ISA endp 		; End A20DIS_ISA procedure
	 NPPROC  A20DIS_XMS -- A20 Disable for XMS Drivers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for XMS drivers

On exit:

AH	 =	 XMS function code to enable A20

|

	 mov	 ah,@XMS_LCLDIS ; Disable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_XMS endp 		; End A20DIS_XMS procedure
	 NPPROC  DEGATEA20 -- Disable Address Line A20
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable address line A20.
Different systems require different techniques.  Here we
differentiate MC systems from non-MC systems only.

On exit:

CF	 =	 0 if all went well
	 =	 1 if we couldn't disable A20

|

	 push	 bx		; Save register

	 lea	 bx,ACTA20_DIS	; CS:BX ==> disable A20 actions

	 jmp	 short ACTA20_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEGATEA20 endp			; End DEGATEA20 procedure
	 NPPROC  ACTA20_COM -- A20 Enable/Disable Common Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable/disable common routine
Different systems require different techniques.  Here we
differentiate MC systems from non-MC systems only.

On entry:

BX	 pushed onto stack
CS:BX	 ==>	 enable/disable action structure

|

	 push	 ax		; Save register

	 clc			; Assume all goes well
	 lahf			; Load AH with flags

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 cmp	 XMSDRV_VEC,0	; Is there an XMS driver?
	 jz	 short ACTA20_COM_NOXMS ; Not this time

	 call	 PGROUP:[bx].ACTA20_XMS ; Call common XMS action
	 call	 XMSDRV_VEC	; Request XMS service

	 jmp	 short ACTA20_COM_EXIT ; Join common exit code

ACTA20_COM_NOXMS:

	 test	 LCL_FLAG,@LCL_MC ; Izit an MC-compatible machine?
	 jz	 short ACTA20_COM_XMC ; Not this time

	 in	 al,@PS2_A	; Get system control port A
	 call	 PGROUP:[bx].ACTA20_MC ; Call common MC action
	 out	 @PS2_A,al	; Tell the system about it

	 jmp	 short ACTA20_COM_EXIT ; Join common exit code

ACTA20_COM_XMC:

; Write the output port byte

	 REGSAVE <ax>		; Save for a moment

; First, clear any pending scan code from the output buffer
; This might lose a keystroke

	 call	 WAITOBUF_CLR	; Wait for the output buffer to clear

	 mov	 ah,@S2C_ROUT	; Read output port byte command
	 call	 PPI_S2C_K2S	; Send AH to 8042, return with AL = response
	 jc	 short ACTA20_COM_ERR0 ; Jump if error (note CF=1)

	 call	 PGROUP:[bx].ACTA20_ISA ; Call common ISA action
	 mov	 ah,@S2C_WOUT	; Write output port byte
	 call	 PPI_S2C_S2K	; Write command AH, data AL to 8042
	 jc	 short ACTA20_COM_ERR0 ; Jump if error (note CF=1)

	 call	 PULSE8042	; Pulse the 8042 to ensure A20 toggle done
				; Return with CF significant
ACTA20_COM_ERR0:
	 pushf			; Save previous flags

; Last, enable the keyboard

	 mov	 ah,@S2C_ENA	; Enable the keyboard
	 call	 PPI_S2C	; Send command AH to 8042
				; Ignore error return
	 popf			; Restore previous flags
ACTA20_COM_ERR1:
	 REGREST <ax>		; Restore
ACTA20_COM_ERR:
	 adc	 ah,0		; Set CF in AH image of flags as necessary
ACTA20_COM_EXIT:
	 popf			; Restore flags

	 sahf			; Store AH into flags

	 pop	 ax		; Restore

	 pop	 bx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACTA20_COM endp 		; End ACTA20_COM procedure
	 NPPROC  PPI_S2C -- PPI System to Controller
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller.
Send a command to the controller (8042).

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Wait for the input buffer to clear to avoid overrun.
2.  Send the command in AH to the keyboard controller port 64h.
    There is no acknowledgement of this command.

On entry:

AH	 =	 command
IF	 =	 0

On exit:

CF	 =	 1 if keyboard controller not responding
	 =	 0 otherwise

|

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short @F	; Error, controller not reading data (note CF=1)

	 xchg	 al,ah		; Swap to put command in AL
	 out	 @8042_ST,al	; Send the command
	 xchg	 al,ah		; Restore
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2C  endp			; End PPI_S2C procedure
	 NPPROC  PPI_S2C_K2S -- PPI System to Controller, Keyboard to System
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller, Keyboard to System
Send a command to the controller (8042), wait for a response.

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Send the command to the 8042.
2.  Wait for the output buffer to fill.
3.  Read the response.

Note that resend does not occur with the controller (8042)
(although it can with the keyboard (6805)).

On entry:

AH	 =	 S2C command
IF	 =	 0

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

AL	 =	 byte read (if CF=0)

|

	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short @F	; Jump if something went wrong (note CF=1)

	 call	 PPI_K2S	; Wait for a response, returned in AL
				; Return with CF significant
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2C_K2S endp		; End PPI_S2C_K2S procedure
	 NPPROC  PPI_S2C_S2K -- PPI System to Controller, System to Keyboard
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller, System to Keyboard.

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Send the command to the 8042.
2.  Send the data to the 8042.

On entry:

AH	 =	 S2C command
AL	 =	 byte to send
IF	 =	 0

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short PPI_S2C_S2K_EXIT ; Jump if something went wrong (note CF=1)

	 out	 @8255_A,al	; Send data AL to 8042
PPI_S2C_S2K_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2C_S2K endp		; End PPI_S2C_S2K procedure
	 NPPROC  PPI_K2S -- PPI Keyboard to System
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI Keyboard to System.
Wait for a response from the keyboard or its controller.

On entry:

IF	 =	 0

On exit:

CF	 =	 1 if no response
	 =	 0 otherwise

AL	 =	 response if CF=0

|

	 call	 WAITOBUF_SET	; Wait for the output buffer to fill
	 jc	 short @F	; Jump if no timely response (note CF=1)

	 in	 al,@8255_A	; Read in the code
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_K2S  endp			; End PPI_K2S procedure
	 NPPROC  PPI_S2K -- PPI System to Keyboard
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Keyboard.
Send command to keyboard.

1.  Wait for the input buffer to clear to avoid overrun.
2.  Send the command in AH to the keyboard port 60h.
    There is no acknowledgement of this command.

On entry:

AH	 =	 command to send
IF	 =	 0

On exit:

CF	 =	 1 if timeout
	 =	 0 otherwise

AL	 =	 keyboard response if CF=0

|

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short @F	; Error, controller not reading data (note CF=1)

	 xchg	 al,ah		; Swap to put command in AL
	 out	 @8255_A,al	; Issue the command
	 xchg	 al,ah		; Restore
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2K  endp			; End PPI_S2K procedure
	 NPPROC  PPI_S2K_K2S -- PPI System to Keyboard, Keyboard to System
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Keyboard, Keyboard to System.
Send command to keyboard (6805), wait for its response.

Note that it's the caller's responsibility to ensure that
the 6805 output buffer is clear.

1.  Send the command to the 6805.
2.  Wait for the output buffer to fill.
3.  Read the response.
4.  Check for resend.

On entry:

AH	 =	 command to send
IF	 =	 0

On exit:

CF	 =	 1 if timeout
	 =	 0 otherwise

AL	 =	 keyboard response if CF=0

|

	 push	 cx		; Save for a moment

	 mov	 cx,6		; # retries of resend (arbitrary value)
PPI_S2K_K2S_AGAIN:
	 call	 PPI_S2K	; Send command AH to 6805
	 jc	 short PPI_S2K_K2S_EXIT ; Jump if something went wrong (note CF=1)

	 call	 PPI_K2S	; Wait for a response, returned in AL
	 jc	 short PPI_S2K_K2S_EXIT ; Jump if something went wrong (note CF=1)

	 cmp	 al,@K2S_RESEND ; Izit a resend?
	 clc			; In case not
	 jne	 short PPI_S2K_K2S_EXIT ; Jump if not (note CF=0)

	 loop	 PPI_S2K_K2S_AGAIN ; Jump if more retries

	 stc			; Indicate something went wrong
PPI_S2K_K2S_EXIT:
	 pop	 cx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2K_K2S endp		; End PPI_S2K_K2S procedure
	 NPPROC  WAITIBUF_CLR -- Wait For The Input Buffer To Clear
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait for the one-byte input buffer to clear.

On entry:

IF	 =	 0

On exit:

CF	 =	 0 if buffer empty
	 =	 1 otherwise

|


	 REGSAVE <ax,cx>	; Save registers

	 mov	 ah,6		; Outer loop counter (arbitrary value)
	 xor	 cx,cx		; Inner loop counter (arbitrary value)
WAITIBUF_CLR1:
	 in	 al,@8042_ST	; Get status from keyboard

	 and	 al,mask $INPFULL ; Check Input Buffer Full flag
	 loopnz  WAITIBUF_CLR1	; Last char not read as yet
	 jz	 short WAITIBUF_CLR_EXIT ; Jump if buffer clear (note CF=0)

	 dec	 ah		; One fewer time
	 jnz	 short WAITIBUF_CLR1 ; Go around again

	 stc			; Indicate something went wrong
WAITIBUF_CLR_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WAITIBUF_CLR endp		; End WAITIBUF_CLR procedure
	 NPPROC  WAITOBUF_CLR -- Wait For The Output Buffer To Clear
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait for the one-byte output buffer to clear.

On entry:

IF	 =	 0

|

	 push	 ax		; Save for a moment
WAITOBUF_CLR1:
	 in	 al,@8042_ST	; Get status from keyboard

	 and	 al,mask $OUTFULL ; Check Output Buffer Full flag
	 jz	 short WAITOBUF_CLR_EXIT ; Jump if buffer clear before

	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@8255_A	; Purge the character
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 jmp	 short WAITOBUF_CLR1 ; Go around again

WAITOBUF_CLR_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WAITOBUF_CLR endp		; End WAITOBUF_CLR procedure
	 NPPROC  WAITOBUF_SET -- Wait for Output Buffer Full
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait for the output buffer to fill.

On entry:

IF	 =	 0

On exit:

CF	 =	 1 if no response
	 =	 0 otherwise

|

	 REGSAVE <ax,cx>	; Save registers

; Wait for a response

	 mov	 ah,6		; Outer loop counter (arbitrary value)
	 xor	 cx,cx		; Inner loop counter (arbitrary value)
WAITOBUF_SET1:
	 in	 al,@8042_ST	; Get status from keyboard

	 and	 al,mask $OUTFULL ; Check Output Buffer Full flag
	 loopz	 WAITOBUF_SET1	; Jump if no response as yet
	 jnz	 short WAITOBUF_SET_EXIT ; Join common exit code (note CF=0)

	 dec	 ah		; One fewer time
	 jnz	 short WAITOBUF_SET1 ; Jump if more tries available

	 stc			; Indicate something went wrong
WAITOBUF_SET_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WAITOBUF_SET endp		; End WAITOBUF_SET procedure
	 NPPROC  PULSE8042 -- Pulse 8042
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Pulse the 8042 to ensure the last command has been accepted.
Typically (if needed at all), this is necssary after toggling A20
on an ISA bus machine.

|

; Pulse the controller to ensure the last 8042 command has been processed

	 push	 ax		; Save for a moment
	 mov	 ah,@S2C_RESET	; Ensure in a stable state
	 call	 PPI_S2C	; Send command AH to 8042
	 pop	 ax		; Restore
				; Return with CF significant
PULSE8042_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PULSE8042 endp			; End PULSE8042 procedure

CODE	 ends			; End CODE segment

	 MEND			; End 386ID2 module
