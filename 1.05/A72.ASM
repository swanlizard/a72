	PAGE	64
	ORG	100H
LSTWID	EQU	6
MAXLEN	EQU	100H
DEFORG	EQU	100H
DEFPAG	EQU	50
PGMVAR	EQU	BUF5
USER	EQU	BUF5+80H
FUNC	EQU	USER
TXTBUF	EQU	USER+2
BINBUF	EQU	USER+4
PC	EQU	USER+6
USIZE	EQU	USER+8
VORG	EQU	USER+0AH
SYM	EQU	USER+0CH
STK	EQU	USER+0EH
WADJ	EQU	USER+10H
ARGS	EQU	USER+12H
FLAGS	EQU	USER+16H
SEGPRE	EQU	USER+17H
OPCODE	EQU	USER+18H
MODRM	EQU	USER+19H
DISP	EQU	USER+1AH
IMM	EQU	USER+1CH
BINLEN	EQU	USER+1EH
TXTLEN	EQU	USER+20H
OUTHDL	EQU	PGMVAR
LSTHDL	EQU	PGMVAR+2
INCLEV	EQU	PGMVAR+4
ERRORS	EQU	PGMVAR+6
TEMP	EQU	PGMVAR+8
PASS	EQU	PGMVAR+0AH
OLDPC	EQU	PGMVAR+0CH
PAGNUM	EQU	PGMVAR+0EH
LSTLIN	EQU	PGMVAR+10H
INFN	EQU	BUF4
OUTFN	EQU	BUF4+40H
LSTFN	EQU	BUF4+80H
DEFFN	EQU	BUF4+0C0H
START:	MOV	AH,9
	MOV	DX,AMSG
	INT	21H
	MOV	AH,30H
	INT	21H
	TEST	AL,AL
	JNZ	MAIN
	MOV	AH,9
	MOV	DX,DOSERR
	INT	21H
	INT	20H
ERROR:	MOV	AH,9
	INT	21H
	MOV	AX,4C00H
	INT	21H
BAH:	CALL	CLOSE
OVER:	MOV	AX,4C01H
	INT	21H
MAIN:	CALL	INIT
	MOV	SI,81H
	CALL	PARAM
	JC	ERROR
	CALL	OPEN
	JC	OVER
	MOV	DI,[TEMP]
	MOV	SI,INM
	CALL	WRM
	MOV	SI,INFN
	CALL	WRM
	CALL	PRUNT
	PUSH	WORD [FUNC]
RUN:	MOV	DI,[TEMP]
	MOV	SI,PASSM
	CALL	WRM
	MOV	AX,[PASS]
	MOV	CX,10
	CALL	WN
	CALL	PRUNT
	INC	WORD [PASS]
	CALL	PROCF
	JC	BAH
	MOV	SI,SYMBS
	CALL	SYMLST
	MOV	AX,[ERRORS]
	TEST	AX,AX
	JNZ	HUMBUG
	MOV	AX,[FUNC]
	XOR	AL,AL
	XCHG	AL,AH
	MOV	[FUNC],AX
	TEST	AL,AL
	JNZ	RUN
	POP	WORD [FUNC]
	MOV	DI,[TEMP]
	MOV	SI,OUTM
	CALL	WRM
	MOV	AX,1010H
	MOV	SI,OUTFN
	CALL	NOTHER
	TEST	WORD [FUNC],8080H
	JNZ	NOWLST
	MOV	AX,4040H
	MOV	SI,LSTFN
	CALL	NOTHER
NOWLST:	CALL	PRUNT
	CALL	CLOSE
	MOV	AX,4C00H
	INT	21H
HUMBUG:	CALL	CLOSE
	MOV	AX,4C02H
	INT	21H
NOTHER:	TEST	[FUNC],AX
	JZ	NOTH0
	CALL	WRM
	MOV	AL,20H
	STOSB
NOTH0:	RET
PARAM:	CALL	RFN
	JC	PARASC
	JNZ	PARAIN
	JMP	PARAEN
