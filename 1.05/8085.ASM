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
ASMLIN:	CALL	CC
	JZ	ASMEND
	MOV	DI,I8085
	MOV	DX,IHDL
	CALL	ASMCMD
	JZ	WROUT
	MOV	DI,D8085
	MOV	DX,AHDL
	CALL	ASMCMD
	JZ	ASMEND
	JNZ	ASMLBL
WROUT:	MOV	AL,CH
	CLD
	MOV	DI,[BINBUF]
	STOSB
	MOV	AX,[IMM]
	STOSW
	XOR	CH,CH
	MOV	[BINLEN],CX
	ADD	[PC],CX
ASMEND:	CLC
	RET
ASMCMD:	PUSH	DX
	CALL	SL
	POP	DX
	JNZ	ASMCM0
	MOV	[OPCODE],AL
	MOV	CH,AL
	XCHG	AL,AH
	XOR	AH,AH
	SHL	AX,1
	ADD	AX,DX
	MOV	DI,AX
	CALL	[DI]
	CALL	CC
	JZ	ASMCM0
	MOV	AL,9
	JMP	FAIL
ASMCM0:	RET
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
	STC
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
RNM:	PUSH	AX
	PUSH	CX
	PUSH	DX
	PUSH	BX
	PUSH	SI
	MOV	DI,D8085
	CALL	SL
	POP	SI
	POP	BX
	POP	DX
	POP	CX
	JNZ	RNMEND
	CMP	AH,5
	JNZ	RNMEND
	ADD	SI,BX
	MOV	AH,4
	CMP	AL,12H
	JZ	RNMLO
	CMP	AL,13H
	JZ	RNMHI
D5:	MOV	AL,0CH
	JMP	FAIL
RNMHI:	SHL	AH,1
RNMLO:	OR	CL,AH
	CALL	CC
	JZ	RNMER8
	CMP	AL,AL
RNMEND:	POP	AX
	RET
RNMER8:	MOV	AL,8
	JMP	FAIL
G6:	CALL	RI
	CMP	AL,8
	JC	G4S
	MOV	AL,7
	JMP	FAIL
G7:	CALL	G5
	CALL	COMMA
G3:	CALL	RI
	MOV	CL,3
	RET
G8:	CALL	G4
	CALL	COMMA
G1:	CALL	RA
	JMP	SHORT G4E
G9:	CALL	G4
	CALL	COMMA
G2:	CALL	RI
	MOV	CL,2
	RET
G4:	CALL	RA
G4S:	SHL	AL,1
	SHL	AL,1
	SHL	AL,1
G4E:	OR	CH,AL
G0:	MOV	CL,1
	RET
RA:	CALL	CC
	JZ	RA8
	DEC	BX
	JNZ	RA0
	INC	SI
RR:	PUSH	CX
	MOV	DI,REGS+7
	MOV	CX,8
	STD
	REPNE SCASB
	POP	AX
	JNZ	RA0
	XCHG	AX,CX
	RET
COMMA:	CALL	CC
	JZ	RA8
	CMP	AL,2CH
	JNZ	RA1
	INC	SI
	RET
G5:	CALL	CC
	JZ	RA8
	MOV	CL,1
	INC	SI
	DEC	BX
	JZ	RT1
	DEC	BX
	JZ	RT2
	DEC	BX
	JZ	RT3
RA0:	MOV	AL,0
	JMP	FAIL
RA1:	MOV	AL,1
	JMP	FAIL
RA8:	MOV	AL,8
	JMP	FAIL
RT1:	CALL	RR
	TEST	AL,1
	JNZ	RA0
	CMP	AL,6
	JNC	RA0
	JMP	SHORT G4S
RT2:	CMP	AL,53H
	JNZ	RA0
	LODSB
	CMP	AL,50H
	JNZ	RA0
	OR	CH,30H
	RET
RT3:	CMP	AL,50H
	JNZ	RA0
	LODSW
	CMP	AX,5753H
	JNZ	RA0
	OR	CH,30H
	RET
