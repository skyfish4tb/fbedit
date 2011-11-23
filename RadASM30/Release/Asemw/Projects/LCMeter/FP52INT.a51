; This is a complete BCD floating point package for the 8051 micro-
; controller. It provides 8 digits of accuracy with exponents that
; range from +127 to -127. The mantissa is in packed BCD, while the
; exponent is expressed in pseudo-twos complement. A ZERO exponent
; is used to express the number ZERO. An exponent value of 80H or
; greater than means the exponent is positive, i.e. 80H = E 0,
; 81H = E+1, 82H = E+2 and so on. If the exponent is 7FH or less,
; the exponent is negative, 7FH = E-1, 7EH = E-2, and so on.
; ALL NUMBERS ARE ASSUMED TO BE NORMALIZED and all results are
; normalized after calculation. A normalized mantissa is >=.10 and
; <=.99999999.
;
; The numbers in memory assumed to be stored as follows:
;
; EXPONENT OF ARGUMENT 2   =   VALUE OF ARG_STACK+FP_NUMBER_SIZE
; SIGN OF ARGUMENT 2       =   VALUE OF ARG_STACK+FP_NUMBER_SIZE-1
; DIGIT 78 OF ARGUMENT 2   =   VALUE OF ARG_STACK+FP_NUMBER_SIZE-2
; DIGIT 56 OF ARGUMENT 2   =   VALUE OF ARG_STACK+FP_NUMBER_SIZE-3
; DIGIT 34 OF ARGUMENT 2   =   VALUE OF ARG_STACK+FP_NUMBER_SIZE-4
; DIGIT 12 OF ARGUMENT 2   =   VALUE OF ARG_STACK+FP_NUMBER_SIZE-5
;
; EXPONENT OF ARGUMENT 1   =   VALUE OF ARG_STACK
; SIGN OF ARGUMENT 1       =   VALUE OF ARG_STACK-1
; DIGIT 78 OF ARGUMENT 1   =   VALUE OF ARG_STACK-2
; DIGIT 56 OF ARGUMENT 1   =   VALUE OF ARG_STACK-3
; DIGIT 34 OF ARGUMENT 1   =   VALUE OF ARG_STACK-4
; DIGIT 12 OF ARGUMENT 1   =   VALUE OF ARG_STACK-5
;
; The operations are performed thusly:
;
; ARG_STACK+FP_NUMBER_SIZE = ARG_STACK+FP_NUMBER_SIZE # ARG_STACK
;
; Which is ARGUMENT 2 = ARGUMENT 2 # ARGUMENT 1
;
; Where # can be ADD, SUBTRACT, MULTIPLY OR DIVIDE.
;
; Note that the stack gets popped after an operation.
;
; The FP_COMP instruction POPS the ARG_STACK TWICE and returns status.
;
;**********************************************************************
;
;**********************************************************************
;
; STATUS ON RETURN - After performing an operation (+, -, *, /)
;                    the accumulator contains the following status
;
; ACCUMULATOR - BIT 0 - FLOATING POINT UNDERFLOW OCCURED
;
;             - BIT 1 - FLOATING POINT OVERFLOW OCCURED
;
;             - BIT 2 - RESULT WAS ZER0
;
;             - BIT 3 - DIVIDE BY ZERO ATTEMPTED
;
;             - BIT 4 - NOT USED, 0 RETURNED
;
;             - BIT 5 - NOT USED, 0 RETURNED
;
;             - BIT 6 - NOT USED, 0 RETURNED
;
;             - BIT 7 - NOT USED, 0 RETURNED
;
; NOTE: When underflow occures, a ZERO result is returned.
;       When overflow or divide by zero occures, a result of
;       .99999999 E+127 is returned and it is up to the user
;       to handle these conditions as needed in the program.
;
; NOTE: The Compare instruction returns F0 = 0 if ARG 1 = ARG 2
;       and returns a CARRY FLAG = 1 if ARG 1 is > ARG 2
;
;***********************************************************************
;

;$NOTABS                  ;expand tabs


CMP MACRO REGISTER,CONSTANT
CJNE	REGISTER,CONSTANT,$+3
ENDM
;***********************************************************************
;
; The following values MUST be provided by the user
;
;***********************************************************************
;
ARG_STACK		EQU	24H				;ARGUMENT STACK POINTER
FORMAT			EQU	25H				;LOCATION OF OUTPUT FORMAT BYTE
INTGRC			BIT	26H.1				;BIT SET IF INTEGER ERROR
ADD_IN			BIT	26H.3				;DCMPXZ IN BASIC BACKAGE
ZSURP			BIT	26H.6				;ZERO SUPRESSION FOR HEX PRINT
CONVT			EQU	27H				;String addr TO CONVERT NUMBERS
;
;***********************************************************************
;
; The following equates are used internally
;
;***********************************************************************
;
FP_NUMBER_SIZE		EQU	6
DIGIT			EQU	4
R0B0			EQU	0
R1B0			EQU	1
UNDERFLOW		EQU	0
OVERFLOW		EQU	1
ZERO			EQU	2
ZERO_DIVIDE		EQU	3
;
;***********************************************************************
	;**************************************************************
	;
	; The following internal locations are used by the math pack
	; ordering is important and the FP_DIGITS must be bit
	; addressable
	;
	;***************************************************************
	;
FP_STATUS		EQU	28H				;28 NOT used data pointer me
FP_TEMP			EQU	FP_STATUS+1			;29 NOT USED
FP_CARRY		EQU	FP_STATUS+2			;2A USED FOR BITS
FP_DIG12		EQU	FP_CARRY+1			;2B
FP_DIG34		EQU	FP_CARRY+2			;2C
FP_DIG56		EQU	FP_CARRY+3			;2D
FP_DIG78		EQU	FP_CARRY+4			;2E
FP_SIGN			EQU	FP_CARRY+5			;2F
FP_EXP			EQU	FP_CARRY+6			;30
MSIGN			BIT	FP_SIGN.0			;2F.0
XSIGN			BIT	FP_CARRY.0			;2A.0
FOUND_RADIX		BIT	FP_CARRY.1			;2A.1
FIRST_RADIX		BIT	FP_CARRY.2			;2A.2
DONE_LOAD		BIT	FP_CARRY.3			;2A.3
FP_NIB1			EQU	FP_DIG12			;2B
FP_NIB2			EQU	FP_NIB1+1			;2C
FP_NIB3			EQU	FP_NIB1+2			;2D
FP_NIB4			EQU	FP_NIB1+3			;2E
FP_NIB5			EQU	FP_NIB1+4			;2F
FP_NIB6			EQU	FP_NIB1+5			;30
FP_NIB7			EQU	FP_NIB1+6			;31
FP_NIB8			EQU	FP_NIB1+7			;32
FP_ACCX			EQU	FP_NIB1+8			;33
FP_ACCC			EQU	FP_NIB1+9			;34
FP_ACC1			EQU	FP_NIB1+10			;35
FP_ACC2			EQU	FP_NIB1+11			;36
FP_ACC3			EQU	FP_NIB1+12			;37
FP_ACC4			EQU	FP_NIB1+13			;38
FP_ACC5			EQU	FP_NIB1+14			;39
FP_ACC6			EQU	FP_NIB1+15			;3A
FP_ACC7			EQU	FP_NIB1+16			;3B
FP_ACC8			EQU	FP_NIB1+17			;3C
FP_ACCS			EQU	FP_NIB1+18			;3D


;			MOV	SP,#50H
;			MOV	24H,#07FH
;			MOV	25H,#044H
;
;			MOV	DPTR,#FPONE
;			ACALL	PUSHC
;			MOV	DPTR,#FPTWO
;			ACALL	PUSHC
;			ACALL	FLOATING_ADD
;
;
;			MOV	24H,#07FH
;			MOV	DPTR,#FPTHREE
;			ACALL	PUSHC
;			MOV	DPTR,#FPTWO
;			ACALL	PUSHC
;			ACALL	FLOATING_MUL
;			ACALL	FLOATING_POINT_OUTPUT
;			SJMP	$
;
;FP_BASE			EQU	$

	;**************************************************************
	;
	; The floating point entry points and jump table
	;
	;**************************************************************
	;
