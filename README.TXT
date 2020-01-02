A72 is a 8086 assembler without bells, whistles, gongs, or macros.  It's a bare-bones assembler that will take standard Intel-format assembly and turn it into a COM file executable under MS-DOS.  I fully acknowledge that it is entirely obsolete and nigh useless in 2019.  I wrote it for my own sake because I wanted to write assembly without having to use a bunch of directives and extraneous garbage in order to even just start writing.  I wrote it in assembly because I'm not a programmer and assembly and machine code are the only kind of programming I understand.  In order to facilitate testing and working with machine code more closely, I had to write a disassembler as well, U72, which is included.

I broke many cardinal rules when writing the program.  It's uncommented and does not use descriptive symbols.  It's self-modifying spaghetti code.  This README file is brief explanation of some of its internal mechanics.  On the flip side, the code is more or less modular, but with little overhead.  Expanding it would be trivial.  I was working with it from a machine code perspective, so a lot of bit manipulation is involved, and every possible 8086 encoding for a given instruction is incorporated.  Its final test was assembling itself and its companion disassembler U72, equally bare-bones and without any extra features.  It passed the test.  The included binaries are its own output binaries.

1. Functions

AA, Adjust accumulator: if the value of the accumulator is negative and can be represented by AL alone, AH is cleared.
ASM, Assemble: assembles one line of code.  [PC] is updated according to [OUTPUT].  See ASMF below.
ASMF, Assemble file: assembles the default input file once.  If any assembly flags in [FLAGS] are set, [OUTPUT] is treated as a P-string and written/counted directly.  If no flags are set, [OUTPUT] is treated as a data structure and read record by record.  For format of records, refer to the G14H table.
CASE, Change case: if CF set, changes P-string at DS:[SI] to lowercase.  If CF is clear, changes it to uppercase.
CC, Combine characters: a tokeniser. Scans data from DS:[SI] and on and writes to ES:[DI] either P-strings of valid alphanumeric characters to be used as identifiers, or 1-character P-strings to be used as symbols, skipping all blanks and control codes excepting 00h or 0Dh.  Returns a 0-length string is unsuccessful.
CMDLIN, Command line: reads file specs from the command line.  If only infile is specified, outfile name is automatically generated.  Missing extensions are filled in with default extensions .ASM and .COM for input and output, respectively.  An extensionless file is specified with a lone period.
COMMA: checks if the next element on the line is a comma and generates an error if not.
DECIM, Decimal: converts the value of AX to decimal and just writes it straight to ES:[DI] (not as a P-string!)
FAIL: Aborts assembly of given line, writes error message (specified in AL) to console, and transfers control directly back to ASM by skipping back to its return value on the stack.
FSPEC, Filespec adjust: Checks file name and extension lengths of the filespec at DS:[SI] and truncates them to 8 and 3, respectively, if either is longer.  If no extension is specified, a default extension is added from a 4-byte literal (period included) pointed to by DX.
G0 thru G17H, Assembly groups: instruction encoders, including assembler directives, indexed by the table at [IHDL]. Instructions are grouped according to the way they read operands and the way those operands are encoded and written.
GN, Get next: reads the next token in a data sequence pointed to by [NEXT].  Usually [NEXT] will be set to whatever's in SI when the input is initialised.
HALX, Hex AL to AX: converts byte value in AL to full hex string in AX, ready to STOSW.
HEX, Hexadecimal: converts the value of AX to hexadecimal and just writes the digits straight to ES:[DI].
ISLTR, Is AL a letter: checks value of AL and clears the carry flag if it counts as a letter.  Sets carry flag if not.
ISNUM, Is AL a numeric digit: checks value of AL and clears the carry flag if it's a decimal digit.  Sets carry flag if not.
MAIN: Main program.  Reads command line, displays main status messages, handles file open/close operations, and calls both passes of assembly.  If any errors are encountered during pass 1, pass 2 isn't executed and an output file isn't created or modified.
MMODRM: Make Mod-Reg-R/M byte: constructs a Mod byte based on [ARGS] and the displacement specification in [FLAGS].  Sets Mod byte flag (in [FLAGS]).  Refer to [ARGS] and [FLAGS] specifications for detail.
RA, Read argument: reads one full argument of an instruction, detecting its exact nature, type, and size, and sets all three levels of [ARGS] accordingly, as well as displacement/immediate/segment prefix flags (in [FLAGS]) as applicable.  As above, see [ARGS] and [FLAGS] specifications for details.
RL, Read line: reads one full line of code from the default input file, up to and including the CR.  LF is ignored by the parser, along with other control codes.
SA, Symbol add: adds symbol at DS:[SI] to a lexicon specified at ES:[DI].  Sets carry flag and does not add if there is already a symbol with the same name.  Otherwise, clears carry flag.
SL, Symbol lookup: looks symbol at DS:[SI] in a lexicon specified at ES:[DI].  Sets carry flag is unsuccessful.  Otherwise, clears carry flag and returns symbol value in AX, and the pointer to said value in the symbol's entry in the lexicon in DI.
VAL, Value of string: reads a number P-string and translates it to a value in AX. It scans for a sigil at the end of a number, B for binary or H for hex, as per convention.  If a numeric character is the final character, it's assumed to be decimal.
WA, Word adjust: reads [ARGS+2], detects dominant instruction argument size, and sets [WADJ] accordingly for use by instruction encoders.
WR, Write: writes resulting binary code and data to the default output file.  See OUTPUT.

