Version 1.01

Changes from 1.0:
- Merged U72 into the main A72 program, since they have a lot of shared code between them, and doing so was trivial.  The disassembler is automatically invoked if a .COM file is specified as an input file.
- No longer freezes on labels that are on their own lines.
- Supports the ESC instruction.
- All data size manipulations are now shift-based.
- Reserved words are now scanned for during the instruction scan and generate an error if left alone on a line.
- CACHE is no longer used as the OUTPUT index.  In fact, CACHE no longer even exists.  Instead, INDEX serves the index purpose while TEMP is for temporary strings.
- Included files now have their own line counters, so errors can be tracked within them easier.
- A rudimentary EVEN directive has been added, which pads the code with a NOP if a given instruction or data block has an odd length.
- Certain sections of code were rewritten to remove branching and replace with bit manipulation to increase speed and reliability.
- Both output code and data blocks are now treated as OUTPUT records to avoid doing two separate scans for writing output to a file or calculating its size for [PC].
- Restructured code to be more modular so it can be more easily expanded in the future.
- Default extensions no longer have their own string, and are instead read from the command line syntax message.
- Input files are no longer read character by character, so assembly time is significantly reduced on slower systems.
- LABEL directive was added for the sole purpose of being ignored.

A72 is a 8086 assembler without bells, whistles, gongs, or macros.  It's a bare-bones assembler that will take standard Intel-format assembly and turn it into a COM file executable under MS-DOS.  I fully acknowledge that it is entirely obsolete and nigh useless in 2019.  I wrote it for my own sake because I wanted to write assembly without having to use a bunch of directives and extraneous garbage in order to even just start writing.  I wrote it in assembly because I'm not a programmer and assembly and machine code are the only kind of programming I understand.  In order to facilitate testing and working with machine code more closely, I had to write a disassembler as well, U72, which has since been built into A72 itself.

I broke many cardinal rules when writing the program.  It's uncommented and does not use descriptive symbols.  It's self-modifying spaghetti code.  This README file is brief explanation of some of its internal mechanics.  On the flip side, the code is more or less modular, but with little overhead.  Expanding it would be trivial.  I was working with it from a machine code perspective, so a lot of bit manipulation is involved, and every possible 8086 encoding for a given instruction is incorporated.  Its final test was assembling itself.  It passed the test.  The included binary is its own output binary.

A72 doesn't care about spacing.  A line is automatically cut off at the comment semicolon or a carriage return, whichever is first.  Numeric constants may only be passed as integers, in either hexadecimal, binary, or decimal.  Valid characters for identifiers are all digits, all letters, period, underscore, and @.  An identifier may not start on a numeric lest it be interpreted as a value.  Everything else is parsed as a symbol.  A72 is not case-sensitive, and uses syntax based on Ideal Mode syntax, but with some key differences:

- Addressing always uses brackets.  Anything enclosed in brackets is a pointer.  Anything without brackets is an offset or an immediate.
	MOV	AX,[VAR]		; puts contents of VAR into AX
	MOV	AX,VAR		; puts offset to VAR into AX
	MOV	BX,[0DEADH]	; puts word value at address 0DEADH into BX
	MOV	BX,0DEADH	; puts value 0DEADH into BX

- Array referencing and addressing takes place entirely within displacement brackets along with base and index registers:
	MOV	AX,[BX+VAR]	; good
	MOV	DX,[SI+VAR+BX]	; good
	MOV	SI,VAR[BX]	; bad; tries to load offset of VAR into SI and generates "Characters past end" error due to "[BX]"
	MOV	CL,[4+DI-VAR]	; good
	MOV	DI,[BP-SI]		; bad; can't use minus with displacement registers
	MOV	[BP][DI],CL	; bad; generates "Syntax error" error because "[DI]" is where a comma is expected

- Data types of memory locations are never checked, so WORD PTR/BYTE PTR are used solely for displacement operands with immediate sources:
	MOV	[BP],AX		; good; data size implied by AX being a 16-bit register
	MOV	BYTE PTR [SI],4	; good
	MOV	[VAR],4		; misguided; will assemble, but requires type size to be specified, since it defaults to byte
	MOV	[VAR],0F00H	; bad; generates "Constant too large" error since default data type is byte
	MOV	WORD PTR [VAR],5	; good

- Boilerplate code isn't required (and is barely even supported because there's no CODESEG/DATASEG/MODEL directives)
- Segment overrides can be written on separate lines, just like in the old MS-DOS DEBUG.EXE.
- Explicit-operand forms of the string instructions are not supported, but if a segment prefix must be specified, this can be done as the above.
- SALC is supported.
- An instruction may be prefixed with a number, which will cause it to be repeated that amount of times.
- REL keyword may be used to obtain relative offsets (from the current instruction) of symbols.
- A72 does not support duplicating strings by DUP or nesting DUPs within one another.  Yet.