PARAIN:	MOV	DI,INFN
	MOV	AL,[DI]
	TEST	AL,AL
	JNZ	PARARG
PARAWF:	MOV	DX,SI
	CALL	WFN
	MOV	AL,[DEFFN]
	TEST	AL,AL
	JNZ	PARAM
	PUSH	SI
	MOV	SI,DX
	MOV	DI,DEFFN
	CALL	WFN
	MOV	SI,DEFFN
	STC
	CALL	ADDEX
	POP	SI
	JMP	SHORT PARAM
PARASC:	MOV	DI,LSTFN
	MOV	DX,4201H
	CMP	AL,4CH
	JZ	PARAFN
	MOV	DI,OUTFN
	MOV	DX,0D0H
	CMP	AL,44H
	JZ	PARAFN
	MOV	DX,90H
	CMP	AL,55H
	JZ	PARAFN
	MOV	DX,1201H
	CMP	AL,41H
	JZ	PARAFN
	MOV	DI,ORIGIN
	CMP	AL,4FH
	JZ	PARARN
PARARG:	MOV	DX,USAGE
	STC
	RET
PARAFN:	OR	[FUNC],DX
	CALL	RFN
	JC	PARASC
	JZ	PARAEN
	JMP	PARAWF
PARARN:	CALL	CC
	JZ	PARANO
	CALL	RNC
	JC	PARANO
	MOV	[DI],DX
	JMP	PARAM
PARANO:	MOV	DX,NOPAR
	STC
	RET
PARAEN:	MOV	AL,[DEFFN]
	TEST	AL,AL
	JZ	PARANO
	MOV	AX,[FUNC]
	TEST	AX,AX
	JNZ	PARAFS
	MOV	AX,5201H
	MOV	[FUNC],AX
PARAFS:	MOV	BP,DOTCOM
	MOV	DX,DOTASM
	MOV	DI,INFN
	TEST	AX,8080H
	JZ	PARANS
	XCHG	BP,DX
PARANS:	MOV	SI,DEFFN
	CALL	RFN2
	CALL	PARAWN
	MOV	DX,BP
	MOV	DI,OUTFN
	CALL	PARAWN
	MOV	DX,DOTLST
	MOV	DI,LSTFN
PARAWN:	PUSH	BX
	PUSH	SI
	PUSH	DI
	MOV	AX,[DI]
	TEST	AL,AL
	JNZ	PARANX
	CALL	WFN
PARANX:	POP	SI
	CALL	RFN2
	CLC
	CALL	ADDEX
	POP	SI
	POP	BX
	CLC
	RET
PROCF:	MOV	AX,[ORIGIN]
	MOV	[VORG],AX
	XOR	AX,AX
	MOV	[PC],AX
	MOV	[USIZE],AX
	MOV	[ERRORS],AX
	MOV	[LSTLIN],AX
	MOV	[BUF7],AX
	INC	AX
	MOV	[PAGNUM],AX
	CALL	CALF
	LODSW
	MOV	BX,4200H
	XCHG	AX,BX
	XOR	CX,CX
	XOR	DX,DX
	MOV	[SI],DX
	INT	21H
PROCF1:	CALL	READ
	JBE	PROCF3
	MOV	AX,[PC]
	MOV	[OLDPC],AX
	CALL	ASM
	JC	PROCF4
	CALL	WLST
	JC	PROCF2
	CALL	WRITE
	JNC	PROCF1
PROCF2:	CALL	DECF
	JNC	PROCF2
	RET
PROCF3:	CALL	DECF
	JNC	PROCF1
	CLC
	RET
PROCF4:	TEST	AL,AL
	JNS	PROCF6
	CBW
	INC	AX
	JZ	PROCF3
	NEG	AX
	DEC	AX
	JNZ	PROCF5
	CALL	WLST
PROCF5:	PUSH	AX
	MOV	DI,ADIR
	SHL	AX,1
	ADD	DI,AX
	CALL	[DI]
	POP	CX
	JC	PROCF6
	JCXZ	PROCF1
	CALL	WLST
	JMP	SHORT PROCF1
