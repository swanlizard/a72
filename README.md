# A72
A minimal symbolic assembler for MS-DOS 2.0 compatible systems.

## Features (and limitations) at a glance

### Yes!

- Nested *INCLUDE*s&mdash;as in, an *INCLUDE*d file can *INCLUDE* other files which in turn can *INCLUDE* other files...etc.  Goes 15 levels deep&dagger; at present.  If you are a psycho who needs more levels than that, it is as trivial as editing one (1) value to increase the *[INCLEV]* buffer size.
- Covers every possible 8086 and 8087 instruction encoding, including undocumented instructions.
- Doesn't give a hoot about code formatting/spacing.
- Supports undefined data and the basic directives *EVEN*, *EQU*&ddagger;, *END*, and *ORG*.
- Accepts binary, quaternary, octal, hexadecimal, and decimal numeric constants.  Quaternary is in there because it was a debug thing that got left in.  It takes up all of 2 lines (4 bytes) of extra code, oh no.
- Disassembler (built in).

> &dagger; That is you can have 15 layers of files including other files.  The amount of *INCLUDE*s **per** layer is limited only by your disk space.

> &ddagger; Caveat: due to how *EQU*s are handled, if they reference any named offsets (i.e. symbols), such *EQU*s **must** be either A) **before** all code in which they are used, or B) **after** the symbols they reference.  To make *EQU*s fully forward- and backward-referencing would require instituting two (2) runs of pass 1 for a total of three (3) passes.  It is trivial to alter the code to do this but I felt it wasted too much time.  In any event, this is a non-issue unless you have an inordinate fondness for spaghetti.

### No!

- No macros.
- Segments schmegments!
- No OBJ files, relocations, segment trickery, external symbol definitions, basically anything that is remotely useful to the modern programmer who is into linking and modularity.  And bloat.
- No algebra.  It'll do the basic +/- arithmetic, but no fancy infix stuff or other operators.
- No MASM/Intel-style displacement voodoo with consigning displacement registers to separate sets of brackets (e.g. *[BP][DI]*) or appending brackets to variables BASIC-style to pretend play arrays (e.g. *BYTE PTR BENZINO[BX+54]*) or even weirder stuff like *40H[SI]*.  *RA* could potentially be spruced up to handle things like this but I deemed it hideous and bailed.  Displacements entirely go inside brackets, like *WORD PTR [NAPALONI+BP+SI-0BEEFH]*.  I figured this is assembly, not bloody BASIC.
- Numbers may be 16 bits at most.  *DD*/*DQ*/*DT* will reserve the proper amount of bytes, and any 16-bit value will be sign-extended to be stored, but there's no higher math beyond this.  I chose to leave it at that because in practice, 16-bit assembly at its lowest level uses, well, only 16 bits.  If anything, *ADC DX,0* and *SBB DX,0* are your friends.
- On a similar note, no floating point numeric constant handling/display.  This is for the simple reason that I have absolutely 0 concept of how that would even work.  I'm bad at math.  I bring you instruction encodings, not Einsteinian theorems.  There's probably someone out there more savvy than I who could implement it without breaking a sweat.  I would not just be breaking a sweat; I'd be breaking every single braincell in the process.