1. Functions

AA, Adjust accumulator: tests if accumulator fits inside a single byte and generate error 7 if not.
ASM, Assemble: assembles one line of code.  [PC] is updated according to [OUTPUT].  See ASMF below.
ASMF, Assemble file: assembles the default input file once.
BORW, Byte or word: scans for BYTE PTR/WORD PTR/DWORD PTR sequence and sets [WADJ] accordingly.
BSS, Build string without spaces: reads one block of characters from a line of text, delimited by spaces.  Included solely to read file names from the command line, since CC broke them up into symbols if anything non-alphanumeric (but still valid for file specs) was included in the file spec.
CASE, Change case: if CF set, changes P-string at DS:[SI] to uppercase.  If CF is clear, changes it to lowercase.
CC, Combine characters: a tokeniser. Scans data from DS:[SI] and on and writes to ES:[DI] either P-strings of valid alphanumeric characters to be used as identifiers, or 1-character P-strings to be used as symbols, skipping all blanks and control codes excepting 00h or 0Dh.  Returns a 0-length string is unsuccessful.
CMDLIN, Command line: reads file specs from the command line.  If only infile is specified, outfile name is automatically generated.  Missing extensions are filled in with default extensions .ASM and .COM for input and output, respectively.  An extensionless file is specified with a lone period.
COMMA: checks if the next element on the line is a comma and generates an error if not.
DECIM, Decimal: converts the value of AX to decimal and just writes it straight to ES:[DI] (not as a P-string!)
DISASM, Disassemble: disassembles one line of code.  [PC] is updated according to scan.  See DISF below.
DISF, Disassemble file: disassembles the default input file once.  Scan is conducted according to the detected instruction.  [PC] is updated by the amount of characters scanned.
ENDL: End line: inserts end of line and comment with address and opcodes into disassembly output.
FAIL: Aborts assembly of given line, writes error message (specified in AL) to console, and transfers control directly back to ASM by skipping back to its return value on the stack.
FSPEC, Filespec adjust: Checks file name and extension lengths of the filespec at DS:[SI] and truncates them to 8 and 3, respectively, if either is longer.  If no extension is specified, a default extension is added from a 4-byte literal (period included) pointed to by DX.
G0 thru G1AH, Assembly groups: instruction encoders, including assembler directives, indexed by the table at [IHDL]. Instructions are grouped according to the way they read operands and the way those operands are encoded and written.
GN, Get next: reads the next token in a data sequence pointed to by [NEXT].  Usually [NEXT] will be set to whatever's in SI when the input is initialised.
GRP, Group: prepare opcode extension for scan in group lookup table.
HALX, Hex AL to AX: converts byte value in AL to full hex string in AX, ready to STOSW.
HEX, Hexadecimal: converts the value of AX to hexadecimal and just writes the digits straight to ES:[DI].
ISLTR, Is AL a letter: checks value of AL and clears the carry flag if it counts as a letter.  Sets carry flag if not.
ISNUM, Is AL a numeric digit: checks value of AL and clears the carry flag if it's a decimal digit.  Sets carry flag if not.
MAIN: Main program.  Reads command line, displays main status messages, handles file open/close operations, and calls both passes of assembly.  If any errors are encountered during pass 1, pass 2 isn't executed and an output file isn't created or modified.
MMODRM: Make Mod-Reg-R/M byte: constructs a Mod byte based on [ARGS] and the displacement specification in [FLAGS].  Sets Mod byte flag (in [FLAGS]).  Refer to [ARGS] and [FLAGS] specifications for detail.
NORF, Near or far: scans for NEAR/FAR/SHORT sequence and sets AL to the length of the given word detected.
RA, Read argument: reads one full argument of an instruction, detecting its exact nature, type, and size, and sets all three levels of [ARGS] accordingly, as well as displacement/immediate/segment prefix flags (in [FLAGS]) as applicable.  As above, see [ARGS] and [FLAGS] specifications for details.
RBIN, Read binary: reads a block of bytes from a binary input file.
RE, Read element: reads an argument that is either an offset, a symbol, or a numeric constant, returning the result as an immediate along with its nature.  See [ARGS] format.
RL, Read line: reads one full line of code from the default input file, up to and including the CR.  LF is ignored by the parser, along with other control codes.
RQ, Read quote: scans for a string literal used as an operand, and checks if it's valid to use as input.
SA, Symbol add: adds symbol at DS:[SI] to a lexicon specified at ES:[DI].  Sets carry flag and does not add if there is already a symbol with the same name.  Otherwise, clears carry flag.
SL, Symbol lookup: looks symbol at DS:[SI] in a lexicon specified at ES:[DI].  Sets carry flag is unsuccessful.  Otherwise, clears carry flag and returns symbol value in AX, and the pointer to said value in the symbol's entry in the lexicon in DI.
TGN, Test get next: reads the next token in data sequence pointed to by [NEXT] without updating [NEXT].  Used for checking ahead.
VAL, Value of string: reads a number P-string and translates it to a value in AX. It scans for a sigil at the end of a number, B for binary or H for hex, as per convention.  If a numeric character is the final character, it's assumed to be decimal.
WA, Word adjust: reads [ARGS+2], detects dominant instruction argument size, and sets [WADJ] accordingly for use by instruction encoders.
WARG, Write argument: updates all three levels of [ARGS] at the end of RA.  See [ARGS] tables.
WDISP, Write displacement: decodes mod byte and writes the decoded R/M field to the output disassembly.
WFN, Write file name: writes a file name to the console.
WHAL/WHALS, Write hex AL/signed: writes the value of AL as a hex string to the output disassembly.
WHAX/WHAXS, Write hex AX/signed: writes the value of AX as a hex string to the output disassembly.
WPTR, Write PTR sequence: writes the BYTE/WORD PTR sequence to the output disassembly according to [WADJ].
WR, Write: writes resulting binary code and data from [OUTPUT], indexed by [INDEX] to the default output file if the relevant [FUNC] flag is set.  See [FUNC] flags format.  For format of [OUTPUT] records, refer to the G14H table and [OUTPUT].
WRASM, Write assembly: writes disassembled code to output file.
WREG, Write register: writes register from register field to disassembly.
WSPR, Write segment prefix: writes cached segment prefix to disassembly.