PROCF6:	CALL	WLST
	CALL	SCREAM
	INC	WORD [ERRORS]
	MOV	AL,[FUNC]
	TEST	AL,40H
	JZ	PROCF1
	MOV	AH,40H
	MOV	BX,[LSTHDL]
	INT	21H
	JMP	SHORT PROCF1
WRM:	CLD
WRML:	LODSB
	STOSB
	CMP	AL,20H
	JNC	WRML
	DEC	DI
	RET
WFN:	CLD
	PUSH	BX
WFN1:	LODSB
	CMP	AL,61H
	JC	WFN2
	CMP	AL,7BH
	JNC	WFN2
	AND	AL,0DFH
WFN2:	STOSB
	DEC	BX
	JNZ	WFN1
	XOR	AL,AL
	STOSB
	POP	BX
	RET
RFN:	CLD
RFN1:	LODSB
	TEST	AL,AL
	JZ	RFN0
	CMP	AL,0DH
	JZ	RFN0
	CMP	AL,21H
	JC	RFN1
	CMP	AL,2FH
	JZ	RFN5
	DEC	SI
RFN2:	CLD
	MOV	BX,SI
RFN3:	LODSB
	CMP	AL,2FH
	JZ	RFN4
	CMP	AL,21H
	JNC	RFN3
RFN4:	DEC	SI
	SUB	SI,BX
	XCHG	SI,BX
	MOV	AL,[SI]
	TEST	BX,BX
RFN0:	RET
RFN5:	LODSB
	AND	AL,0DFH
	STC
	RET
ADDEX:	LAHF
	LEA	DI,[BX+SI]
	MOV	AL,2EH
	MOV	CX,BX
	STD
	REPNE SCASB
	JNZ	ADDEX1
	SAHF
	JNC	ADDEX0
	INC	DI
	JMP	SHORT ADDEX3
ADDEX1:	SAHF
	JC	ADDEX0
	LEA	DI,[BX+SI]
	XCHG	SI,DX
	CLD
ADDEX2:	STOSB
	LODSB
	TEST	AL,AL
	JNZ	ADDEX2
	XCHG	SI,DX
ADDEX3:	MOV	BX,DI
	SUB	BX,SI
ADDEX0:	LEA	DI,[BX+SI]
	XOR	AL,AL
	STOSB
	RET
CALF:	MOV	AX,[INCLEV]
	TEST	AX,AX
	JZ	CALF0
	CLD
	DEC	AX
	PUSHF
	XCHG	AL,AH
	SHR	AX,1
	SHR	AX,1
	MOV	SI,INCBUF
	ADD	SI,AX
	POPF
	CLC
	RET
INCF:	INC	WORD [INCLEV]
	MOV	DI,SI
	CALL	CALF
	JC	INCF0
	XCHG	DI,SI
	PUSH	DI
	CLD
	XOR	AX,AX
	STOSW
	STOSW
	MOV	DX,DI
	CALL	WFN
	MOV	AX,3D00H
	INT	21H
	POP	DI
	JC	INCF0
	STOSW
	MOV	AX,[PAGLEN]
	MOV	[LSTLIN],AX
	RET
INCF0:	DEC	WORD [INCLEV]
CALF0:	STC
	RET
DECF:	CALL	CALF
	JBE	CALF0
	MOV	AH,3EH
	MOV	BX,[SI]
	INT	21H
	DEC	WORD [INCLEV]
	MOV	AX,[PAGLEN]
	MOV	[LSTLIN],AX
	CLC
	RET
WLST:	MOV	[STK],SP
	PUSH	AX
	PUSH	DX
	PUSH	BX
	PUSH	SI
	PUSH	DI
	MOV	SI,[BINBUF]
	MOV	DI,[TEMP]
	MOV	BX,[BINLEN]
	MOV	DX,[OLDPC]
	ADD	DX,[VORG]
	MOV	AL,[FUNC]
	MOV	BP,DI
	TEST	AL,0C0H
	JZ	WLSTE
	TEST	AL,40H
	JZ	WLSTT
	CALL	WLSTS
	CALL	WLSTI
	MOV	BP,DI