D4:	MOV	CX,[PC]
	AND	CX,1
	JZ	D4X
	MOV	DI,[BINBUF]
	MOV	[DI],CH
D4X:	RET
D8:	MOV	DI,[TEMP]
D8L:	CALL	CC
	JZ	D9X
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
	JC	D9X
	PUSH	SI
	MOV	CX,10
	CALL	WN
	POP	SI
	JMP	SHORT D8L
D8Q:	INC	SI
	SUB	BX,2
	JBE	D9X
	CLD
	MOV	CX,BX
	REP MOVSB
D8C:	INC	SI
	JMP	SHORT D8L
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
	XOR	BH,BH
	MOV	BL,[SI]
	MOV	DX,[SI+1]
	XOR	CH,CH
	MOV	CL,[BIN85+BX]
	MOV	SI,I8085+2
	JCXZ	DISAS2
DISAS1:	LODSB
	TEST	AL,AL
	JNZ	DISAS1
	LODSW
	LOOP	DISAS1
DISAS2:	LODSB
	STOSB
	TEST	AL,AL
	JNZ	DISAS2
	DEC	DI
	MOV	AL,9
	STOSB
	MOV	AL,BL
	SHR	BL,1
	MOV	BL,[HDL85+BX]
	JC	DISAS3
	SHR	BL,1
	SHR	BL,1
	SHR	BL,1
	SHR	BL,1
DISAS3:	AND	BL,0FH
	SHL	BL,1
	MOV	CL,1
	CALL	[DHDL+BX]
	MOV	AX,0A0DH
	STOSW
	MOV	[BINLEN],CX
	ADD	[PC],CX
	MOV	AX,DI
	SUB	AX,[TXTBUF]
	MOV	[TXTLEN],AX
	CLC
	RET
RIMD:	MOV	BX,IMBD
	PUSH	BX
WREGC:	PUSH	AX
	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	CALL	REGD
	MOV	AL,2CH
	STOSB
	POP	AX
	RET
INCD:	CALL	WREGC
IMPD:	DEC	DI
	RET
RRMD:	CALL	WREGC
REGD:	AND	AL,7
	MOV	BX,REGS
	XLATB
	STOSB
	RET
RGPD:	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	AND	AL,6
	CMP	AL,6
	JC	REGD
	MOV	AX,5053H
	STOSW
	RET
PSWD:	MOV	AX,5350H
	STOSW
	MOV	AL,57H
	STOSB
	RET
RPID:	CALL	RGPD
	MOV	AL,2CH
	STOSB
IMWD:	INC	CX
IMBD:	INC	CX
WRIM:	MOV	AL,DH
	OR	AL,AL
	JZ	WRIM1
	CALL	WRIM2
	MOV	AL,DL
	JNC	WRIM3
	DEC	DI
	JMP	SHORT WRIM3
WRIM1:	MOV	AL,DL
WRIM2:	CMP	AL,0AH
	JC	WRIM4
	CMP	AL,0A0H
	JC	WRIM3
	MOV	BYTE [DI],30H
	INC	DI
WRIM3:	CALL	HALX
	MOV	AL,48H
	STOSB
	STC
	RET
RSTD:	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	AND	AL,7
WRIM4:	ADD	AL,30H
	STOSB
	RET
IHDL:	DW	G0,G1,G2,G3
	DW	G4,G5,G6,G7
	DW	G8,G9
AHDL:	DW	SETEQU,SETDFB
	DW	SETDFS,SETORG
	DW	D4,D5,SETINC
	DW	SETEND,D8,D9
DHDL:	DW	IMPD,REGD,IMBD
	DW	IMWD,INCD,RGPD
	DW	RSTD,RPID,RRMD
	DW	RIMD,PSWD
