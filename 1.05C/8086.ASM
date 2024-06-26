; --------------------------------
; 8086-SPECIFIC LINE ASSEMBLER
ASMCMD:	XOR	AX,AX
	MOV	DI,WADJ
	MOV	CX,8
	CLD
	REP STOSW

; FIRST CHECK FOR MNEMONIC
	MOV	DI,MNMTBL
	XOR	BYTE [FLAGS],20H
	CALL	SL
	MOV	DI,IHDL
	JZ	ASMCM1

; THEN CHECK FOR DIRECTIVE
	MOV	DI,DIRTBL
	XOR	BYTE [FLAGS],20H
	CALL	SL
	MOV	DI,AHDL
	JNZ	ASMCM6

; CALL THE REQUISITE HANDLER
ASMCM1:	XCHG	AL,[OPCODE]
	XCHG	AL,AH
	SHL	AX,1
	ADD	DI,AX
	CALL	[DI]

; WRITE OUTPUT ACCORDING TO
; COMPONENT FLAGS
ASMCM2:	XOR	DL,DL
	XCHG	DL,[FLAGS]
	MOV	DI,BINBUF
	ADD	DI,[BINLEN]
	PUSH	SI
	PUSH	DI
	MOV	SI,PREFIX
	CLD

; SHIFT FLAG BITS ONE BY ONE
; INTO CARRY FLAG
ASMCM3:	LODSB
	SHL	DL,1
	JNC	ASMCM4
	STOSB
ASMCM4:	JNZ	ASMCM3
	POP	CX
	POP	SI
	XCHG	CX,DI
	SUB	CX,DI
	ADD	[BINLEN],CX
	ADD	[PC],CX

; SET ZERO FLAG TO SIGNAL
; SUCCESSFUL ASSEMBLY
ASMCM5:	CMP	AL,AL
ASMCM6:	RET

; --------------------------------
; SCAN AND FLAG RESERVED WORD
SW:	CMP	BX,2
	JB	SW3

; DON'T BOTHER SCANNING IF IT
; IS A NUMERIC
	CMP	AL,30H
	JB	SW1
	CMP	AL,3AH
	JB	SW3

; EVERY ONE OF THESE REGISTERS
; IS NEEDED FOR LATER PROCESSING
; AND SL DESTROYS THEM ALL
SW1:	PUSH	CX
	PUSH	DX
	PUSH	BX
	PUSH	SI
	MOV	DI,DIRTBL
	CALL	SL

; WE REALLY ONLY NEED THE ZERO
; FLAG FROM THIS OPERATION
	POP	SI
	POP	BX
	POP	DX
	POP	CX
	JNZ	SW2

; SET FLAG IF VALID USABLE
; KEYWORD
	CMP	AH,5
	JE	SW3
SW2:	MOV	AL,[SI]
SW3:	RET

; --------------------------------
; READ NUMERIC CONSTANT
RNC:	PUSH	AX
	PUSH	CX
	PUSH	SI

; DEFAULT TO DECIMAL
	MOV	CL,5
	CMP	AL,30H
	JB	RNC1
	CMP	AL,3AH
	JNB	RNC1

; SAVE END OF CONSTANT
; FOR LATER
	LEA	DI,[BX+SI]
	DEC	BX

; GET FINAL CHARACTER TO
; CHECK FOR SIGIL
	MOV	AL,[BX+SI]
	CMP	AL,42H
	JE	RNC2
	CMP	AL,48H
	JE	RNC16
	CMP	AL,4FH
	JE	RNC8
	CMP	AL,51H
	JE	RNC8
	INC	BX

; NUMERIC DIGIT MEANS DECIMAL
	CMP	AL,30H
	JB	RNC1
	CMP	AL,3AH
	JB	RNC10

; RESTORE OLD LOCATION
RNC1:	POP	SI
	POP	CX
	POP	AX
	STC
	RET

; ROTATION COUNT SLIDE
RNC2:	DEC	CX
RNC4:	DEC	CX
RNC8:	DEC	CX
RNC16:	DEC	CX
RNC10:	CALL	RN
	JNZ	RNC1
	POP	SI

; SKIP PAST CONSTANT
	MOV	SI,DI
	POP	CX
	POP	AX
	CLC
	RET

; --------------------------------
; SCAN FOR LOW/HIGH BYTE OVERRIDE
RNM:	CALL	SW
	JNZ	RNM2
	ADD	SI,BX

; PREPARE FOR OPERAND FLAG
	MOV	AH,10H
	CMP	AL,11H
	JZ	RNM1
	MOV	AH,8
	CMP	AL,12H
	JZ	RNM1
	MOV	AH,4
	CMP	AL,13H
	JZ	RNM1

; FALL-THROUGH KEYWORD ABUSE
; ERROR DOUBLES AS DIRECTIVE
; HANDLER
D5:	MOV	AL,0CH
	JMP	FAIL

; SHIFT BIT INTO POSITION AND
; SET OPERAND FLAG
RNM1:	OR	CL,AH
	CALL	CC
	JZ	RNMER8
	CMP	AL,AL
RNM2:	RET

; MISSING OPERAND ERROR
RNMER8:	MOV	AL,8
	JMP	FAIL

; --------------------------------
; SCAN FOR OPERAND SIZE OVERRIDE
BORW:	CALL	CC
	JZ	RNMER8
	CALL	SW
	JNZ	BORW2
	CMP	AL,10H
	JE	RA1
	JNB	BORW2
	ADD	SI,BX
	MOV	DI,WADJ

; SHIFT TO DISTANCE BYTE IF
; DISTANCE OVERRIDE
	CMP	AL,8
	JC	BORW1
	INC	DI
BORW1:	XCHG	AL,[DI]
	TEST	AL,AL
	JNZ	RA1
	CALL	CC
	JZ	BORW2
	CALL	SW
	JNZ	BORW2
	CMP	AL,10H
	JNZ	RA1

; SKIP AND SCAN
	ADD	SI,BX
	CALL	CC
BORW2:	RET

; --------------------------------
; READ ARGUMENTS
RA:	XOR	DX,DX
	XOR	CX,CX

; RESET SIZE
	MOV	[WADJ],DX
RAS:	CALL	BORW
	JZ	RAIX

; BRACKET?  MEMORY?
	CMP	AL,5BH
	JZ	RAM

; REGISTER?
	CALL	SCREG
	JZ	RAR

; NOPE, IDENTIFIER OR CONSTANT
RAL:	CALL	RE
	MOV	DX,304H
	XCHG	DH,CL
	AND	DH,CL
	JNZ	RAIW
	TEST	AH,AH
	JZ	RAIB

; IF UPPER BYTE IS NONZERO,
; SEE IF IT STILL FITS IN A
; BYTE SIGNED
	CALL	AA
	JNZ	RAIW
RAIB:	DEC	CX
RAIW:	MOV	AL,[WADJ]
	TEST	AL,AL
	JZ	RAIX
	MOV	CL,2
	DEC	AX
	JZ	RAIX
	INC	CX
RAIX:	JMP	WARG
RA1:	MOV	AL,1
	JMP	FAIL

; FIRST CHECK IF SEGMENT PREFIX
RAR:	CALL	GSPR
	JNC	RAS
	MOV	DH,AL

; CHECK FOR SEGMENT REGISTER
; AND SAVE FLAGS FOR LATER
	CMP	AL,10H
	LAHF

; SET SIZE BY REGISTER NUMBER;
; THIS USES THE CARRY FLAG TO
; AVOID JUMPS
	CMP	AL,8
	SBB	AL,AL
	ADD	AL,2
	MOV	[WADJ],AL

; NOW ACT ON SEGMENT REGISTER
	SAHF
	SBB	AL,AL
	ADD	AL,2