WLSTT:	PUSH	BX
	PUSH	SI
	MOV	SI,[TXTBUF]
	MOV	BX,[TXTLEN]
	TEST	BX,BX
	JZ	WLSTM
WLSTL:	LODSB
	TEST	AL,AL
	JZ	WLSTM
	CMP	AL,0DH
	JZ	WLSTM
	CMP	AL,0AH
	JZ	WLSTL
	CMP	AL,9
	JNZ	WLSTN
	MOV	AX,DI
	SUB	AX,BP
	AND	AX,7
	MOV	CX,8
	SUB	CX,AX
	MOV	AL,20H
	REP
WLSTN:	STOSB
	DEC	BX
	JNZ	WLSTL
WLSTM:	POP	SI
	POP	BX
WLSTB:	MOV	AX,0A0DH
	STOSW
	PUSH	DX
	PUSH	BX
	PUSH	SI
	CALL	WTITLE
	MOV	DX,[TEMP]
	MOV	AH,40H
	MOV	BX,[LSTHDL]
	MOV	CX,DI
	SUB	CX,DX
	INT	21H
	JC	WLSTF
	POP	SI
	POP	BX
	POP	DX
	MOV	AL,[FUNC]
	TEST	AL,40H
	JZ	WLSTE
	MOV	DI,[TEMP]
	CALL	WLSTS
	JNZ	WLSTB
WLSTE:	POP	DI
	POP	SI
	POP	BX
	POP	DX
	POP	AX
	CLC
	RET
WLSTS:	MOV	AL,DH
	CALL	HALX
	MOV	AL,DL
	CALL	HALX
	TEST	BX,BX
	JZ	WLSTX
	MOV	CX,BX
	CMP	CX,LSTWID
	JC	WLSTG
	MOV	CX,LSTWID
WLSTG:	SUB	BX,CX
	JNC	WLSTR
	XOR	BX,BX
WLSTR:	ADD	DX,CX
	MOV	AL,20H
	CLD
	STOSB
WLSTP:	LODSB
	CALL	HALX
	LOOP	WLSTP
	TEST	AL,AL
WLSTX:	RET
WLSTF:	MOV	DX,LSTFN
	MOV	AL,0FH
	JMP	SCREAM
WLSTI:	PUSH	DX
	PUSH	BX
	PUSH	SI
	MOV	CX,[TEMP]
	SUB	CX,DI
	ADD	CX,LSTWID+LSTWID+6
	MOV	AL,20H
	REP STOSB
	TEST	BYTE [FUNC],80H
	JNZ	WLSTO
	CALL	CALF
	JC	WLSTO
	MOV	BP,DI
	MOV	AX,[SI+2]
	MOV	CX,10
	CALL	WN
	MOV	CX,BP
	SUB	CX,DI
	ADD	CX,6
	MOV	AL,20H
	REP STOSB
WLSTO:	POP	SI
	POP	BX
	POP	DX
	RET
WTITLE:	CLD
	PUSH	DI
	MOV	DI,BUF6
	MOV	AL,[FUNC]
	TEST	AL,40H
	JZ	WTITL5
	MOV	AX,[LSTLIN]
	TEST	AX,AX
	JZ	WTITL1
	CMP	AX,[PAGLEN]
	JC	WTITL5
	INC	WORD [PAGNUM]
	MOV	WORD [LSTLIN],0
	MOV	AL,0CH
	STOSB
WTITL1:	MOV	SI,AMSG
	CALL	WRM
	MOV	AL,20H
	MOV	CX,8
	REP STOSB
	CALL	CALF
	JC	WTITL3
	PUSH	DI
	ADD	SI,4
	CALL	WRM
	POP	CX
	SUB	CX,DI
	ADD	CX,10H
	JNS	WTITL2
	MOV	CX,1
