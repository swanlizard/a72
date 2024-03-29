ASM:	MOV	[STK],SP
	XOR	AX,AX
	MOV	[BINLEN],AX
	MOV	SI,[TXTBUF]
	MOV	AL,[FUNC]
	TEST	AL,AL
	JNS	ASMLIN
	XOR	AX,AX
	MOV	[TXTLEN],AX
	MOV	SI,[BINBUF]
	MOV	DI,[TXTBUF]
	JMP	DISASM
ASMLBL:	CALL	LBL
ASMLIN:	MOV	SP,[STK]
	XOR	AX,AX
	MOV	DI,WADJ
	MOV	CX,7
	CLD
	REP STOSW
	CALL	CC
	JZ	ASMEND
	MOV	DI,I8086
	MOV	DX,IHDL
	CALL	ASMCMD
	JZ	WROUT
	MOV	DI,D8086
	MOV	DX,AHDL
	CALL	ASMCMD
	JZ	WROUT
	CALL	SCREG
	JNZ	ASMLBL
	CALL	GSPR
	JC	D5
G0AH:	MOV	AX,ASMLIN
	PUSH	AX
WROUT:	XOR	DL,DL
	XCHG	DL,[FLAGS]
	SHL	DL,1
	JZ	ASMEND
	MOV	DI,[BINBUF]
	ADD	DI,[BINLEN]
	PUSH	SI
	PUSH	DI
	MOV	SI,SEGPRE
	CLD
WROUT1:	LODSB
	SHL	DL,1
	JNC	WROUT2
	STOSB
WROUT2:	JNZ	WROUT1
	POP	CX
	POP	SI
	XCHG	CX,DI
	SUB	CX,DI
	ADD	[BINLEN],CX
	ADD	[PC],CX
ASMEND:	CLC
	RET
RNM:	PUSH	AX
	CALL	SW
	JNZ	RNMEND
	ADD	SI,BX
	MOV	AH,4
	CMP	AL,11H
	JZ	RNMOFF
	CMP	AL,12H
	JZ	RNMLO
	CMP	AL,13H
	JZ	RNMHI
D5:	MOV	AL,0CH
	JMP	FAIL
RNMOFF:	SHL	AH,1
RNMHI:	SHL	AH,1
RNMLO:	OR	CL,AH
	CALL	CC
	JZ	RNMER8
	CMP	AL,AL
RNMEND:	POP	AX
	RET
RNMER8:	MOV	AL,8
	JMP	FAIL
BORW:	CALL	CC
	JZ	RNMER8
	CALL	SW
	JNZ	BORW2
	CMP	AL,10H
	JZ	RA1
	JNC	BORW2
	ADD	SI,BX
	MOV	DI,WADJ
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
	ADD	SI,BX
	CALL	CC
BORW2:	RET
RA:	XOR	DX,DX
	XOR	CX,CX
	MOV	[WADJ],DX
RAS:	CALL	BORW
	JC	RAIX
	CMP	AL,5BH
	JZ	RAM
	CALL	SCREG
	JZ	RAR
RAL:	CALL	RI
	MOV	DX,304H
	XCHG	DH,CL
	AND	DH,CL
	JNZ	RAIW
	TEST	AH,AH
	JZ	RAIB
	CALL	AA
	JC	RAIW
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
RAR:	CALL	GSPR
	JNC	RAS
	MOV	DH,AL
	CMP	AL,10H
	LAHF
	CMP	AL,8
	SBB	AL,AL
	ADD	AL,2
	MOV	[WADJ],AL
	SAHF
	SBB	AL,AL
	ADD	AL,2
	AND	DH,7
	MOV	DL,AL
	JMP	WARG
RAM:	INC	SI
	CALL	BORW
	XOR	DX,DX
	XOR	CL,CL
RAD:	CALL	CC
	JZ	RA8
	CMP	AL,5DH
	JZ	RADX
	CMP	AL,2BH
	JZ	RADP
	CMP	AL,2DH
	JZ	RADM
	CALL	SCREG
	JZ	RADR
	PUSH	DX
	MOV	DL,24H
	CALL	GV
	POP	DX
	JC	RA1
	ADD	[DISP],AX
	JMP	SHORT RAD
