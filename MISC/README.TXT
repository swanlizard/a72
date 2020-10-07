BBBR	Read BL x BH pixels from (CX, AL) into buffer at [DI]
BBBW	Draw BL x BH pixels at (CX, AL) from buffer at [SI]
BMCP	Compress BL x BH bytewise bitmap at [SI] into packed bitmap at [DI]
BMHF	Horizontal flip BL x BH bitmap at [DI]
BMSL	Draw BL x BH pixels at (CX, AL) from buffer at [SI], AH clear colour
BMVF	Vertical flip BL x BH bitmap at [DI]
BMXP	Expand BL x BH packed bitmal at [SI] into bytewise bitmap at [SI]
CASE	Change case of P-string at [DI] according to CF
CRLF	Write CR&LF to console
DBIT	Double up bits of AL expanding into AX
DOSR	Read a C-string from console to [DI], including CRLF
DOSW	Write a C-string to console from [SI]
FRLT	Read P-string of text from file to [DI], up until and including CRLF
FWLT	Write P-string of text from [SI] to file
HALX	Convert value in AL into hex digits in AX
HAXL	Convert hex digits in AX to value in AL
PACL	Parse command line in [SI] to token sequence at [DI]
PXLR	Read pixel at (CX, AL)
PXLW	Write pixel at (CX, AL) with colour AH
RAND	Get random AX-maxed value into AX
SBIN	Convert value in AX to binary numeral P-string at [DI]
SC2P	Convert C-string at [SI] to P-string
SDCM	Convert value in AX to decimal numeral P-string at [DI]
SHEX	Convert value in AX to hex numeral P-string at [DI]
SP2C	Convert P-string at [SI] to C-string
STAP	Append P-string at [SI] to P-string at [DI]
STCP	Compare P-strings at [SI] and [DI] and return mismatch position
STDP	Copy P-string from [SI] to [DI]
STIS	Insert P-string at [SI] into P-string at [DI] at position AX
STKS	Continued scanning of P-string at [SI] for P-string at [DI] if CF=0
STOP	Write P-string to console
STRM	Remove CX characters at position AX in P-string at [SI]
STRV	Reverse P-string at [SI]
STSC	Scan for P-string at [SI] in P-string at [DI]
STVA	Convert numeral P-string at [SI] to value according to sigil
TBAL	Point out symbol in table at [DI] by value in AX
TBAP	Append symbol in [SI] to table at [DI] with value AX
TBNL	Point to symbol number DX in table at [DI]
TBRM	Remove symbol number DX from table at [DI]
TBSL	Get value of symbol in [SI] in table at [DI]
TKAP	Append token in [SI] to sequence at [DI]
TKCC	Read token from C-string at [SI] into P-string at [DI]
TKRM	Remove token number AX from sequence [SI]
TKSC	Find number of token [DI] in sequence [SI]
TKSN	Select token number AX in sequence [SI]
TNDX	Index table in [DI] in array in [SI]
TRIM	Trim P-string at [SI] to token P-string sequence at [DI]
VRET	Wait for vertical retrace