WTITL2:	MOV	AL,20H
	REP STOSB
WTITL3:	MOV	AX,[PAGNUM]
	MOV	CX,10
	CALL	WN
	MOV	AX,0A0DH
	STOSW
	MOV	SI,BUF7
	TEST	BYTE PTR [SI],0FFH
	JZ	WTITL4
	CALL	WRM
	MOV	AX,0A0DH
	STOSW
WTITL4:	STOSW
	MOV	DX,BUF6
	MOV	CX,DI
	SUB	CX,DX
	MOV	BX,[LSTHDL]
	MOV	AH,40H
	INT	21H
WTITL5:	INC	WORD [LSTLIN]
	POP	DI
	CLC
	RET
READ:	MOV	[STK],SP
	CALL	CALF
	JC	READ1
	INC	WORD [SI+2]
	MOV	BX,[SI]
	MOV	AL,[FUNC]
	TEST	AL,AL
	JNS	READ2
	MOV	AX,4200H
	XOR	CX,CX
	MOV	DX,[PC]
	INT	21H
	JC	READ8
	MOV	AH,3FH
	MOV	CX,8
	MOV	DX,[BINBUF]
	INT	21H
	JC	READ8
	TEST	AX,AX
	RET
READ1:	SUB	AX,AX
	RET
READ2:	MOV	AH,3FH
	MOV	CX,MAXLEN
	MOV	DX,[TXTBUF]
	INT	21H
	JC	READ8
	TEST	AX,AX
	JZ	READ1
	MOV	CX,AX
	MOV	DX,AX
	XOR	BX,BX
	MOV	DI,[TXTBUF]
READ3:	MOV	AL,[BX+DI]
	INC	BX
	MOV	AH,0AH
	CMP	AL,0DH
	JZ	READ6
	MOV	AH,0DH
	CMP	AL,0AH
	JZ	READ6
	LOOP	READ3
	CMP	BX,MAXLEN
	JNC	READ5
	MOV	[BX+DI],AH
	INC	BX
READ4:	MOV	[TXTLEN],BX
	TEST	BX,BX
	CLC
	RET
READ5:	MOV	AL,0EH
	JMP	SCREAM
READ6:	JCXZ	READ7
	CMP	[BX+DI],AH
	JNZ	READ7
	INC	BX
READ7:	XOR	AL,AL
	MOV	[BX+DI],AL
	MOV	AX,BX
	SUB	AX,DX
	JZ	READ4
	CWD
	PUSH	BX
	MOV	CX,4201H
	XCHG	AX,DX
	XCHG	AX,CX
	MOV	BX,[SI]
	INT	21H
	POP	BX
	JNC	READ4
READ8:	MOV	DX,4
	ADD	DX,SI
	MOV	AL,0FH
	JMP	SCREAM
WRITE:	MOV	[STK],SP
	MOV	AL,[FUNC]
	TEST	AL,AL
	JS	WRITE5
	TEST	AL,10H
	JZ	WRITE0
	MOV	CX,[BINLEN]
	JCXZ	WRITE5
	MOV	DX,[USIZE]
	TEST	DX,DX
	JZ	WRITE3
	MOV	DI,[TEMP]
	MOV	CX,100H
	XOR	AL,AL
	CLD
	REP STOSB
WRITE1:	PUSH	DX
	MOV	CX,100H
	CMP	CX,DX
	JC	WRITE2
	MOV	CX,DX
WRITE2:	PUSH	CX
	MOV	AH,40H
	MOV	DX,[TEMP]
	MOV	BX,[OUTHDL]
	INT	21H
	JC	WRITE4
	POP	CX
	POP	DX
	SUB	DX,CX
	JA	WRITE1
WRITE3:	MOV	AH,40H
	MOV	CX,[BINLEN]
	MOV	DX,[BINBUF]
	MOV	BX,[OUTHDL]
	INT	21H
	JNC	WRITE0
WRITE4:	MOV	DX,OUTFN
	MOV	AL,0FH
	JMP	SCREAM