HDL85	DB	07H,55H,44H,90H
	DB	05H,55H,44H,90H
	DB	07H,55H,44H,90H
	DB	05H,55H,44H,90H
	DB	07H,35H,44H,90H
	DB	25H,35H,44H,90H
	DB	07H,35H,44H,90H
	DB	25H,35H,44H,90H
	DB	88H,88H,88H,88H
	DB	88H,88H,88H,88H
	DB	88H,88H,88H,88H
	DB	88H,88H,88H,88H
	DB	88H,88H,88H,88H
	DB	88H,88H,88H,88H
	DB	88H,88H,88H,08H
	DB	88H,88H,88H,88H
	DB	11H,11H,11H,11H
	DB	11H,11H,11H,11H
	DB	11H,11H,11H,11H
	DB	11H,11H,11H,11H
	DB	11H,11H,11H,11H
	DB	11H,11H,11H,11H
	DB	11H,11H,11H,11H
	DB	11H,11H,11H,11H
	DB	05H,33H,35H,26H
	DB	00H,30H,33H,26H
	DB	05H,32H,35H,26H
	DB	00H,32H,33H,26H
	DB	05H,30H,35H,26H
	DB	00H,30H,30H,26H
	DB	0AH,30H,3AH,26H
	DB	00H,30H,33H,26H
BIN85	DB	33H,30H,52H,1EH
	DB	1DH,16H,32H,40H
	DB	19H,15H,2BH,17H
	DB	1DH,16H,32H,47H
	DB	06H,30H,52H,1EH
	DB	1DH,16H,32H,3AH
	DB	3DH,15H,2BH,17H
	DB	1DH,16H,32H,3BH
	DB	3FH,30H,4DH,1EH
	DB	1DH,16H,32H,14H
	DB	2CH,15H,2EH,17H
	DB	1DH,16H,32H,0AH
	DB	4FH,30H,51H,1EH
	DB	1DH,16H,32H,53H
	DB	2DH,15H,2AH,17H
	DB	1DH,16H,32H,0BH
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,1BH,31H
	DB	31H,31H,31H,31H
	DB	31H,31H,31H,31H
	DB	02H,02H,02H,02H
	DB	02H,02H,02H,02H
	DB	01H,01H,01H,01H
	DB	01H,01H,01H,01H
	DB	54H,54H,54H,54H
	DB	54H,54H,54H,54H
	DB	4BH,4BH,4BH,4BH
	DB	4BH,4BH,4BH,4BH
	DB	04H,04H,04H,04H
	DB	04H,04H,04H,04H
	DB	57H,57H,57H,57H
	DB	57H,57H,57H,57H
	DB	34H,34H,34H,34H
	DB	34H,34H,34H,34H
	DB	0CH,0CH,0CH,0CH
	DB	0CH,0CH,0CH,0CH
	DB	43H,38H,25H,22H
	DB	0EH,39H,03H,48H
	DB	4AH,3EH,29H,49H
	DB	13H,07H,00H,48H
	DB	42H,38H,23H,36H
	DB	0DH,39H,55H,48H
	DB	3CH,4EH,1FH,1CH
	DB	08H,24H,4CH,48H
	DB	46H,38H,28H,59H
	DB	12H,39H,05H,48H
	DB	45H,37H,27H,56H
	DB	10H,2FH,58H,48H
	DB	44H,38H,26H,18H
	DB	0FH,39H,35H,48H
	DB	41H,50H,21H,1AH
	DB	09H,20H,11H,48H