; SAVE REGISTER NUMBER AND SIZE
	AND	DH,7
	MOV	DL,AL
	JMP	WARG

; HANDLE MEMORY REFERENCE
RAM:	INC	SI

; CHECK FOR SIZE OVERRIDE AGAIN
	CALL	BORW
	XOR	DX,DX
	XOR	CL,CL

; SIMPLE EXPRESSION EVALUATOR
RAD:	CALL	CC
	JZ	RA8
	CMP	AL,5DH
	JZ	RADX
	CMP	AL,2BH
	JZ	RADP
	CMP	AL,2DH
	JZ	RADM

; IF NOT PLUS, MINUS, OR
; BRACKET, IT'S AN OPERAND
	CALL	SCREG
	JZ	RADR
	PUSH	DX
	CALL	GV
	POP	DX
	JC	RA1
	ADD	[DISP],AX
	JMP	SHORT RAD

; SET OPERATOR FLAG
RADM:	XOR	CL,80H
RADP:	AND	CL,0BFH
	INC	SI
	JMP	SHORT RAD

; PREPARE REGISTER FLAGS
; BY ROTATING A BIT INTO
; POSITION AND PUTTING INTO
; OPERAND FLAGS, THEN TO BE
; USED IN THE BITMASK TO
; CHECK FOR DUPLICATES. SINCE
; THERE ARE ONLY FOUR VALID
; REGISTERS, THERE ARE ONLY
; FOUR BITS, SO A 16-BYTE
; LOOKUP TABLE ALONG WITH THE
; BIT MASK CAN BE USED TO
; TEST FOR ILLEGAL COMBINATIONS
RADR:	MOV	DL,1
	CMP	AL,11
	JZ	BXD
	CMP	AL,13
	JZ	BPD
	CMP	AL,14
	JZ	SID
	CMP	AL,15
	JZ	DID
	CALL	GSPR
	JNC	RAD

; IF THE REGISTER IS NEITHER A
; VALID INDEX OR SEGMENT,
; RAISE INVALID REGISTER ERROR
RA0D:	MOV	AL,0DH
	JMP	FAIL

; INVALID ADDRESSING ERROR
RA2:	MOV	AL,2
	JMP	FAIL

; BITMASK ROTATION SLIDE
SID:	SHL	DL,1
DID:	SHL	DL,1
BPD:	SHL	DL,1

; REGISTER USED?
BXD:	TEST	DH,DL
	JNZ	RA2
	TEST	CL,80H
	JNZ	RA2
	OR	DH,DL
	OR	CL,40H
	JMP	SHORT RAD
RA8:	MOV	AL,8
	JMP	FAIL

; IS OPERAND THERE?  NO
; DANGLING OPERATORS?
RADX:	TEST	CL,40H
	JZ	RA8
	INC	SI

; CHECK FOR VALID REGISTER
; COMBINATION
	MOV	AL,DH
	MOV	BX,RM
	XLATB
	CMP	AL,0FFH
	JZ	RA0D

; ISOLATE IDENTIFIER FLAG
	MOV	DL,3
	MOV	DH,AL

; NO REGISTERS USED?
	CMP	AL,0EH
	JZ	RADW

; NAMED ADDRESS IS RESOLVED
; AS WORD-SIZED
	AND	CL,DL
	JNZ	RADW

; NUMERIC VALUE IS EVALUATED
; FOR SIZE
	MOV	AX,[DISP]
	TEST	AX,AX
	JNZ	RADB
	CMP	DH,6
	JNZ	WARG
RADB:	MOV	CL,8
	CALL	AA
	JZ	WARG
RADW:	MOV	CL,0CH

; SET ARGUMENT TYPE
WARG:	OR	[FLAGS],CL
	MOV	AX,[WADJ]
	MOV	CL,4

; IF ONE OPERAND PRESENT,
; ROTATE IT INTO POSITION
	TEST	BYTE [ARGS],0FH
	JZ	NARGS
	ROL	AX,CL
	ROL	DX,CL
NARGS:	OR	[SIZES],AX
	OR	[ARGS],DX
	CALL	CC
	JNZ	COMMA
	MOV	AX,[ARGS]
	MOV	CH,[SIZES]
	RET

; CHECK FOR COMMA BETWEEN
; OPERANDS
COMMA:	INC	SI
	CMP	AL,3AH
	JZ	COL
	CMP	AL,2CH
	JNZ	GSPR1
	CALL	CC
	JZ	RA8
	JMP	RA

; COLON AS OPERAND IS A SPECIAL
; CASE TO DENOTE SEGMENT:OFFSET
; ADDRESSING
COL:	MOV	AL,[ARGS]
	CMP	AL,4
	JNZ	GSPR1
	MOV	AX,[IMM]
	XCHG	AX,[DISP]
	MOV	[IMM],AX
	CALL	RE
	MOV	DX,304H
	AND	DH,CL
	MOV	CL,0FH
	JMP	SHORT WARG
GSPR0:	STC
	RET
GSPR1:	MOV	AL,1
	JMP	FAIL

; --------------------------------
; SCAN AND VERIFY SEGMENT PREFIX
GSPR:	CMP	AL,10H
	JC	GSPR0
	XCHG	AL,AH
	CALL	CC
	XCHG	AL,AH
	JZ	GSPR0

; A COLON IS REQUIRED FOR A
; SEGMENT PREFIX
	CMP	AH,3AH
	JNZ	GSPR0
	AND	AL,3
	SHL	AL,1
	SHL	AL,1
	SHL	AL,1
	OR	AL,26H
GSPR2:	INC	SI
	MOV	[SEGPRE],AL
	MOV	AL,[FLAGS]
	TEST	AL,40H
	JNZ	GSPR1
	OR	AL,40H
	MOV	[FLAGS],AL
	CLC
	RET

; --------------------------------
; SCAN REGISTER AND RETURN
; REGISTER INDEX
SCREG:	PUSH	CX
	CMP	BX,2
	JNZ	SCREG0
	MOV	AX,[SI]
	MOV	DI,REGS
	MOV	CX,14H
	CLD
	REPNE SCASW
	JNZ	SCREG0
	ADD	SI,BX
	MOV	AL,13H
	SUB	AL,CL
	XOR	BX,BX
SCREG0:	POP	CX
	RET

; --------------------------------
; ADJUST AND CHECK OPERAND
; SIZE CORRESPONDENCE
WA:	PUSH	AX
	PUSH	CX

; SPLIT ARGUMENT SIZE NYBBLES
; INTO BYTES
	AND	AL,0F0H
	MOV	AH,CH
	XCHG	AL,CH
	SHR	AH,CL

; MASK OUT ARGUMENTS
	AND	AX,0F0FH
	JZ	WAZ
	TEST	AL,AL
	JZ	WALZ
	TEST	AH,AH
	JZ	WAHZ
	CMP	AL,AH
	JZ	WAHZ
	CMP	CH,40H
	JZ	WAHZ

; OPERAND SIZE MISMATCH ERROR
WA6:	MOV	AL,6
	JMP	FAIL

; INVALID OPERAND ERROR
WA0:	XOR	AL,AL
	JMP	FAIL

; ONLY ONE OPERAND IS EXPLICIT
WALZ:	MOV	AL,AH
WAHZ:	CMP	AL,3
	JNC	WA0
	DEC	AX

; EQUAL OR NO EXPLICIT KNOWN
; OPERAND SIZE
WAZ:	MOV	[WADJ],AL
	TEST	BYTE [FLAGS],2
	JZ	WAE
	TEST	AL,AL
	JZ	WAB
	CMP	AH,1
	JZ	WAB
	OR	BYTE [FLAGS],1
WAE:	POP	CX
	POP	AX
	RET