In addition, all of the functions ending on D are disassembly groups.  The handlers used depend not on the instruction but on the way its trailing bytes are encoded and stored.

2. Buffers, indexes, and variables

_DISP, Displacement table: lookup table for offsets to pertinent registers in [REGS] from start of [REGS], for use in WDISP
_G01D thru _G04D, Group disassembly: lookup tables to mnemonics for group instruction opcodes.
_GRP, Blank group: zeroes to signal to the disassembler that it shouldn't write a mnemonic until further notice.
ARGS, Arguments: instruction arguments, see [ARGS] entry among the tables further down.
BIN86, Binary 8086 opcodes: a 256-entry table with offsets to mnemonics and handler routines for each 8086 opcode.
COUNT, File counter: position inside input file.
DISP, Displacement: displacement value read as part of a R/M-type argument, stored as a 16-bit value.
ELEMENT: used to hold the P-strings read as tokens by GN through CC.
ERRM, Error messages: index of error message offsets to be addressed with AL during FAIL.
ERRS, Errors: amount of errors encountered during one assembly pass.
FLAGS: See [FLAGS] entry in tables below.
FUNC, Function: specifies the function.  See [FUNC] format in tables ahead.
I8086, 8086 instructions: List of all valid 8086 instructions in SL-readable lexicon format (see [SYMBS] in tables).  Every entry has a P-string for the instruction, followed by one byte containing the expected or default opcode, and another byte denoting the instruction's group.  The group number is used with IHDL as an index to the appropriate encoder subfunction.
IHDL: Instruction handlers: index of instruction encoders according to group.  See I8086 above.
IMM, Immediate: immediate value detected as argument, stored as a 16-bit value.
INCLEV, Include level: a stack of file handles used when the INCLUDE directive is invoked.  If a file is opened, the current input file's handle is put on the INCLEV stack, and a new handle is set as the default input handle until the included file is closed, at which point the stack counts down and any previous input file handle is returned.  This allows for multiple include levels, limited only by the buffer size.  Then again, only psychopaths would have more than three or four include levels, although A72 allows for at least 15 by virtue of the buffer's size.  It can be increased in the most banal manner to allow for more.
INDEX, Output index: an index of offsets to a formatted table of data records read from DB/DW and stored in OUTPUT.
INFILE, Input file: handle of default input file to read lines of assembly from.  May change through INCLUDE directives.  See [INCLEV] entry above.
INFN, Input file name, in ASCIIZ string form.
INPUT, Input buffer: used to hold a line of code that is read from a file and assembled.
LN, Line: current line read from the input file and/or assembled.
MODRM: Mod byte generated by MMODRM and/or altered by instruction encoders.
NEXT: points to the next token the data sequence currently being scanned for tokens.
OP, Operator: temporary arithmetic operator storage used during RA to read if anything is added to or subtracted from displacements or immediates.
OPCODE: the default/expected opcode for a given scanned valid instruction.
OUTFILE, Output file: handle of default output file to write assembled binary code or data to.
OUTFN, Output file name, as an ASCIIZ string.
OUTPUT, Output buffer: used to hold the assembled binary code as a P-string, or a set of data records indexed by [CACHE].  See G14H table specification further down.
PC, Program counter: current write address in assembled binary.
PREFIX: Instruction prefix opcode held for use.
REGS: All valid registers, including segment registers, in R/M order, stored as one big string literal addressable with R/M and WADJ.
RM: Valid R/M field register combinations.  See [RM] entry in tables below.
RSIZE, Repeat size: amount of times to write the current binary string to the output file.  Default is one.
SEGPREF: Segment override prefix opcode held for use.
STK, Stack: holds the stack as it is before any function is called from ASM.  Used by FAIL to ensure safe returns to ASM after errors.
SYMBS, Symbols: 8KB buffer to hold the symbols used.  The first word is the amount of entries in the buffer, followed by the entries sequentially, with no index.  Each entry has a P-string (length byte for the symbol, followed by its name string) and two data bytes (address word or the opcode-group combo used in I8086) and are therefore read through one by one in order to either find a particular one or just get to the end.
TEMP, Temp buffer: used to hold temporary data.
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
3	dword

