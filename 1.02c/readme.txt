Version 1.02c

Changes from 1.01:
- Removed redundant code in places
- Rewrote entire sections of code, such as RA, the file I/O routines, G14H handler
- The parser now uses the older (but better) TRIM instead of CC/GN/TGN
- Everything not fully implemented has been cut (specifically EVEN, LABEL, EQU, and DUP)
- DB x DUP(y) macro structure removed
- Added DS directive to reserve arbitrary amounts of undefined bytes of buffer space
- Removed REL keyword and numeric instruction duplication prefixes since there was no point to them
- Added full support for the 8087 instruction set--no more need for ESCs!

A72 is a 8086 assembler without bells, whistles, gongs, or macros.  It's a bare-bones assembler that will take standard Intel-format assembly and turn it into a COM file executable under MS-DOS.  I fully acknowledge that it is entirely obsolete and nigh useless in 2019.  I wrote it for my own sake because I wanted to write assembly without having to use a bunch of directives and extraneous garbage in order to even just start writing.  I wrote it in assembly because I'm not a programmer and assembly and machine code are the only kind of programming I understand.  In order to facilitate testing and working with machine code more closely, I put a disassembler into it.

I broke many cardinal rules when writing the program.  It's uncommented and does not use descriptive symbols.  It's absolute spaghetti code.  This README file is brief explanation of some of its internal mechanics.  On the flip side, the code is more or less modular, but with little overhead.  Expanding it would be trivial.  I was working with it from a machine code perspective, so a lot of bit manipulation is involved, and every possible 8086 encoding for a given instruction is incorporated.  Its final test was assembling itself.  It passed the test.  The included binary is its own output binary.

A72 doesn't care about spacing.  A line is automatically cut off at the comment semicolon or a carriage return, whichever is first.  Numeric constants may only be passed as integers, in either hexadecimal, binary, or decimal.  Simple arithmetics (e.g. to add further numeric offsets to label references) will be evaluated.  Valid characters for identifiers are all digits, all letters, period, underscore, and @.  An identifier may not start on a numeric lest it be interpreted as a value.  Everything else is parsed as a symbol.  A72 is not case-sensitive, and uses syntax based on Ideal Mode syntax, but with some key differences to make it ultra-orthodox:

- Addressing always uses brackets.  Anything enclosed in brackets is a pointer.  Anything without brackets is an offset or an immediate.  The OFFSET keyword can be used, but is simply skipped by the parser:
	MOV	AX,[VAR]		; puts contents of VAR into AX
	MOV	AX,VAR		; puts offset to VAR into AX
	MOV	AX,OFFSET VAR	; completely equivalent to the above
	MOV	BX,[0DEADH]	; puts word value at address 0DEADH into BX
	MOV	BX,0DEADH	; puts value 0DEADH into BX

- Array referencing and addressing takes place entirely within displacement brackets along with base and index registers:
	MOV	AX,[BX+VAR]	; good
	MOV	DX,[SI+VAR+BX]	; good
	MOV	SI,VAR[BX]	; bad; tries to load offset of VAR into SI and generates "Characters past end" error due to "[BX]"
	MOV	CL,[4+DI-VAR]	; good
	MOV	[VAR+VAR2-4],AX	; good
	MOV	DI,[BP-SI]		; bad; can't use minus with displacement registers
	MOV	[BP][DI],CL	; bad; generates "Syntax error" error because "[DI]" is where a comma is expected

- Data types of memory locations are never checked, so WORD PTR/BYTE PTR are used solely for displacement operands with immediate sources:
	MOV	[BP],AX		; good; data size implied by AX being a 16-bit register
	MOV	BYTE PTR [SI],4	; good
	MOV	[VAR],4		; misguided; will assemble, but requires type size to be specified, since it defaults to byte
	MOV	[VAR],0F00H	; bad; generates "Constant too large" error since zero data type is byte
	MOV	WORD PTR [VAR],5	; good

- Boilerplate code isn't required (and is barely even supported because there's no CODESEG/DATASEG/MODEL directives)
- Segment overrides can be written on separate lines, just like in the old MS-DOS DEBUG.EXE.
- Explicit-operand forms of the string instructions are not supported, but if a segment prefix must be specified, this can be done as the above.
- SALC and AAM/AAD with (8-bit numeric!) arguments is supported.

1. Functions