;			AJMP	FLOATING_ADD
;			AJMP	FLOATING_SUB
;			AJMP	FLOATING_COMP
;			AJMP	FLOATING_MUL
;			AJMP	FLOATING_DIV
;			AJMP	HEXSCAN
;			AJMP	FLOATING_POINT_INPUT
;			AJMP	FLOATING_POINT_OUTPUT
;			AJMP	MULNUM10
;			AJMP	HEXOUT
;			AJMP	PUSHAS				;PUSH R0 TO ARGUMENT
;			AJMP	POPAS				;POP ARGUMENT TO R1
;			AJMP	MOVAS				;COPY ARGUMENT TO R1
;			AJMP	AINT				;INT FUNCTION
;			AJMP	PUSHC				;PUSH ARG IN CODE MEM POINTED TO BY DPTR TO STACK

	;
	;IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
	;
FLOATING_INIT:
	;
	;IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
	;
			MOV	ARG_STACK,#FPSTACK
			RET

PRTERR:			RET
BADPRM:			RET

	;
	;
FLOATING_SUB:
	;
			MOV	R0,ARG_STACK
			DEC	R0				;POINT TO SIGN
			MOV	A,@R0				;READ SIGN
			CPL	ACC.0
			MOV	@R0,A
	;
	;AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	;
FLOATING_ADD:
	;
	;AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	;
	;
			ACALL 	MDES1				;R7=TOS EXP, R6=TOS-1 EXP, R4=TOS SIGN
								;R3=TOS-1 SIGN, OPERATION IS R1 # R0
	;
			MOV	A,R7				;GET TOS EXPONENT
			JZ	POP_AND_EXIT			;IF TOS=0 THEN POP AND EXIT
			CJNE	R6,#0,LOAD1			;CLEAR CARRY EXIT IF ZERO
	;
	;**************************************************************
	;
SWAP_AND_EXIT:							; Swap external args and return
	;
	;**************************************************************
	;
			ACALL	LOAD_POINTERS
			MOV	R7,#FP_NUMBER_SIZE
	;
SE1:			MOV	A,@R0				;SWAP THE ARGUMENTS
			MOV	@R1,A
			DEC	R0
			DEC	R1
			DJNZ	R7,SE1
	;
POP_AND_EXIT:
	;
			MOV	A,ARG_STACK			;POP THE STACK
			ADD	A,#FP_NUMBER_SIZE
			MOV	ARG_STACK,A
			CLR	A
			RET
	;
	;
LOAD1:			SUBB	A,R6				;A = ARG 1 EXP - ARG 2 EXP
			MOV	FP_EXP,R7			;SAVE EXPONENT AND SIGN
			MOV	FP_SIGN,R4
			JNC	LOAD2				;ARG1 EXPONENT IS LARGER OR SAME
			MOV	FP_EXP,R6
			MOV	FP_SIGN,R3
			CPL	A
			INC	A				;COMPENSATE FOR EXP DELTA
			XCH	A,R0				;FORCE R0 TO POINT AT THE LARGEST
			XCH	A,R1				;EXPONENT
			XCH	A,R0
	;
LOAD2:			MOV	R7,A				;SAVE THE EXPONENT DELTA IN R7
			CLR	ADD_IN
			CJNE	R5,#0,LOAD3
			SETB	ADD_IN
	;
	; Load the R1 mantissa
	;
LOAD3:			ACALL	LOADR1_MANTISSA			;LOAD THE SMALLEST NUMBER
	;
	; Now align the number to the delta exponent
	; R4 points to the string of the last digits lost
	;
			CMP	R7,#DIGIT+DIGIT+3
			JC	LOAD4
			MOV	R7,#DIGIT+DIGIT+2
	;
LOAD4:			MOV	FP_CARRY,#00			;CLEAR THE CARRY
			ACALL	RIGHT				;SHIFT THE NUMBER
	;
	; Set up for addition and subtraction
	;
			MOV	R7,#DIGIT			;LOOP COUNT
			MOV	R1,#FP_DIG78
			MOV	A,#9EH
			CLR	C
			SUBB	A,R4
			DA	A
			XCH	A,R4
			JNZ	LOAD5
			MOV	R4,A
LOAD5:			CMP	A,#50H				;TEST FOR SUBTRACTION
			JNB	ADD_IN,SUBLP			;DO SUBTRACTION IF NO ADD_IN
			CPL	C				;FLIP CARRY FOR ADDITION
			ACALL	ADDLP				;DO ADDITION
	;
			JNC	ADD_R
			INC	FP_CARRY
			MOV	R7,#1
			ACALL	RIGHT
			ACALL	INC_FP_EXP			;SHIFT AND BUMP EXPONENT
	;
ADD_R:			AJMP	STORE_ALIGN_TEST_AND_EXIT
	;
ADDLP:			MOV	A,@R0
			ADDC	A,@R1
			DA	A
			MOV	@R1,A
			DEC	R0
			DEC	R1
			DJNZ	R7,ADDLP			;LOOP UNTIL DONE
			RET
	;
	;
SUBLP:			MOV	A,@R0				;NOW DO SUBTRACTION
			MOV	R6,A
			CLR	A
			ADDC	A,#99H
			SUBB	A,@R1
			ADD	A,R6
			DA	A
			MOV	@R1,A
			DEC	R0
			DEC	R1
			DJNZ	R7,SUBLP
			JC	FSUB6
	;
	;
	; Need to complement the result and sign because the floating
	; point accumulator mantissa was larger than the external
	; memory and their signs were equal.
	;
			CPL	FP_SIGN.0
			MOV	R1,#FP_DIG78
			MOV	R7,#DIGIT			;LOOP COUNT
	;
FSUB5:			MOV	A,#9AH
			SUBB	A,@R1
			ADD	A,#0
			DA	A
			MOV	@R1,A
			DEC	R1
			CPL	C
			DJNZ	R7,FSUB5			;LOOP
	;
	; Now see how many zeros their are
	;
FSUB6:			MOV	R0,#FP_DIG12
			MOV	R7,#0
	;
FSUB7:			MOV	A,@R0
			JNZ	FSUB8
			INC	R7
			INC	R7
			INC	R0
			CJNE	R0,#FP_SIGN,FSUB7
			AJMP	ZERO_AND_EXIT
	;
FSUB8:			CMP	A,#10H
			JNC	FSUB9
			INC	R7
	;
	; Now R7 has the number of leading zeros in the FP ACC
	;
FSUB9:			MOV	A,FP_EXP			;GET THE OLD EXPONENT
			CLR	C
			SUBB	A,R7				;SUBTRACT FROM THE NUMBER OF ZEROS
			JZ	FSUB10
			JC	FSUB10
	;
			MOV	FP_EXP,A			;SAVE THE NEW EXPONENT
	;
			ACALL	LEFT1				;SHIFT THE FP ACC
			MOV	FP_CARRY,#0
			AJMP	STORE_ALIGN_TEST_AND_EXIT
	;
FSUB10:			AJMP	UNDERFLOW_AND_EXIT
	;
	;***************************************************************
	;