2. Buffers, indexes, and variables

ARGS, Arguments: instruction arguments, see [ARGS] entry among the tables further down.
CACHE, Cache buffer: used to hold temporary data.  It is normally A) a copy of a string that was scanned but recognised as an instruction, in which case context is read to determine if it's meant as a label; or B) an index of offsets to a formatted table of data records read from DB/DW and stored in OUTPUT.
DISP, Displacement: displacement value read as part of a R/M-type argument, stored as a 16-bit value.
ELEMENT: used to hold the P-strings read as tokens by GN through CC.
ERRM, Error messages: index of error message offsets to be addressed with AL during FAIL.
ERRS, Errors: amount of errors encountered during one assembly pass.
FLAGS: See [FLAGS] entry in tables below.
FUNC, Function: specifies the function.  If [FUNC] is zero, any symbols encountered will be ignored, none will be saved to [SYMBS], and symbol references will return [PC].  Nothing is written to an output file.  If [FUNC] is 1 (pass one), all symbol definitions encountered will be saved to [SYMBS] and symbol references will return [PC].  Nothing will be written to output file.  If [FUNC] is 2 (pass two), symbols will not be saved to [SYMBS], but symbol references will be read from [SYMBS].  If there is output, it is written to the output file.
I8086, 8086 instructions: List of all valid 8086 instructions in SL-readable lexicon format (see [SYMBS] in tables).  Every entry has a P-string for the instruction, followed by one byte containing the expected or default opcode, and another byte denoting the instruction's group.  The group number is used with IHDL as an index to the appropriate encoder subfunction.
IHDL: Instruction handlers: index of instruction encoders according to group.  See I8086 above.
IMM, Immediate: immediate value detected as argument, stored as a 16-bit value.
INCLEV, Include level: a stack of file handles used when the INCLUDE directive is invoked.  If a file is opened, the current input file's handle is put on the INCLEV stack, and a new handle is set as the default input handle until the included file is closed, at which point the stack counts down and any previous input file handle is returned.  This allows for multiple include levels, limited only by the buffer size.  Then again, only psychopaths would have more than three or four include levels, although A72 allows for at least 15 by virtue of the buffer's size.  It can be increased in the most banal manner to allow for more.
INFILE, Input file: handle of default input file to read lines of assembly from.  May change through INCLUDE directives.  See [INCLEV] entry above.
INPUT, Input buffer: used to hold a line of code that is read from a file and assembled.
LN, Line: current line read from the input file and/or assembled.
MODRM: Mod byte generated by MMODRM and/or altered by instruction encoders.
NEXT: points to the next token the data sequence currently being scanned for tokens.
OP, Operator: temporary arithmetic operator storage used during RA to read if anything is added to or subtracted from displacements or immediates.
OPCODE: the default/expected opcode for a given scanned valid instruction.
OUTFILE, Output file: handle of default output file to write assembled binary code or data to.
OUTPUT, Output buffer: used to hold the assembled binary code as a P-string, or a set of data records indexed by [CACHE].  See G14H table specification further down.
PC, Program counter: current write address in assembled binary.
PREFIX: Instruction prefix opcode held for use.
REGS: All valid registers, including segment registers, in R/M order, stored as one big string literal addressable with R/M and WADJ.
RM: Valid R/M field register combinations.  See [RM] entry in tables below.
RSIZE, Repeat size: amount of times to write the current binary string to the output file.  Default is one.
SEGPREF: Segment override prefix opcode held for use.
STK, Stack: holds the stack as it is before any function is called from ASM.  Used by FAIL to ensure safe returns to ASM after errors.
SYMBS, Symbols: 8KB buffer to hold the symbols used.  The first word is the amount of entries in the buffer, followed by the entries sequentially, with no index.  Each entry has a P-string (length byte for the symbol, followed by its name string) and two data bytes (address word or the opcode-group combo used in I8086) and are therefore read through one by one in order to either find a particular one or just get to the end.
USIZE, Undefined size: amount of undefined bytes left over after everything is written.  They are not written to the file if they are the last thing to be written, otherwise they are written as zeroes.
VORG, Value of origin: current origin, 100h by default; added to [PC] during symbol scanning, and set by the ORG directive.
WADJ, Word adjustment: used by instruction encoders to detect and encode 16-bit operands or instructions.  Instruction encoders to which [WADJ] is critical rely on WA to read [ARGS+2] and set [WADJ] accordingly for use as a word flag.  It's set to 1 to specify 16-bit size; otherwise it's 0.  Otherwise, [WADJ] is used internally in RA to transmit any detected argument size.  It would likely have been a saner practice to split this use of [WADJ] into a separate variable, but since the two functions were entirely parallel, I saw fit to use and reuse it liberally.