RADM:	XOR	CL,80H
RADP:	AND	CL,0BFH
	INC	SI
	JMP	SHORT RAD
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
RA0D:	MOV	AL,0DH
	JMP	FAIL
RA2:	MOV	AL,2
	JMP	FAIL
SID:	SHL	DL,1
DID:	SHL	DL,1
BPD:	SHL	DL,1
BXD:	TEST	DH,DL
	JNZ	RA2
	TEST	CL,80H
	JNZ	RA2
	OR	DH,DL
	OR	CL,40H
	JMP	SHORT RAD
RA8:	MOV	AL,8
	JMP	FAIL
RADX:	TEST	CL,40H
	JZ	RA8
	INC	SI
	MOV	AL,DH
	MOV	BX,RM
	XLATB
	CMP	AL,0FFH
	JZ	RA0D
	MOV	DL,3
	MOV	DH,AL
	CMP	AL,0EH
	JZ	RADW
	AND	CL,DL
	JNZ	RADW
	MOV	AX,[DISP]
	TEST	AX,AX
	JNZ	RADB
	CMP	DH,6
	JNZ	WARG
RADB:	MOV	CL,8
	CALL	AA
	JNC	WARG
RADW:	MOV	CL,0CH
WARG:	OR	[FLAGS],CL
	MOV	AX,[WADJ]
	MOV	CL,4
	TEST	BYTE [ARGS],0FH
	JZ	NARGS
	ROL	AX,CL
	ROL	DX,CL
NARGS:	OR	[ARGS+2],AX
	OR	[ARGS],DX
	CALL	CC
	JNZ	COMMA
	MOV	AX,[ARGS]
	MOV	CH,[ARGS+2]
	RET
COMMA:	INC	SI
	CMP	AL,3AH
	JZ	COL
	CMP	AL,2CH
	JNZ	GSPR1
	CALL	CC
	JZ	RA8
	JMP	RA
COL:	MOV	AL,[ARGS]
	CMP	AL,4
	JNZ	GSPR1
	MOV	AX,[IMM]
	XCHG	AX,[DISP]
	MOV	[IMM],AX
	CALL	RI
	MOV	DX,304H
	AND	DH,CL
	MOV	AL,2
	MOV	CL,0FH
	JMP	SHORT WARG
GSPR1:	MOV	AL,1
	JMP	FAIL
GSPR:	CMP	AL,10H
	JC	GSPR0
	XCHG	AL,AH
	CALL	CC
	XCHG	AL,AH
	JZ	GSPR0
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
RNC:	PUSH	AX
	PUSH	CX
	PUSH	SI
	MOV	CL,5
	CMP	AL,30H
	JB	RNC1
	CMP	AL,3AH
	JNB	RNC1
	LEA	DI,[BX+SI]
	DEC	BX
	MOV	AL,[BX+SI]
	CMP	AL,42H
	JE	RNC2
	CMP	AL,48H
	JE	RNC16
	CMP	AL,4FH
	JE	RNC8
	CMP	AL,51H
	JE	RNC8;RNC4
	INC	BX
	CMP	AL,30H
	JB	RNC1
	CMP	AL,3AH
	JB	RNC10
RNC1:	POP	SI
	POP	CX
	POP	AX
GSPR0:	STC
	RET
RNC2:	DEC	CX
RNC4:	DEC	CX
RNC8:	DEC	CX
RNC16:	DEC	CX
RNC10:	CALL	RN
	JNZ	RNC1
	POP	SI
	MOV	SI,DI
RNC0:	POP	CX
	POP	AX
	CLC
	RET
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
SW:	PUSH	CX
	PUSH	DX
	PUSH	BX
	PUSH	SI
	MOV	DI,D8086
	CALL	SL
	POP	SI
	POP	BX
	POP	DX
	POP	CX
	JNZ	SW1
	CMP	AH,5
	JZ	SW2
SW1:	MOV	AX,[SI]
SW2:	RET
ASMCMD:	XOR	BYTE [FLAGS],20H
	PUSH	DX
	CALL	SL
	POP	DI
	JNZ	SW2
	XCHG	AL,[OPCODE]
	XCHG	AL,AH
	SHL	AX,1
	ADD	DI,AX
	CALL	[DI]
	CALL	CC
	JZ	SW2
	MOV	AL,9
	JMP	FAIL
WA:	PUSH	AX
	PUSH	CX
	AND	AL,0F0H
	MOV	AH,CH
	XCHG	AL,CH
	SHR	AH,CL
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
WA6:	MOV	AL,6
	JMP	FAIL
WA0:	XOR	AL,AL
	JMP	FAIL
WALZ:	MOV	AL,AH
WAHZ:	CMP	AL,3
	JNC	WA0
	DEC	AX
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
WAB:	AND	BYTE [FLAGS],0FEH
	TEST	BYTE [FUNC],1
	JNZ	WAE
	MOV	AX,[IMM]
	TEST	AH,AH
	JZ	WAE
	CALL	AA
	JNC	WAE
WA7:	MOV	AL,7
	JMP	FAIL
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
	MOV	AL,[FLAGS]
	AND	AL,0CH
	JZ	MM0
	MOV	AH,40H
	AND	AL,4
	JZ	MM8
	SHL	AH,1
	JMP	SHORT MM8
MREGL:	ROR	AH,CL
MREGR:	MOV	AL,AH
	ROR	AH,1
	AND	AX,3807H
	OR	AL,0C0H
	OR	AH,AL
MM8:	OR	[MODRM],AH
MM0:	RET
G2:	CALL	RA
	PUSH	AX
	AND	AX,0F0FH
	MOV	[ARGS],AX
	MOV	AL,0D0H
	XCHG	AL,[OPCODE]
	MOV	[MODRM],AL
	MOV	AL,CH
	AND	AL,0FH
	JZ	G2B
	DEC	AX
	JZ	G2B
	OR	[OPCODE],AL
G2B:	POP	AX
	AND	AX,0F0F0H
	JZ	G2N
	CMP	AX,1010H
	JZ	G2CL
	CMP	AL,40H
	JNZ	G2F
	MOV	AX,[IMM]
	CMP	AX,1
	JZ	G2N
G2F:	MOV	AL,1
	JMP	FAIL
G2CL:	OR	BYTE [OPCODE],2
G2N:	AND	BYTE [FLAGS],0FCH
	JMP	MMODRM
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
G1MI:	MOV	AL,80H
	XCHG	AL,[OPCODE]
	OR	[MODRM],AL
	MOV	AX,[IMM]
	CALL	AA
	JC	G1MR
	MOV	AL,[ARGS+2]
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
G4M:	MOV	AL,[OPCODE]
	CMP	AL,38H
	MOV	AX,8FH
	JZ	G4P
	MOV	AL,[WADJ]
	TEST	CH,CH
	JNZ	G4W
	INC	AX
G4W:	OR	AL,0FEH
	MOV	AH,[OPCODE]
G4P:	MOV	[OPCODE],AX
	JMP	MMODRM
G4S:	DEC	CX
	SHL	AH,CL
	MOV	AL,[OPCODE]
	SHR	AL,CL
	AND	AL,1
	OR	AL,AH
	OR	AL,6
	MOV	[OPCODE],AL
	RET
G6:	CALL	RA
	CMP	AL,1
	JZ	G6R
	CMP	AL,4
	JZ	G6I
	CMP	AL,44H
	JZ	G6IF
	CMP	AL,3
	JNZ	G6F0
G6R:	MOV	AL,[ARGS+3]
	CMP	AL,8
	JZ	G6F0
	CMP	AL,9
	JZ	G6RN
	CMP	AL,0AH
	JZ	G6RF
	MOV	AL,CH
	CMP	AL,0
	JZ	G6RN
	CMP	AL,2
	JZ	G6RN
	CMP	AL,3
	JNZ	G6F0