REGS:	DB	"BCDEHLMA"
I8085	DW	90
	DB	"ACI",0,0CEH,2
	DB	"ADC",0,88H,1
	DB	"ADD",0,80H,1
	DB	"ADI",0,0C6H,2
	DB	"ANA",0,0A0H,1
	DB	"ANI",0,0E6H,2
	DB	"ARHL",0,10H,0
	DB	"CALL",0,0CDH,3
	DB	"CC",0,0DCH,3
	DB	"CM",0,0FCH,3
	DB	"CMA",0,2FH,0
	DB	"CMC",0,3FH,0
	DB	"CMP",0,0B8H,1
	DB	"CNC",0,0D4H,3
	DB	"CNZ",0,0C4H,3
	DB	"CP",0,0F4H,3
	DB	"CPE",0,0ECH,3
	DB	"CPI",0,0FEH,2
	DB	"CPO",0,0E4H,3
	DB	"CZ",0,0CCH,3
	DB	"DAA",0,27H,0
	DB	"DAD",0,9,5
	DB	"DCR",0,5,4
	DB	"DCX",0,0BH,5
	DB	"DI",0,0F3H,0
	DB	"DSUB",0,8,0
	DB	"EI",0,0FBH,0
	DB	"HLT",0,76H,0
	DB	"IN",0,0DBH,2
	DB	"INR",0,4,4
	DB	"INX",0,3,5
	DB	"JC",0,0DAH,3
	DB	"JK",0,0FDH,3
	DB	"JM",0,0FAH,3
	DB	"JMP",0,0C3H,3
	DB	"JNC",0,0D2H,3
	DB	"JNK",0,0DDH,3
	DB	"JNZ",0,0C2H,3
	DB	"JP",0,0F2H,3
	DB	"JPE",0,0EAH,3
	DB	"JPO",0,0E2H,3
	DB	"JZ",0,0CAH,3
	DB	"LDA",0,3AH,3
	DB	"LDAX",0,0AH,5
	DB	"LDHI",0,28H,2
	DB	"LDSI",0,38H,2
	DB	"LHLD",0,2AH,3
	DB	"LHLX",0,0EDH,0
	DB	"LXI",0,1,7
	DB	"MOV",0,40H,8
	DB	"MVI",0,6,9
	DB	"NOP",0,0,0
	DB	"ORA",0,0B0H,1
	DB	"ORI",0,0F6H,2
	DB	"OUT",0,0D3H,2
	DB	"PCHL",0,0E9H,0
	DB	"POP",0,0C1H,5
	DB	"PUSH",0,0C5H,5
	DB	"RAL",0,17H,0
	DB	"RAR",0,1FH,0
	DB	"RC",0,0D8H,0
	DB	"RDEL",0,18H,0
	DB	"RET",0,0C9H,0
	DB	"RIM",0,20H,0
	DB	"RLC",0,7,0
	DB	"RM",0,0F8H,0
	DB	"RNC",0,0D0H,0
	DB	"RNZ",0,0C0H,0
	DB	"RP",0,0F0H,0
	DB	"RPE",0,0E8H,0
	DB	"RPO",0,0E0H,0
	DB	"RRC",0,0FH,0
	DB	"RST",0,0C7H,6
	DB	"RSTV",0,0CBH,0
	DB	"RZ",0,0C8H,0
	DB	"SBB",0,98H,1
	DB	"SBI",0,0DEH,2
	DB	"SHLD",0,22H,3
	DB	"SHLX",0,0D9H,0
	DB	"SIM",0,30H,0
	DB	"SPHL",0,0F9H,0
	DB	"STA",0,32H,3
	DB	"STAX",0,2,5
	DB	"STC",0,37H,0
	DB	"SUB",0,90H,1
	DB	"SUI",0,0D6H,2
	DB	"XCHG",0,0EBH,0
	DB	"XRA",0,0A8H,1
	DB	"XRI",0,0EEH,2
	DB	"XTHL",0,0E3H,0
D8080:	DW	14
	DB	"DB",0,1,1
	DB	"DS",0,0,2
	DB	"DW",0,2,1
	DB	"ECHO",0,0FCH,8
	DB	"END",0,0FFH,7
	DB	"EQU",0,0,0
	DB	"EVEN",0,0,4
	DB	"HIGH",0,13H,5
	DB	"INCBIN",0,0FDH,6
	DB	"INCLUDE",0,0FEH,6
	DB	"LOW",0,12H,5
	DB	"ORG",0,0,3
	DB	"PAGE",0,0FAH,9
	DB	"TITLE",0,0FBH,6