FLOATING_COMP:	; Compare two floating point numbers
		; used for relational operations and is faster
		; than subtraction. ON RETURN, The carry is set
		; if ARG1 is > ARG2, else carry is not set
		; if ARG1 = ARG2, F0 gets set
	;
	;***************************************************************
	;
			ACALL	MDES1				;SET UP THE REGISTERS
			MOV	A,ARG_STACK
			ADD	A,#FP_NUMBER_SIZE+FP_NUMBER_SIZE
			MOV	ARG_STACK,A			;POP THE STACK TWICE, CLEAR THE CARRY
			MOV	A,R6				;CHECK OUT EXPONENTS
			CLR	F0
        		CLR     C
			SUBB	A,R7
			JZ	EXPONENTS_EQUAL
			JC	ARG1_EXP_IS_LARGER
	;
	; Now the ARG2 EXPONENT is > ARG1 EXPONENT
	;
SIGNS_DIFFERENT:
	;
			MOV	A,R3				;SEE IF SIGN OF ARG2 IS POSITIVE
			SJMP	ARG1_EXP_IS_LARGER1
	;
ARG1_EXP_IS_LARGER:
	;
			MOV	A,R4				;GET THE SIGN OF ARG1 EXPONENT
ARG1_EXP_IS_LARGER1:	JZ	ARG1_EXP_IS_LARGER2
			CPL	C
ARG1_EXP_IS_LARGER2:	RET
	;
EXPONENTS_EQUAL:
	;
	; First, test the sign, then the mantissa
	;
			CJNE	R5,#0,SIGNS_DIFFERENT
	;
BOTH_PLUS:
	;
			MOV	R7,#DIGIT			;POINT AT MS DIGIT
			DEC	R0
			DEC	R0
			DEC	R0
			DEC	R1
			DEC	R1
			DEC	R1
	;
	; Now do the compare
	;
CLOOP:			MOV	A,@R0
			MOV	R6,A
			MOV	A,@R1
			SUBB	A,R6
			JNZ	ARG1_EXP_IS_LARGER
			INC	R0
			INC	R1
			DJNZ	R7,CLOOP
	;
	; If here, the numbers are the same, the carry is cleared
	;
			SETB	F0
			RET					;EXIT WITH EQUAL
	;
;MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
;
FLOATING_MUL:							; Floating point multiply
;
;MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
;
			ACALL	MUL_DIV_EXP_AND_SIGN
	;
	; check for zero exponents
	;
			CJNE	R6,#00,FMUL1			;ARG 2 EXP ZERO?
FMUL0:			AJMP	ZERO_AND_EXIT
	;
	; calculate the exponent
	;
FMUL1:			MOV	FP_SIGN,R5			;SAVE THE SIGN, IN CASE OF FAILURE
	;
			MOV	A,R7
			JZ	FMUL0
			ADD	A,R6				;ADD THE EXPONENTS
			JB	ACC.7,FMUL_OVER
			JBC	CY,FMUL2			;SEE IF CARRY IS SET
	;
			AJMP	UNDERFLOW_AND_EXIT
	;
FMUL_OVER:
	;
			JNC	FMUL2				;OK IF SET
	;
FOV:			AJMP	OVERFLOW_AND_EXIT
	;
FMUL2:			SUBB	A,#129				;SUBTRACT THE EXPONENT BIAS
			MOV	R6,A				;SAVE IT FOR LATER
	;
	; Unpack and load R0
	;
			ACALL	UNPACK_R0
	;
	; Now set up for loop multiply
	;
			MOV	R3,#DIGIT
			MOV	R4,R1B0
	;
	;
	; Now, do the multiply and accumulate the product
	;
FMUL3:			MOV	R1B0,R4
			MOV	A,@R1
			MOV	R2,A
			ACALL	MUL_NIBBLE
	;
			MOV	A,R2
			SWAP	A
			ACALL	MUL_NIBBLE
			DEC	R4
			DJNZ	R3,FMUL3
	;
	; Now, pack and restore the sign
	;
			MOV	FP_EXP,R6
			MOV	FP_SIGN,R5
			AJMP	PACK				;FINISH IT OFF
	;
	;DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
	;
FLOATING_DIV:
	;
	;DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
	;
			ACALL	MDES1
	;
	; Check the exponents
	;
			MOV	FP_SIGN,R5			;SAVE THE SIGN
			CJNE	R7,#0,DIV0			;CLEARS THE CARRY
			ACALL	OVERFLOW_AND_EXIT
			CLR	A
			SETB	ACC.ZERO_DIVIDE
			RET
	;
DIV0:			MOV	A,R6				;GET EXPONENT
			JZ	FMUL1-2				;EXIT IF ZERO
			SUBB	A,R7				;DELTA EXPONENT
			JB	ACC.7,D_UNDER
			JNC	DIV3
			AJMP	UNDERFLOW_AND_EXIT
	;
D_UNDER:		JNC	FOV
	;
DIV3:			ADD	A,#129				;CORRECTLY BIAS THE EXPONENT
			MOV	FP_EXP,A			;SAVE THE EXPONENT
			ACALL	LOADR1_MANTISSA			;LOAD THE DIVIDED
	;
			MOV	R2,#FP_ACCC			;SAVE LOCATION
			MOV	R3,R0B0				;SAVE POINTER IN R3
			MOV	FP_CARRY,#0			;ZERO CARRY BYTE
	;
DIV4:			MOV	R5,#0FFH			;LOOP COUNT
			SETB	C
	;
DIV5:			MOV	R0B0,R3				;RESTORE THE EXTERNAL POINTER
			MOV	R1,#FP_DIG78			;SET UP INTERNAL POINTER
			MOV	R7,#DIGIT			;LOOP COUNT
			JNC	DIV7				;EXIT IF NO CARRY
	;
DIV6:			MOV	A,@R0				;DO ACCUMLATION
			MOV	R6,A
			CLR	A
			ADDC	A,#99H
			SUBB	A,R6
			ADD	A,@R1
			DA	A
			MOV	@R1,A
			DEC	R0
			DEC	R1
			DJNZ	R7,DIV6				;LOOP
	;
			INC	R5				;SUBTRACT COUNTER
			JC	DIV5				;KEEP LOOPING IF CARRY
			MOV	A,@R1				;GET CARRY
			SUBB	A,#1				;CARRY IS CLEARED
			MOV	@R1,A				;SAVE CARRY DIGIT
			CPL	C
			SJMP	DIV5				;LOOP
	;
	; Restore the result if carry was found
	;
DIV7:			ACALL	ADDLP				;ADD NUMBER BACK
			MOV	@R1,#0				;CLEAR CARRY
			MOV	R0B0,R2				;GET SAVE COUNTER
			MOV	@R0,5				;SAVE COUNT BYTE
	;
			INC	R2				;ADJUST SAVE COUNTER
			MOV	R7,#1				;BUMP DIVIDEND
			ACALL	LEFT
			CJNE	R2,#FP_ACC8+2,DIV4
	;
			DJNZ	FP_EXP,DIV8
			AJMP	UNDERFLOW_AND_EXIT
	;
DIV8:			MOV	FP_CARRY,#0
	;
	;***************************************************************
	;
PACK:	; Pack the mantissa
	;
	;***************************************************************
	;
	; First, set up the pointers
	;
			MOV	R0,#FP_ACCC
			MOV	A,@R0				;GET FP_ACCC
			MOV	R6,A				;SAVE FOR ZERO COUNT
			JZ	PACK0				;JUMP OVER IF ZERO
			ACALL	INC_FP_EXP			;BUMP THE EXPONENT
			DEC	R0
	;
PACK0:			INC	R0				;POINT AT FP_ACC1
	;
PACK1:			MOV	A,#8				;ADJUST NIBBLE POINTER
			MOV	R1,A
			ADD	A,R0
			MOV	R0,A
			CMP	@R0,#5				;SEE IF ADJUSTING NEEDED
			JC	PACK3+1
	;
PACK2:			SETB	C
			CLR	A
			DEC	R0
			ADDC	A,@R0
			DA	A
			XCHD	A,@R0				;SAVE THE VALUE
			JNB	ACC.4,PACK3
			DJNZ	R1,PACK2
	;
			DEC	R0
			MOV	@R0,#1
			ACALL	INC_FP_EXP
			SJMP	PACK4
	;