G6RF:	OR	BYTE [MODRM],8
G6RN:	MOV	CL,0FFH
	XCHG	CL,[OPCODE]
	MOV	AL,10H
	SHL	AL,CL
	OR	[MODRM],AL
	JMP	MMODRM
G6I:	MOV	AL,[ARGS+3]
	CMP	AL,0
	JZ	G6IN
	CMP	AL,8
	JZ	G6IS
	CMP	AL,9
	JZ	G6IN
	CMP	AL,0AH
	JNZ	G6F0
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
G6IS:	MOV	AL,0EBH
	XCHG	AL,[OPCODE]
	TEST	AL,AL
	JNZ	G5S
G6F0:	MOV	AL,0
	JMP	FAIL
G6IN:	MOV	AX,[IMM]
	SUB	AX,[PC]
	SUB	AX,[VORG]
	SUB	AX,3
	MOV	[IMM],AX
	OR	BYTE [FLAGS],3
	OR	BYTE [OPCODE],0E8H
	RET
G5:	CALL	RA
G5S:	AND	BYTE [FLAGS],0FEH
	MOV	AX,[IMM]
	SUB	AX,[PC]
	SUB	AX,[VORG]
	SUB	AX,2
	MOV	[IMM],AX
	TEST	BYTE [FUNC],2
	JZ	G5X
	CALL	AA
	JNC	G5X
	MOV	AL,5
	JMP	FAIL
G8:	CALL	RA
	CMP	AL,31H
	JNZ	G6F0
	JMP	MMODRM
G9:	CALL	RA
	CALL	WA
	XOR	CH,CH
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
	MOV	CH,2
	CMP	AL,12H
	JZ	G9SR
	CMP	AL,31H
	JZ	G9MR
	CMP	AL,32H
	JZ	G9SR
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
G7:	CALL	CC
	JNZ	G7A
	MOV	AX,0AH
	MOV	[IMM],AX
G7B:	OR	BYTE [FLAGS],2
	RET
G7A:	CALL	RI
	TEST	AH,AH
	JZ	G7B
G0CHF:	MOV	AL,7
	JMP	FAIL
G0CH:	CALL	RE
	CMP	AX,3
	JZ	G0CH3
	TEST	AH,AH
	JNZ	G0CHF
	OR	BYTE [FLAGS],2
	RET
G0CH3:	DEC	BYTE [OPCODE]
	RET
G0DH:	CALL	RA
	AND	BYTE [FLAGS],0FEH
	CMP	AL,41H
	JZ	G0DHI
	CMP	AL,14H
	JZ	G0DHO
	OR	BYTE [OPCODE],8
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
G0BH:	CALL	CC
	JZ	G0
	CALL	RA
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
G0:	RET
D0:	MOV	AX,[PC]
	SHR	AL,1
	SBB	AL,AL
	AND	AL,20H
	MOV	[FLAGS],AL
	XOR	CX,CX
	RET
D6:	CALL	CC
	CMP	AL,3AH
	JZ	D6SEG
	JMP	SETDFS
D6SEG:	MOV	AL,3EH
	CALL	GSPR2
	XOR	CX,CX
	JMP	G0AH
D8:	MOV	DI,[TEMP]
D8L:	CALL	CC
	JZ	D9X	;D8P
	CMP	AL,27H
	JZ	D8Q
	CMP	AL,22H
	JZ	D8Q
	CMP	AL,2CH
	JZ	D8C
	PUSH	WORD [STK]
	PUSH	DI
	CALL	D8F
	POP	DI
	POP	WORD [STK]
	JC	D9X	;D8P
	PUSH	SI
	MOV	CX,10
	CALL	WN
	POP	SI
	JMP	SHORT D8L
D8Q:	INC	SI
	SUB	BX,2
	JBE	D9X	;D8P
	CLD
	MOV	CX,BX
	REP MOVSB
D8C:	INC	SI
	JMP	SHORT D8L
