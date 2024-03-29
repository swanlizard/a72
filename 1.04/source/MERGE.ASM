	XOR	AX,AX
	MOV	[INCLEV],AX
	MOV	[REVFILE],AL
	CALL	OPENF
	JNC	MAIN
	RET
MAIN:	MOV	SI,OFFSET INFILE
	CALL	OPNEW
MAINL:	CALL	CALF
	MOV	DX,80H
	CALL	FRLT
	JC	MAINLE
	PUSH	CX
	MOV	SI,80H
	MOV	DI,OFFSET BUFFER
	CLD
	REPZ	MOVSB
	POP	CX
	MOV	SI,OFFSET BUFFER
FINDL:	CALL	CC
	JZ	WRITE
	CMP	BL,7
	JNZ	FINDL1
	PUSH	CX
	PUSH	SI
	MOV	DI,OFFSET INCL
	MOV	CX,7
	REPZ	CMPSB
	POP	SI
	POP	CX
	JZ	READIN
FINDL1:	ADD	SI,BX
	JMP	SHORT FINDL
WRITE:	MOV	AH,40H
	MOV	BX,[OUTHDL]
	INT	21H
	INC	WORD PTR [LN]
	JMP	SHORT MAINL
READIN:	ADD	SI,BX
	CALL	CC
	JZ	MAINL
	MOV	CX,BX
	MOV	DI,OFFSET INCFILE
	CMP	AL,22H
	JZ	READQ
	CMP	AL,27H
	JNZ	NREADQ
READQ:	INC	SI
	SUB	CX,2
	JNA	MAINL
NREADQ:	MOV	AL,CL
	CLD
	STOSB
	REPZ	MOVSB
	XOR	AL,AL
	STOSB
	MOV	SI,OFFSET INCFILE
	CALL	OPNEW
	JMP	SHORT MAINL
MAINLE:	CALL	WREV
	CALL	CLOSF
	JNC	MAINL
	MOV	SI,OFFSET OUTM
	MOV	DI,80H
	CALL	WRM
	MOV	SI,OFFSET OUTFILE
	MOV	AL,[REVFILE]
	TEST	AL,AL
	JZ	MAINL0
	CALL	WRM
	MOV	AX,202CH
	STOSW
	MOV	AH,40H
	MOV	DX,OFFSET QREC
	MOV	CX,3
	MOV	BX,[REVHDL]
	INT	21H
	MOV	AH,3EH
	MOV	BX,[REVHDL]
	INT	21H
	MOV	SI,OFFSET REVFILE
MAINL0:	CALL	FINAL
	MOV	AH,3EH
	MOV	BX,[OUTHDL]
	INT	21H
	MOV	AX,4C00H
	INT	21H
WREV:	MOV	AL,[REVFILE]
	TEST	AL,AL
	JZ	WREV0
	MOV	AX,[INCLEV]
	CMP	AL,2
	JC	WREV0
	CLD
	MOV	DI,80H
	MOV	AX,[LN+2]
	CALL	STR
	MOV	AL,2CH
	CLD
	STOSB
	MOV	AX,[LN]
	CALL	STR
	MOV	AL,58H
	CLD
	STOSB
	CALL	CALF
	MOV	SI,AX
	LODSW
	CALL	WRM
	MOV	AX,0A0DH
	STOSW
	MOV	AH,40H
	MOV	DX,80H
	MOV	CX,DI
	SUB	CX,DX
	MOV	BX,[REVHDL]
	INT	21H
WREV0:	RET
OPNEW:	MOV	AX,3D00H
	MOV	DX,SI
	INC	DX
	INT	21H
	JC	OPNEW0
	INC	WORD PTR [INCLEV]
	MOV	DI,AX
	CALL	CALF
	XCHG	AX,DI
	CLD
	STOSW
	PUSH	SI
	MOVSB
	DEC	SI
	CALL	WRM
	MOV	AX,[LN]
	INC	AX
	MOV	[LN+2],AX
	MOV	SI,OFFSET PROCM
	MOV	DI,80H
	CALL	WRM
	POP	SI
	JMP	FINAL
OPNEW0:	PUSH	SI
	MOV	SI,OFFSET FILERR
	MOV	DI,80H
	CALL	WRM
	POP	SI
	CALL	FINAL
	STC
	RET