; FITS IN A BYTE?
WAB:	AND	BYTE [FLAGS],0FEH
	TEST	BYTE [FUNC],1
	JNZ	WAE
	MOV	AX,[IMM]
	TEST	AH,AH
	JZ	WAE
	CALL	AA
	JZ	WAE

; CONSTANT TOO LARGE ERROR
WA7:	MOV	AL,7
	JMP	FAIL

; --------------------------------
; GENERATE VALID MODIFIER BYTE
; BASED ON ENCODED OPERANDS
MMODRM:	OR	BYTE [FLAGS],10H
	MOV	AX,[ARGS]
	MOV	CL,4
	CMP	AL,11H
	JZ	MREGR
	CMP	AL,12H
	JZ	MREGL
	CMP	AL,13H
	JZ	MMEMR
	CMP	AL,21H
	JZ	MREGR
	CMP	AL,23H
	JZ	MMEMR
	CMP	AL,31H
	JZ	MMEML
	CMP	AL,32H
	JZ	MMEML

; ONLY ONE OPERAND?
	AND	AX,0F0FH
	CMP	AL,1
	JZ	MREGR
	CMP	AL,3
	JZ	MMEMR
	MOV	AX,[ARGS]
	ROR	AX,CL
	AND	AX,0F0FH
	CMP	AL,1
	JZ	MREGR
	CMP	AL,3
	JZ	MMEMR
	RET

; R/M DESTINATION:
; TO BE ROTATED INTO POSITION
MMEML:	ROR	AH,CL
MMEMR:	MOV	AL,AH
	PUSH	AX
	AND	AX,7007H
	ROR	AH,1
	OR	AL,AH
	OR	[MODRM],AL
	POP	AX
	AND	AL,8
	JNZ	MM0

; SET MODIFIER BITS ACCORDING
; TO DISPLACEMENT
	MOV	AL,[FLAGS]
	AND	AL,0CH
	JZ	MM0
	MOV	AH,40H
	AND	AL,4
	JZ	MM8
	SHL	AH,1
	JMP	SHORT MM8

; SEGMENT REGISTER DESTINATION
; ALSO TO BE ROTATED
MREGL:	ROR	AH,CL
MREGR:	MOV	AL,AH
	ROR	AH,1
	AND	AX,3807H

; SET REGISTER MODIFIER
	OR	AL,0C0H
	OR	AH,AL
MM8:	OR	[MODRM],AH
MM0:	RET

; --------------------------------
; SHIFT AND ROTATE HANDLER
G2:	CALL	RA

; REMEMBER DETECTED ARGUMENTS
	PUSH	AX

; NEGLECT THEM FOR PURPOSES OF
; GENERATING A MODIFIER
	AND	AX,0F0FH
	MOV	[ARGS],AX

; MODIFIER EXTENSION IS IN TABLE
	MOV	AL,0D0H
	XCHG	AL,[OPCODE]
	MOV	[MODRM],AL

; GET OPERATION SIZE
	MOV	AL,CH
	AND	AL,0FH
	JZ	G2B
	DEC	AX
	JZ	G2B
	OR	[OPCODE],AL

; HANDLE DETECTED OPERANDS
G2B:	POP	AX

; ALLOW NON-CANON SINGLE
; OPERAND FORM
	AND	AX,0F0F0H
	JZ	G2N

; OTHERWISE SECOND OPERAND MUST
; BE EITHER CL OR 1
	CMP	AX,1010H
	JZ	G2CL
	CMP	AL,40H
	JNZ	G2F
	MOV	AX,[IMM]
	CMP	AX,1
	JZ	G2N

; SYNTAX ERROR
G2F:	MOV	AL,1
	JMP	FAIL
G2CL:	OR	BYTE [OPCODE],2
G2N:	AND	BYTE [FLAGS],0FCH
	JMP	MMODRM

; --------------------------------
; ARITHMETIC/LOGIC HANDLER
G1:	CALL	RA
	CALL	WA
	MOV	CH,4
	AND	AH,0FH
	CMP	AX,41H
	JZ	G1AI
	CMP	AL,11H
	JZ	G1MR
	CMP	AL,13H
	JZ	G1MR
	CMP	AL,31H
	JZ	G1RM
	CMP	AL,41H
	JZ	G1MI
	CMP	AL,43H
	JNZ	ERR0

; 80-83 GROUP
G1MI:	MOV	AL,80H
	XCHG	AL,[OPCODE]
	OR	[MODRM],AL

; IF IMMEDIATE FITS IN ONE BYTE
; USE SPECIAL 82 OPCODES
	MOV	AX,[IMM]
	CALL	AA
	JNZ	G1MR
	MOV	AL,[SIZES]
	CMP	AL,22H
	JZ	G1MR
	AND	BYTE [FLAGS],0FEH
	TEST	BYTE [WADJ],0FFH
	JZ	G1MR
G1RM:	OR	BYTE [OPCODE],2
G1MR:	MOV	AL,[WADJ]
	OR	[OPCODE],AL
	JMP	MMODRM
G1AI:	MOV	AL,[WADJ]
	OR	AL,CH
	OR	[OPCODE],AL
	RET
ERR0:	MOV	AL,0
	JMP	FAIL

; --------------------------------
; ADVANCED ARITHMETIC/LOGIC
; TEST / MUL / DIV / NEG / NOT
G3:	CALL	RA
	CALL	WA
	MOV	CH,0A8H
	AND	AH,0FH
	CMP	AX,41H
	JZ	G1AI
	MOV	CH,0F6H
	CMP	AL,1
	JZ	G3R
	CMP	AL,3
	JZ	G3R
	CMP	AL,41H
	JZ	G3R
	CMP	AL,43H
	JZ	G3R
	MOV	CH,84H
	CMP	AL,11H
	JZ	G3R
	CMP	AL,13H
	JZ	G3R
	CMP	AL,31H
	JNZ	ERR0
G3R:	MOV	AL,[WADJ]
	OR	AL,CH
	XCHG	AL,[OPCODE]
	OR	[MODRM],AL
	JMP	MMODRM

; --------------------------------
; SINGLE OPERAND [GENERALLY]
; ONE-BYTE INSTRUCTIONS
G4:	CALL	RA
	CALL	WA
	CMP	AL,2
	JZ	G4S
	CMP	AL,3
	JZ	G4M
	CMP	AL,1
	JNZ	ERR0
	CMP	CH,2
	JC	G4M
	MOV	AL,[OPCODE]
	AND	AL,18H
	OR	AL,40H
	OR	AL,AH
	MOV	[OPCODE],AL
	RET

; R/M OPERANDS USE MULTI-BYTE
; EXTENSION OPCODES; POP IS A
; SPECIAL CASE SCENARIO
G4M:	MOV	AL,[OPCODE]
	CMP	AL,38H
	MOV	AX,8FH
	JZ	G4P
	MOV	AL,[WADJ]
	TEST	CH,CH
	JNZ	G4W
	INC	AX

; EVERYTHING ELSE GOES TO FE/FF
G4W:	OR	AL,0FEH
	MOV	AH,[OPCODE]
G4P:	MOV	[OPCODE],AX
	JMP	MMODRM

; ROTATE BY 3, AS CX IS
; ALREADY 4
G4S:	DEC	CX
	SHL	AH,CL
	MOV	AL,[OPCODE]

; SEG PSEUDOINSTRUCTION IS A
; SPECIAL CASE
	CMP	AL,26H
	JZ	G4PSR
	SHR	AL,CL
	AND	AL,1
G4PSR:	OR	AL,AH
	OR	AL,6
	MOV	[OPCODE],AL
	RET

; --------------------------------
; NEAR AND FAR JUMPS AND CALLS
G6:	CALL	RA

; INDIRECT VIA REGISTER
	CMP	AL,1
	JZ	G6R

; DIRECT LABEL/CONSTANT
	CMP	AL,4
	JZ	G6I

