# A72
A minimal symbolic assembler for MS-DOS 2.0 compatible systems.

## Features (and limitations) at a glance

### Yes!

- Nested *INCLUDE*s&mdash;as in, an *INCLUDE*d file can *INCLUDE* other files which in turn can *INCLUDE* other files...etc.  How deep it goes is determined only by the size of the buffer.[^1]
- Covers every possible 8086 ~~and 8087~~[^3] instruction encoding, including undocumented instructions.
- Doesn't give a hoot about code formatting/spacing.
- Supports undefined data and the basic directives *EVEN*, *EQU[^2], *END*, and *ORG*.
- Accepts binary, quaternary, octal, hexadecimal, and decimal numeric constants.  ~~Quaternary is in there[^4] because it was a debug thing that got left in.  It takes up all of 2 lines (4 bytes) of extra code, oh no.~~ not anymore it isn't
- Built-in VERY basic disassembler.
- Basic listing functionality.

[^1]: Every layer requires 64 bytes.  YOU DO THE MATH!!  The amount of *INCLUDE*s **per** layer is limited only by your disk space.

[^2]: Caveat: due to how *EQU*s are handled, if they reference any named offsets (i.e. symbols), such *EQU*s **must** be either A) **before** all code in which they are used, or B) **after** the symbols they reference.  To make *EQU*s fully forward- and backward-referencing would require instituting two (2) runs of pass 1 for a total of three (3) passes.  It is trivial to alter the code to do this but I felt it wasted too much time.  In any event, this is a non-issue unless you have an inordinate fondness for spaghetti.
[^3]: 8087 not supported after 1.04 until I have figured out how to work with floating point numerics and encoding.
[^4]: Beware the Q sigil.  Only use O for octals.

### No!

- No macros.
- Segments schmegments!
- No OBJ files, relocations, segment trickery, external symbol definitions, basically anything that is remotely useful to the modern programmer who is into linking and modularity.  And bloat.
- No algebra.  It'll do the basic +/- arithmetic, but no fancy infix stuff or other operators.
- No MASM/Intel-style displacement voodoo with consigning displacement registers to separate sets of brackets (e.g. *[BP][DI]*) or appending brackets to variables BASIC-style to pretend play arrays (e.g. *BYTE PTR BENZINO[BX+54]*) or even weirder stuff like *40H[SI]*.  *RA* could potentially be spruced up to handle things like this but I deemed it hideous and bailed.  Displacements entirely go inside brackets, like *WORD PTR [NAPALONI+BP+SI-0BEEFH]*.[^5]  I figured this is assembly, not bloody BASIC.
- Numbers may be 16 bits at most.  *DD*/*DQ*/*DT* will reserve the proper amount of bytes, and any 16-bit value will be sign-extended to be stored, but there's no higher math beyond this.  I chose to leave it at that because in practice, 16-bit assembly at its lowest level uses, well, only 16 bits.  If anything, *ADC DX,0* and *SBB DX,0* are your friends.
- On a similar note, no floating point numeric constant handling/display.  This is for the simple reason that I have absolutely 0 concept of how that would even work.  I'm bad at math.  I bring you instruction encodings, not Einsteinian theorems.  There's probably someone out there more savvy than I who could implement it without breaking a sweat.  I would not just be breaking a sweat; I'd be breaking every single braincell in the process.

[^5]: Segment prefixes and size overrides may be put either inside or outside the brackets&mdash;or even on separate lines.

### Disclaimer

- You use this program and its accompanying examples and utilities entirely at your own risk.  I may not be held responsible for damage caused to your system through improper use of this program.
- This program is provided as is, with no warranties express or implied, and no development schedule.  It is updated at my leisure and at my whim.
- I am not responsible for physical accidents, deaths, and other disasters caused by improper use of the program.