ADDEXT, Add extension: if CF unset, checks a file name in [DI] if it has an extension and adds one (pointed to by [SI]).  If CF set, removes extension from file name if there is one.
ASM, Assemble: assembles one line of code, read from DS:[SI] and written to [OUTPUT], and updates [PC].
ASMF, Assemble file: assembles the default input file once, regulated by [FUNC].
BITS, Check signed AX size: determines if AX, signed, can fit into a single byte.  CF=0 if it can.
CALF, Calculate file: calculates the addresses of the records at the top of the [INCLEV] stack.
CLOSF, Close files: closes the input and output file.
CNVTB, Convert byte: writes a lookup table addressed mnemonic to disassembly output.
COMMA: checks if the next element on the line is a comma and generates an error if not.
CRLF: Writes a CRLF line break to the console.
DISASM, Disassemble: disassembles one line of code.  [PC] is updated according to scan.  See DISF below.
DISF, Disassemble file: disassembles the default input file once.  Scan is conducted according to the detected instruction.  [PC] is updated by the amount of characters read from DS:[SI].
ENDL: End line: inserts end of line and comment with address and opcodes into disassembly output.
EXTEND: extends the 8087 opcodes stored in the 8087 instruction table to a full ESC sequence.  See stored 8087 opcode format in the tables.
FAIL: Aborts assembly of given line, generates an error message (specified in AL) in [ELEMENT], and transfers control directly back to ASM by skipping back to its return value on the stack.
G0 thru G27H, Assembly groups: instruction encoders, including assembler directives, indexed by the table at [IHDL]. Instructions are grouped according to the way they read operands and the way those operands are encoded and written.
GETFN, Get file name: a simple, stupid, quick and dirty line scanner that takes out elements separated by spaces and returns them as file names.
GRP, Group: prepare opcode extension for scan in group lookup table during disassembly.  Some opcode groups have MODRM extensions and the lookup tables point to the requisite mnemonics.
HALX, Hex AL to AX: converts byte value in AL to full hex string in AX, ready to STOSW.
INCF, Include file: updates [INCLEV] with currently active [INFILE] and add its file name (pointed to by [SI]) to the file name table.
LSPR, Loose prefix: writes a "dangling" segment or FWAIT prefix (one that wasn't included in a displacement) as a separate instruction, inserted before the main output code line.
MAIN: Main program.  Reads command line, displays main status messages, handles file open/close operations, and calls both passes of assembly.  If any errors are encountered during pass 1, pass 2 isn't executed and an output file isn't created or modified.
MMODRM: Make Mod-Reg-R/M byte: constructs a Mod byte based on [ARGS] and the displacement specification in [FLAGS].  Sets Mod byte flag (in [FLAGS]).  Refer to [ARGS] and [FLAGS] specifications for detail.
NORF, Near or far: scans for NEAR/FAR/SHORT sequence and sets AL to the length of the given word detected.
OPENF, Open files: opens the input and output file and handles the errors with either.
RA, Read argument: the heart of the assembler.  Reads one full argument of an instruction, detecting its exact nature, type, and size, and sets all three levels of [ARGS] accordingly, as well as displacement/immediate/segment prefix flags (in [FLAGS]) as applicable.  As above, see [ARGS] and [FLAGS] specifications for details.
RD, Read: reads one full line of code from the default input file, up to and including the CR.  LF is ignored by the parser, along with other control codes.
RE, Read element: a subcompartment of RA, but can be called separately.  Reads an argument that is either an offset, a symbol, or a numeric constant, returning the result as an immediate in AX, the type of the immediate in DH, and its size in CH.  DL always returns 4.  Refer to [ARGS] format for specifications.
SCREG, Scan registers: part of the larger RA algorithm.  Checks if the P-string at [SI] is the name of a register, and returns the [REGS] index in CL and CF=0 if it is.
SL, Symbol lookup: looks symbol at DS:[SI] in a lexicon specified at ES:[DI].  Sets carry flag is unsuccessful.  Otherwise, clears carry flag and returns symbol value in AX, and the pointer to said value in the symbol's entry in the lexicon in DI.
STOP, String output: Writes a P-string to the console.
SW, Scan words: compares P-strings at [SI] and [DI] and returns the length in CX if they are the same.  If not, returns 0 in CX.
TABS: Insert tabs: used by ENDL and DISASM to generate the correct amount of tabs needed to line up the hex opcode comments.
TRIM: a tokeniser. Scans a P-string at DS:[SI] and on and writes all discrete tokens to DS:[DI] as P-strings, terminating the sequence with NUL.
VAL, Value of string: reads a number P-string and translates it to a value in AX. It scans for a sigil at the end of a number, B for binary or H for hex, as per convention.  If a numeric character is the final character, it's assumed to be decimal.  Clears CF if it reads a valid number, and sets CF if not.
WA, Word adjust: reads [ARGS+2], detects dominant instruction argument size, and sets [WADJ] accordingly for use by instruction encoders.
WARG, Write argument: Intrinsic part of RA.  Updates all three levels of [ARGS] at the end of RA.  See [ARGS] tables.
WDA, Write decimal AX: converts the value of AX to decimal and just writes it straight to ES:[DI] (not as a P-string!)
WDISP, Write displacement: decodes mod byte and writes the decoded R/M field to the output disassembly.
WFST, Write F-stack register: writes 8087 stack register from register field to disassembly.
WHA, Write hexadecimal AX: converts the value of AX to hexadecimal and writes it directly to ES:[DI] (only the characters; no terminator or length byte)
WPTR, Write PTR sequence: writes the BYTE/WORD/DWORD etc. PTR sequence to the output disassembly according to [WADJ].
WR, Write: writes [OUTPUT] to the default output file if the relevant [FUNC] flag is set.  See [FUNC] flags format.
WREG, Write register: writes register from register field to disassembly.
WSPR, Write segment prefix: writes cached segment prefix to disassembly.
WSR, Write segment register: writes segment register from register field to disassembly.

In addition, all of the functions ending on D are disassembly groups, addressed by the [BIN86] and [BIN87] tables.  The handlers used depend not on the instruction but on the way its trailing bytes are encoded and stored.

2. Buffers, tables, indexes, and variables

_DISP, Displacement table: lookup table for offsets to pertinent registers in [REGS] from start of [REGS], for use in WDISP
_G01D thru _G04D, Group disassembly: lookup tables to mnemonics for group instruction opcodes.
_GRP, Blank group: zeroes to signal to the disassembler that it shouldn't write a mnemonic until further notice.
_SG5 thru _SG7: lookup tables for mnemonics for 8087 group instruction opcodes.
_SGS, Singles: lookup table for mnemonics of 8087 instructions distinguished only by the lower 3 bits of the instruction.
ARGS, Arguments: instruction arguments, see [ARGS] entry among the tables further down.
ARITB, Arithmetic table: accounts for some encoding inconsistencies of the 8087 arithmetic instructions.
BIN86, Binary 8086 opcodes: a 256-entry table with offsets to mnemonics and handler routines for each 8086 opcode.
BIN87, Binary 8087 opcodes: same as above, for 8087 opcodes.
DISP, Displacement: displacement value read as part of a R/M-type argument, stored as a 16-bit value.
ELEMENT: used to hold the P-strings read as tokens by the parser, as well as to convey error messages.
ERRM, Error messages: index of error message offsets to be addressed with AL during FAIL.
ERRS, Errors: amount of errors encountered during one assembly pass.
FLAGS: See [FLAGS] entry in tables below.
FLDTB, FLD table: accounts for some encoding inconsistencies in the 8087.
FNAMES, File names: buffer used to hold file names on the [INCLEV] stack.
FUNC, Function: specifies the function.  See [FUNC] in tables ahead.
I8086, 8086 instructions: List of all valid 8086 instructions in SL-readable lexicon format (see [SYMBS] in tables).  Every entry has a P-string for the instruction, followed by one byte containing the expected or default opcode, and another byte denoting the instruction's group.  The group number is used with IHDL as an index to the appropriate encoder subfunction.
IHDL: Instruction handlers: index of instruction encoders according to group.  See I8086 above.
IMM, Immediate: immediate value detected as argument, stored as a 16-bit value.
INCLEV, Include level: a stack of file handles used when the INCLUDE directive is invoked.  Whenever an included file is opened, the include stack is incremented and the name and handle of the file are put on the stack.  When it's closed, the stack is decremented.  This allows for multiple include levels, limited only by the buffer size.  Then again, only psychopaths would have more than three or four include levels.  The buffer size can be increased in the most banal manner to allow for more.
INFILE, Input file: handle of default input file to read lines of assembly from.  May change through INCLUDE directives.  See [INCLEV] entry above.
INFN, Input file name, in ASCIIZ string form.
INPUT, Input buffer: default buffer used to hold a line of code that is read from a file and assembled.
LN, Line: current line read from the input file and/or assembled.
MODRM: Mod byte generated by MMODRM and/or altered by instruction encoders.
OP, Operator: temporary arithmetic operator storage used during RA to read if anything is added to or subtracted from displacements or immediates.
OPCODE: the default/expected opcode for a given scanned valid instruction.
OUTFILE, Output file: handle of default output file to write assembled binary code or data to.
OUTFN, Output file name, as an ASCIIZ string.
OUTPUT, Output buffer: used to hold the assembled binary code or data as a P-string.
PC, Program counter: current write address in assembled binary.
PREFIX: Instruction prefix opcode held for use.
REGS: All valid registers, including segment registers, in R/M order, stored as one big string literal addressable with R/M and WADJ.
RM: Lookup table of valid R/M field register combinations.  The displacement scanner works with a bit for each of the SI, DI, BP, and BX registers, for a total of 16 combinations.  The lookup table filters out the illegal ones and returns the proper R/M field number of a valid combination.  See [RM] entry in tables below.
SEGPREF: Segment override prefix opcode held for use.
SIZES: data size keywords used by WPTR addressed by size index (see [ARGS]data types in the tables)
STK, Stack: holds the stack as it is before any function is called from ASM.  Used by FAIL to ensure safe returns to ASM after errors.
SYMBS, Symbols: 8KB buffer to hold the symbols used.  The first word is the amount of entries in the buffer, followed by the entries sequentially, with no index.  Each entry has a P-string (length byte for the symbol, followed by its name string) and two data bytes (address word or the opcode-group combo used in I8086) and are therefore read through one by one in order to either find a particular one or just get to the end.
TEMP, Temp buffer: used to hold temporary data.
USIZE, Undefined size: amount of undefined bytes left over after everything is written.  They are not written to the file if they are the last thing to be written, otherwise they are written as zeroes.
VORG, Value of origin: current origin, 100h by default; added to [PC] during symbol scanning, and set by the ORG directive.
WADJ, Word adjustment: used by instruction encoders to detect and encode 16-bit operands or instructions.  Instruction encoders to which [WADJ] is critical rely on WA to read [ARGS+2] and set [WADJ] accordingly for use as a word flag.

3. Data formats

3.1. ARGS is three bytes holding the specification of the arguments read by RA.  The first argument's specifications is in the lower nibbles of the ARGS bytes; the second argument is in the upper nibbles if present--otherwise, those are 0.

3.1.1. [ARGS+0], argument type
1	Register
2	R/M
3	Segment register
4	Immediate value
5	8087 stack register

3.1.2. [ARGS+1], types of register if [ARGS] is 1 and [ARGS+2] is 1:
0	AL
1	CL
2	DL
3	BL
4	AH
5	CH
6	DH
7	BH

3.1.3. [ARGS+1], types of register if [ARGS] is 1 and [ARGS+2] is 2:
0	AX
1	CX
2	DX
3	BX
4	SP
5	BP
6	SI
7	DI

3.1.4. [ARGS+1], types of stack register if [ARGS] is 5:
0	ST(0)
1	ST(1)
2	ST(2)
3	ST(3)
4	ST(4)
5	ST(5)
6	ST(6)
7	ST(7)

3.1.5. [ARGS+1], types of R/M if [ARGS] is 2:
0	[BX+SI]
1	[BX+DI]
2	[BP+SI]
3	[BP+DI]
4	[SI]
5	[DI]
6	[BP]
7	[BX]
0Eh	[imm16]

3.1.6. [ARGS+1], types of segment register if [ARGS] is 3:
0	ES
1	CS
2	SS
3	DS

3.1.7. [ARGS+1], types of immediate value if [ARGS] is 4:
0	regular numeric value
1	offset
2	[PC] (dollar sign)
3	string literal

3.1.8. [ARGS+2], argument sizes
0	unset/flexible
1	byte
2	word
3	dword
4	quadword
5	ten bytes (encoded as a full paragraph out of laziness)

3.2. FLAGS is the binary output flags.  Each bit corresponds to a part of the instruction.  When a valid instruction or directive is scanned, the opcode flag is set automatically.  In the case of directives, the opcode flag is manually unset by the handler invoked.  Other flags are set by relevant subfunctions; e.g. RA is responsible for setting the displacement, immediate, and segment prefix flags.  MMODRM sets the Mod flag.
80h	Prefix instruction
40h	Segment prefix
20h	Opcode
10h	Mod byte
8	Displacement
4	16-bit extension for displacement
2	Immediate value
1	16-bit extension for immediate

3.3. FUNC is the assembler function.
0	Do not scan or save symbols.  Do not read or write files.  Essentially, just assembles one line of code to [OUTPUT].  Used for debug purposes.
1	Save symbols and read from input file.  Pass one of assembly.
2	Read symbols, read input file, write output file.  Pass two of assembly.
3	Disassemble.

4. Instruction groups
0	Single-byte instructions without any parameters (DAA, DAS, AAA, AAS, NOP, CBW, CWD, WAIT, PUSHF, POPF, SAHF, LAHF, MOVSx, CMPSx, STOSx, LODSx, SCASx, INTO, IRET, SALC, XLATB, HLT, CMC, CLC, STC, CLI, STI, CLD, STD)
1	Group 1 instructions with set two-parameter format (ADD, OR, ADC, SBB, AND, SUB, XOR, CMP)
2	Group 2 instructions with set two-parameter format (ROL, ROR, RCL, RCR, SHL, SHR, SAL, SAR)
3	Group 3 instructions with set one-parameter format (NOT, NEG, MUL, IMUL, DIV, IDIV)
4	Group 4 instructions with set one-parameter format (INC, DEC)
5	Relative jumps with signed byte range (JMP SHORT, Jcc, JCXZ, LOOP, LOOPcc)
6	Branch instructions (CALL, JMP)
7	AAD and AAM
8	Two-parameter instructions with REG, R/M order (LDS, LEA, LES)
9	MOV
0Ah	Instruction prefixes (LOCK, REPcc)
0Bh	RET
0Ch	INT
0Dh	PUSH, POP
0Eh	ESC
0Fh	TEST
10h	XCHG
11h	IN
12h	OUT
13h	ORG directive (defaults to 100h)
14h	DB, DW, DD, DQ, DT directives
15h	Reserved words (BYTE, WORD, DWORD, OFFSET, REL, SHORT, NEAR, FAR), generates error 0Ch when read by the assembler where they do not belong.
16h	INCLUDE directive
17h	Illegal instruction handler (symbol definitions, instruction multipliers, actual illegal instructions)
18h	DS directive
19h	8087 instructions without parameters (F2XM1, FABS, FCHS, FDECSTP, FINCSTP, FLD1, FLDL2E, FLDL2T, FLDLG2, FLFLN2, FLDPI, FLDZ, FNOP, FPATAN, FPREM, FPTAN, FSCALE, FSQRT, FTST, FXAM, FXTRACT, FYL2X, FYL2XP1)
1Ah	8087 arithmetic instructions with optional parameters (FADDP, FDIVP, FDIVRP, FMULP, FSUBP, FSUBRP)
1Bh	8087 arithmetic instructions with a single memory parameter that must either be 16-bit or 32-bit (FIADD, FICOM, FICOMP, FIDIV, FIDIVR, FIMUL, FIST, FISUB, FISUBR)
1Ch	8087 arithmetic instructions with a single memory parameter of only one size per instruction (FBLD, FBSTP, FLDCW, FLDENV, FNSAVE, FNSTENV, FNSTCW, FNSTSW, FRSTOR)
1Dh	FCOMPP
1Eh	8087 instructions without parameters that have N-variants without an automatic FWAIT prefix (FCLEX, FDISI, FENI, FINIT, FNCLEX, FNDISI, FNENI, FNINIT)
1Fh	FST
20h	FFREE
21h	8087 instructions with a memory parameter that have an automatic FWAIT prefix (FSAVE, FSTCW, FSTENV, FSTSW)
22h	FCOM and FCOMP
23h	8087 arithmetics (FADD, FDIV, FDIVR, FMUL, FSUB, FSUBR)
24h	FILD and FISTP
25h	FLD and FSTP
26h	FISTTP
27h	FXCH

Note that some groups, including--most prominently, 1, 2, 3, 4, and 6, do not put any specific opcode in the opcode field of their I8086 entry.  In the mentioned cases, for instance, the opcode is the the necessary regfield extension for the Mod byte, and the actual instruction opcode is generated or calculated by the particular encoder.  In other cases, such as 14h, the opcode acts as a word-size adjustment.  For some, like 9, it's just a placeholder.

The 8087 opcode values, on the other hand, are 6-bit encodings: the 3 bits of the MODRM extension superimposed over the 3 bits of the ESC extension, and unpacked to full ESC sequences by the EXTEND procedure.  The BIN87 lookup table for the disassembler, however, does not use the same indices.  Instead, it takes a bite--nay, makes a byte out of the lower 3 bits of ESC and appends the upper 5 bits of the following byte.  This allows for 256 discrete encodings with minimal crowding.