; EXPLICITLY SPECIFIED
; SEGMENT:OFFSET ADDRESSING
	CMP	AL,44H
	JZ	G6IF

; INDIRECT VIA MEMORY
	CMP	AL,3
	JNZ	G6F0
G6R:	MOV	AL,[SIZES+1]
	CMP	AL,8
	JZ	G6F0
	CMP	AL,9
	JZ	G6RN
	CMP	AL,0AH
	JZ	G6RF

; IF NO DISTANCE OVERRIDE IS
; SPECIFIED, CHECK FOR SIZE
; OVERRIDES
	MOV	AL,CH
	CMP	AL,0
	JZ	G6RN
	CMP	AL,2
	JZ	G6RN
	CMP	AL,3
	JNZ	G6F0

; AT LEAST SOME ENCODING IS
; SUFFICIENTLY REGULAR
G6RF:	OR	BYTE [MODRM],8
G6RN:	MOV	CL,0FFH
	XCHG	CL,[OPCODE]
	MOV	AL,10H
	SHL	AL,CL
	OR	[MODRM],AL
	JMP	MMODRM

; FAR AND SHORT JUMPS NEED
; EXPLICIT OVERRIDES SINCE NEAR
; JUMP IS THE DEFAULT
G6I:	MOV	AL,[SIZES+1]
	CMP	AL,0
	JZ	G6IN
	CMP	AL,8
	JZ	G6IS
	CMP	AL,9
	JZ	G6IN
	CMP	AL,0AH
	JNZ	G6F0

; EXPLICIT SEGMENT:OFFSET FORM
; NEEDS NO OVERRIDES
G6IF:	MOV	AX,[IMM]
	XCHG	AX,[DISP]
	MOV	[IMM],AX
	OR	BYTE [FLAGS],0FH
	MOV	AX,9AEAH
	XCHG	AH,[OPCODE]
	TEST	AH,AH
	JZ	G5X
	MOV	[OPCODE],AL
G5X:	RET

; JMP SHORT OVERLAPS WITH OTHER
; SHORT JUMPS
G6IS:	MOV	AL,0EBH
	XCHG	AL,[OPCODE]
	TEST	AL,AL
	JNZ	G5S
G6F0:	MOV	AL,0
	JMP	FAIL

; REGULAR NEAR JUMP AS WE KNOW
G6IN:	MOV	AX,[IMM]
	SUB	AX,[PC]
	SUB	AX,3
	MOV	[IMM],AX
	OR	BYTE [FLAGS],3
	OR	BYTE [OPCODE],0E8H
	RET

; --------------------------------
; SHORT, TYPICALLY CONDITIONAL
; BRANCHES
G5:	CALL	RA

; ONLY ONE TRAILING BYTE
G5S:	AND	BYTE [FLAGS],0FEH

; CONVERT ABSOLUTE ADDRESS TO
; RELATIVE VALUE
	MOV	AX,[IMM]
	SUB	AX,[PC]
	SUB	AX,2
	MOV	[IMM],AX

; NEGLECT TO CHECK JUMP LENGTH
; UNTIL EVALUATION
	TEST	BYTE [FUNC],2
	JZ	G5X
	CALL	AA
	JZ	G5X

; JUMP OUT OF RANGE ERROR
	MOV	AL,5
	JMP	FAIL

; --------------------------------
; LDS / LEA / LES DESERVE THEIR
; OWN LITTLE CATEGORY SO WE
; NEEDN'T DEAL WITH MORE KLUDGES
G8:	CALL	RA
	CMP	AL,31H
	JNZ	G6F0
	JMP	MMODRM

; --------------------------------
; MOV HANDLER
G9:	CALL	RA
	CALL	WA
	XOR	CH,CH

; THESE ARE BASICALLY LDA/STA
	CMP	AX,0E031H
	JZ	G9A
	CMP	AX,0E13H
	JZ	G9A2
	CMP	AL,11H
	JZ	G9MR
	CMP	AL,13H
	JZ	G9MR
	CMP	AL,21H
	JZ	G9SR
	CMP	AL,23H
	JZ	G9SR
	CMP	AL,43H
	JZ	G9MI

; DIRECTION CHANGE
	MOV	CH,2
	CMP	AL,12H
	JZ	G9SR
	CMP	AL,31H
	JZ	G9MR
	CMP	AL,32H
	JZ	G9SR

; SINGLE BYTE MOVES
	MOV	CH,0B0H
	CMP	AL,41H
	JNZ	G9F0
	MOV	AL,[WADJ]
	DEC	CX
	SHL	AL,CL
	JMP	SHORT G9S
G9A2:	MOV	CH,2
G9A:	MOV	AX,[DISP]
	MOV	[IMM],AX
	MOV	AL,[FLAGS]
	AND	AX,0E3H
	OR	AL,3
	MOV	[FLAGS],AL
	MOV	AL,[WADJ]
	OR	AL,0A0H
G9S:	OR	AL,AH
	OR	AL,CH
	MOV	[OPCODE],AL
	RET
G9SR:	MOV	AL,8CH
	MOV	[OPCODE],AL
	JMP	SHORT G9M
G9MI:	MOV	AL,0C6H
	MOV	[OPCODE],AL
G9MR:	MOV	AL,[WADJ]
G9M:	OR	AL,CH
	OR	[OPCODE],AL
	JMP	MMODRM

; --------------------------------
; ESC IS A MESSY AND WEIRD
; INSTRUCTION
G0EH:	CALL	RA
	CMP	AL,14H
	JZ	G0EHRM
	CMP	AL,34H
	JNZ	G9F0
G0EHRM:	MOV	AX,[IMM]
	CMP	AX,3FH
	JA	G0CHF
	MOV	AH,AL
	DEC	CX
	ROR	AL,CL
	AND	AX,707H
	ROL	AH,CL
	OR	[OPCODE],AX
	AND	BYTE [FLAGS],0FCH
	JMP	MMODRM
G9F0:	MOV	AL,0
	JMP	FAIL

; --------------------------------
; AAM AND AAD
G7:	CALL	CC
	JNZ	G7A

; NO OPERAND MEANS IMPLICIT 10
	MOV	AX,0AH
	MOV	[IMM],AX
G7B:	OR	BYTE [FLAGS],2
	RET

; OTHERWISE PROCESS OPERAND
G7A:	CALL	RE
	TEST	AH,AH
	JZ	G7B
G0CHF:	MOV	AL,7
	JMP	FAIL

; --------------------------------
; INTERRUPT CALL
G0CH:	CALL	RE

; INT 3 IS ITS OWN OPCODE
	CMP	AX,3
	JZ	G0CH3
	TEST	AH,AH
	JNZ	G0CHF
	OR	BYTE [FLAGS],2
	RET
G0CH3:	DEC	BYTE [OPCODE]
	RET

; --------------------------------
; IN / OUT
G0DH:	CALL	RA
	AND	BYTE [FLAGS],0FEH

; EXPLICIT PORT FORM
	CMP	AL,41H
	JZ	G0DHI
	CMP	AL,14H
	JZ	G0DHO
	OR	BYTE [OPCODE],8

; INDIRECT VIA DX
	CMP	AX,2011H
	JZ	G0DHI
	CMP	AX,211H
	JNZ	G9F0
G0DHO:	SHR	CH,CL
G0DHI:	MOV	AL,CH
	AND	AL,0FH
	CMP	AL,2
	JC	G0DH0
	INC	BYTE [OPCODE]
G0DH0:	RET

; --------------------------------
; XCHG
G0FH:	CALL	RA
	CALL	WA
	CMP	AL,13H
	JZ	G0FHM
	CMP	AL,31H
	JZ	G0FHM
	CMP	AL,11H
	JNZ	G9F0
	MOV	AL,[WADJ]
	TEST	AL,0FFH
	JZ	G0FHM
	MOV	AL,AH
	TEST	AL,0FH
	JZ	G0FHAR
	TEST	AL,0F0H
	JZ	G0FHRA
G0FHM:	MOV	AL,[WADJ]
	OR	AL,86H
	MOV	[OPCODE],AL
	JMP	MMODRM
G0FHAR:	SHR	AL,CL
G0FHRA:	OR	AL,90H
	MOV	[OPCODE],AL
	RET

; --------------------------------
; RET
G0BH:	CALL	CC
	JZ	G0
	CALL	RA

; IF IMMEDIATE VALUE SPECIFIED,
; ADJUST OPCODE ACCORDINGLY
	CMP	AL,4
	JNZ	G0BH1
	OR	BYTE [FLAGS],3
	DEC	BYTE [OPCODE]
G0BH1:	MOV	AL,[ARGS+3]
	CMP	AL,9
	JZ	G0
	CMP	AL,10
	JNZ	G0
G0BH2:	OR	BYTE [OPCODE],8

; --------------------------------
; INSTRUCTIONS WITHOUT OPERANDS
; JUST GET A TRAILING RET
G0:	RET

; --------------------------------
; PREFIX INSTRUCTIONS JUST GET
; WRITTEN RIGHT AWAY AND LINE
; ASSEMBLY CONTINUES
G0AH:	CALL	ASMCM2
	JMP	ASMLIN

; --------------------------------
; EVEN DIRECTIVE
D0:	MOV	AX,[PC]
	SHR	AL,1
	SBB	AL,AL
	AND	AL,20H
	MOV	[FLAGS],AL
	XOR	CX,CX
	RET

; --------------------------------
; PAGE DIRECTIVE
D8:	XOR	DX,DX
	CALL	CC
	JZ	D8X
	CALL	RE
	MOV	DX,AX
D8X:	JMP	SETEND

; --------------------------------
; WRITE ELEMENT FROM TABLE
; AT SI
WMN:	CLD
	XOR	CH,CH
	JZ	WMN2
WMN1:	LODSB
	CMP	AL,20H
	JNB	WMN1
WMN2:	LODSW
	DEC	CX
	JNS	WMN1
	JMP	WRM

; --------------------------------
; WRAPPER FOR WRITING
; DIRECTIVES
WDIR:	PUSH	SI
	MOV	SI,DIRTBL
	CALL	WMN	
	POP	SI
	MOV	AL,20H
	STOSB
	RET

; --------------------------------
; DISASSEMBLE ONE INSTRUCTION
DISASM:	MOV	BX,14

; WRITE DATA BYTE AS DB
	CALL	LDDAT
	JNC	DISAS2

; IF NOT DATA, DISASSEMBLE
	XOR	AH,AH
	MOV	AL,[OPCODE]
	MOV	BX,AX

; PREPARE SIZE ADJUSTMENT FOR
; REGISTER OPERAND BASED ON
; WORD BIT
	AND	AL,1
	SHL	AL,1
	SHL	AL,1
	SHL	AL,1
	SHL	AL,1
	MOV	[WADJ],AX

; GET MNEMONIC FOR OPCODE
	MOV	CL,[BINTBL+BX]
	TEST	CL,CL
	JS	DISAS1

; SIGNED INDEX MEANS DO NOT
; WRITE MNEMONIC QUITE YET
	PUSH	SI
	MOV	SI,MNMTBL
	CALL	WMN
	POP	SI
	MOV	AL,9
	STOSB

; INVOKE HANDLER TO DECODE
; OPERANDS
DISAS1:	MOV	BL,[BX+HDLTBL]
	SHL	BX,1
DISAS2:	MOV	AL,[OPCODE]
	CALL	[BX+DHDL]
	MOV	AX,SI
	SUB	AX,BINBUF
	MOV	[BINLEN],AX
	RET

; --------------------------------
; ACCUMULATOR AND IMMEDIATE
ACCID:	XOR	AL,AL
	CALL	WREG
	TEST	BYTE [WADJ],0FFH
	JMP	SHORT RIMMDW

; --------------------------------
; IF 10 IS ENCODED, IT CAN BE
; CONSIDERED IMPLICIT
AAMD:	LODSB
	CMP	AL,0AH
	JNZ	WHAL

; --------------------------------
; REMOVE TRAILING TAB SINCE
; THERE IS NO OPERAND
SINGD:	DEC	DI
	RET

; --------------------------------
; IMMEDIATE INTO REGISTER
RIMMD:	PUSH	SI

; THE REGISTER IS DIRECTLY
; ENCODED INTO OPCODE SERIES B*
	AND	AX,0FH
	SHL	AL,1
	PUSH	AX
	ADD	AX,REGS
	MOV	SI,AX
	MOVSW
	POP	AX
	TEST	AL,10H
	POP	SI
RIMMDW:	MOV	AL,2CH
	STOSB
	LODSW
	JNZ	WHAX

; WHOLE WORD LOADED BY DEFAULT
; SO RECEDE INPUT BUFFER IF ONLY
; A BYTE IS RELEVANT
RIMMDB:	DEC	SI
	JMP	SHORT WHAL

; --------------------------------
; GROUP 1 INSTRUCTIONS
; OPCODES 80-83
G01D:	MOV	CX,_G01D
	CALL	GRPD

; --------------------------------
; IMMEDIATE INTO R/M
RMID:	CALL	WPTR

; WRITE COMMA AND VALUE
G03DT:	MOV	AL,2CH
	STOSB
	LODSW
	TEST	BYTE [WADJ],0FFH
	JZ	RIMMDB
	CMP	BYTE [OPCODE],83H
	JNZ	WHAX
	DEC	SI

; --------------------------------
; WRITE SYMBOL OR SIGNED BYTE
WHALS:	TEST	AL,AL
	JNS	WHAL
	MOV	BYTE [DI],2DH
	INC	DI
	NEG	AL

; --------------------------------
; WRITE SYMBOL OR UNSIGNED BYTE
WHAL:	XOR	CL,CL
	CALL	WSYMA
	JNC	WHAL2
WHAL0:	CMP	AL,0A0H
	JB	WHAL1
	MOV	BYTE [DI],30H
	INC	DI
WHAL1:	CALL	HALX
	MOV	AL,48H
	STOSB
WHAL2:	RET

; --------------------------------
; SHORT BRANCHES, WITH SPECIAL
; EXCEPTION GRANTED TO JMP SHORT
; WHICH NEEDS AN ADDITIONAL
; SHORT DIRECTIVE
RELBD:	CMP	AL,0EBH
	JNE	NOTJMP
	MOV	CL,19
	CALL	WDIR
NOTJMP:	LODSB
	CBW
	ADD	AX,2
	ADD	AX,[PC]
	JMP	SHORT WHAX

; --------------------------------
; GROUP 3 INSTRUCTIONS
G03D:	MOV	CX,_G03D
	CALL	GRPD
	PUSH	WORD [SI]
	CALL	WPTR
	POP	AX
	TEST	AL,30H
	JZ	G03DT
	RET

; --------------------------------
; WRITE SIGNED WORD VALUE
WHAXS:	TEST	AX,AX
	JNS	WHAX
	MOV	BYTE [DI],2DH
	INC	DI
	NEG	AX

; --------------------------------
; WRITE UNSIGNED WORD VALUE
WHAX:	MOV	CL,0CH
	CALL	WSYMA
	JNC	WHAX2
WHAX0:	CMP	AH,0A0H
	JB	WHAX1
	MOV	BYTE [DI],30H
	INC	DI
WHAX1:	PUSH	AX
	XCHG	AL,AH
	CALL	HALX
	POP	AX
	CALL	HALX
	MOV	AL,48H
	STOSB
WHAX2:	RET

; --------------------------------
; LDA HANDLER
MACCD:	MOV	AL,6
	JMP	SHORT MRD1