WRITE0:	XOR	AX,AX
	MOV	[USIZE],AX
WRITE5:	CLC
	RET
CLOSE:	CALL	CALF
	JC	NOIN
	MOV	AH,3EH
	MOV	BX,[SI]
	INT	21H
NOIN:	TEST	WORD [FUNC],4040H
	JZ	NOLST
	TEST	WORD [FUNC],8080H
	JNZ	NOLST
	MOV	AH,3EH
	MOV	BX,[LSTHDL]
	INT	21H
NOLST:	TEST	WORD [FUNC],1010H
	JZ	NOOUT
	MOV	AH,3EH
	MOV	BX,[OUTHDL]
	INT	21H
NOOUT:	RET
OPEN:	MOV	SI,INFN
	CALL	RFN2
	CALL	INCF
	MOV	AL,0BH
	JC	SCREAM
	TEST	WORD [FUNC],1010H
	JZ	OPEN2
	MOV	AH,3CH
	XOR	CX,CX
	MOV	DX,OUTFN
	INT	21H
	JC	OPEN4
	MOV	[OUTHDL],AX
OPEN2:	TEST	WORD [FUNC],8080H
	JNZ	OPEN3
	TEST	WORD [FUNC],4040H
	JZ	OPEN1
	MOV	AH,3CH
	XOR	CX,CX
	MOV	DX,LSTFN
	INT	21H
	JC	OPEN5
	MOV	[LSTHDL],AX
OPEN1:	CLC
	RET
OPEN3:	MOV	[LSTHDL],AX
	CLC
	RET
OPEN5:	CALL	NOLST
OPEN4:	MOV	AL,0BH
SCREAM:	CLD
	CBW
	MOV	DI,[TEMP]
	MOV	CX,AX
	CMP	AL,0FH
	JZ	SCRUM
	CALL	CALF
	JC	SCROOM
	LODSW
	LODSW
	PUSH	AX
	CALL	WRM
	MOV	AL,28H
	STOSB
	POP	AX
	PUSH	CX
	PUSH	DX
	MOV	CX,10
	CALL	WN
	POP	DX
	POP	CX
	MOV	AX,2029H
	STOSW
SCROOM:	CMP	CL,5
	JZ	SCROYM
	CMP	CL,0BH
	JNZ	SCROME
SCRUM:	MOV	SI,DX
	CALL	WRM
	JMP	SHORT SCROME
SCROYM:	PUSH	CX
	MOV	AX,DX
	MOV	CX,10
	CALL	WN
	POP	CX
SCROME:	MOV	SI,EM0
	JCXZ	SCRAM
SCREM:	LODSB
	TEST	AL,AL
	JNZ	SCREM
	LOOP	SCREM
SCRAM:	CALL	WRM
PRUNT:	MOV	DX,[TEMP]
	MOV	AX,0A0DH
	STOSW
	MOV	CX,DI
	SUB	CX,DX
	PUSH	CX
	PUSH	DX
	MOV	AH,40H
	MOV	BX,1
	INT	21H
	POP	DX
	POP	CX
	STC
	RET
INIT:	MOV	AX,BUF1
	MOV	[TXTBUF],AX
	MOV	AX,BUF2
	MOV	[BINBUF],AX
	MOV	AX,BUF3
	MOV	[TEMP],AX
	MOV	AX,SYMBS
	MOV	[SYM],AX
	XOR	DI,DI
	XCHG	DI,AX
	STOSW
	MOV	[INCLEV],AX
	MOV	[FUNC],AX
	MOV	[INFN],AX
	MOV	[OUTFN],AX
	MOV	[LSTFN],AX
	MOV	[DEFFN],AX
	INC	AX
	MOV	[PASS],AX
	RET
P2:	XOR	AL,AL
	MOV	[BX+SI],AL
	CALL	INCF
P2F:	MOV	AL,0BH
	RET
P3:	MOV	AX,3D00H
	MOV	[BX+SI],AL
	MOV	DX,SI
	INT	21H
	JC	P2F
	MOV	BX,AX