PACK3:			DEC	R1
			MOV	A,R1
			CLR	C
			XCH	A,R0
			SUBB	A,R0
			MOV	R0,A
	;
PACK4:			MOV	R1,#FP_DIG12
	;
	; Now, pack
	;
PLOOP:			MOV	A,@R0
			SWAP	A				;FLIP THE DIGITS
			INC	R0
			XCHD	A,@R0
			ORL	6,A				;ACCUMULATE THE OR'ED DIGITS
			MOV	@R1,A
			INC	R0
			INC	R1
			CJNE	R1,#FP_SIGN,PLOOP
			MOV	A,R6
			JNZ	STORE_ALIGN_TEST_AND_EXIT
			MOV	FP_EXP,#0			;ZERO EXPONENT
	;
	;**************************************************************
	;
STORE_ALIGN_TEST_AND_EXIT:					;Save the number align carry and exit
	;
	;**************************************************************
	;
			ACALL	LOAD_POINTERS
			MOV	ARG_STACK,R1			;SET UP THE NEW STACK
			MOV	R0,#FP_EXP
	;
	; Now load the numbers
	;
STORE2:			MOV	A,@R0
			MOV	@R1,A				;SAVE THE NUMBER
			DEC	R0
			DEC	R1
			CJNE	R0,#FP_CARRY,STORE2
	;
			CLR	A				;NO ERRORS
	;
PRET:			RET					;EXIT
	;
INC_FP_EXP:
	;
			INC	FP_EXP
			MOV	A,FP_EXP
			JNZ	PRET				;EXIT IF NOT ZERO
			POP	ACC				;WASTE THE CALLING STACK
			POP	ACC
			AJMP	OVERFLOW_AND_EXIT
	;
;***********************************************************************
;
UNPACK_R0:	; Unpack BCD digits and load into nibble locations
;
;***********************************************************************
	;
			PUSH	R1B0
			MOV	R1,#FP_NIB8
	;
ULOOP:			MOV	A,@R0
			ANL	A,#0FH
			MOV	@R1,A				;SAVE THE NIBBLE
			MOV	A,@R0
			SWAP	A
			ANL	A,#0FH
			DEC	R1
			MOV	@R1,A				;SAVE THE NIBBLE AGAIN
			DEC	R0
			DEC	R1
			CJNE	R1,#FP_NIB1-1,ULOOP
	;
			POP	R1B0
	;
LOAD7:			RET
	;
	;**************************************************************
	;
OVERFLOW_AND_EXIT:	;LOAD 99999999 E+127,  SET OV BIT, AND EXIT
	;
	;**************************************************************
	;
			MOV	R0,#FP_DIG78
			MOV	A,#99H
	;
OVE1:			MOV	@R0,A
			DEC	R0
			CJNE	R0,#FP_CARRY,OVE1
	;
			MOV	FP_EXP,#0FFH
			ACALL	STORE_ALIGN_TEST_AND_EXIT
	;
			SETB	ACC.OVERFLOW
			RET
	;
	;**************************************************************
	;
UNDERFLOW_AND_EXIT:	;LOAD 0, SET UF BIT, AND EXIT
	;
	;**************************************************************
	;
			ACALL	ZERO_AND_EXIT
			CLR		A
			SETB	ACC.UNDERFLOW
			RET
	;
	;**************************************************************
	;
ZERO_AND_EXIT:		;LOAD 0, SET ZERO BIT, AND EXIT
	;
	;**************************************************************
	;
			ACALL	FP_CLEAR
			ACALL	STORE_ALIGN_TEST_AND_EXIT
			SETB	ACC.ZERO
			RET					;EXIT
	;
	;**************************************************************
	;
FP_CLEAR:
	;
	; Clear internal storage
	;
	;**************************************************************
	;
			CLR	A
			MOV	R0,#FP_ACC8+1
	;
FPC1:			MOV	@R0,A
			DEC	R0
			CJNE	R0,#FP_TEMP,FPC1
			RET
	;
	;**************************************************************
	;
RIGHT:	; Shift ACCUMULATOR RIGHT the number of nibbles in R7
	; Save the shifted values in R4 if SAVE_ROUND is set
	;
	;**************************************************************
	;
			MOV	R4,#0				;IN CASE OF NO SHIFT
	;
RIGHT1:			CLR	C
			MOV	A,R7				;GET THE DIGITS TO SHIFT
			JZ	RIGHT5-1			;EXIT IF ZERO
			SUBB	A,#2				;TWO TO DO?
			JNC	RIGHT5				;SHIFT TWO NIBBLES
	;
	; Swap one nibble then exit
	;
RIGHT3:			PUSH	R0B0				;SAVE POINTER REGISTER
			PUSH	R1B0
	;
			MOV	R1,#FP_DIG78			;LOAD THE POINTERS
			MOV	R0,#FP_DIG56
			MOV	A,R4				;GET THE OVERFLOW REGISTER
			XCHD	A,@R1				;GET DIGIT 8
			SWAP	A				;FLIP FOR LOAD
			MOV	R4,A
	;
RIGHTL:			MOV	A,@R1				;GET THE LOW ORDER BYTE
			XCHD	A,@R0				;SWAP NIBBLES
			SWAP	A				;FLIP FOR STORE
			MOV	@R1,A				;SAVE THE DIGITS
			DEC	R0				;BUMP THE POINTERS
			DEC	R1
			CJNE	R1,#FP_DIG12-1,RIGHTL	;LOOP
	;
			MOV	A,@R1				;ACC = CH8
			SWAP	A				;ACC = 8CH
			ANL	A,#0FH				;ACC = 0CH
			MOV	@R1,A				;CARRY DONE
			POP	R1B0				;EXIT
			POP	R0B0				;RESTORE REGISTER
			RET
	;
RIGHT5:			MOV	R7,A				;SAVE THE NEW SHIFT NUMBER
			CLR	A
			XCH	A,FP_CARRY			;SWAP THE NIBBLES
			XCH	A,FP_DIG12
			XCH	A,FP_DIG34
			XCH	A,FP_DIG56
			XCH	A,FP_DIG78
			MOV	R4,A				;SAVE THE LAST DIGIT SHIFTED
			SJMP	RIGHT1+1
	;
	;***************************************************************
	;
LEFT:	; Shift ACCUMULATOR LEFT the number of nibbles in R7
	;
	;***************************************************************
	;
			MOV	R4,#00H				;CLEAR FOR SOME ENTRYS
	;
LEFT1:			CLR	C
			MOV	A,R7				;GET SHIFT VALUE
			JZ	LEFT5-1				;EXIT IF ZERO
			SUBB	A,#2				;SEE HOW MANY BYTES TO SHIFT
			JNC	LEFT5
	;
LEFT3:			PUSH	R0B0				;SAVE POINTER
			PUSH	R1B0
			MOV	R0,#FP_CARRY
			MOV	R1,#FP_DIG12
	;
			MOV	A,@R0				;ACC=CHCL
			SWAP	A				;ACC = CLCH
			MOV	@R0,A				;ACC = CLCH, @R0 = CLCH
	;
LEFTL:			MOV	A,@R1				;DIG 12
			SWAP	A				;DIG 21
			XCHD	A,@R0
			MOV	@R1,A				;SAVE IT
			INC	R0				;BUMP POINTERS
			INC	R1
			CJNE	R0,#FP_DIG78,LEFTL
	;
			MOV	A,R4
			SWAP	A
			XCHD	A,@R0
			ANL	A,#0F0H
			MOV	R4,A
	;
			POP	R1B0
			POP	R0B0				;RESTORE
			RET					;DONE
	;