; --------------------------------
; REGISTER INTO R/M
MRD:	LODSB
MRD1:	PUSH	AX
	CALL	WDISP
	MOV	AL,2CH
	STOSB
	POP	AX

; --------------------------------
; WRITE REGISTER FIELD
WREG:	CLD
	PUSH	SI
	MOV	SI,AX
	SHR	SI,1
	SHR	SI,1
	AND	SI,0EH
	JMP	SHORT WDISP1

; --------------------------------
; WRITE R/M SIZE OVERRIDE
WPTR:	LODSB
	CMP	AL,0C0H
	JNC	WDISP
	PUSH	AX
	MOV	CL,21
	TEST	BYTE [WADJ],0FFH
	JNZ	WSELF
	XOR	CL,CL
WSELF:	CALL	WDIR
	MOV	CL,18
	CALL	WDIR
	POP	AX

; --------------------------------
; WRITE R/M FIELD
WDISP:	PUSH	SI
	MOV	SI,AX
	AND	SI,7

; EVERYTHING BELOW 11XXXXXX IS
; R/M DISPLACEMENTS
	CMP	AL,0C0H
	JC	WDD
	SHL	SI,1

; 11XXXXXX AND UP IS REGISTERS
WDISP1:	ADD	SI,REGS
	ADD	SI,[WADJ]
	MOVSW
	POP	SI
	RET

; START WRITING BRACKETED
; IDEAL MODE DISPLACEMENT
WDD:	PUSH	AX
	MOV	AL,5BH
	STOSB
	POP	AX

; ISOLATE DISPLACEMENT SIZE
; AND TYPE
	AND	AL,0C7H
	CMP	AL,6
	JNZ	WDC

; BP ALONE IS NOT A THING;
; WRITE IMMEDIATE DISPLACEMENT
; ONLY
	POP	SI
	LODSW
	CALL	WHAX
	MOV	AL,5DH
	STOSB
	RET

; WRITE DISPLACEMENT REGISTER
; AND DISPLACEMENT
WDC:	PUSH	AX
	ADD	SI,_DISP
	MOV	DL,[SI]
	MOV	AL,2BH
	MOV	CL,4
WDL:	MOV	SI,DX
	AND	SI,0FH
	ADD	SI,REGS+16
	MOVSW
	STOSB
	SHR	DL,CL
	JNZ	WDL
	POP	AX
	POP	SI
	SHL	AL,1
	JC	WDW
	SHL	AL,1
	JC	WDB
WDX:	DEC	DI
	MOV	AL,5DH
	STOSB
	RET

; 16-BIT SIGNED DISPLACEMENT
WDW:	LODSW
	TEST	AX,AX
	JZ	WDX
	JNS	WDAX
	DEC	DI
WDAX:	CALL	WHAXS
	MOV	AL,5DH
	STOSB
	RET

; 8-BIT SIGNED DISPLACEMENT
WDB:	LODSB
	TEST	AL,AL
	JZ	WDX
	JNS	WDAL
	DEC	DI
WDAL:	CALL	WHALS
	MOV	AL,5DH
	STOSB
	RET

; --------------------------------
; MOVE INTO SEGMENT REGISTER
MSD:	MOV	BYTE [WADJ],10H
	LODSB
	PUSH	AX
	CALL	WDISP
	MOV	AL,2CH
	STOSB
	POP	AX

; --------------------------------
; WRITE SEGMENT REGISTER OPERAND
PSRD:	SHR	AL,1
	SHR	AL,1
	AND	AX,6
	OR	AL,20H
	ADD	AX,REGS
	XCHG	AX,SI
	CLD
	MOVSW
	XCHG	AX,SI
	RET

; --------------------------------
; MOVE FROM SEGMENT REGISTER
SMD:	MOV	BYTE [WADJ],10H
	LODSB
	PUSH	AX
	CALL	PSRD
	MOV	AL,2CH
	STOSB
	POP	AX
	JMP	WDISP

; --------------------------------
; EXCHANGE ACCUMULATOR AND
; 16-BIT REGISTER
ACCRD:	PUSH	AX
	MOV	AX,5841H
	STOSW
	MOV	AL,2CH
	STOSB
	POP	AX

; --------------------------------
; WRITE 16-BIT REGISTER OPERAND
REGWD:	MOV	BYTE [WADJ],10H
	OR	AL,0C0H
	JMP	WDISP

; --------------------------------
; DECODE AND WRITE 16-BIT
; RELATIVE OFFSET, CALL/JMP
RELWD:	LODSW
	ADD	AX,3
	ADD	AX,[PC]
	JMP	WHAX

; --------------------------------
; DECODE HORRIBLE ESC INSTRUCTION
ESCD:	MOV	AH,[SI]
	MOV	CL,3
	ROR	AH,CL
	AND	AX,707H
	ROL	AL,CL
	OR	AL,AH
	CALL	WHAL
	MOV	AL,2CH
	STOSB
	LODSB
	JMP	WDISP

; --------------------------------
; SIMPLE INT+VALUE
INTD:	LODSB
	JMP	WHAL

; --------------------------------
; INT 3 IS ITS OWN THING, SO
; JUST WRITE OUT THE DIGIT 3
INT3D:	MOV	AL,33H
	STOSB
	RET

; --------------------------------
; RETURN FAR IS RET+FAR OVERRIDE
RETFD:	MOV	CL,9
	CALL	WDIR
	TEST	BYTE [OPCODE],1
	JZ	RETD
	DEC	DI
	RET

; --------------------------------
; DECODE RET WITH ARGUMENT
; REGULAR RETS JUST FALL INTO
; GROUP WITHOUT OPERANDS
RETD:	LODSW
	JMP	WHAX

; --------------------------------
; IN/OUT INSTRUCTIONS WITH DX
; AND ACCUMULATOR
ADIOD:	MOV	AX,[WADJ]

; USE THE WORD ADJUST TO GET
; CORRECT ACCUMULATOR SIZE
	ADD	AX,REGS
	PUSH	SI
	MOV	SI,AX
	LODSW
	POP	SI
	MOV	DX,5844H

; THE DIRECTION BIT IS THE DEAD
; GIVEAWAY OF THE INSTRUCTION
	TEST	BYTE [OPCODE],2
	JZ	ADIOD0

; WRITE THE REGISTERS
	XCHG	AX,DX
ADIOD0:	STOSW
	MOV	AL,2CH
	STOSB
	XCHG	AX,DX
	STOSW
	RET

; --------------------------------
; IN INSTRUCTION
IBAPD:	LODSB
	CALL	WHAL
	MOV	AL,2CH
	STOSB
	MOV	AL,0C0H
	JMP	WDISP

; --------------------------------
; 32-BIT INDIRECT CALL OR JUMP
SEGOFD:	LODSW
	PUSH	AX
	LODSW
	CALL	WHAX
	MOV	AL,3AH
	STOSB
	POP	AX
	JMP	WHAX

; --------------------------------
; WRITE OUT GROUP INSTRUCTIONS:
; THE FOUR GROUP HANDLERS HAVE
; THEIR OWN INSTRUCTION TABLES
; SINCE SEVERAL INSTRUCTIONS WILL
; SHARE THE SAME OPCODE, AND
; THE MNEMONIC CANNOT BE WRITTEN
; UNTIL MODIFIER BYTE IS PROCESSED
GRPD:	PUSH	SI
	LODSB

; GET OPCODE EXTENSION
	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	AND	AX,7
	PUSH	AX

; CX POINTS TO GROUP-SPECIFIC
; INSTRUCTION TABLE
	MOV	SI,AX
	ADD	SI,CX
	MOV	CL,[SI]
	MOV	SI,MNMTBL

; WRITE MNEMONIC AND TAB,
; AS YOU DO
	CALL	WMN
	MOV	AL,9
	STOSB
	POP	AX
	POP	SI
	RET

; --------------------------------
; STA HANDLER
ACCMD:	MOV	AL,6
	JMP	SHORT RMD1

; --------------------------------
; LDS/LES/LEA GROUP
RWMD:	MOV	BYTE [WADJ],10H

; --------------------------------
; REGISTER TO R/M
RMD:	LODSB
RMD1:	PUSH	AX
	CALL	WREG
	MOV	AL,2CH
	STOSB
	POP	AX
	JMP	WDISP

; --------------------------------
; GROUP 2: SHIFTS AND ROTATES
G02D:	MOV	CX,_G02D
	CALL	GRPD
	CALL	WPTR
	MOV	AL,2CH
	STOSB

; ONLY CL OR 1 ARE VALID
	TEST	BYTE [OPCODE],2
	JZ	G02D1
	MOV	AX,4C43H
	STOSW
	RET
G02D1:	MOV	AL,31H
	STOSB
	RET

; --------------------------------
; GROUP 4
G04D:	MOV	CX,_G04D
	CALL	GRPD

; SOME OF THEM NEED SIZE OR
; DISTANCE OVERRIDES FOR
; DISAMBIGUATION
	CMP	AL,7
	JZ	INVD
	CMP	AL,5
	JZ	G04DF
	CMP	AL,4
	JZ	DISPD
	CMP	AL,3
	JZ	G04DF
	CMP	AL,2
	JZ	DISPD
	JMP	WPTR
G04DF:	MOV	CL,9
	CALL	WDIR

; --------------------------------
; WRITE R/M FIELD AS OPERAND
DISPD:	LODSB
	JMP	WDISP

; --------------------------------
; INVALID INSTRUCTIONS ARE
; WRITTEN AS DATA DEFINITIONS
INVD:	PUSH	AX
	MOV	AX,4244H
	STOSW
	MOV	AL,9
	STOSB
	POP	AX
	JMP	WHAL
	EVEN

; --------------------------------
; INSTRUCTION ASSEMBLY HANDLERS
IHDL:	DW	G0,G1,G2,G3
	DW	G4,G5,G6,G7
	DW	G8,G9,G0AH,G0BH
	DW	G0CH,G0DH,G0EH,G0FH

; --------------------------------
; DIRECTIVE HANDLERS
AHDL:	DW	D0,SETEQU,SETEND
	DW	SETORG,SETDFB,D5
	DW	SETDFS,SETINC,D8

; --------------------------------
; OPERAND DISASSEMBLY HANDLERS
DHDL:	DW	MRD,RMD,ACCID
	DW	PSRD,ADIOD,SINGD
	DW	REGWD,INVD,RELBD
	DW	G01D,G03D,G04D
	DW	MSD,SMD,DISPD
	DW	ACCRD,SEGOFD,ACCMD
	DW	MACCD,RIMMD,RETD
	DW	RWMD,RMID,RETFD
	DW	INT3D,INTD,G02D
	DW	AAMD,ESCD,IBAPD
	DW	RELWD

; --------------------------------
; OPERAND DECODER PER INSTRUCTION
HDLTBL:	DB	0,0,1,1,2,2,3,3
	DB	0,0,1,1,2,2,3,3
	DB	0,0,1,1,2,2,3,3
	DB	0,0,1,1,2,2,3,3
	DB	0,0,1,1,2,2,3,5
	DB	0,0,1,1,2,2,3,5
	DB	0,0,1,1,2,2,3,5
	DB	0,0,1,1,2,2,3,5
	DB	6,6,6,6,6,6,6,6
	DB	6,6,6,6,6,6,6,6
	DB	6,6,6,6,6,6,6,6
	DB	6,6,6,6,6,6,6,6
	DB	7,7,7,7,7,7,7,7
	DB	7,7,7,7,7,7,7,7
	DB	8,8,8,8,8,8,8,8
	DB	8,8,8,8,8,8,8,8
	DB	9,9,9,9,1,1,1,1
	DB	0,0,1,1
	DB	0CH,01H,0DH,0EH
	DB	05H,0FH,0FH,0FH
	DB	0FH,0FH,0FH,0FH
	DB	05H,05H,10H,05H
	DB	05H,05H,05H,05H
	DB	11H,11H,12H,12H
	DB	05H,05H,05H,05H
	DB	02H,02H,05H,05H
	DB	05H,05H,05H,05H
	DB	13H,13H,13H,13H
	DB	13H,13H,13H,13H
	DB	13H,13H,13H,13H
	DB	13H,13H,13H,13H
	DB	07H,07H,14H,05H
	DB	15H,01H,16H,16H
	DB	07H,07H,17H,17H
	DB	18H,19H,05H,05H
	DB	1AH,1AH,1AH,1AH
	DB	1BH,1BH,05H,05H
	DB	1CH,1CH,1CH,1CH
	DB	1CH,1CH,1CH,1CH
	DB	08H,08H,08H,08H
	DB	02H,02H,1DH,1DH
	DB	1EH,1EH,10H,08H
	DB	04H,04H,04H,04H
	DB	05H,07H,05H,05H
	DB	05H,05H,0AH,0AH
	DB	05H,05H,05H,05H
	DB	05H,05H,0BH,0BH

; --------------------------------
; MNEMONIC PER INSTRUCTION
BINTBL:	DB	05H,05H,05H,05H
	DB	05H,05H,55H,53H
	DB	51H,51H,51H,51H
	DB	51H,51H,55H,53H
	DB	04H,04H,04H,04H
	DB	04H,04H,55H,53H
	DB	65H,65H,65H,65H
	DB	65H,65H,55H,53H
	DB	06H,06H,06H,06H
	DB	06H,06H,68H,11H
	DB	70H,70H,70H,70H
	DB	70H,70H,68H,12H
	DB	75H,75H,75H,75H
	DB	75H,75H,68H,00H
	DB	0DH,0DH,0DH,0DH
	DB	0DH,0DH,68H,03H
	DB	1AH,1AH,1AH,1AH
	DB	1AH,1AH,1AH,1AH
	DB	13H,13H,13H,13H
	DB	13H,13H,13H,13H
	DB	55H,55H,55H,55H
	DB	55H,55H,55H,55H
	DB	53H,53H,53H,53H
	DB	53H,53H,53H,53H
	DB	80H,80H,80H,80H
	DB	80H,80H,80H,80H
	DB	80H,80H,80H,80H
	DB	80H,80H,80H,80H
	DB	38H,34H,22H,2EH
	DB	3DH,37H,2CH,1EH
	DB	3CH,36H,39H,35H
	DB	27H,32H,30H,25H
	DB	80H,80H,80H,80H
	DB	71H,71H,73H,73H
	DB	4AH,4AH,4AH,4AH
	DB	4AH,40H,4AH,53H
	DB	4FH,73H,73H,73H
	DB	73H,73H,73H,73H
	DB	08H,10H,07H,72H
	DB	56H,54H,61H,3EH
	DB	4AH,4AH,4AH,4AH
	DB	4BH,4CH,0EH,0FH
	DB	71H,71H,6EH,6FH
	DB	43H,44H,66H,67H
	DB	4AH,4AH,4AH,4AH
	DB	4AH,4AH,4AH,4AH
	DB	4AH,4AH,4AH,4AH
	DB	4AH,4AH,4AH,4AH
	DB	80H,80H,5EH,5EH
	DB	41H,3FH,4AH,4AH
	DB	80H,80H,5EH,5EH
	DB	1BH,1BH,1CH,1DH
	DB	80H,80H,80H,80H
	DB	02H,01H,63H,74H
	DB	15H,15H,15H,15H
	DB	15H,15H,15H,15H
	DB	48H,49H,45H,23H
	DB	19H,19H,52H,52H
	DB	07H,29H,29H,29H
	DB	19H,19H,52H,52H
	DB	42H,80H,5CH,5DH
	DB	16H,0CH,80H,80H
	DB	09H,6BH,0BH,6CH
	DB	0AH,6DH,80H,80H