P3L:	MOV	AH,3FH
	MOV	DX,[TEMP]
	MOV	CX,100H
	INT	21H
	MOV	DX,SI
	JC	P2F
	ADD	[PC],AX
	MOV	CX,AX
	JCXZ	P3E
	TEST	BYTE [FUNC],10H
	JZ	P3S
	PUSH	AX
	PUSH	BX
	MOV	AH,40H
	MOV	DX,[TEMP]
	MOV	BX,[OUTHDL]
	INT	21H
	POP	BX
	POP	AX
P3S:	TEST	AX,AX
	JNZ	P3L
P3E:	MOV	AH,3EH
	INT	21H
	RET
P4:	CALL	PRUNT
	CLC
	RET
P5:	CLD
	MOV	DI,BUF7
	MOV	CX,BX
	REP MOVSB
	XOR	AL,AL
	STOSB
	CLC
	RET
P6:	TEST	DX,DX
	JNZ	P6S
	MOV	AX,[PAGLEN]
	MOV	[LSTLIN],AX
	CLC
	RET
P6S:	MOV	[PAGLEN],DX
	CLC
	RET
SYMLST:	TEST	BYTE [FUNC],40H
	JNZ	SYMLS0
	RET
SYMLS0:	CLD
	PUSH	SI
	CALL	SYMSRT
	POP	SI
	LODSW
	MOV	CX,AX
	XOR	DX,DX
	MOV	AX,[PAGLEN]
	MOV	[LSTLIN],AX
	JCXZ	SYMLS8
	PUSH	CX
	PUSH	SI
SYMLS1:	XOR	BX,BX
SYMLS2:	LODSB
	INC	BX
	TEST	AL,AL
	JNZ	SYMLS2
	LODSW
	CMP	DX,BX
	JNC	SYMLS3
	MOV	DX,BX
SYMLS3:	LOOP	SYMLS1
	POP	SI
	POP	CX
	MOV	DI,[TEMP]
SYMLS4:	CLD
	PUSH	CX
	MOV	CX,DI
SYMLS5:	LODSB
	STOSB
	TEST	AL,AL
	JNZ	SYMLS5
	DEC	DI
	SUB	CX,DI
	ADD	CX,DX
	MOV	AL,20H
	REP STOSB
	LODSW
	PUSH	AX
	MOV	AL,AH
	CALL	HALX
	POP	AX
	CALL	HALX
	MOV	AX,2020H
	STOSW
	MOV	CX,DI
	SUB	CX,[TEMP]
	ADD	CX,DX
	CMP	CX,4EH
	POP	CX
	JB	SYMLS6
	CALL	SYMLS7
	MOV	DI,[TEMP]
SYMLS6:	DEC	CX
	JNZ	SYMLS4
SYMLS7:	CMP	DI,[TEMP]
	JBE	SYMLS8
	DEC	DI
	DEC	DI
	MOV	AX,0A0DH
	STOSW
	PUSH	CX
	PUSH	DX
	PUSH	SI
	CALL	WTITLE
	MOV	AH,40H
	MOV	DX,[TEMP]
	MOV	CX,DI
	SUB	CX,DX
	MOV	BX,[LSTHDL]
	INT	21H
	POP	SI
	POP	DX
	POP	CX
SYMLS8:	RET
SYMSRT:	CLD
	LODSW
	MOV	CX,AX
	CMP	AX,2
	JNC	SYMSR1
	RET
SYMSR1:	MOV	DX,CX
	PUSH	CX
	PUSH	SI
	MOV	DI,SI
SYMSR2:	LODSB
	AND	AL,7FH
	STOSB
	JNZ	SYMSR2
	MOVSW
	LOOP	SYMSR2
	POP	SI
	POP	CX
	PUSH	CX
	PUSH	SI
