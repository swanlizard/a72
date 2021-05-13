CHANGES FROM 1.02 RELEASE

- Lexical analyser uses new CC ("Count Characters") instead of TRIM.  CC skips all delimiters and returns the position of the first valid token in SI, its length in BX, and its first character in AL.
- Collapsed instruction handlers 20 and 26.
- Faster RD that now uses the whole buffer instead of reading one line at a time.
- Completely rewrote RA and RE and split them up some more for a less confusing control flow and more reuse of modular code.  As a side effect it ended up being more compact.
- Added some more error messages so the errors would be a little bit less obtuse.
- Rewrote VAL to use one unified decoder rather than three different ones.  It uses a MUL but the cycle penalty is much less serious than the old RD was.
- Rewrote WDA to use one unified encoder.  Like above, except with DIV.
- Added EVEN, EQU, and END directives.
- Support for single elements of uninitialised data (stuff like DB ?, DW ?, etc).
- Generally tightened up the code a tad more.
- Added two more example programs: a textmode tetris clone and a Base64 transcoder.
- Fixed bugs in BMSD, BBBW, BBBR.  Now we have proper CGA bitmap graphics.
- No longer freaks out when unable to include a file.