LEFT5:			MOV	R7,A				;RESTORE COUNT
			CLR	A
			XCH	A,R4				;GET THE RESTORATION BYTE
			XCH	A,FP_DIG78			;DO THE SWAP
			XCH	A,FP_DIG56
			XCH	A,FP_DIG34
			XCH	A,FP_DIG12
			XCH	A,FP_CARRY
			SJMP	LEFT1+1
	;
MUL_NIBBLE:
	;
	; Multiply the nibble in R7 by the FP_NIB locations
	; accumulate the product in FP_ACC
	;
	; Set up the pointers for multiplication
	;
			ANL	A,#0FH				;STRIP OFF MS NIBBLE
			MOV	R7,A
			MOV	R0,#FP_ACC8
			MOV	R1,#FP_NIB8
			CLR	A
			MOV	FP_ACCX,A
	;
MNLOOP:			DEC	R0				;BUMP POINTER TO PROPAGATE CARRY
			ADD	A,@R0				;ATTEMPT TO FORCE CARRY
			DA	A				;BCD ADJUST
			JNB	ACC.4,MNL0			;DON'T ADJUST IF NO NEED
			DEC	R0				;PROPAGATE CARRY TO THE NEXT DIGIT
			INC	@R0				;DO THE ADJUSTING
			INC	R0				;RESTORE R0
	;
MNL0:			XCHD	A,@R0				;RESTORE INITIAL NUMBER
			MOV	B,R7				;GET THE NUBBLE TO MULTIPLY
			MOV	A,@R1				;GET THE OTHER NIBBLE
			MUL	AB					;DO THE MULTIPLY
			MOV	B,#10				;NOW BCD ADJUST
			DIV	AB
			XCH	A,B				;GET THE REMAINDER
			ADD	A,@R0				;PROPAGATE THE PARTIAL PRODUCTS
			DA	A				;BCD ADJUST
			JNB	ACC.4,MNL1			;PROPAGATE PARTIAL PRODUCT CARRY
			INC	B
	;
MNL1:			INC	R0
			XCHD	A,@R0				;SAVE THE NEW PRODUCT
			DEC	R0
			MOV	A,B				;GET BACK THE QUOTIENT
			DEC	R1
			CJNE	R1,#FP_NIB1-1,MNLOOP
	;
			ADD	A,FP_ACCX			;GET THE OVERFLOW
			DA	A				;ADJUST
			MOV	@R0,A				;SAVE IT
			RET					;EXIT
	;
	;***************************************************************
	;
LOAD_POINTERS:	; Load the ARG_STACK into R0 and bump R1
	;
	;***************************************************************
	;
			MOV	R0,ARG_STACK
			MOV	A,#FP_NUMBER_SIZE
			ADD	A,R0
			MOV	R1,A
			RET
	;
	;***************************************************************
	;
MUL_DIV_EXP_AND_SIGN:
	;
	; Load the sign into R7, R6. R5 gets the sign for
	; multiply and divide.
	;
	;***************************************************************
	;
			ACALL	FP_CLEAR			;CLEAR INTERNAL MEMORY
	;
MDES1:			ACALL	LOAD_POINTERS			;LOAD REGISTERS
			MOV	A,@R0				;ARG 1 EXP
			MOV	R7,A				;SAVED IN R7
			MOV	A,@R1				;ARG 2 EXP
			MOV	R6,A				;SAVED IN R6
			DEC	R0				;BUMP POINTERS TO SIGN
			DEC	R1
			MOV	A,@R0				;GET THE SIGN
			MOV	R4,A				;SIGN OF ARG1
			MOV	A,@R1				;GET SIGN OF NEXT ARG
			MOV	R3,A				;SIGN OF ARG2
			XRL	A,R4				;ACC GETS THE NEW SIGN
			MOV	R5,A				;R5 GETS THE NEW SIGN
	;
	; Bump the pointers to point at the LS digit
	;
			DEC	R0
			DEC	R1
	;
			RET
	;
	;***************************************************************
	;
LOADR1_MANTISSA:
	;
	; Load the mantissa of R0 into FP_Digits
	;
	;***************************************************************
	;
			PUSH	R0B0				;SAVE REGISTER 1
			MOV	R0,#FP_DIG78			;SET UP THE POINTER
	;
LOADR1:			MOV	A,@R1
			MOV	@R0,A
			DEC	R1
			DEC	R0
			CJNE	R0,#FP_CARRY,LOADR1
	;
			POP	R0B0
			RET
	;
	;***************************************************************
	;
HEXSCAN:	; Scan a string to determine if it is a hex number
		; set carry if hex, else carry = 0
	;
	;***************************************************************
	;
			ACALL	GET_R1_CHARACTER
	;
HEXSC1:			MOV	A,@R1				;GET THE CHARACTER
			ACALL	DIGIT_CHECK			;SEE IF A DIGIT
			JC	HS1				;CONTINUE IF A DIGIT
			ACALL	HEX_CHECK			;SEE IF HEX
			JC	HS1
	;
			CLR	ACC.5				;NO LOWER CASE
			CJNE	A,#'H',HEXDON
			SETB	C
			SJMP	HEXDO1				;NUMBER IS VALID HEX, MAYBE
	;
HEXDON:			CLR	C
	;
HEXDO1:			RET
	;
HS1:			INC	R1				;BUMP TO NEXT CHARACTER
			SJMP	HEXSC1				;LOOP
	;
HEX_CHECK:	;CHECK FOR A VALID ASCII HEX, SET CARRY IF FOUND
	;
			CLR	ACC.5				;WASTE LOWER CASE
			CMP	A,#'F'+1			;SEE IF F OR LESS
			JC	HC1
			RET
	;
HC1:			CMP	A,#'A'				;SEE IF A OR GREATER
			CPL	C
			RET
	;
	;***************************************************************
	;
FLOATING_POINT_INPUT:	; Input a floating point number pointed to by R1
	;
	;***************************************************************
	;
			ACALL	FP_CLEAR			;CLEAR EVERYTHING
			ACALL	GET_R1_CHARACTER
			ACALL	PLUS_MINUS_TEST
			MOV	MSIGN,C				;SAVE THE MANTISSA SIGN
	;
	; Now, set up for input loop
	;
			MOV	R0,#FP_ACCC
			MOV	R6,#7FH				;BASE EXPONENT
			SETB	F0				;SET INITIAL FLAG
	;
INLOOP:			ACALL	GET_DIGIT_CHECK
			JNC	GTEST				;IF NOT A CHARACTER, WHAT IS IT?
			ANL	A,#0FH				;STRIP ASCII
			ACALL	STDIG				;STORE THE DIGITS
	;
INLPIK:			INC	R1				;BUMP POINTER FOR LOOP
			SJMP	INLOOP				;LOOP FOR INPUT
	;
GTEST:			CJNE	A,#'.',GT1			;SEE IF A RADIX
			JB	FOUND_RADIX,INERR
			SETB	FOUND_RADIX
			CJNE	R0,#FP_ACCC,INLPIK
			SETB	FIRST_RADIX			;SET IF FIRST RADIX
			SJMP	INLPIK				;GET ADDITIONAL DIGITS
	;
GT1:			JB	F0,INERR			;ERROR IF NOT CLEARED
			CJNE	A,#'e',GT11			;CHECK FOR LOWER CASE
			SJMP	GT12
GT11:			CJNE	A,#'E',FINISH_UP
GT12:			ACALL	INC_AND_GET_R1_CHARACTER
			ACALL	PLUS_MINUS_TEST
			MOV	XSIGN,C				;SAVE SIGN STATUS
			ACALL	GET_DIGIT_CHECK
			JNC	INERR
	;
			ANL	A,#0FH				;STRIP ASCII BIAS OFF THE CHARACTER
			MOV	R5,A				;SAVE THE CHARACTER IN R5
	;