SYMSR3:	XOR	BX,BX
SYMSR4:	MOV	AL,[BX+SI]
	INC	BX
	TEST	AL,AL
	JNZ	SYMSR4
	INC	BX
	INC	BX
	LEA	DI,[BX+SI]
	XOR	BP,BP
SYMSR5:	MOV	AL,[BP+DI]
	INC	BP
	TEST	AL,AL
	JNZ	SYMSR5
	INC	BP
	INC	BP
	MOV	CX,BX
	CMP	CX,BP
	JNB	SYMSR6
	MOV	CX,BP
SYMSR6:	PUSH	SI
	PUSH	DI
	REPE CMPSB
	POP	DI
	POP	SI
	JB	SYMSR7
	PUSH	SI
	PUSH	DI
	MOV	DI,[TEMP]
	MOV	CX,BX
	REP MOVSB
	POP	DI
	POP	SI
	PUSH	SI
	XCHG	SI,DI
	MOV	CX,BP
	REP MOVSB
	MOV	SI,[TEMP]
	MOV	CX,BX
	REP MOVSB
	POP	SI
	MOV	BX,BP
SYMSR7:	ADD	SI,BX
	DEC	DX
	CMP	DX,2
	JNC	SYMSR3
	POP	SI
	POP	CX
	DEC	CX
	CMP	CX,2
	JNC	SYMSR1
	RET
	INCLUDE	GENERIC.ASM
	INCLUDE	8086.ASM
ORIGIN:	DW	DEFORG
PAGLEN:	DW	DEFPAG
ADIR:	DW	P2,P3,P4,P5
	DW	P6
EM0:	DB	"INVALID OPERAND",0
EM1:	DB	"SYNTAX ERROR",0
EM2:	DB	"INVALID ADDRESSING",0
EM3:	DB	"INVALID INSTRUCTION",0
EM4:	DB	"UNDEFINED SYMBOL",0
EM5:	DB	" BYTE(S) OUT OF RANGE",0
EM6:	DB	"OPERAND SIZE MISMATCH",0
EM7:	DB	"CONSTANT TOO LARGE",0
EM8:	DB	"MISSING OPERAND",0
EM9:	DB	"GARBAGE PAST END",0
EMA:	DB	"DUPLICATE SYMBOL",0
EMB:	DB	" NOT ACCESSIBLE",0
EMC:	DB	"RESERVED WORD MISUSE",0
EMD:	DB	"INVALID REGISTER",0
EME:	DB	"LINE TOO LONG",0
EMF:	DB	" FILE I/O ERROR",0
DOTASM:	DB	"ASM",0
DOTCOM:	DB	"COM",0
DOTLST:	DB	"LST",0
PASSM:	DB	"PASS ",0
INM:	DB	"IN: ",0
OUTM:	DB	"OUT: ",0
AMSG:	DB	"PC-72 ASSEMBLER"
	DB	" VERSION 1.05"
	DB	13,10,36
DOSERR:	DB	"BAD DOS VERSION"
	DB	13,10,36
NOPAR:	DB	"MISSING PARAMETER"
	DB	13,10,36
USAGE:	DB	"A72 IN [/SWITCH [OUT]"
	DB	" [/SWITCH [OUT]] ...]"
	DB	13,10
	DB	"/A [OUT[.COM]]",9
	DB	"ASSEMBLE TO BINARY"
	DB	13,10
	DB	"/D [OUT[.ASM]]",9
	DB	"DISASSEMBLE WITH HEX"
	DB	13,10
	DB	"/L [OUT[.LST]]",9
	DB	"ASSEMBLE TO LISTING"
	DB	13,10
	DB	"/O 100H",9,9
	DB	"SET ORIGIN"
	DB	13,10
	DB	"/U [OUT[.ASM]]",9
	DB	"DISASSEMBLE PLAIN"
	DB	13,10,36
BUF1:	DS	MAXLEN
BUF2:	DS	100H
BUF3:	DS	100H
BUF4:	DS	100H
BUF5:	DS	100H
BUF6:	DS	100H
BUF7:	DS	100H
INCBUF:	DS	100H
SYMBS:
