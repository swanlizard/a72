# VERSION 1.05 UPDATE NOTES

I got delayed by COVID (vax did protect me some but I still took a hit; this new variant is a doozy) but we're back on track.

- More modular construction; in particular, the CPU-specific assembler module is exchangeable.
- Displacements no longer care if size and segment overrides are inside brackets.  As long as addresses/labels are within the brackets, it's a valid memory access.  Long live Ideal Mode!
- `HIGH`, `LOW`, `INCBIN`, `ECHO`, `TITLE`, `PAGE` directives added.
- Undocumented instructions (i.e. `SALC` and `AAM 16`) are no longer used in the code, just in case someone runs A72 on a V20 or similar. I've heard of those new-fangled XT laptops being peddled on Ebay these days.
- Disassembled jumps will now show absolute addresses rather than `$+X` type nonsense.  I don't know what possessed me to show them as `$+X` rather than absolute addresses.
- Lines can be 255 characters long (previously 120-something) and generate an error otherwise.  Line length can be extended by altering buffer length, the `MAXLEN` equate at the start.  Count on one byte always being a CR.
- File names (potentially with paths) should not be longer than 63 characters.  The buffer sizes can be changed, of course, but A72 is meant for limited, cramped environments.
- LF now recognised as valid line terminator alongside CR, because Oonicks is presumably a common place to find DOS emulation.  (CAVEAT: ONLY WHEN READING FILES.  The line reader will put a CR at the end of the line because only CR will terminate CC)

