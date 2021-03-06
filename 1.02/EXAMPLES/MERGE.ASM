		XOR AX, AX
		MOV [INCLEV], AX
		MOV SI, 80H
		CLD
		LODSB
		MOV CX, AX
		ADD CX, SI
		MOV DI, OFFSET INFN
		CALL GETFN
		JC HELP
		MOV DI, OFFSET OUTFN
		CALL GETFN
		JC HELP
		MOV SI, OFFSET DOTASM
		MOV DI, OFFSET INFN
		CLC
		CALL ADDEXT
		MOV SI, OFFSET DOTASM
		MOV DI, OFFSET OUTFN
		CLC
		CALL ADDEXT
		MOV DI, OFFSET OUTFN
		XOR AL, AL
		MOV CX, 13
	REPNZ	SCASB
		NEG CX
		ADD CX, 12
		MOV SI, OFFSET INFN
		MOV DI, OFFSET OUTFN
	REPZ	CMPSB
		JNZ PERF
		MOV AH, 9
		MOV DX, OFFSET SAMEM
		INT 21H
		RET
HELP:		MOV AH, 9
		MOV DX, OFFSET AMSG
		INT 21H
		RET
PERF:		MOV SI, OFFSET INFN
		CALL OPNEW
		JC OVER
		MOV AH, 3CH
		XOR CX, CX
		MOV DX, OFFSET OUTFN
		INT 21H
		JNC GOTOUT
		CALL CLOSF
		MOV SI, OFFSET NOPE
		CALL STOP
		MOV SI, OFFSET OUTFN
		CALL OUTF
		CALL CRLF
OVER:		RET
GOTOUT:		MOV [OUTFILE], AX
MAINL:		MOV AX, [INCLEV]
		SHL AX, 1
		ADD AX, OFFSET INCLEV
		MOV BX, AX
		MOV BX, [BX]
		MOV DI, OFFSET BUFFER
		CALL FRLT
		OR AX, AX
		JZ MAINLE
		MOV SI, OFFSET BUFFER
		MOV DI, OFFSET TRIMMED
		CALL TRIM
		MOV SI, OFFSET TRIMMED
		LODSB
		OR AL, AL
		JZ WRITE
		XOR AH, AH
		MOV DX, AX
FINDL:		PUSH SI
		MOV DI, OFFSET INCL
		MOV AL, [SI]
		INC AX
		MOV CX, AX
	REPZ	CMPSB
		POP SI
		JZ READIN
		ADD SI, AX
		DEC DX
		JNZ FINDL
WRITE:		MOV AH, 40H
		XOR CH, CH
		MOV CL, [BUFFER]
		MOV DX, OFFSET BUFFER+1
		MOV BX, [OUTFILE]
		INT 21H
		JMP SHORT MAINL
READIN:		ADD SI, AX
		MOV DI, OFFSET INCFN
		LODSB
		MOV CX, AX
		JCXZ MAINL
		MOV AL, [SI]
		CMP AL, 22H
		JZ $+6
		CMP AL, 27H
		JNZ $+7
		INC SI
		SUB CX, 2
		JNA MAINL
		MOV DI, OFFSET INCFN
	REPZ	MOVSB
		XOR AL, AL
		STOSB
		MOV SI, OFFSET INCFN
		CALL OPNEW
		JMP SHORT MAINL
MAINLE:		CALL CLOSF
		JNZ MAINL
		MOV AH, 3EH
		MOV BX, [OUTFILE]
		INT 21H
		MOV SI, OFFSET DONE
		CALL STOP
		MOV SI, OFFSET OUTFN
		CALL OUTF
		CALL CRLF
		RET
OPNEW:		MOV AX, 3D00H
		MOV DX, SI
		INT 21H
		JC OPNEW0
		INC WORD PTR [INCLEV]
		MOV BX, [INCLEV]
		SHL BX, 1
		ADD BX, OFFSET INCLEV
		MOV [BX], AX
		PUSH SI
		MOV SI, OFFSET PROCM
		CALL STOP
		POP SI
		CALL OUTF
		CALL CRLF
		CLC
		RET
OPNEW0:		PUSH SI
		MOV SI, OFFSET NOPE
		CALL STOP
		POP SI
		CALL OUTF
		CALL CRLF
		STC
		RET
CLOSF:		MOV BX, [INCLEV]
		SHL BX, 1
		ADD BX, OFFSET INCLEV
		MOV AH, 3EH
		MOV BX, [BX]
		INT 21H
		DEC WORD PTR [INCLEV]
		RET
		INCLUDE GETFN.
		INCLUDE ADDEXT.
		INCLUDE TRIM.
		INCLUDE FRLT.
		INCLUDE OUTF.
		INCLUDE STOP.
		INCLUDE CRLF.
OUTFILE		DW 0
DOTASM		DB 3, "ASM"
INCL		DB 7, "include"
PROCM		DB 8, "Reading "
NOPE		DB 14, "Couldn't open "
DONE		DB 10, "Merged to "
SAMEM		DB "Cannot read from and write to the same file", 13, 10, 36
AMSG		DB "Recursively merges INCLUDEs into one file", 13, 10
		DB "Syntax:  MERGE <in>[.ASM] <out>[.ASM]", 13, 10, 36
INFN		DS 40H
OUTFN		DS 40H
INCFN		DS 40H
BUFFER		DS 100H
TRIMMED		DS 100H
INCLEV		DS 100H