;D8P:	MOV	AL,[OPCODE]
;	MOV	SI,[TEMP]
;	MOV	BX,DI
;	SUB	BX,SI
;	JMP	FAIL
D8F:	MOV	[STK],SP
RI:	MOV	DL,24H
	JMP	RE
D9:	XOR	DX,DX
	CALL	CC
	JZ	D9X
	CALL	RI
	MOV	DX,AX
D9X:	JMP	SETEND
DISASM:	CLD
	PUSH	SI
	LODSB
	XOR	AH,AH
	MOV	[OPCODE],AL
	MOV	BX,AX
	AND	AL,1
	SHL	AL,1
	SHL	AL,1
	SHL	AL,1
	SHL	AL,1
	MOV	[WADJ],AX
	MOV	AL,[BIN86+BX]
	MOV	CX,AX
	MOV	AL,[HDL86+BX]
	MOV	BX,AX
	CMP	CL,7FH
	JNC	DISAS1
	MOV	DX,I8086+2
	CALL	WMN
	MOV	AL,9
	STOSB
DISAS1:	SHL	BX,1
	CALL	[DHDL+BX]
	MOV	AX,0A0DH
	STOSW
	MOV	CX,SI
	POP	SI
	SUB	CX,SI
	MOV	[BINLEN],CX
	ADD	[PC],CX
	MOV	AX,DI
	SUB	AX,[TXTBUF]
	MOV	[TXTLEN],AX
	CLC
	RET
WMN:	CLD
	PUSH	SI
	MOV	SI,DX
	XOR	CH,CH
	JCXZ	WMN2
WMN1:	LODSB
	TEST	AL,AL
	JNZ	WMN1
	LODSW
	LOOP	WMN1
WMN2:	LODSB
	STOSB
	TEST	AL,AL
	JNZ	WMN2
	DEC	DI
	POP	SI
	RET
RELBD:	CMP	BYTE [OPCODE],0EBH
	JNZ	NOTJMP
	MOV	CL,20
	MOV	DX,D8086+2
	CALL	WMN
	MOV	AL,20H
	STOSB
NOTJMP:	LODSB
	CBW
	ADD	AX,2
	ADD	AX,[PC]
	ADD	AX,[VORG]
	JMP	SHORT WHA
;NOTJMP:	MOV	AX,2B24H
;	STOSW
;	LODSB
;	ADD	AL,2
;	JNS	RELBNM
;	DEC	DI
;RELBNM:	CBW
WHAS:	TEST	AX,AX
	JNS	WHA
	NEG	AX
	MOV	BYTE [DI],2DH
	INC	DI
WHA:	PUSH	SI
	PUSH	AX
	MOV	CX,16
	CALL	WN
	POP	AX
	POP	SI
	CMP	AX,9
	JNA	WHA0
	MOV	AL,48H
	STOSB
WHA0:	RET
MACCD:	MOV	AL,6
	JMP	SHORT MRD1
MRD:	LODSB
MRD1:	PUSH	AX
	CALL	WDISP
	MOV	AL,2CH
	STOSB
	POP	AX
WREG:	CLD
	PUSH	SI
	MOV	SI,AX
	SHR	SI,1
	SHR	SI,1
	AND	SI,0EH
	JMP	SHORT WDISP1
WPTR:	LODSB
	CMP	AL,0C0H
	JNC	WDISP
	MOV	DX,D8086+2
	PUSH	AX
	MOV	CL,22
	TEST	BYTE [WADJ],0FFH
	JNZ	WSELF
	XOR	CL,CL
WSELF:	CALL	WMN
	MOV	AL,20H
	STOSB
	MOV	CL,19
	CALL	WMN
	MOV	AL,20H
	STOSB
	POP	AX
WDISP:	PUSH	SI
	MOV	SI,AX
	AND	SI,7
	CMP	AL,0C0H
	JC	WDD
	SHL	SI,1
WDISP1:	ADD	SI,REGS
	ADD	SI,[WADJ]
	MOVSW
	POP	SI
	RET
WDD:	PUSH	AX
	MOV	AL,5BH
	STOSB
	POP	AX
	AND	AL,0C7H
	CMP	AL,6
	JNZ	WDC
	POP	SI
	LODSW
	CALL	WHA
	MOV	AL,5DH
	STOSB
	RET
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
	CMP	AL,80H
	JC	WDB
	LODSW
	JMP	SHORT WDW
WDB:	CMP	AL,40H
	JC	WDX
	LODSB
	CBW
WDW:	TEST	AX,AX
	JZ	WDX
	JNS	WDM
	DEC	DI
WDM:	CALL	WHAS
	MOV	AL,5DH
	STOSB
	RET
WDX:	DEC	DI
	MOV	AL,5DH
	STOSB
	RET
SINGD:	DEC	DI
	RET
SPREFD:	CALL	PSRD
	MOV	AL,3AH
	STOSB
	RET
ACCID:	XOR	AL,AL
	CALL	WREG
	JMP	G03DT
PSRD:	MOV	AL,[OPCODE]
WSR:	SHR	AL,1
	SHR	AL,1
	AND	AX,6
	ADD	AX,REGS+20H
	XCHG	AX,SI
	CLD
	MOVSW
	XCHG	AX,SI
	RET
MSD:	MOV	AL,10H
	MOV	[WADJ],AL
	LODSB
	PUSH	AX
	CALL	WDISP
	MOV	AL,2CH
	STOSB
	POP	AX
	JMP	WSR
SMD:	MOV	AL,10H
	MOV	[WADJ],AL
	LODSB
	PUSH	AX
	CALL	WSR
	MOV	AL,2CH
	STOSB
	POP	AX
	JMP	WDISP
ACCRD:	MOV	AX,[REGS+10H]
	STOSW
	MOV	AL,2CH
	STOSB
REGWD:	MOV	AL,10H
	MOV	[WADJ],AL
	MOV	AL,[OPCODE]
	OR	AL,0C0H
	JMP	WDISP
RIMMD:	MOV	AL,[OPCODE]
	PUSH	SI
	AND	AX,0FH
	SHL	AL,1
	PUSH	AX
	ADD	AX,REGS
	MOV	SI,AX
	MOVSW
	POP	AX
	AND	AL,10H
	POP	SI
	MOV	[WADJ],AL
	JMP	G03DT
RELWD:	LODSW
	ADD	AX,3
	ADD	AX,[PC]
	ADD	AX,[VORG]
	JMP	WHA
;RELWD:	MOV	AX,2B24H
;	STOSW
;	LODSW
;	ADD	AX,3
;	JNS	RELWNM
;	DEC	DI
;RELWNM:	JMP	WHAS
AAMD:	LODSB
	CMP	AL,0AH
	JZ	AAMD0
	XOR	AH,AH
	CALL	WHA
AAMD0:	RET
ESCD:	MOV	AL,[OPCODE]
	MOV	AH,[SI]
	MOV	CL,3
	ROR	AH,CL
	AND	AX,707H
	ROL	AL,CL
	OR	AL,AH
	XOR	AH,AH
	CALL	WHA
	MOV	AL,2CH
	STOSB
	LODSB
	JMP	WDISP
INTD:	LODSB
	XOR	AH,AH
	JMP	WHA
INT3D:	MOV	AL,33H
	STOSB
	RET
RETFD:	MOV	CL,0AH
	MOV	DX,D8086+2
	CALL	WMN
	TEST	BYTE [OPCODE],1
	JZ	RETD
	DEC	DI
	RET
RETD:	LODSW
	JMP	WHA
ADIOD:	MOV	AX,[WADJ]
	ADD	AX,REGS
	PUSH	SI
	MOV	SI,AX
	LODSW
	POP	SI
	MOV	DX,5844H
	TEST	BYTE [OPCODE],2
	JZ	ADIOD0
	XCHG	AX,DX
ADIOD0:	STOSW
	MOV	AL,2CH
	STOSB
	XCHG	AX,DX
	STOSW
	RET
IBAPD:	LODSB
	XOR	AH,AH
	CALL	WHA
	MOV	AL,2CH
	STOSB
	MOV	AL,0C0H
	JMP	WDISP