## BUG FIXES (granted, some of the bugs were caused by the rewrite):
- `RAD` not clearing CL properly, resulting in operand processing flags influencing output opcode flags, creating phantom null segment prefixes
- `RAD` not checking the displacement value, meaning negative displacements were always 16 bits (connected to the above)
- `GV` blanking the lower two bits of CL past the appropriate label, resulting in overzealous erasure of symbol and program counter references (part of the high/low byte reader)
- `DB`/`DW`/`DD` not advancing program counter because SOMEONE decided to clear CX indiscriminately on all directives (oops)
- freeze at overly long lines
- getting mad when not encountering `PTR` after size overrides (it was meant to be skipped automatically like `OFFSET`...)
- numeric constant 0D0H (in that exact spelling) was read as the `BYTE` directive thanks to idiot checksum and caused errors (was I high?!  I don't know what on earth possessed me to have SL put together a DARNED CHECKSUM rather than just set a flag; checksum of "0D0H" XOR "BYTE" returned 0, so it thought, hey, whee, `BYTE` directive)
- `INCLUDE` directive advanced program counter by the length of the source code line (BX, you traitor!!)
- `LBL1` not skipping to data field on redefining a symbol
- `GV` setting sign bit on symbol length rather than first character, causing bogus lengths and crashes/freezes
- `ECHO` directive not working (because yours truly forgot to preserve DI)
- error code 5 returning bogus byte count (because yours truly forgot to preserve DX)

## NOT FIXES BUT THINGS TO NOTE:
- Due to the way the rewritten RA handles size/distance override directives, short branches now ignore all overrides
- Internal reg,reg order is reversed (for consistency with operand handling)
- `WA` is cursed.  Rewriting it repeatedly yields the same result.  Do not meddle with it at all.  Don't look in its general direction.
- If assembly AND listing are desired, the `/A` and `/L` switches must both be used.  `A72/Lfile` will generate only a listing, so you'll need `A72/A/Lfile` or `A72/L/Afile` to generate both listing and output.
- On that note, the first mention of a file name on the command line will be taken as the default file name.  Switches expect output file names, and if no input file name is given, it will be assumed as name-of-output-file-but-with-.ASM-extension.  Any file name following a switch will be that switch's output file name.  Any file name outside of a switch will be taken as the input file.
- Major sections of the program have been entirely rewritten; such as the OS interface routines, the inevitable `RA`, and the `G6` instruction handler (yes, again.  It was a horrible mess.)  I have tried to make the control flow less (overtly) idiotic overall, but spaghetti prevails still.  I think I've succeeded in some parts.  Again, the dreaded `G6` comes to mind.

## INTERNAL OPERATION REMINDER
A72 uses several sets of signal values for internal processing and for interfacing with the system/user/programmer.  There's also a set of internal conventions for data transfer between the subroutines.

The most important convention is string transfer, which takes place via BX and SI.  SI holds the string address and BX holds the length, as per the `CC` convention.

### [FUNC]
is a set of flags that control the overall assembler operation.  The bits are set so:
|Bit|Function|
|---|---|
|1|scan, store, read symbols, generate error on duplicate symbols (pass 1)|
|2|allow symbol redefinition, generate error on missing symbols instead (pass 2)|
|4|(reserved)|
|8|(reserved)|
|$10|(used by OS interface) generate binary|
|$20|(unused)|
|$40|(used by OS interface) generate listing|
|$80|invoke disassembler|

### [ARGS]
is encoded by RA as it processes the instruction operands.  The parameters are stored as nybbles, with the destination operand parameters being the low nybbles of each layer and the source operand parameters as the corresponding high nybbles.

Examples:
|Operands|[ARGS]|[ARGS+1]|[ARGS+2]|[ARGS+3]
|----|----|----|----|----|
|DS,DX|$12|$23|$22|$00|
|FAR [BX]|$03|$07|$00|$0A[^1]|
|BP|$01|$05|$02|$00|
|AL,3|$41|$00|$01|$00|
|NEAR BENZINO|$04|$02|$02|$09|
|[BX+DI],CH|$13|$51|$10|$00|
|BL,LOW NAPALONI|$41|$03[^2]|$11|$00|
|21H|$04|$00|$00|$00|
|BYTE [BX+SI],AL|$13|$00|$11[^3]|$00|
[^1]: Distance override is used, so [ARG+3] is used
[^2]: Using the LOW override negates the symbol subtype
[^3]: Using the BYTE override makes the memory reference size explicit and so its size parameter is set.

The following is all the values used internally by A72.  Any values not explicitly noted or reserved are to be considered unused.

|[ARGS]|operand type|
|---|---|
|0|no operand|
|1|register|
|2|segment register|
|3|memory reference|
|4|immediate|
|5|(reserved)|
|6|(reserved)|
|7|(reserved)|

Operand subtype when `[ARGS]`=1 and `[ARGS+2]`=1
|[ARGS+1]|register|
|---|---|
|0|AL|
|1|CL|
|2|DL|
|3|BL|
|4|AH|
|5|CH|
|6|DH|
|7|BH|

Operand subtype when `[ARGS]`=1 and `[ARGS+2]`=2
|[ARGS+1]|register|
|---|---|
|0|AX|
|1|CX|
|2|DX|
|3|BX|
|4|SP|
|5|BP|
|6|SI|
|7|DI|

Operand subtype when `[ARGS]`=2
|[ARGS+1]|segment register|
|---|---|
|0|ES|
|1|CS|
|2|SS|
|3|DX|
|4|(reserved)|
|5|(reserved)|
|6|(reserved)|
|7|(reserved)|

Operand subtype when `[ARGS]`=3
|[ARGS+1]|displacement| 
|---|---|
|0|[BX+SI]|
|1|[BX+DI]|
|2|[BP+SI]|
|3|[BP+DI]|
|4|[SI]|
|5|[DI]|
|6|[BP]|
|7|[BX]|
|$0E|[addr16]|

Operand subtype when `[ARGS]`=4
|[ARGS+1]|immediate|
|---|---|
|0|normal immediate|
|1|current PC|
|2|symbol reference|
|3|(reserved)|

|[ARGS+2]|operand size|
|---|---|
|0|not specified|
|1|byte|
|2|word|
|3|dword|
|4|(reserved)|
|5|(reserved)|
|6|(reserved)|
|7|(reserved)|

|[ARGS+3]|operand distance|
|---|---|
|0|not specified|
|8|short|
|9|near|
|$0A|far|

### [FLAGS]
is set as the line is processed and signals what is written to the binary output when the assembly of one line concludes.  The bits signal the following elements:
|Bit|Function|
|---|---|
|1|high byte of 16-bit immediate|
|2|8-bit immediate or low byte of 16-bit immediate|
|4|high byte of 16-bit displacement|
|8|8-bit displacement or low byte of 16-bit displacement|
|$10|modifier byte|
|$20|opcode|
|$40|segment prefix|
|$80|(reserved)|

### CL
is used for processing flags during the internal operation of `RE`/`GV`, in connection with decoding numeric constants and resolving symbols.  These flags are not referenced anywhere outside `RE` or `GV`:
|Bit|Function|
|---|---|
|1|current PC used|
|2|symbol reference used|
|4|low byte override|
|8|high byte override|
|$10|full word override|
|$20|(unused)|
|$40|value resolved|
|$80|negate value|

### Error codes
are defined solely by appending a new zero-terminated error message to the existing list.  It can then be generated by setting AL to its index number and branching to `FAIL`, as per usual protocol.

Some error codes, specifically ones with the sign bit set, are used to signal certain assembly directives, because `FAIL` is an instant way to transfer control from the assembler to the interface, without intervening nonsense processing.  It resets the stack to the main caller (usually `ASM`) so don't bother with `POP`s.  They have a special handler and are not treated as errors.

The default error codes are:
|Error code|Blunder|
|---|---|
|$00|Invalid operand, not allowed by operation|
|$01|Syntax error, a badly constructed operand sequence|
|$02|Wrong addressing mode, bogus displacement|
|$03|Unrecognised instruction mnemonic, caused by a label not marked as such (with a colon or a valid instruction right after)|
|$04|Undefined symbol, a label is referenced that is not recorded|
|$05|Relative jump out of range; DX holds the number of bytes out of range|
|$06|Operand size mismatch, caused by `WA` detecting two different-sized operands with known sizes or explicit size overrides|
|$07|Numeric constant too large for its intended use|
|$08|Missing operand: an operand or character was expected and not detected|
|$09|Garbage past end of line--all operands have been processed but there's still stuff on the line that's not commented away|
|$0A|Duplicate symbol, or attempt at symbol redefinition without bit 2 of `[FUNC]` set|
|$0B|Error accessing file (generated by OS interface), for files specified by `INCLUDE` or `INCBIN` directives as well as some internal processing|
|$0C|Reserved word misuse.  There was an attempt to use a reserved word as a label.|
|$0D|Invalid register, generated only during memory operand processing where the only valid registers are BP, BX, SI, and DI.|
|$0E|Line too long (generated by OS interface)|
|$0F|File I/O error (generated by OS interface), similar to 0B but used by the OS interface to refer to the main input file, to bypass parts of `SCREAM`|
|$FA|`PAGE` directive.|
|$FB|`TITLE` directive.  [SI](BX) points to a string, enclosed in quotes, to use as a page subtitle in listings.|
|$FC|`ECHO` directive.  The assembler constructs an output string in `[TEMP]` with the elements it reads.  At the end DI points to the end of the string and the interface takes over and sends it to `PRUNT`.|
|$FD|`INCBIN` directive.  [SI](BX) points to the file name.  The OS interface then takes over and handles the file directly.|
|$FE|`INCLUDE` directive.  Same principle as above, but the file is sent into the input file queue.|
|$FF|`END` directive.  The OS interface will immediately cease reading the current topmost input file and close it.|