3. Data formats

3.1. ARGS is three bytes holding the specification of the arguments read by RA.  The first argument's specifications is in the lower nibbles of the ARGS bytes; the second argument is in the upper nibbles if present--otherwise, those are 0.

3.1.1. [ARGS+0], argument type
1	Register
2	R/M
3	Segment register
4	Immediate value

3.1.2. [ARGS+1], types of register if [ARGS] is 1:
0	AL/AX
1	CL/CX
2	DL/DX
3	BL/BX
4	AH/SP
5	CH/BP
6	DH/SI
7	BH/DI

3.1.3. [ARGS+1], types of R/M if [ARGS] is 2:
0	[BX+SI]
1	[BX+DI]
2	[BP+SI]
3	[BP+DI]
4	[SI]
5	[DI]
6	[BP]
7	[BX]
0Eh	[imm16]

3.1.4. [ARGS+1], types of segment register if [ARGS] is 3:
0	ES
1	CS
2	SS
3	DS

3.1.5. [ARGS+1], types of immediate value if [ARGS] is 4:
0	regular
1	offset
2	relative
3	[PC] (dollar sign)
4	string literal

3.1.6. [ARGS+2], argument sizes
0	unset/flexible
1	byte
2	word

3.2. FLAGS is the binary output flags.  Each bit corresponds to a part of the instruction.  When a valid instruction or directive is scanned, the opcode flag is set automatically.  In the case of directives, the opcode flag is manually unset by the handler invoked.  Other flags are set by relevant subfunctions; e.g. RA is responsible for setting the displacement, immediate, and segment prefix flags.  MMODRM sets the Mod flag.
80h	Prefix instruction
40h	Segment prefix
20h	Opcode
10h	Mod byte
8	Displacement
4	16-bit extension for displacement
2	Immediate value
1	16-bit extension for immediate

3.3. G14H, the encoder for DB/DW instructions, uses a special output record format.  The binary output for writing is stored in [OUTPUT] with an index of pointers stored in [CACHE].

3.3.1. [OUTPUT] record format
1 byte	type of data in record (see 3.3.2.)
2 bytes	amount of elements
X bytes	value(s) of elements

For duplicated bytes, the value field will be one byte long; for words, correspondingly, 2 bytes.  Single repeating entries of the same type will be grouped together.  Undefined entries (denoted by the question mark) will be assigned the value zero in case they are to be written to a file.  If the entry is a sequence of different bytes, such as a string literal, the value field will hold the entire string.  There is no type checking in G14H.  All string literals are treated as sequences of bytes, and all offsets are treated as word-sized entries.  Everything else depends on whether DB or DW was used.  The "opcode" values of DB (00h) and DW (01h) are used to calculate sizes, whether in CL for left shifts, or as word-size extensions for what would otherwise be bytes.  As such, a DD, DQ, and DP could feasibly be implemented with the corresponding opcodes 02h, 03h, and 04h, respectively, to accomodate for the shifts, but this would create problems with the simple increments.
Feasibly all size manipulations could be replaced with shifts.  I was not taking those three directives into consideration originally since there is little use for them on the 8086 except for 8087 code, which this assembler does not support.  That is another extension that could be made reasonably trivially, if with some tedium: but I have yet to find a comprehensive listing of 8087 instructions and opcodes which does not involve me having to sift through every possible ModR/M combination used and check back and forth with a reference to determine which instructions belong on the 8087 and which had come with later developments in the x87 line.  The 8087 was of no use to me, anyway, and was therefore neglected for the time being.

3.3.2. [OUTPUT] record data types
0	defined byte(s)
1	defined word(s)
2	undefined byte(s)
3	undefined word(s)
4	duplicate defined bytes
5	duplicate defined words
6	duplicate undefined bytes
7	duplicate undefined words

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
0Ah	Instruction prefixes (LOCK, REP, REPN)
0Bh	RET
0Ch	INT
0Dh	PUSH
0Eh	POP
0Fh	TEST
10h	XCHG
11h	IN
12h	OUT
13h	ORG directive
14h	DB/DW directives
15h	EQU directive
16h	INCLUDE directive
17h	Illegal instruction handler (symbol definitions, instruction multipliers, actual illegal instructions)

Note that some groups, including--most prominently, 1, 2, 3, 4, and 6, do not put any specific opcode in the opcode field of their I8086 entry.  In the mentioned cases, for instance, the opcode is the the necessary regfield extension for the Mod byte, and the actual instruction opcode is generated or calculated by the particular encoder.  In other cases, such as 14h, the opcode acts as a word-size adjustment.  For some, like 9, it's just a placeholder.