SEGOFD:	LODSW
	PUSH	AX
	LODSW
	CALL	WHA
	MOV	AL,3AH
	STOSB
	POP	AX
	JMP	WHA
GRPD:	PUSH	SI
	LODSB
	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	AND	AX,7
	PUSH	AX
	MOV	SI,AX
	ADD	SI,CX
	MOV	CL,[SI]
	MOV	DX,I8086+2
	CALL	WMN
	MOV	AL,9
	STOSB
	POP	AX
	POP	SI
	RET
ACCMD:	MOV	AL,6
	JMP	SHORT RMD1
RWMD:	MOV	BYTE [WADJ],10H
RMD:	LODSB
RMD1:	PUSH	AX
	CALL	WREG
	MOV	AL,2CH
	STOSB
	POP	AX
	JMP	WDISP
G02D:	MOV	CX,_G02D
	CALL	GRPD
	CALL	WPTR
	MOV	AL,2CH
	STOSB
	TEST	BYTE [OPCODE],2
	JZ	G02D1
	MOV	AX,[REGS+2]
	STOSW
	RET
G02D1:	MOV	AL,31H
	STOSB
	RET
G03D:	MOV	CX,_G03D
	CALL	GRPD
	PUSH	WORD [SI]
	CALL	WPTR
	POP	AX
	TEST	AL,30H
	JZ	G03DT
	RET
G01D:	MOV	CX,_G01D
	CALL	GRPD
RMID:	CALL	WPTR
G03DT:	MOV	AL,2CH
	STOSB
	LODSW
	TEST	BYTE [WADJ],0FFH
	JZ	G03DB
	CMP	BYTE [OPCODE],83H
	JNZ	G03DW
G03DB:	CBW
	DEC	SI
G03DW:	JMP	WHA
G04D:	MOV	CX,_G04D
	CALL	GRPD
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
G04DF:	MOV	CL,0AH
	MOV	DX,D8086+2
	CALL	WMN
DISPD:	LODSB
	JMP	WDISP
INVD:	MOV	AX,4244H
	STOSW
	MOV	AX,9
	STOSB
	MOV	AL,[OPCODE]
	JMP	WHA
	EVEN
IHDL:	DW	G0,G1,G2,G3
	DW	G4,G5,G6,G7
	DW	G8,G9,G0AH,G0BH
	DW	G0CH,G0DH,G0EH,G0FH
AHDL:	DW	D0,SETEQU,SETEND
	DW	SETORG,SETDFB
	DW	D5,D6,SETINC
	DW	D8,D9
DHDL:	DW	MRD,RMD,ACCID
	DW	PSRD,SPREFD,SINGD
	DW	REGWD,INVD,RELBD
	DW	G01D,G03D,G04D
	DW	MSD,SMD,DISPD
	DW	ACCRD,SEGOFD,ACCMD
	DW	MACCD,RIMMD,RETD
	DW	RWMD,RMID,RETFD
	DW	INT3D,INTD,G02D
	DW	AAMD,ESCD,IBAPD
	DW	RELWD,ADIOD
HDL86:	DB	0,0,1,1,2,2,3,3
	DB	0,0,1,1,2,2,3,3
	DB	0,0,1,1,2,2,3,3
	DB	0,0,1,1,2,2,3,3
	DB	0,0,1,1,2,2,4,5
	DB	0,0,1,1,2,2,4,5
	DB	0,0,1,1,2,2,4,5
	DB	0,0,1,1,2,2,4,5
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
	DB	1FH,1FH,1FH,1FH
	DB	05H,07H,05H,05H
	DB	05H,05H,0AH,0AH
	DB	05H,05H,05H,05H
	DB	05H,05H,0BH,0BH
BIN86:	DB	05H,05H,05H,05H
	DB	05H,05H,55H,53H
	DB	51H,51H,51H,51H
	DB	51H,51H,55H,53H
	DB	04H,04H,04H,04H
	DB	04H,04H,55H,53H
	DB	65H,65H,65H,65H
	DB	65H,65H,55H,53H
	DB	06H,06H,06H,06H
	DB	06H,06H,7FH,11H
	DB	6FH,6FH,6FH,6FH
	DB	6FH,6FH,7FH,12H
	DB	74H,74H,74H,74H
	DB	74H,74H,7FH,00H
	DB	0DH,0DH,0DH,0DH
	DB	0DH,0DH,7FH,03H
	DB	1AH,1AH,1AH,1AH
	DB	1AH,1AH,1AH,1AH
	DB	13H,13H,13H,13H
	DB	13H,13H,13H,13H
	DB	55H,55H,55H,55H
	DB	55H,55H,55H,55H
	DB	53H,53H,53H,53H
	DB	53H,53H,53H,53H
	DB	7FH,7FH,7FH,7FH
	DB	7FH,7FH,7FH,7FH
	DB	7FH,7FH,7FH,7FH
	DB	7FH,7FH,7FH,7FH
	DB	38H,34H,22H,2EH
	DB	3DH,37H,2CH,1EH
	DB	3CH,36H,39H,35H
	DB	27H,32H,30H,25H
	DB	7FH,7FH,7FH,7FH
	DB	70H,70H,72H,72H
	DB	4AH,4AH,4AH,4AH
	DB	4AH,40H,4AH,53H
	DB	4FH,72H,72H,72H
	DB	72H,72H,72H,72H
	DB	08H,10H,07H,71H
	DB	56H,54H,61H,3EH
	DB	4AH,4AH,4AH,4AH
	DB	4BH,4CH,0EH,0FH
	DB	70H,70H,6DH,6EH
	DB	43H,44H,66H,67H
	DB	4AH,4AH,4AH,4AH
	DB	4AH,4AH,4AH,4AH
	DB	4AH,4AH,4AH,4AH
	DB	4AH,4AH,4AH,4AH
	DB	7FH,7FH,5EH,5EH
	DB	41H,3FH,4AH,4AH
	DB	7FH,7FH,5EH,5EH
	DB	1BH,1BH,1CH,1DH
	DB	7FH,7FH,7FH,7FH
	DB	02H,01H,63H,73H
	DB	15H,15H,15H,15H
	DB	15H,15H,15H,15H
	DB	48H,49H,45H,23H
	DB	19H,19H,52H,52H
	DB	07H,29H,29H,29H
	DB	19H,19H,52H,52H
	DB	42H,7FH,5CH,5DH
	DB	16H,0CH,7FH,7FH
	DB	09H,6AH,0BH,6BH
	DB	0AH,6CH,7FH,7FH
_G01D:	DB	05H,51H,04H,65H
	DB	06H,6FH,74H,0DH
_G02D:	DB	5FH,60H,57H,58H
	DB	68H,69H,62H,64H
_G03D:	DB	60H,60H,50H,4EH
	DB	4FH,18H,14H,17H
_G04D:	DB	1AH,13H,07H,07H
	DB	29H,29H,55H,7FH
_DISP:	DB	0C6H,0E6H,0CAH,0EAH
	DB	0CH,0EH,0AH,6
RM:	DB	0EH,7,6,0FFH
	DB	5,1,3,0FFH
	DB	4,0,2,0FFH
	DB	0FFH,0FFH,0FFH,0FFH
REGS:	DB	"ALCLDLBLAHCHDHBH"
	DB	"AXCXDXBXSPBPSIDI"
	DB	"ESCSSSDS"
I8086:	DW	117
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
D8086:	DW	23
	DB	"BYTE",0,1,5
	DB	"DB",0,1,4
	DB	"DD",0,4,4
	DB	"DS",0,0,6
	DB	"DW",0,2,4
	DB	"DWORD",0,3,5
	DB	"ECHO",0,0FCH,8
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
	DB	"PAGE",0,0FAH,9
	DB	"PTR",0,10H,5
	DB	"SHORT",0,8,5
	DB	"TITLE",0,0FBH,7
	DB	"WORD",0,2,5