3.2. FLAGS is the binary output flags.  Each bit corresponds to a part of the instruction.  When a valid instruction or directive is scanned, the opcode flag is set automatically.  In the case of directives, the opcode flag is manually unset by the handler invoked.  Other flags are set by relevant subfunctions; e.g. RA is responsible for setting the displacement, immediate, and segment prefix flags.  MMODRM sets the Mod flag.
80h	Prefix instruction
40h	Segment prefix
20h	Opcode
10h	Mod byte
8	Displacement
4	16-bit extension for displacement
2	Immediate value
1	16-bit extension for immediate

3.3. G14H, the encoder for DB/DW instructions, uses a special output record format.  The binary output for writing is stored in [OUTPUT] with an index of pointers to each entry stored in [INDEX].  The first word of [INDEX] is the amount of entries indexed.

3.3.1. [OUTPUT] record format
byte	element type
word	dup amount
byte	amount of discrete elements
X bytes	values of elements

For duplicated bytes, the value field will be one byte long; for words, correspondingly, 2 bytes.  Single repeating entries of the same type will be grouped together.  Undefined entries (denoted by the question mark) will be assigned the value zero in case they are to be written to a file.  The entry may be considered a P-string: there is no type checking in G14H and all string literals are treated as sequences of bytes, while all offsets are treated as word-sized entries.  Everything else depends on whether DB, DW, or DD was used.  The "opcode" values of DB (00h), DW (01h), and DD (02h) are used to calculate sizes, using CL for left shifts.  As such, a DQ and DP can easily be implemented with the corresponding opcodes 03h, and 04h, respectively.  In the same vein, the keywords QUAD/QWORD and PARA could be implemented with opcodes 4 and 5, respectively.  I have implemented neither because the 8086 has no instructions that require handling data types of that size.  It barely even comprehends the power of DD, which is implemented for the sake of CWD-able things and far jumps that use DWORD PTR.

3.3.2. [OUTPUT] record data types
The upper nibble defines the data arrangement:
80h	record set
40h	defined value (0=undefined value, "?" mark)

The lower nibble defines the stored data size:
0	byte
1	word
2	dword

3.4. FUNC is the assembler function flags.  Each bit corresponds to a subfunction the assembler has to concurrently perform.
80h	even directive in effect
40h	(reserved for future use)
20h	(reserved for future use)
10h	1=assemble 0=disassemble
8	write symbols
4	read symbols
2	write to file
1	read from file

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
0Dh	PUSH
0Eh	POP
0Fh	TEST
10h	XCHG
11h	IN
12h	OUT
13h	ORG directive (defaults to 100h)
14h	DB/DW directives
15h	EQU directive
16h	INCLUDE directive
17h	Illegal instruction handler (symbol definitions, instruction multipliers, actual illegal instructions)
18h	ESC
19h	Reserved words (BYTE, WORD, DWORD, OFFSET, REL, SHORT, NEAR, FAR)
1Ah	EVEN directive
1Bh	LABEL directive

Note that some groups, including--most prominently, 1, 2, 3, 4, and 6, do not put any specific opcode in the opcode field of their I8086 entry.  In the mentioned cases, for instance, the opcode is the the necessary regfield extension for the Mod byte, and the actual instruction opcode is generated or calculated by the particular encoder.  In other cases, such as 14h, the opcode acts as a word-size adjustment.  For some, like 9, it's just a placeholder.