; --------------------------------
; GROUP MNEMONIC TABLES
_G01D:	DB	05H,51H,04H,65H
	DB	06H,70H,75H,0DH
_G02D:	DB	5FH,60H,57H,58H
	DB	69H,6AH,62H,64H
_G03D:	DB	71H,71H,50H,4EH
	DB	4DH,18H,14H,17H
_G04D:	DB	1AH,13H,07H,07H
	DB	29H,29H,55H,80H

; --------------------------------
; DISPLACEMENT REGISTER INDICES
_DISP:	DB	0C6H,0E6H,0CAH,0EAH
	DB	0CH,0EH,0AH,6

; --------------------------------
; DISPLACEMENT TYPE TABLE
RM:	DB	0EH,7,6,0FFH
	DB	5,1,3,0FFH
	DB	4,0,2,0FFH
	DB	0FFH,0FFH,0FFH,0FFH

; --------------------------------
; THREE GUESSES WHAT THIS IS
REGS:	DB	"ALCLDLBLAHCHDHBH"
	DB	"AXCXDXBXSPBPSIDI"
	DB	"ESCSSSDS"

; --------------------------------
; EVERY MNEMONIC ENTRY IS LISTED
; WITH ITS MOST LIKELY EXPECTED
; OPCODE EXCEPT GROUP INSTRUCTIONS
; WHICH HAVE THEIR OPCODE
; EXTENSION INSTEAD
MNMTBL:	DW	118
	DB	"AAA",0,37H,0
	DB	"AAD",0,0D5H,7
	DB	"AAM",0,0D4H,7
	DB	"AAS",0,3FH,0
	DB	"ADC",0,10H,1
	DB	"ADD",0,0,1
	DB	"AND",0,20H,1
	DB	"CALL",0,0,6
	DB	"CBW",0,98H,0
	DB	"CLC",0,0F8H,0
	DB	"CLD",0,0FCH,0
	DB	"CLI",0,0FAH,0
	DB	"CMC",0,0F5H,0
	DB	"CMP",0,38H,1
	DB	"CMPSB",0,0A6H,0
	DB	"CMPSW",0,0A7H,0
	DB	"CWD",0,99H,0
	DB	"DAA",0,27H,0
	DB	"DAS",0,2FH,0
	DB	"DEC",0,8,4
	DB	"DIV",0,30H,3
	DB	"ESC",0,0D8H,0EH
	DB	"HLT",0,0F4H,0
	DB	"IDIV",0,38H,3
	DB	"IMUL",0,28H,3
	DB	"IN",0,0E4H,0DH
	DB	"INC",0,0,4
	DB	"INT",0,0CDH,0CH
	DB	"INTO",0,0CEH,0
	DB	"IRET",0,0CFH,0
	DB	"JA",0,77H,5
	DB	"JAE",0,73H,5
	DB	"JB",0,72H,5
	DB	"JBE",0,76H,5
	DB	"JC",0,72H,5
	DB	"JCXZ",0,0E3H,5
	DB	"JE",0,74H,5
	DB	"JG",0,7FH,5
	DB	"JGE",0,7DH,5
	DB	"JL",0,7CH,5
	DB	"JLE",0,7EH,5
	DB	"JMP",0,1,6
	DB	"JNA",0,76H,5
	DB	"JNAE",0,72H,5
	DB	"JNB",0,73H,5
	DB	"JNBE",0,77H,5
	DB	"JNC",0,73H,5
	DB	"JNE",0,75H,5
	DB	"JNG",0,7EH,5
	DB	"JNGE",0,7CH,5
	DB	"JNL",0,7DH,5
	DB	"JNLE",0,7FH,5
	DB	"JNO",0,71H,5
	DB	"JNP",0,7BH,5
	DB	"JNS",0,79H,5
	DB	"JNZ",0,75H,5
	DB	"JO",0,70H,5
	DB	"JP",0,7AH,5
	DB	"JPE",0,7AH,5
	DB	"JPO",0,7BH,5
	DB	"JS",0,78H,5
	DB	"JZ",0,74H,5
	DB	"LAHF",0,9FH,0
	DB	"LDS",0,0C5H,8
	DB	"LEA",0,8DH,8
	DB	"LES",0,0C4H,8
	DB	"LOCK",0,0F0H,0AH
	DB	"LODSB",0,0ACH,0
	DB	"LODSW",0,0ADH,0
	DB	"LOOP",0,0E2H,5
	DB	"LOOPE",0,0E1H,5
	DB	"LOOPNE",0,0E0H,5
	DB	"LOOPNZ",0,0E0H,5
	DB	"LOOPZ",0,0E1H,5
	DB	"MOV",0,88H,9
	DB	"MOVSB",0,0A4H,0
	DB	"MOVSW",0,0A5H,0
	DB	"MUL",0,20H,3
	DB	"NEG",0,18H,3
	DB	"NOP",0,90H,0
	DB	"NOT",0,10H,3
	DB	"OR",0,8,1
	DB	"OUT",0,0E6H,0DH
	DB	"POP",0,38H,4
	DB	"POPF",0,9DH,0
	DB	"PUSH",0,30H,4
	DB	"PUSHF",0,9CH,0
	DB	"RCL",0,10H,2
	DB	"RCR",0,18H,2
	DB	"REP",0,0F3H,0AH
	DB	"REPE",0,0F3H,0AH
	DB	"REPNE",0,0F2H,0AH
	DB	"REPNZ",0,0F2H,0AH
	DB	"REPZ",0,0F3H,0AH
	DB	"RET",0,0C3H,0BH
	DB	"ROL",0,0,2
	DB	"ROR",0,8,2
	DB	"SAHF",0,9EH,0
	DB	"SAL",0,30H,2
	DB	"SALC",0,0D6H,0
	DB	"SAR",0,38H,2
	DB	"SBB",0,18H,1
	DB	"SCASB",0,0AEH,0
	DB	"SCASW",0,0AFH,0
	DB	"SEG",0,26H,4
	DB	"SHL",0,20H,2
	DB	"SHR",0,28H,2
	DB	"STC",0,0F9H,0
	DB	"STD",0,0FDH,0
	DB	"STI",0,0FBH,0
	DB	"STOSB",0,0AAH,0
	DB	"STOSW",0,0ABH,0
	DB	"SUB",0,28H,1
	DB	"TEST",0,0,3
	DB	"WAIT",0,9BH,0
	DB	"XCHG",0,86H,0FH
	DB	"XLATB",0,0D7H,0
	DB	"XOR",0,30H,1

; --------------------------------
; ASSEMBLER DIRECTIVES
DIRTBL:	DW	22
	DB	"BYTE",0,1,5
	DB	"DB",0,1,4
	DB	"DD",0,4,4
	DB	"DS",0,0,6
	DB	"DW",0,2,4
	DB	"DWORD",0,3,5
	DB	"END",0,0FFH,2
	DB	"EQU",0,0,1
	DB	"EVEN",0,90H,0
	DB	"FAR",0,0AH,5
	DB	"INCBIN",0,0FDH,7
	DB	"INCLUDE",0,0FEH,7
	DB	"HIGH",0,13H,5
	DB	"LOW",0,12H,5
	DB	"NEAR",0,9,5
	DB	"OFFSET",0,11H,5
	DB	"ORG",0,0,3
	DB	"PAGE",0,0FCH,8
	DB	"PTR",0,10H,5
	DB	"SHORT",0,8,5
	DB	"TITLE",0,0FBH,7
	DB	"WORD",0,2,5