CLOSF:	CALL	CALF
	MOV	AH,3EH
	INT	21H
	MOV	AX,[INCLEV]
	DEC	AX
	MOV	[INCLEV],AX
	CMP	AL,1
	RET
CALF:	MOV	AX,[INCLEV]
	DEC	AX
	MOV	CL,5
	SHL	AX,CL
	ADD	AX,OFFSET INCLEV+2
	MOV	BX,AX
	MOV	BX,[BX]
	RET
STR:	MOV	BX,DI
	MOV	CX,10
STR1:	XOR	DX,DX
	DIV	CX
	ADD	DL,30H
	MOV	[DI],DL
	INC	DI
	TEST	AX,AX
	JNZ	STR1
	MOV	CX,DI
	SUB	CX,BX
	SHR	CX,1
	JZ	STR0
	STD
	PUSH	DI
	DEC	DI
STR2:	MOV	AL,[DI]
	XCHG	[BX],AL
	STOSB
	INC	BX
	LOOP	STR2
	POP	DI
STR0:	RET
NOPE:	MOV	AH,9
	MOV	DX,OFFSET USAGE
	INT	21H
	STC
	RET
OPENF:	MOV	SI,81H
	MOV	DI,OFFSET INFILE
	CALL	GETFN
	JZ	NOPE
	MOV	AX,[INFILE+1]
	CMP	AX,522FH
	JNZ	OPENF1
	MOV	[REVFILE],AL
	MOV	DI,OFFSET INFILE
	CALL	GETFN
	JZ	NOPE
OPENF1:	MOV	DI,OFFSET OUTFILE
	CALL	GETFN
	JZ	NOPE
	MOV	AL,[REVFILE]
	TEST	AL,AL
	JZ	OPENF2
	MOV	DI,OFFSET REVFILE
	CALL	GETFN
	JZ	NOPE
	MOV	SI,OFFSET DOTREV
	MOV	DI,OFFSET REVFILE
	CLC
	CALL	ADDEXT
OPENF2:	MOV	SI,OFFSET DOTASM
	MOV	DI,OFFSET INFILE
	CLC
	CALL	ADDEXT
	MOV	SI,OFFSET DOTASM
	MOV	DI,OFFSET OUTFILE
	CLC
	CALL	ADDEXT
	MOV	AX,3D00H
	MOV	DX,OFFSET INFILE+1
	INT	21H
	JC	FAIL
	MOV	[INHDL],AX
	MOV	SI,OFFSET OUTFILE
	MOV	AH,3CH
	XOR	CX,CX
	MOV	DX,OFFSET OUTFILE+1
	INT	21H
	JC	FAIL1
	MOV	[OUTHDL],AX
	MOV	AL,[REVFILE]
	TEST	AL,AL
	JZ	OK
	MOV	SI,OFFSET REVFILE
	MOV	AH,3CH
	XOR	CX,CX
	MOV	DX,OFFSET REVFILE+1
	INT	21H
	JNC	OK
	MOV	AH,3EH
	MOV	BX,[OUTHDL]
	INT	21H
FAIL1:	MOV	AH,3EH
	MOV	BX,[INHDL]
	INT	21H
FAIL:	PUSH	SI
	MOV	DI,80H
	MOV	SI,OFFSET FILERR
	CALL	WRM
	POP	SI
	CALL	FINAL
	STC
	RET
OK:	MOV	[REVHDL],AX
	MOV	SI,OFFSET INM
	MOV	DI,80H
	CALL	WRM
	MOV	SI,OFFSET INFILE
FINAL:	CALL	WRM
	MOV	AX,0A0DH
	STOSW
	MOV	AX,924H
	STOSB
	MOV	DX,80H
	INT	21H
	CLC
	RET
GETFN:	XOR	CX,CX
	PUSH	DI
	INC	DI
	CLD
GETFN1:	LODSB
	CMP	AL,0DH
	JZ	GETFN0
	CMP	AL,21H
	JC	GETFN2
	CMP	AL,61H
	JC	GETFN3
	CMP	AL,7BH
	JNC	GETFN3
	AND	AL,0DFH
GETFN3:	INC	CX
	STOSB
	JMP	SHORT GETFN1