GT2:			INC	R1
			ACALL	GET_DIGIT_CHECK
			JNC	FINISH1
			ANL	A,#0FH				;STRIP OFF BIAS
			XCH	A,R5				;GET THE LAST DIGIT
			MOV	B,#10				;MULTIPLY BY TEN
			MUL	AB
			ADD	A,R5				;ADD TO ORIGINAL VALUE
			MOV	R5,A				;SAVE IN R5
			JNC	GT2					;LOOP IF NO CARRY
			MOV	R5,#0FFH			;FORCE AN ERROR
	;
FINISH1:		MOV	A,R5				;GET THE SIGN
			JNB	XSIGN,POSNUM			;SEE IF EXPONENT IS POS OR NEG
			CLR	C
			SUBB	A,R6
			CPL	A
			INC	A
			JC	FINISH2
			MOV	A,#01H
			RET
	;
POSNUM:			ADD	A,R6				;ADD TO EXPONENT
			JNC	FINISH2
	;
POSNM1:			MOV	A,#02H
			RET
	;
FINISH2:		XCH	A,R6				;SAVE THE EXPONENT
	;
FINISH_UP:
	;
			MOV	FP_EXP,R6			;SAVE EXPONENT
			CJNE	R0,#FP_ACCC,FINISH_UP1
			ACALL	FP_CLEAR			;CLEAR THE MEMORY IF 0
FINISH_UP1:		MOV	A,ARG_STACK			;GET THE ARG STACK
			CLR	C
			SUBB	A,#FP_NUMBER_SIZE+FP_NUMBER_SIZE
			MOV	ARG_STACK,A			;ADJUST FOR STORE
			AJMP	PACK
	;
STDIG:			CLR	F0				;CLEAR INITIAL DESIGNATOR
			JNZ	STDIG1				;CONTINUE IF NOT ZERO
			CJNE	R0,#FP_ACCC,STDIG1
			JNB	FIRST_RADIX,RET_X
	;
DECX:			DJNZ	R6,RET_X
	;
INERR:			MOV	A,#0FFH
	;
RET_X:			RET
	;
STDIG1:			JB	DONE_LOAD,FRTEST
			CLR	FIRST_RADIX
	;
FRTEST:			JB	FIRST_RADIX,DECX
	;
FDTEST:			JB	FOUND_RADIX,FDT1
			INC	R6
	;
FDT1:			JB	DONE_LOAD,RET_X
			CJNE	R0,#FP_ACC8+1,FDT2
			SETB	DONE_LOAD
	;
FDT2:			MOV	@R0,A				;SAVE THE STRIPPED ACCUMULATOR
			INC	R0				;BUMP THE POINTER
			RET					;EXIT
	;
	;***************************************************************
	;
	; I/O utilities
	;
	;***************************************************************
	;
INC_AND_GET_R1_CHARACTER:
	;
			INC	R1
	;
GET_R1_CHARACTER:
	;
			MOV	A,@R1				;GET THE CHARACTER
			CJNE	A,#' ',PMT1			;SEE IF A SPACE
	;
	; Kill spaces
	;
			SJMP	INC_AND_GET_R1_CHARACTER
	;
PLUS_MINUS_TEST:
	;
			CJNE	A,#'+',PMT0
			SJMP	PMT3
PMT0:			CJNE	A,#'-',PMT1
	;
PMT2:			SETB	C
	;
PMT3:			INC	R1
	;
PMT1:			RET
	;
	;***************************************************************
	;
FLOATING_POINT_OUTPUT:	; Output the number, format is in location 25
	;
	; IF FORMAT = 00 - FREE FLOATING
	;           = FX - EXPONENTIAL (X IS THE NUMBER OF SIG DIGITS)
	;           = NX - N = NUM BEFORE RADIX, X = NUM AFTER RADIX
	;                  N + X = 8 MAX
	;
	;***************************************************************
	;
			ACALL	MDES1				;GET THE NUMBER TO OUTPUT, R0 IS POINTER
			ACALL	POP_AND_EXIT			;OUTPUT POPS THE STACK
			MOV	A,R7
			MOV	R6,A				;PUT THE EXPONENT IN R6
			ACALL	UNPACK_R0			;UNPACK THE NUMBER
			MOV	R0,#FP_NIB1			;POINT AT THE NUMBER
			MOV	A,FORMAT			;GET THE FORMAT
			MOV	R3,A				;SAVE IN CASE OF EXP FORMAT
			JZ	FREE				;FREE FLOATING?
			CMP	A,#0F0H				;SEE IF EXPONENTIAL
			JNC	EXPOUT
	;
	; If here, must be integer USING format
	;
			MOV	A,R6				;GET THE EXPONENT
			JNZ	FPO1
			MOV	R6,#80H
FPO1:			MOV	A,R3				;GET THE FORMAT
			SWAP	A				;SPLIT INTEGER AND FRACTION
			ANL	A,#0FH
			MOV	R2,A				;SAVE INTEGER
			ACALL	NUM_LT				;GET THE NUMBER OF INTEGERS
			XCH	A,R2				;FLIP FOR SUBB
			CLR	C
			SUBB	A,R2
			MOV	R7,A
			JNC	FPO2
			MOV	R5,#'?'				;OUTPUT A QUESTION MARK
			ACALL	SOUT1				;NUMBER IS TOO LARGE FOR FORMAT
			AJMP	FREE
FPO2:			CJNE	R2,#00,USING0			;SEE IF ZERO
			DEC	R7
			ACALL	SS7
			ACALL	ZOUT				;OUTPUT A ZERO
			SJMP	USING1
	;
USING0:			ACALL	SS7				;OUTPUT SPACES, IF NEED TO
			MOV	A,R2				;OUTPUT DIGITS
			MOV	R7,A
			ACALL	OUTR0
	;
USING1:			MOV	A,R3
			ANL	A,#0FH				;GET THE NUMBER RIGHT OF DP
			MOV	R2,A				;SAVE IT
			JZ	PMT1				;EXIT IF ZERO
			ACALL	ROUT				;OUTPUT DP
			ACALL	NUM_RT
			CJNE	A,2,USINGX			;COMPARE A TO R2
	;
USINGY:			MOV	A,R2
			AJMP	Z7R7
	;
USINGX:			JNC	USINGY
	;
USING2:			XCH	A,R2
			CLR	C
			SUBB	A,R2
			XCH	A,R2
			ACALL	Z7R7				;OUTPUT ZEROS IF NEED TO
			MOV	A,R2
			MOV	R7,A
			AJMP	OUTR0
	;
	; First, force exponential output, if need to
	;
FREE:			MOV	A,R6				;GET THE EXPONENT
			JNZ	FREE1				;IF ZERO, PRINT IT
			ACALL	SOUT
			AJMP	ZOUT
	;
FREE1:			MOV	R3,#0F0H			;IN CASE EXP NEEDED
			MOV	A,#80H-DIGIT-DIGIT-1
			ADD	A,R6
			JC	EXPOUT
			SUBB	A,#0F7H
			JC	EXPOUT
	;
	; Now, just print the number
	;
			ACALL	SINOUT				;PRINT THE SIGN OF THE NUMBER
			ACALL	NUM_LT				;GET THE NUMBER LEFT OF DP
			CJNE	A,#8,FREE4
			AJMP	OUTR0
	;
FREE4:			ACALL	OUTR0
			ACALL	ZTEST				;TEST FOR TRAILING ZEROS
			JZ	U_RET				;DONE IF ALL TRAILING ZEROS
			ACALL	ROUT				;OUTPUT RADIX
	;
FREE2:			MOV	R7,#1				;OUTPUT ONE DIGIT
			ACALL	OUTR0
			JNZ	U_RET
			ACALL	ZTEST
			JZ	U_RET
			SJMP	FREE2				;LOOP
	;
EXPOUT:			ACALL	SINOUT				;PRINT THE SIGN
			MOV	R7,#1				;OUTPUT ONE CHARACTER
			ACALL	OUTR0
			ACALL	ROUT				;OUTPUT RADIX
			MOV	A,R3				;GET FORMAT
			ANL	A,#0FH				;STRIP INDICATOR
			JZ	EXPOTX
	;
			MOV	R7,A				;OUTPUT THE NUMBER OF DIGITS
			DEC	R7				;ADJUST BECAUSE ONE CHAR ALREADY OUT
			ACALL	OUTR0
			SJMP	EXPOT4
	;
EXPOTX:			ACALL	FREE2				;OUTPUT UNTIL TRAILING ZEROS
	;
EXPOT4:			ACALL	SOUT				;OUTPUT A SPACE
			MOV	R5,#'E'
			ACALL	SOUT1				;OUTPUT AN E
			MOV	A,R6				;GET THE EXPONENT
			JZ	XOUT0				;EXIT IF ZERO
			DEC	A				;ADJUST FOR THE DIGIT ALREADY OUTPUT
			CJNE	A,#80H,XOUT2			;SEE WHAT IT IS
	;
XOUT0:			ACALL	SOUT
			CLR	A
			SJMP	XOUT4
	;
XOUT2:			JC	XOUT3				;NEGATIVE EXPONENT
			MOV	R5,#'+'				;OUTPUT A PLUS SIGN
			ACALL	SOUT1
			SJMP	XOUT4
	;
XOUT3:			ACALL	MOUT
			CPL	A				;FLIP BITS
			INC	A				;BUMP
	;
XOUT4:			CLR	ACC.7
			MOV	R0,A
			MOV	R2,#0
			MOV	R1,#LOW CONVT			;CONVERSION LOCATION
			MOV	R3,#HIGH CONVT
			ACALL	CONVERT_BINARY_TO_ASCII_STRING
			MOV	R0,#LOW CONVT			;NOW, OUTPUT EXPONENT
	;
EXPOT5:			MOV	A,@R0				;GET THE CHARACTER
			MOV	R5,A				;OUTPUT IT
			ACALL	SOUT1
			INC	R0				;BUMP THE POINTER
			MOV	A,R0				;GET THE POINTER
			CJNE	A,R1B0,EXPOT5			;LOOP
	;
U_RET:			RET					;EXIT
	;
OUTR0:	; Output the characters pointed to by R0, also bias ascii
	;
			MOV	A,R7				;GET THE COUNTER
			JZ	OUTR				;EXIT IF DONE
			MOV	A,@R0				;GET THE NUMBER
			ORL	A,#30H				;ASCII BIAS
			INC	R0				;BUMP POINTER AND COUNTER
			DEC	R7
			MOV	R5,A				;PUT CHARACTER IN OUTPUT REGISTER
			ACALL	SOUT1				;OUTPUT THE CHARACTER
			CLR	A				;JUST FOR TEST
			CJNE	R0,#FP_NIB8+1,OUTR0
			MOV	A,#55H				;KNOW WHERE EXIT OCCURED
	;
OUTR:			RET
	;
ZTEST:			MOV	R1,R0B0				;GET POINTER REGISTER
	;
ZT0:			MOV	A,@R1				;GET THE VALUE
			JNZ	ZT1
			INC	R1				;BUMP POINTER
			CJNE	R1,#FP_NIB8+1,ZT0
	;
ZT1:			RET
	;
NUM_LT:			MOV	A,R6				;GET EXPONENT
			CLR	C				;GET READY FOR SUBB
			SUBB	A,#80H				;SUB EXPONENT BIAS
			JNC	NL1				;OK IF NO CARRY
			CLR	A				;NO DIGITS LEFT
	;
NL1:			MOV	R7,A				;SAVE THE COUNT
			RET
	;
NUM_RT:			CLR	C				;SUBB AGAIN
			MOV	A,#80H				;EXPONENT BIAS
			SUBB	A,R6				;GET THE BIASED EXPONENT
			JNC	NR1
			CLR	A
	;
NR1:			RET					;EXIT
	;
SPACE7:			MOV	A,R7				;GET THE NUMBER OF SPACES
			JZ	NR1				;EXIT IF ZERO
			ACALL	SOUT				;OUTPUT A SPACE
			DEC	R7				;BUMP COUNTER
			SJMP	SPACE7				;LOOP
	;
Z7R7:			MOV	R7,A
	;
ZERO7:			MOV	A,R7				;GET COUNTER
			JZ	NR1				;EXIT IF ZERO
			ACALL	ZOUT				;OUTPUT A ZERO
			DEC	R7				;BUMP COUNTER
			SJMP	ZERO7				;LOOP
	;
SS7:			ACALL	SPACE7
	;
SINOUT:			MOV	A,R4				;GET THE SIGN
			JZ	SOUT				;OUTPUT A SPACE IF ZERO
	;
MOUT:			MOV	R5,#'-'
			SJMP	SOUT1				;OUTPUT A MINUS IF NOT
	;
ROUT:			MOV	R5,#'.'				;OUTPUT A RADIX
			SJMP	SOUT1
	;
ZOUT:			MOV	R5,#'0'				;OUTPUT A ZERO
			SJMP	SOUT1
	;
SOUT:			MOV	R5,#' '				;OUTPUT A SPACE
	;
SOUT1:			AJMP	R5OUT
	;
	;
MULNUM10:		MOV	B,#10
	;
	;***************************************************************
	;
MULNUM:	; Take the next digit in the acc (masked to 0FH)
	; accumulate in R3:R1
	;
	;***************************************************************
	;
			PUSH	ACC				;SAVE ACC
			PUSH	B				;SAVE MULTIPLIER
			MOV	A,R1				;PUT LOW ORDER BITS IN ACC
			MUL	AB				;DO THE MULTIPLY
			MOV	R1,A				;PUT THE RESULT BACK
			MOV	A,R3				;GET THE HIGH ORDER BYTE
			MOV	R3,B				;SAVE THE OVERFLOW
			POP	B				;GET THE MULTIPLIER
			MUL	AB				;DO IT
			MOV	C,OV				;SAVE OVERFLOW IN F0
			MOV	F0,C
			ADD	A,R3				;ADD OVERFLOW TO HIGH RESULT
			MOV	R3,A				;PUT IT BACK
			POP	ACC				;GET THE ORIGINAL ACC BACK
			ORL	C,F0				;OR CARRY AND OVERFLOW
			JC	MULX				;NO GOOD IF THE CARRY IS SET
	;
MUL11:			ANL	A,#0FH				;MASK OFF HIGH ORDER BITS
			ADD	A,R1				;NOW ADD THE ACC
			MOV	R1,A				;PUT IT BACK
			CLR	A				;PROPAGATE THE CARRY
			ADDC	A,R3
			MOV	R3,A				;PUT IT BACK
	;
MULX:			RET					;EXIT WITH OR WITHOUT CARRY
	;
	;***************************************************************
	;
CONVERT_BINARY_TO_ASCII_STRING:
	;
	;R1 contains the address of the string
	;R0 contains the value to convert
	;DPTR, R7, R6, and ACC gets clobbered
	;
	;***************************************************************
	;
			CLR	A				;NO LEADING ZEROS
			MOV	DPTR,#10000			;SUBTRACT 10000
			ACALL	RSUB				;DO THE SUBTRACTION
			MOV	DPTR,#1000			;NOW 1000
			ACALL	RSUB
			MOV	DPTR,#100			;NOW 100
			ACALL	RSUB
			MOV	DPTR,#10			;NOW 10
			ACALL	RSUB
			MOV	DPTR,#1				;NOW 1
			ACALL	RSUB
			JZ	RSUB2				;JUMP OVER RET
	;
RSUB_R:			RET
	;
RSUB:			MOV	R6,#-1				;SET UP THE COUNTER
	;
RSUB1:			INC	R6				;BUMP THE COUNTER
			XCH	A,R2				;DO A FAST COMPARE
			CMP	A,DPH
			XCH	A,R2
			JC	FAST_DONE
			XCH	A,R0				;GET LOW BYTE
			SUBB	A,DPL				;SUBTRACT, CARRY IS CLEARED
			XCH	A,R0				;PUT IT BACK
			XCH	A,R2				;GET THE HIGH BYTE
			SUBB	A,DPH				;ADD THE HIGH BYTE
			XCH	A,R2				;PUT IT BACK
			JNC	RSUB1				;LOOP UNTIL CARRY
	;
			XCH	A,R0
			ADD	A,DPL				;RESTORE R2:R0
			XCH	A,R0
			XCH	A,R2
			ADDC	A,DPH
			XCH	A,R2
	;
FAST_DONE:
	;
			ORL	A,R6				;OR THE COUNT VALUE
			JZ	RSUB_R				;RETURN IF ZERO
	;
RSUB2:			MOV	A,#'0'				;GET THE ASCII BIAS
			ADD	A,R6				;ADD THE COUNT
	;
RSUB4:			MOV	@R1,A				;PLACE THE VALUE IN MEMORY
			INC	R1
	;
			RET					;EXIT
	;
	;***************************************************************
	;
HEXOUT:	; Output the hex number in R3:R1, supress leading zeros, if set
	;
	;***************************************************************
	;
			ACALL	SOUT				;OUTPUT A SPACE
			MOV	C,ZSURP				;GET ZERO SUPPRESSION BIT
			MOV	ADD_IN,C
			MOV	A,R3				;GET HIGH NIBBLE AND PRINT IT
			ACALL	HOUTHI
			MOV	A,R3
			ACALL	HOUTLO
	;
HEX2X:			CLR	ADD_IN				;DON'T SUPPRESS ZEROS
			MOV	A,R1				;GET LOW NIBBLE AND PRINT IT
			ACALL	HOUTHI
			MOV	A,R1
			ACALL	HOUTLO
			MOV	R5,#'H'				;OUTPUT H TO INDICATE HEX MODE
	;
SOUT_1:			AJMP	SOUT1
	;
HOUT1:			CLR	ADD_IN				;PRINTED SOMETHING, SO CLEAR ADD_IN
			ADD	A,#90H				;CONVERT TO ASCII
			DA	A
			ADDC	A,#40H
			DA	A				;GOT IT HERE
			MOV	R5,A				;OUTPUT THE BYTE
			SJMP	SOUT_1
	;
HOUTHI:			SWAP	A				;SWAP TO OUTPUT HIGH NIBBLE
	;
HOUTLO:			ANL	A,#0FH				;STRIP
			JNZ	HOUT1				;PRINT IF NOT ZERO
			JNB	ADD_IN,HOUT1			;OUTPUT A ZERO IF NOT SUPRESSED
			RET
	;
	;
GET_DIGIT_CHECK:	; Get a character, then check for digit
	;
			ACALL	GET_R1_CHARACTER
	;
DIGIT_CHECK:	;CHECK FOR A VALID ASCII DIGIT, SET CARRY IF FOUND
	;
			CMP	A,#'9'+1			;SEE IF ASCII 9 OR LESS
			JC	DC1
			RET
	;
DC1:			CMP	A,#'0'				;SEE IF ASCII 0 OR GREATER
			CPL	C
			RET
	;

R5OUT:			PUSH	ACC				; ME
			PUSH	00H
			MOV	R0,FPCHR_OUT
			MOV	A,R5				; ME
			MOV	@R0,A
			INC	FPCHR_OUT
			POP	00H
			POP	ACC				; ME
			RET

SQ_ERR:			JMP	BADPRM				; me

; Pop the ARG STACK and check for overflow
INC_ASTKA:
			MOV	A,#FP_NUMBER_SIZE		;number to pop
			SJMP	SETREG1

;Push ARG STACK and check for underflow
DEC_ASTKA:
			MOV	A,#-FP_NUMBER_SIZE
			ADD	A,ARG_STACK
			CMP	A,#0
			JC	E4YY
			MOV	ARG_STACK,A
			MOV	R1,A
SRT:			RET

POPAS:			ACALL	INC_ASTKA
			AJMP	VARCOP				;COPY THE VARIABLE

PUSHAS:			ACALL	DEC_ASTKA
			AJMP	VARCOP

SETREG:			CLR	A				;DON'T POP ANYTHING
SETREG1:		MOV	R0,ARG_STACK
			ADD	A,R0
			JC	E4YY
			MOV	ARG_STACK,A
			MOV	A,@R0
A_D:			RET

;Routine to copy bottom arg on stack to address in R1.
MOVAS:  		ACALL   SETREG				;SET UP R0
M_C:			MOV	A,@R0				;READ THE VALUE
			MOV	@R1,A				;SAVE IT
        		INC     R0
        		INC     R1
        		DJNZ    R4,M_C  	        	;LOOP
			RET					;EXIT


; VARCOP - Copy a variable from R0 to R1
VARCOP:			MOV	R4,#FP_NUMBER_SIZE		;LOAD THE LOOP COUNTER
V_C:			MOV	A,@R0				;READ THE VALUE
			MOV	@R1,A				;SAVE IT
			DEC	R0
			DEC	R1
			DJNZ	R4,V_C				;LOOP
			RET					;EXIT
;
E4YY:			MOV	DPTR,#EXA
			JMP	PRTERR				; me

	; integer operator - INT
AINT:			ACALL	SETREG				;SET UP THE REGISTERS, CLEAR CARRY
			SUBB	A,#129				;SUBTRACT EXPONENT BIAS
			JNC	AI1				;JUMP IF ACC > 81H
	;
	; Force the number to be a zero
	;
			ACALL	INC_ASTKA			;BUMP THE STACK
	;
P_Z:			MOV	DPTR,#ZRO			;PUT ZERO ON THE STACK
			AJMP	PUSHC
	;
AI1:			SUBB	A,#7
			JNC	AI3
			CPL	A
			INC	A
			MOV	R3,A
			DEC	R0				;POINT AT SIGN
	;
AI2:			DEC	R0				;NOW AT LSB'S
			MOV	A,@R0				;READ BYTE
			ANL	A,#0F0H				;STRIP NIBBLE
			MOV	@R0,A				;WRITE BYTE
			DJNZ	R3,AI21
			RET
AI21:			CLR	A
			MOV	@R0,A				;CLEAR THE LOCATION
			DJNZ	R3,AI2
AI3:			RET					;EXIT
	;
	; PUSHC - Push constant pointed by DPTR on to the arg stack
PUSHC:			ACALL	DEC_ASTKA
			MOV	R3,#FP_number_SIZe		;LOOP COUNTER
PCL:			CLR	A				;SET UP A
			MOVC	A,@A+DPTR			;LOAD IT
			MOV	@R1,A				;SAVE IT
			INC	DPTR				;BUMP POINTERS
			DEC	R1
			DJNZ	R3,PCL				;LOOP
			RET					;EXIT
;

EXA:			DB	'A-STACK',0
ZRO:			DB	00h,00h,00h
			DB	00h,00h,00h			;0.0000000
FPONE:			DB 	81h,00h,00h
			DB	00h,00h,10h			;1.0000000
FPTWO:			DB 	81h,00h,00h
			DB	00h,00h,20h			;2.0000000
FPPI:			DB	81h,00h,27h
			DB	59h,41h,31h			;3.1415927
FPCCAL:			DB	77h,00h,00h
			DB	00h,50h,94h			;1nF=1e-9
FPP:			DB	8Dh,00h,00h
			DB	00h,00h,10h			;1e12
FPN:			DB	8Ah,00h,00h
			DB	00h,00h,10h			;1e9
FPU:			DB	87h,00h,00h
			DB	00h,00h,10h			;1e6
FPM:			DB	84h,00h,00h
			DB	00h,00h,10h			;1e3