GETFN2:	TEST	CX,CX
	JZ	GETFN1
GETFN0:	DEC	SI
	MOV	[DI],CH
	POP	DI
	MOV	[DI],CL
	TEST	CX,CX
	RET
ADDEXT:	LAHF
	CLD
	MOV	BP,DI
	XOR	CH,CH
	MOV	CL,[DI]
	INC	DI
	MOV	AL,2EH
	REPNZ	SCASB
	JNZ	ADDXT2
	SAHF
	JNC	ADDXT0
	DEC	DI
ADDXT2:	SAHF
	JC	ADDXT1
	STOSB
	CALL	WRM
ADDXT1:	MOV	[DI],CH
	MOV	AX,DI
	SUB	AX,BP
	DEC	AX
	MOV	DI,BP
	STOSB
ADDXT0:	RET
FRLT:	MOV	AH,3FH
	MOV	CX,80H
	MOV	DI,DX
	PUSH	DX
	PUSH	BX
	INT	21H
	POP	BX
	POP	DX
	JC	FRLT0
	CMP	AL,1
	JC	FRLT0
	XCHG	AX,CX
	MOV	AL,0DH
	CLD
	REPNZ	SCASB
	JNZ	FRLT2
	MOV	AL,0AH
	JCXZ	FRLT1
	DEC	CX
	SCASB
	JZ	FRLT2
	DEC	DI
	INC	CX
FRLT1:	STOSB
FRLT2:	XOR	AX,AX
	SUB	AX,CX
	JZ	FRLT3
	PUSH	AX
	PUSH	DX
	CWD
	MOV	CX,4201H
	XCHG	AX,DX
	XCHG	AX,CX
	INT	21H
	POP	DX
	POP	AX
	JC	FRLT0
FRLT3:	ADD	AX,80H
	MOV	CX,DI
	SUB	CX,DX
	CLC
FRLT0:	RET
CC:	XOR	BX,BX
CCM:	MOV	AL,[BX+SI]
	CMP	AL,0
	JZ	CCT
	CMP	AL,0DH
	JZ	CCT
	CMP	AL,21H
	JC	CCK
	CMP	AL,22H
	JZ	CCQ
	CMP	AL,27H
	JZ	CCQ
	CMP	AL,2CH
	JZ	CCK
	CMP	AL,30H
	JC	CCS
	CMP	AL,3AH
	JC	CCL
	CMP	AL,3BH
	JZ	CCT
	CMP	AL,41H
	JC	CCS
	CMP	AL,5BH
	JC	CCL
	CMP	AL,5FH
	JZ	CCL
	CMP	AL,61H
	JC	CCS
	CMP	AL,7BH
	JNC	CCS
	AND	AL,0DFH
	MOV	[BX+SI],AL
CCL:	INC	BX
	JMP	SHORT CCM
CCQ:	TEST	BX,BX
	JNZ	CCT
CCW:	INC	BX
	CMP	[BX+SI],AL
	JNZ	CCW
	INC	BX
CCT:	MOV	AL,[SI]
	TEST	BX,BX
	RET
CCS:	TEST	BX,BX
	JNZ	CCT
	INC	BX
	JMP	SHORT CCT
CCK:	TEST	BX,BX
	JNZ	CCT
	INC	SI
	JMP	SHORT CCM
WRM:	MOV	CL,[SI]
	XOR	CH,CH
	INC	SI
	CLD
	REPZ	MOVSB
	RET
LN	DW	0,0
QREC	DB	"Q",13,10
INCL	DB	7,"INCLUDE"
DOTASM	DB	3,"ASM"
DOTREV	DB	3,"REV"
INM	DB	4,"IN: "
OUTM	DB	5,"OUT: "
PROCM	DB	8,"READING "
FILERR	DB	14,"ERROR READING "
USAGE	DB	"MERGE [/R] <IN>[.ASM] "
	DB	"<OUT>[.ASM] (<OUT>[.REV])"
	DB	13,10,36
INHDL	DW	?
OUTHDL	DW	?
INCHDL	DW	?
REVHDL	DW	?
INFILE	DS	20H
OUTFILE	DS	20H
INCFILE	DS	20H
REVFILE	DS	20H
INCLEV	DS	100H
BUFFER:
