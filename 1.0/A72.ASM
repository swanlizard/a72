	org	100h
main:	mov	ah,9
	mov	dx,offset amsg
	int	21h
	call	cmdlin
	jnc	ginf
	mov	ah,9
	mov	dx,offset usage
	int	21h
	ret
ginf:	mov	word ptr [symbs],0
	mov	ah,9
	mov	dx,offset asmm1
	int	21h
	mov	di,offset infn+0Ch
	mov	cx,0Ch
	xor	al,al
	std
	repnz	scasb
	cld
	inc	cx
	mov	si,offset infn
	mov	di,offset asmm2
	rep	movsb
	mov	ah,9
	mov	dx,offset asmm2
	int	21h
	mov	ax,3D00h
	mov	dx,offset infn
	int	21h
	jnc	infok
	jmp	mierr
infok:	mov	[infile],ax
	mov	byte ptr [func],1
	call	asmf
	or	word ptr [errs],0
	jz	nierr
	jmp	errnum
nierr:	mov	ax,4200h
	xor	cx,cx
	xor	dx,dx
	mov	bx,[infile]
	int	21h
	mov	ah,9
	mov	dx,offset asmm3
	int	21h
	mov	di,offset outfn+0Ch
	mov	cx,0Ch
	xor	al,al
	std
	repnz	scasb
	cld
	inc	cx
	mov	si,offset outfn
	mov	di,offset asmm2
	rep	movsb
	mov	ah,9
	mov	dx,offset asmm2
	int	21h
	mov	ah,3Ch
	xor	cx,cx
	mov	dx,offset outfn
	int	21h
	jnc	outfok
	jmp	short moerr
outfok:	mov	[outfile],ax
	mov	byte ptr [func],2
	call	asmf
	or	word ptr [errs],0
	jz	noerr
	jmp	short errnum
noerr:	mov	ah,3Eh
	mov	bx,[infile]
	int	21h
	mov	ah,3Eh
	mov	bx,[outfile]
	int	21h
	mov	ah,9
	mov	dx,offset done
	int	21h
	ret
mioerr:	mov	ah,3Eh
	mov	bx,[outfile]
	int	21h
moerr:	mov	ah,3Eh
	mov	bx,[infile]
	int	21h
mierr:	mov	ah,9
	mov	dx,offset emB
	int	21h
	mov	ah,9
	mov	dx,offset done+4
	int	21h
	ret
errnum:	mov	ah,3Eh
	mov	bx,[infile]
	int	21h
	mov	ah,9
	mov	dx,offset errf
	int	21h
	mov	ax,[errs]
	mov	di,offset errn
	call	decim
	mov	ah,9
	mov	dx,offset errn
	int	21h
	ret
cmdlin:	cld
	mov	si,80h
	lodsb
	xor	ah,ah
	add	si,ax
	mov	[si],ah
	mov	si,81h
	mov	di,offset element
	call	cc
	mov	bx,si
	mov	si,offset element
	mov	dx,offset specs
	call	fspec
	jc	cmdl0
	clc
	call	case
	mov	di,offset infn
	xor	ah,ah
	lodsb
	mov	cx,ax
	rep	movsb
	mov	[di],ah
	mov	si,bx
	mov	di,offset element
	call	cc
	mov	bx,si
	mov	si,offset element
	mov	dx,offset specs+4
	call	fspec
	jc	cmdl1
	clc
	call	case
	mov	di,offset outfn
	xor	ah,ah
	lodsb
	mov	cx,ax
	rep	movsb
	mov	[di],ah
	clc
	ret
cmdl1:	mov	si,offset infn
	mov	di,offset outfn
	mov	cx,0Dh
	rep	movsb
	mov	di,offset outfn
	mov	al,2Eh
	mov	cx,9
	repnz	scasb
	dec	di
	mov	si,offset specs+4
	movsw
	movsw
	mov	byte ptr [di],0
	clc
	ret
cmdl0:	stc
	ret
specs	db	".ASM.COM"
infn	db	0Dh dup(20h)
outfn	db	0Dh dup(20h)
fspec:	push	si
	mov	cl,[si]
	xor	ch,ch
	jcxz	fsp0
	inc	si
	mov	di,si
	mov	al,2Eh
	cld
	repnz	scasb
	jnz	fspun
	inc	cx
	cmp	cx,4
	jna	fsp3
	mov	cx,4
fsp3:	dec	di
	mov	ax,di
	sub	ax,si
	cmp	ax,8
	jna	fsp8
	push	si
	mov	si,di
	sub	ax,8
	sub	di,ax
	rep	movsb
	pop	si
fsp8:	add	di,cx
	mov	byte ptr [di],0
	mov	ax,di
	sub	ax,si
	mov	[si-1],al
	pop	si
	clc
	ret
fspun:	mov	ax,di
	sub	ax,si
	cmp	ax,8
	jna	fspun8
	sub	ax,8
	sub	di,ax
fspun8:	push	si
	mov	si,dx
	movsw
	movsw
	pop	si
	mov	byte ptr [di],0
	mov	ax,di
	sub	ax,si
	mov	[si-1],al
	pop	si
	clc
	ret
fsp0:	pop	si
	stc
	ret
case:	push	ax
	push	cx
	push	si
	pushf
	lodsb
	xor	ah,ah
	mov	cx,ax
	popf
	jc	lcase
ucase:	lodsb
	cmp	al,61h
	jc	ucnl
	cmp	al,7Ah
	ja	ucnl
	and	al,0DFh
	mov	[si-1],al
ucnl:	loop	ucase
	pop	si
	pop	cx
	pop	ax
	ret
lcase:	lodsb
	cmp	al,41h
	jc	lcnl
	cmp	al,5Ah
	ja	lcnl
	or	al,20h
	mov	[si-1],al
lcnl:	loop	lcase
	pop	si
	pop	cx
	pop	ax
	ret
rl:	cld
	mov	di,offset input
rll:	push	di
	mov	ah,3Fh
	mov	cx,1
	mov	dx,di
	mov	bx,[infile]
	int	21h
	pop	di
	jc	rlx
	or	ax,ax
	jz	rnl
	inc	di
	cmp	di,offset input+78h
	jnc	rnl
	cmp	byte ptr [di-1],0Dh
	jz	rnl
	jmp	short rll
rnl:	inc	word ptr [ln]
	mov	byte ptr [di],0
	mov	ax,di
	sub	ax,offset input
	clc
	ret
rlx:	xor	ax,ax
	stc
	ret
wr:	or	byte ptr [flags],0
	jnz	wrbin
	or	word ptr [cache],0
	jnz	wrout
	clc
	ret
wrbin:	or	word ptr [usize],0
	jz	wrbinl
wrul:	mov	ah,40h
	mov	cx,1
	mov	dx,offset usize
	mov	bx,[outfile]
	int	21h
	dec	word ptr [usize]
	jnz	wrul
wrbinl:	mov	ah,40h
	xor	ch,ch
	mov	cl,[output]
	mov	dx,offset output+1
	mov	bx,[outfile]
	int	21h
	dec	word ptr [rsize]
	jnz	wrbinl
	clc
	ret
wrout:	mov	cx,word ptr [cache]
	mov	si,offset cache+2
wroutl:	lodsw
	mov	bp,ax
	push	si
	mov	si,ax
	lodsb
	test	al,2
	jnz	wrou
	test	al,4
	jnz	wrod
	lodsw
	push	cx
	mov	cl,[bp]
	and	cl,1
	shl	ax,cl
	mov	cx,ax
	mov	ah,40h
	mov	dx,si
	mov	bx,[outfile]
	int	21h
	pop	cx
	jmp	short wle
wrou:	lodsw
	push	cx
	mov	cl,[bp]
	and	cl,1
	shl	ax,cl
	pop	cx
	add	[usize],ax
	jmp	short wle
wrod:	lodsw
	push	cx
	mov	cx,ax
wrodl:	push	cx
	mov	ah,40h
	mov	cl,[bp]
	and	cx,1
	inc	cx
	mov	dx,si
	mov	bx,[outfile]
	int	21h
	pop	cx
	loop	wrodl
	pop	cx
wle:	pop	si
	loop	wroutl
	clc
	ret
asmf:	mov	word ptr [usize],0
	mov	word ptr [inclev],0
	mov	word ptr [errs],0
	mov	word ptr [pc],0
	mov	word ptr [ln],0
asmfl:	call	rl
	or	ax,ax
	jz	asmf0
	mov	si,offset input
	call	asm
	cmp	byte ptr [func],2
	jz	asmfw
	mov	word ptr [usize],0
	jmp	short asmfl
asmfw:	call	wr
	jmp	short asmfl
asmf0:	or	word ptr [inclev],0
	jz	asmfx
	mov	ah,3Eh
	mov	bx,[infile]
	int	21h
	mov	di,word ptr [inclev]
	shl	di,1
	add	di,offset inclev
	mov	ax,[di]
	mov	[infile],ax
	dec	word ptr [inclev]
	jmp	short asmfl
asmfx:	ret
cc:	cld
	push	ax
	push	dx
	push	di
	inc	di
	mov	dx,di
ccl:	mov	al,[si]
	cmp	al,22h
	jz	cquo
	cmp	al,27h
	jz	cquo
	cmp	al,2Eh
	jz	cltr
	cmp	al,3Bh
	jz	cc0
	cmp	al,40h
	jz	cltr
	cmp	al,5Fh
	jz	cltr
	cmp	al,21h
	jc	cskip
	cmp	al,2Fh
	jna	csym
	cmp	al,30h
	jc	cskip
	cmp	al,39h
	jna	cltr
	cmp	al,3Ah
	jc	cskip
	cmp	al,3Fh
	jna	csym
	cmp	al,41h
	jc	cskip
	cmp	al,5Ah
	jna	cltru
	cmp	al,5Bh
	jc	cskip
	cmp	al,60h
	jna	csym
	cmp	al,61h
	jc	cskip
	cmp	al,7Ah
	jna	cltr
	cmp	al,7Bh
	jc	cskip
	cmp	al,7Fh
	jna	csym
cskip:	or	al,al
	jz	cc0
	cmp	al,0Dh
	jz	cc0
	cmp	di,dx
	jnz	cc0
	inc	si
	jmp	short ccl
cltru:	or	al,20h
cltr:	stosb
	inc	si
	jmp	short ccl
cquo:	movsb
	mov	al,[si]
	or	al,al
	jz	cc0
	cmp	al,0Dh
	jz	cc0
	cmp	al,22h
	jz	cc1
	cmp	al,27h
	jz	cc1
	jmp	short cquo
csym:	cmp	di,dx
	jnz	cc0
cc1:	movsb
cc0:	mov	ax,di
	pop	di
	sub	ax,dx
	pop	dx
	mov	[di],al
	pop	ax
	ret
sl:	mov	cx,[di]
	jcxz	sl0
	cld
	xor	ax,ax
sll:	add	di,ax
	add	di,2
	push	di
	mov	al,[di]
	inc	al
	push	cx
	mov	cx,ax
	push	si
	rep	cmpsb
	pop	si
	pop	cx
	pop	di
	jz	sl1
	loop	sll
sl0:	stc
	ret
sl1:	add	di,ax
	mov	ax,[di]
	clc
	ret
sa:	push	ax
	push	di
	call	sl
	pop	di
	pop	ax
	jc	sa1
	stc
	ret
sa1:	xor	dh,dh
	mov	cx,[di]
	inc	word ptr [di]
	jcxz	sa0
sa2:	add	di,2
	mov	dl,[di]
	add	di,dx
	inc	di
	loop	sa2
sa0:	add	di,2
	mov	cl,[si]
	xor	ch,ch
	inc	cx
	cld
	rep	movsb
	stosw
	clc
	ret
val:	xor	ah,ah
	lodsb
	cmp	al,1
	ja	val1
	lodsb
	sub	al,30h
	ret
val1:	dec	si
	push	si
	add	si,ax
	lodsb
	pop	si
	call	isnum
	jnc	decn
	cmp	al,68h
	jz	hexn
	cmp	al,62h
	jz	binn
	xor	ax,ax
	ret
binn:	jmp	short val2
decn:	jmp	short val10
hexn:	jmp	short val16
val2:	cld
	push	cx
	push	dx
	lodsb
	xor	ah,ah
	xor	dx,dx
	mov	cx,ax
val2l:	lodsb
	cmp	al,31h
	ja	val2x
	sub	al,30h
	shl	dx,1
	or	dl,al
	loop	val2l
val2x:	mov	ax,dx
	pop	dx
	pop	cx
	ret
val10:	push	cx
	push	dx
	push	bx
	xor	ch,ch
	mov	cl,[si]
	xor	ax,ax
val10l:	mov	bx,0Ah
	mul	bx
	inc	si
	mov	bl,[si]
	sub	bl,30h
	add	ax,bx
	loop	val10l
	pop	bx
	pop	dx
	pop	cx
	ret
val16:	push	cx
	push	dx
	push	si
	xor	dx,dx
	xor	ch,ch
	mov	cl,[si]
	inc	si
	cld
val16l:	lodsb
	cmp	al,30h
	jc	vend
	cmp	al,39h
	jna	vnum
	cmp	al,61h
	jc	vend
	cmp	al,66h
	ja	vend
	sub	al,27h
vnum:	sub	al,30h
	shl	dx,1
	shl	dx,1
	shl	dx,1
	shl	dx,1
	or	dl,al
	loop	val16l
vend:	pop	si
	mov	ax,dx
	pop	dx
	pop	cx
	ret
decim:	push	ax
	push	dx
	push	bx
	mov	bx,0Ah
	add	di,5
	cmp	ax,2710h
	jnc	decim1
	dec	di
	cmp	ax,3E8h
	jnc	decim1
	dec	di
	cmp	ax,64h
	jnc	decim1
	dec	di
	cmp	ax,0Ah
	jnc	decim1
	dec	di
decim1:	push	di
	dec	di
decim2:	xor	dx,dx
	div	bx
	add	dl,30h
	mov	[di],dl
	dec	di
	or	ax,ax
	jnz	decim2
	pop	di
	pop	bx
	pop	dx
	pop	ax
	ret
halx:	mov	ah,al
	and	al,0Fh
	cmp	al,9
	jna	halx1
	add	al,7
halx1:	add	al,30h
	xchg	ah,al
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	cmp	al,9
	jna	halx2
	add	al,7
halx2:	add	al,30h
	ret
hex:	cld
	push	ax
	cmp	ax,9
	ja	hex9
	add	al,30h
	stosb
	pop	ax
	ret
hex9:	cmp	ah,0A0h
	jc	hex16
	mov	byte ptr [di],30h
	inc	di
hex16:	or	ah,ah
	jz	hex8
	push	ax
	mov	al,ah
	call	halx
	stosw
	pop	ax
hex8:	call	halx
	stosw
	mov	al,68h
	stosb
	pop	ax
	ret
isnum:	cmp	al,30h
	jc	isnum0
	cmp	al,39h
	ja	isnum0
	clc
	ret
isnum0:	stc
	ret
isltr:	cmp	al,2Eh
	jz	isltr1
	cmp	al,40h
	jc	isltr0
	cmp	al,5Ah
	jna	isltr1
	cmp	al,5Fh
	jz	isltr1
	cmp	al,61h
	jc	isltr0
	cmp	al,7Ah
	jna	isltr1
isltr0:	stc
	ret
isltr1:	clc
	ret
fail:	cld
	mov	sp,[stk]
	xor	ah,ah
	shl	ax,1
	add	ax,offset errm
	mov	di,ax
	mov	ah,9
	mov	dx,[di]
	int	21h
	mov	ah,9
	mov	dx,offset onlm
	int	21h
	mov	di,offset element
	mov	ax,[ln]
	call	decim
	mov	ax,0A0Dh
	stosw
	mov	al,24h
	stosb
	mov	ah,9
	mov	dx,offset element
	int	21h
	inc	word ptr [errs]
	mov	word ptr [cache],0
	mov	byte ptr [output],0
	ret
asm:	mov	word ptr [cache],0
	mov	word ptr [output],0
	mov	word ptr [rsize],1
	mov	[next],si
	mov	[stk],sp
	xor	ax,ax
	mov	di,offset flags
	mov	cx,7
	cld
	rep	stosw
asml:	call	gn
	jnc	asm1
	ret
asm1:	mov	di,offset i8086
	call	sl
	jnc	isgood
	mov	ah,17h
isgood:	mov	[opcode],al
	or	byte ptr [flags],20h
	xor	al,al
	xchg	al,ah
	shl	ax,1
	add	ax,offset ihdl
	push	si
	mov	si,ax
	lodsw
	pop	si
	call	ax
	call	gn
	jnc	asmx
	or	byte ptr [flags],0
	jnz	write
	or	word ptr [cache],0
	jnz	dar
	ret
asmx:	mov	al,9
	jmp	fail
write:	mov	di,offset output+1
	mov	si,offset prefix
	lodsb
	test	byte ptr [flags],80h
	jz	wnpref
	stosb
wnpref:	lodsb
	test	byte ptr [flags],40h
	jz	wnsprf
	stosb
wnsprf:	lodsb
	test	byte ptr [flags],20h
	jz	wnopc
	stosb
wnopc:	lodsb
	test	byte ptr [flags],10h
	jz	wnmrm
	stosb
wnmrm:	lodsw
	test	byte ptr [flags],8
	jz	wndisp
	test	byte ptr [flags],4
	jz	wdisp8
	stosb
	mov	al,ah
wdisp8:	stosb
wndisp:	lodsw
	test	byte ptr [flags],2
	jz	wnimm
	test	byte ptr [flags],1
	jz	wimm8
	stosb
	mov	al,ah
wimm8:	stosb
wnimm:	mov	ax,di
	sub	ax,offset output+1
	mov	[output],al
	mul	word ptr [rsize]
	add	[pc],ax
	ret
dar:	mov	cx,word ptr [cache]
	mov	si,cx
	shl	si,1
	add	si,offset cache
	std
darl:	lodsw
	mov	bx,ax
	test	byte ptr [bx],2
	jz	dard
	dec	cx
	jnz	darl
	jmp	short wrd
dard:	mov	si,offset cache+2
	cld
ddl:	lodsw
	mov	bx,ax
	and	byte ptr [bx],0FDh
	loop	ddl
wrd:	mov	si,offset output
	xor	ch,ch
	cld
wrdat:	lodsb
	or	al,al
	jnz	wrsing
	ret
wrsing:	mov	cl,al
	and	cl,1
	and	al,7
	test	al,4
	jnz	wrdup
	test	al,2
	jnz	wrdup
	lodsw
	shl	ax,cl
	add	[pc],ax
	add	si,ax
	jmp	short wrdat
wrdup:	lodsw
	shl	ax,cl
	add	[pc],ax
	add	si,cx
	inc	si
	jmp	short wrdat
ra:	mov	byte ptr [wadj],0
	mov	byte ptr [op],0
	call	gn
	jnc	ra1
	mov	al,8
	jmp	fail
ra1:	xor	dx,dx
	mov	ax,[si]
	cmp	ax,6204h
	jz	rbys
	cmp	ax,7704h
	jz	rwos
	cmp	ax,5B01h
	jz	rdisp
	cmp	ah,22h
	jz	rquos
	cmp	ah,27h
	jz	rquos
	cmp	ax,2401h
	jz	rcurrs
	cmp	ax,2D01h
	jz	rmis
	xchg	al,ah
	call	isnum
	jnc	rimms
	cmp	ah,2
	jz	rregs
	call	isltr
	jnc	rlbs
	mov	al,1
	jmp	fail
rbys:	jmp	rby
rwos:	jmp	rwo
rquos:	jmp	rquo
rcurrs:	jmp	rcurr
rmis:	jmp	rminus
rimms:	jmp	rimm
rregs:	jmp	rreg
rlbs:	jmp	rlb
rdisp:	call	gn
	mov	ax,[si+1]
	cmp	byte ptr [si],2
	jnz	rdelse
	mov	dl,1
	cmp	ax,6973h
	jz	sid
	cmp	ax,6964h
	jz	did
	cmp	ax,7062h
	jz	bpd
	cmp	ax,7862h
	jz	bxd
rdelse:	cmp	word ptr [si],2D01h
	jz	rdmins
	call	isnum
	jnc	rdimmd
	call	isltr
	jnc	lbd
	mov	al,1
	jmp	fail
sid:	shl	dl,1
did:	shl	dl,1
bpd:	shl	dl,1
bxd:	test	dh,dl
	jnz	rdfail
	or	dh,dl
	test	byte ptr [op],2
	jz	rdpm
rdfail:	mov	al,2
	jmp	fail
rdpm:	call	gn
	mov	ax,[si]
	cmp	ax,2D01h
	jz	rdpmm
	cmp	ax,2B01h
	jz	rdpmp
	cmp	ax,5D01h
	jz	rde
	mov	al,1
	jmp	fail
rdpmm:	or	byte ptr [op],2
	jmp	short rdisp
rdpmp:	and	byte ptr [op],0FDh
	jmp	short rdisp
rde:	mov	al,dh
	mov	bx,offset rm
	xlatb
	test	al,0F0h
	jz	rdeok
	mov	al,2
	jmp	fail
rdeok:	mov	dh,al
	mov	dl,2
	jmp	warg
rdmins:	jmp	short rdminu
rdimmd:	call	val
rdtpm:	or	byte ptr [flags],8
	test	byte ptr [op],2
	jz	dispdp
	sub	[disp],ax
	jmp	short rdpm
dispdp:	add	[disp],ax
	jmp	short rdpm
lbd:	call	gl
	jc	lbdf
	or	byte ptr [flags],4
	jmp	short rdtpm
lbdf:	mov	al,4
	jmp	fail
rdminu:	call	gl
	mov	al,[si+1]
	call	isnum
	jnc	rdmin1
	mov	al,1
	jmp	fail
rdmin1:	call	val
	neg	ax
	jmp	short rdtpm
rreg:	mov	ax,[si+1]
	mov	cx,14h
	mov	di,offset regs+26h
	std
	repnz	scasw
	jnz	rlbs1
	xor	dl,dl
	mov	dh,cl
	and	dh,7
	or	byte ptr [wadj],1
	cmp	cl,8
	jc	rgpr
	shl	byte ptr [wadj],1
	cmp	cl,10h
	jc	rgpr
	push	word ptr [next]
	call	gn
	pop	word ptr [next]
	cmp	word ptr [si],3A01h
	jnz	rsr
rsp:	shl	dh,1
	shl	dh,1
	shl	dh,1
	add	dh,26h
	mov	[segpref],dh
	or	byte ptr [flags],40h
	call	gn
	call	gn
	cmp	word ptr [si],5B01h
	jz	rdisps
	mov	al,1
	jmp	fail
rlbs1:	jmp	rlb
rdisps:	xor	dx,dx
	jmp	rdisp
rsr:	or	dl,2
rgpr:	or	dl,1
warg:	test	byte ptr [args],0Fh
	jz	warg1
	shl	byte ptr [wadj],1
	shl	byte ptr [wadj],1
	shl	byte ptr [wadj],1
	shl	byte ptr [wadj],1
	shl	dx,1
	shl	dx,1
	shl	dx,1
	shl	dx,1
warg1:	or	word ptr [args],dx
	mov	al,[wadj]
	or	[args+2],al
	mov	ax,[imm]
	call	aa
	or	ah,ah
	jz	rre1
	or	byte ptr [flags],1
rre1:	mov	ax,[disp]
	call	aa
	or	ah,ah
	jz	rre2
	or	byte ptr [flags],4
rre2:	ret
rby:	cmp	word ptr [si+2],7479h
	jnz	rbw0
	cmp	byte ptr [si+4],65h
	jnz	rbw0
	or	byte ptr [wadj],1
	jmp	short rptr
rwo:	cmp	word ptr [si+2],726Fh
	jnz	rbw0
	cmp	byte ptr [si+4],64h
	jnz	rbw0
	or	byte ptr [wadj],2
rptr:	call	gn
	cmp	word ptr [si],7003h
	jnz	rbwp
	cmp	word ptr [si+2],7274h
	jnz	rbwp
	call	gn
rbwp:	mov	ax,[si]
	cmp	al,2
	jz	rregp
	cmp	ax,5B01h
	jnz	srf
	xor	dx,dx
	jmp	rdisp
rbw0:	jmp	rlb
rregp:	mov	ax,[si+1]
	mov	cx,4
	push	di
	mov	di,offset regs+26h
	std
	repnz	scasw
	pop	di
	jnz	srf
	mov	dh,cl
	call	gn
	cmp	word ptr [si],3A01h
	jz	rsps
srf:	mov	al,2
	jmp	fail
rsps:	jmp	rsp
rimm:	call	val
	or	dl,dl
	jnz	riax
	mov	dx,4
riax:	or	byte ptr [flags],2
	test	byte ptr [op],1
	jz	rimp
	sub	[imm],ax
	jmp	short ripm
rimp:	add	[imm],ax
ripm:	mov	bx,[next]
	call	gn
	mov	ax,[si]
	cmp	ax,2D01h
	jz	ripmm
	cmp	ax,2B01h
	jz	ripmp
	mov	[next],bx
	jmp	warg
ripmm:	or	byte ptr [op],1
	jmp	short rips
ripmp:	and	byte ptr [op],0FEh
rips:	call	gn
	mov	ax,[si]
	cmp	ax,2401h
	jz	rcurr
	cmp	ax,2D01h
	jz	rminus
	xchg	al,ah
	call	isnum
	jnc	rimm
	call	isltr
	jnc	rlb
	xor	al,al
	jmp	fail
rminus:	call	gn
	mov	al,[si+1]
	call	isnum
	jnc	rmin1
	mov	al,1
	jmp	fail
rmin1:	call	val
	neg	ax
	or	dl,dl
	jnz	rmin0
	mov	dx,4
rmin0:	jmp	short riax
rcurr:	mov	ax,[pc]
	add	ax,[vorg]
	or	dl,dl
	jnz	rcurr0
	mov	dx,0304h
rcurr0:	jmp	riax
rlb:	cmp	word ptr [si],6F06h
	jnz	rlb1
	cmp	word ptr [si+2],6666h
	jnz	rlb1
	cmp	word ptr [si+4],6573h
	jnz	rlb1
	cmp	byte ptr [si+6],74h
	jnz	rlb1
	call	gn
	jc	rquo8
rlb2:	call	gl
	jc	rlbf
	or	byte ptr [flags],1
	or	dl,dl
	jnz	rlb0
	mov	dx,0104h
rlb0:	jmp	riax
rlb1:	cmp	word ptr [si],7203h
	jnz	rlb2
	cmp	word ptr [si+2],6C65h
	jnz	rlb2
	call	gn
	jc	rquo8
	call	gl
	jc	rlbf
	sub	ax,[pc]
	sub	ax,[vorg]
	or	dl,dl
	jnz	rlb0
	mov	dx,0204h
	jmp	riax
rlbf:	mov	al,4
	jmp	fail
rquo:	cmp	al,2
	jna	rquo8
	cmp	al,4
	ja	rquo0
	mov	ax,[si+2]
	or	byte ptr [flags],3
	cmp	byte ptr [si],3
	ja	rquo16
	and	byte ptr [flags],0FEh
	xor	ah,ah
rquo16:	mov	[imm],ax
	mov	dx,0404h
	jmp	warg
rquo8:	mov	al,8
	jmp	fail
rquo0:	mov	al,7
	jmp	fail
mmodrm:	or	byte ptr [flags],10h
	mov	ax,word ptr [args]
	cmp	al,11h
	jz	mwrs
	cmp	al,12h
	jz	mwmr
	cmp	al,13h
	jz	mwrs
	cmp	al,21h
	jz	mwrm
	cmp	al,23h
	jz	mwrm
	cmp	al,31h
	jz	mwsr
	cmp	al,32h
	jz	mwmr
	and	ax,0F0Fh
	cmp	al,1
	jz	mwr
	cmp	al,2
	jz	mwm
	mov	ax,word ptr [args]
	ror	ax,1
	ror	ax,1
	ror	ax,1
	ror	ax,1
	and	ax,0F0Fh
	cmp	al,1
	jz	mwr
	cmp	al,2
	jz	mwm
	ret
mwrs:	or	byte ptr [modrm],0C0h
mwrm:	rol	ah,1
	rol	ah,1
	rol	ah,1
	rol	ah,1
	jmp	short mwmr
mwsr:	or	byte ptr [modrm],0C0h
mwmr:	mov	al,ah
	push	ax
	and	ax,7007h
	shr	ah,1
	or	al,ah
	or	[modrm],al
	pop	ax
	cmp	byte ptr [modrm],0C0h
	jc	mwdisp
	ret
mwr:	or	byte ptr [modrm],0C0h
mwm:	mov	al,ah
	and	al,7
	or	[modrm],al
	cmp	byte ptr [modrm],0C0h
	jc	mwdisp
	ret
mwdisp:	test	byte ptr [flags],8
	jz	mwd0
	test	ah,8
	jz	mwd16
	or	byte ptr [flags],4
	ret
mwd16:	test	byte ptr [flags],4
	jz	mwd8
	or	byte ptr [modrm],80h
	ret
mwd8:	or	byte ptr [modrm],40h
	or	byte ptr [flags],8
	ret
mwd0:	mov	al,[modrm]
	and	al,0C7h
	cmp	al,6
	jz	mwd8
	ret
wa:	mov	al,[args+2]
	mov	ah,al
	shr	ah,1
	shr	ah,1
	shr	ah,1
	shr	ah,1
	and	ax,303h
	cmp	al,ah
	jnz	wanz
wa16:	or	al,al
	jz	wa0
	cmp	al,1
	jz	wa8
	mov	byte ptr [wadj],1
	ret
wanz:	or	ah,ah
	jz	wa16
	or	al,al
	jnz	wax
	mov	al,ah
	jmp	short wa16
wa8:	test	byte ptr [flags],1
	jnz	wax
	mov	byte ptr [wadj],0
	ret
wa0:	mov	al,[flags]
	and	al,1
	mov	[wadj],al
	ret
wax:	mov	al,6
	jmp	fail
comma:	call	gn
	jc	comma0
	cmp	word ptr [si],2C01h
	jnz	comma0
	ret
comma0:	mov	al,8
	jmp	fail
aa:	or	ax,ax
	jns	aa0
	cmp	ah,0FFh
	jc	aa0
	test	al,80h
	jz	aa0
	xor	ah,ah
aa0:	ret
gn:	mov	si,[next]
	push	di
	mov	di,offset element
	call	cc
	pop	di
	mov	[next],si
	mov	si,offset element
	or	byte ptr [si],0
	jz	gn0
	clc
	ret
gn0:	stc
	ret
gl:	cmp	byte ptr [func],2
	jz	gl1
	mov	ax,[pc]
	add	ax,[vorg]
	clc
	ret
gl1:	push	di
	mov	di,offset symbs
	call	sl
	pop	di
	ret
g0:	ret
g1:	call	ra
	call	comma
	call	ra
	call	wa
	mov	ax,word ptr [args]
	cmp	al,11h
	jz	g1rm
	cmp	al,12h
	jz	g1mr
	cmp	al,21h
	jz	g1rm
	cmp	al,41h
	jz	g1ri
	cmp	al,42h
	jz	g1mi
	mov	al,0
	jmp	fail
g1ri:	and	ah,7
	jz	g1ai
g1mi:	mov	al,[opcode]
	or	[modrm],al
	mov	al,[wadj]
	or	[flags],al
	or	al,80h
	mov	[opcode],al
	test	byte ptr [wadj],1
	jnz	g1rib
g1riw:	jmp	mmodrm
g1rib:	mov	ax,[imm]
	or	ah,ah
	jnz	g1riw
	or	al,al
	js	g1riw
	add	byte ptr [opcode],2
	and	byte ptr [flags],0FEh
	jmp	mmodrm
g1rm:	add	byte ptr [opcode],2
g1mr:	mov	al,[wadj]
	add	[opcode],al
	jmp	mmodrm
g1ai:	or	byte ptr [opcode],4
	mov	al,[wadj]
	or	[flags],al
	or	[opcode],al
	ret
g2:	call	ra
	call	comma
	jc	g2n
	call	gn
	jc	g2mp
	mov	al,[opcode]
	mov	[modrm],al
	mov	al,[args+2]
	shr	al,1
	and	al,1
	add	al,0D0h
	mov	[opcode],al
	lodsw
	cmp	ax,3101h
	jz	g2n
	cmp	ax,6302h
	jz	g2cl
g2f:	mov	al,0
	jmp	fail
g2mp:	mov	al,8
	jmp	fail
g2cl:	lodsb
	cmp	al,6Ch
	jnz	g2f
	add	byte ptr [opcode],2
g2n:	jmp	mmodrm
g3:	call	ra
	call	wa
	mov	al,[args]
	cmp	al,1
	jz	g3r
	cmp	al,2
	jz	g3r
	mov	al,0
	jmp	fail
g3r:	mov	al,0F6h
	add	al,[wadj]
	xchg	al,[opcode]
	or	[modrm],al
	jmp	mmodrm
g4:	call	ra
	call	wa
	mov	ax,word ptr [args]
	cmp	al,1
	jz	g4r
	cmp	al,2
	jz	g4m
	mov	al,0
	jmp	fail
g4r:	test	byte ptr [args+2],2
	jz	g4m
	and	ah,7
	add	ah,40h
	add	[opcode],ah
	ret
g4m:	mov	al,0FEh
	add	al,[wadj]
	xchg	al,[opcode]
	or	[modrm],al
	jmp	mmodrm
g5:	call	ra
	and	byte ptr [flags],0E2h
	mov	ax,word ptr [args]
	cmp	al,4
	jnz	g5f0
	mov	dx,[imm]
	cmp	ah,0
	jz	g5i0
	cmp	ah,1
	jz	g5i1
	cmp	ah,2
	jz	g5i2
	cmp	ah,3
	jz	g5i3
g5f0:	mov	al,0
	jmp	fail
g5i2:	sub	dx,2
	jmp	short g5i0
g5i1:	sub	dx,2
g5i3:	sub	dx,[pc]
	sub	dx,[vorg]
g5i0:	mov	ax,dx
	or	ax,ax
	jns	g5ins
	neg	ax
	cmp	ax,80h
	ja	g5f5
	mov	[imm],dx
	ret
g5ins:	cmp	dx,7Fh
	ja	g5f5
	mov	[imm],dx
	ret
g5f5:	mov	al,5
	jmp	fail
g6:	push	word ptr [next]
	call	gn
	pop	word ptr [next]
	jnc	g6g
	mov	al,8
	jmp	fail
g6g:	cmp	word ptr [si],7305h
	jz	g6s
	cmp	word ptr [si],6E04h
	jz	g6n
	cmp	word ptr [si],6603h
	jz	g6f
g6l:	call	ra
	mov	ax,word ptr [args]
	cmp	al,1
	jz	g6rm
	cmp	al,4
	jz	g6i
	cmp	al,2
	jnz	g6x
g6rm:	mov	al,[opcode]
	or	[modrm],al
	mov	byte ptr [opcode],0FFh
	jmp	mmodrm
g6s:	cmp	word ptr [si+2],6F68h
	jnz	g6l
	cmp	word ptr [si+4],7472h
	jnz	g6l
	cmp	byte ptr [opcode],20h
	jnz	g6x
	mov	byte ptr [opcode],0EBh
	call	gn
	jmp	g5
g6n:	cmp	word ptr [si+2],6165h
	jnz	g6l
	cmp	byte ptr [si+4],72h
	jnz	g6l
	call	gn
	jmp	short g6l
g6f:	cmp	word ptr [si+2],7261h
	jnz	g6l
	add	byte ptr [opcode],8
	call	gn
	jmp	short g6l
g6x:	mov	al,0
	jmp	fail
g6i:	push	word ptr [next]
	call	gn
	pop	word ptr [next]
	cmp	word ptr [si],3A01h
	jz	g6if
	mov	al,[opcode]
	test	al,8
	jz	g6r
	mov	al,8
	jmp	fail
g6if:	call	gn
	call	gn
	jc	g6x
	mov	al,[si+1]
	call	isnum
	jc	g6x
	call	val
	mov	[disp],ax
	or	byte ptr [flags],0Fh
	mov	al,0
	xchg	al,byte ptr [opcode]
	cmp	al,20h
	jc	g6iop
	add	byte ptr [opcode],50h
g6iop:	add	byte ptr [opcode],9Ah
	ret
g6r:	rol	al,1
	rol	al,1
	rol	al,1
	and	al,1
	add	al,0E8h
	mov	[opcode],al
	mov	dx,[imm]
	cmp	ah,0
	jz	g6i0
	cmp	ah,1
	jz	g6i1
	cmp	ah,2
	jz	g6i2
	cmp	ah,3
	jz	g6i0
	jmp	short g6x
g6i1:	sub	dx,[pc]
	sub	dx,[vorg]
g6i2:	sub	dx,3
	mov	[imm],dx
g6i0:	or	byte ptr [flags],3
	ret
g7:	call	gn
	jnc	g7a
	mov	ax,0Ah
	jmp	short g7c
g7a:	mov	al,[si+1]
	call	isnum
	jnc	g7b
	mov	al,0
	jmp	fail
g7b:	call	val
	or	ah,ah
	jz	g7c
	mov	al,7
	jmp	fail
g7c:	mov	[imm],ax
	or	byte ptr [flags],2
	ret
g8:	call	ra
	call	comma
	call	ra
	cmp	byte ptr [args],21h
	jnz	g8f
	jmp	mmodrm
g8f:	mov	al,0
	jmp	fail
g9:	call	ra
	call	comma
	call	ra
	call	wa
	mov	ax,word ptr [args]
	cmp	al,11h
	jz	g9rm
	cmp	al,12h
	jz	g9mr
	cmp	al,13h
	jz	g9sr
	cmp	al,21h
	jz	g9rm
	cmp	al,23h
	jz	g9sr
	cmp	al,31h
	jz	g9rs
	cmp	al,32h
	jz	g9rs
	cmp	al,41h
	jz	g9ri
	cmp	al,42h
	jz	g9mi
	mov	al,0
	jmp	fail
g9ri:	mov	al,[wadj]
	or	[flags],al
	shl	al,1
	shl	al,1
	shl	al,1
	and	ah,7
	or	al,ah
	or	al,0B0h
	mov	[opcode],al
	ret
g9mi:	mov	al,[wadj]
	or	[flags],al
	add	al,0C6h
	mov	[opcode],al
	jmp	mmodrm
g9rm:	mov	byte ptr [opcode],2
	cmp	ah,0E0h
	jz	g9a
	jmp	short g9na
g9mr:	cmp	ah,0Eh
	jz	g9a
g9na:	mov	al,88h
	add	al,[wadj]
	add	[opcode],al
	jmp	mmodrm
g9sr:	mov	byte ptr [opcode],2
g9rs:	add	byte ptr [opcode],8Ch
	jmp	mmodrm
g9a:	xor	byte ptr [opcode],2
	mov	al,0A0h
	add	al,[wadj]
	add	[opcode],al
	mov	ax,[disp]
	mov	[imm],ax
	and	byte ptr [flags],0E3h
	or	byte ptr [flags],3
	ret
g0Ah:	mov	sp,[stk]
	mov	al,[opcode]
	mov	[prefix],al
	or	byte ptr [flags],80h
	jmp	asml
g0Bh:	call	gn
	jc	g0Bh0
	mov	al,[si+1]
	call	isnum
	jnc	g0Bhva
	cmp	word ptr [si],6603h
	jz	g0Bhf
	cmp	word ptr [si],6E04h
	jz	g0Bhn
g0Bhx:	mov	al,0
	jmp	fail
g0Bhf:	cmp	word ptr [si+2],7261h
	jnz	g0Bhx
	mov	byte ptr [opcode],0CBh
	call	gn
	jc	g0Bh0
	mov	al,[si+1]
	call	isnum
	jc	g0Bhx
	jmp	short g0Bhva
g0Bhn:	cmp	word ptr [si+2],6165h
	jnz	g0Bhx
	cmp	word ptr [si+4],72h
	jnz	g0Bhx
	call	gn
	jc	g0Bh0
	mov	al,[si+1]
	call	isnum
	jc	g0Bhx
g0Bhva:	call	val
	or	ah,ah
	jz	g0Bhcb
	mov	al,7
	jmp	fail
g0Bhcb:	mov	[imm],ax
	or	byte ptr [flags],2
	dec	byte ptr [opcode]
g0Bh0:	ret
g0Ch:	call	gn
	jnc	g0Ch1
	mov	al,8
	jmp	fail
g0Ch1:	mov	al,[si+1]
	call	isnum
	jnc	g0Ch2
	mov	al,0
	jmp	fail
g0Ch2:	call	val
	cmp	ax,3
	jz	g0Ch3
	or	ah,ah
	jz	g0Ch4
	mov	al,7
	jmp	fail
g0Ch3:	dec	byte ptr [opcode]
	ret
g0Ch4:	mov	[imm],ax
	or	byte ptr [flags],2
	ret
g0Dh:	call	ra
	mov	ax,word ptr [args]
	test	byte ptr [args+2],2
	jz	g0Dhf
	cmp	al,1
	jz	g0Dhr
	cmp	al,2
	jz	g0Dhm
	cmp	al,3
	jz	g0Dhs
g0Dhf:	mov	al,0
	jmp	fail
g0Dhr:	and	ah,7
	add	ah,50h
	mov	[opcode],ah
	ret
g0Dhm:	or	byte ptr [modrm],30h
	mov	byte ptr [opcode],0FFh
	jmp	mmodrm
g0Dhs:	and	ah,3
	shl	ah,1
	shl	ah,1
	shl	ah,1
	add	ah,6
	mov	[opcode],ah
	ret
g0Eh:	call	ra
	mov	ax,word ptr [args]
	test	byte ptr [args+2],2
	jz	g0Ehf
	cmp	al,1
	jz	g0Ehr
	cmp	al,2
	jz	g0Ehm
	cmp	al,3
	jz	g0Ehs
g0Ehf:	mov	al,0
	jmp	fail
g0Ehr:	and	ah,7
	add	ah,58h
	mov	[opcode],ah
	ret
g0Ehm:	jmp	mmodrm
g0Ehs:	and	ah,3
	shl	ah,1
	shl	ah,1
	shl	ah,1
	add	ah,7
	mov	[opcode],ah
	ret
g0Fh:	call	ra
	call	comma
	call	ra
	call	wa
	mov	ax,word ptr [args]
	cmp	al,11h
	jz	g0Fhr
	cmp	al,12h
	jz	g0Fhr
	cmp	al,21h
	jz	g0Fhr
	cmp	al,41h
	jz	g0Fhri
	cmp	al,42h
	jz	g0Fhmi
	mov	al,0
	jmp	fail
g0Fhr:	mov	al,84h
	add	al,[wadj]
	mov	[opcode],al
	jmp	mmodrm
g0Fhri:	or	ah,ah
	jz	g0Fha
g0Fhmi:	mov	al,[wadj]
	or	[flags],al
	or	al,0F6h
	mov	[opcode],al
	jmp	mmodrm
g0Fha:	mov	al,[wadj]
	or	[flags],al
	or	al,0A8h
	mov	[opcode],al
	ret
g10h:	call	ra
	call	comma
	call	ra
	call	wa
	mov	ax,word ptr [args]
	cmp	al,11h
	jz	g10hr
	cmp	al,12h
	jz	g10hm
	cmp	al,21h
	jz	g10hm
	mov	al,0
	jmp	fail
g10hr:	or	byte ptr [wadj],0
	jz	g10hm
	test	ah,0Fh
	jz	g10har
	test	ah,0F0h
	jz	g10hra
g10hm:	mov	al,86h
	or	al,[wadj]
	mov	[opcode],al
	jmp	mmodrm
g10har:	shr	ah,1
	shr	ah,1
	shr	ah,1
	shr	ah,1
g10hra:	and	ah,7
	add	ah,90h
	mov	[opcode],ah
	ret
g11h:	call	ra
	call	comma
	call	ra
	mov	ax,word ptr [args]
	cmp	al,11h
	jz	g11hr
	cmp	al,41h
	jz	g11hi
g11hf:	mov	al,0
	jmp	fail
g11hr:	cmp	ah,20h
	jnz	g11hf
	test	byte ptr [args+2],20h
	jz	g11hf
	mov	byte ptr [opcode],0ECh
	test	byte ptr [args+2],2
	jz	g11h0
	inc	byte ptr [opcode]
g11h0:	ret
g11hi:	mov	ax,[imm]
	or	ah,ah
	jnz	g11hf
	and	byte ptr [flags],0FEh
	mov	byte ptr [opcode],0E4h
	test	byte ptr [args+2],2
	jz	g11h0
	inc	byte ptr [opcode]
	ret
g12h:	call	ra
	call	comma
	call	ra
	mov	ax,word ptr [args]
	cmp	al,11h
	jz	g12hr
	cmp	al,14h
	jz	g12hi
g12hf:	mov	al,0
	jmp	fail
g12hr:	cmp	ah,2
	jnz	g12hf
	test	byte ptr [args+2],2
	jz	g12hf
	mov	byte ptr [opcode],0EEh
	test	byte ptr [args+2],20h
	jz	g12h0
	inc	byte ptr [opcode]
g12h0:	ret
g12hi:	mov	ax,[imm]
	or	ah,ah
	jnz	g12hf
	and	byte ptr [flags],0FEh
	mov	byte ptr [opcode],0E6h
	test	byte ptr [args+2],20h
	jz	g12h0
	inc	byte ptr [opcode]
	ret
g13h:	mov	byte ptr [flags],0
	call	gn
	jnc	g13h1
	mov	al,8
	jmp	fail
g13h1:	mov	al,[si+1]
	call	isnum
	jnc	g13h2
	mov	al,0
	jmp	fail
g13h2:	call	val
	mov	[vorg],ax
	ret
g14h:	mov	byte ptr [flags],0
	mov	bp,offset output
	mov	di,offset output+3
	mov	byte ptr [bp],0
	mov	word ptr [bp+1],0
	mov	word ptr [cache],0
	cld
g14hl:	call	gn
	jc	g14h0
	mov	ax,[si]
	cmp	ax,2D01h
	jz	g14hmi
	cmp	ax,3F01h
	jz	g14hsu
	cmp	ax,2401h
	jz	g14hcu
	xchg	al,ah
	cmp	al,22h
	jz	g14hqs
	cmp	al,27h
	jz	g14hqs
	call	isnum
	jnc	g14hi
	call	isltr
	jnc	g14hlb
	mov	al,1
	jmp	fail
g14h0:	mov	al,8
	jmp	fail
g14hqs:	jmp	g14hq
g14hsu:	jmp	g14hu
g14hi:	call	val
	push	word ptr [next]
	call	gn
	pop	word ptr [next]
	cmp	word ptr [si],6403h
	jz	g14hdc
	cmp	word ptr [si],2801h
	jz	g14hdd
	jmp	short g14hiv
g14hmi:	call	gn
	mov	al,[si+1]
	call	isnum
	jc	g14hf
	call	val
	neg	ax
	jmp	short g14hiv
g14hcu:	mov	ax,[pc]
	add	ax,[vorg]
g14hiv:	mov	cx,ax
	mov	al,[opcode]
	or	al,8
	jmp	g14hv
g14hlb:	cmp	word ptr [si],6F07h
	jnz	g14hrl
	cmp	word ptr [si+2],6666h
	jnz	g14hrl
	cmp	word ptr [si+4],6573h
	jnz	g14hrl
	cmp	byte ptr [si+6],74h
	jnz	g14hrl
	call	gn
	jc	g14h0
g14hrl:	call	gl
	jnc	g14hiv
	mov	al,4
	jmp	fail
g14hf:	mov	al,1
	jmp	fail
g14hdc:	cmp	word ptr [si+2],7075h
	jnz	g14hf
	call	gn
g14hdd:	call	gn
	mov	cx,ax
	cmp	word ptr [si],2801h
	jnz	g14hf
	call	gn
	jc	g14hf
	mov	ax,[si]
	cmp	ax,3F01h
	jz	g14hdu
	mov	al,ah
	call	isnum
	jc	g14hf
	call	val
	mov	dx,ax
	mov	al,[opcode]
	or	al,0Ch
	jmp	short g14hue
g14hdu:	xor	dx,dx
	mov	al,[opcode]
	or	al,0Eh
g14hue:	cmp	al,[bp]
	jz	g14hua
	call	ubp
	mov	[bp],al
g14hua:	add	[bp+1],cx
	mov	[di],dx
	call	udi
	call	gn
	jc	g14hf
	cmp	word ptr [si],2901h
	jnz	g14hf
g14hte:	call	gn
	jc	g14hx
	cmp	word ptr [si],2C01h
	jnz	g14hf
	jmp	g14hl
g14hx:	mov	word ptr [di],0
	ret
g14hu:	mov	al,[opcode]
	or	al,0Ah
	xor	cx,cx
g14hv:	cmp	[bp],al
	jz	g14hm
	call	ubp
	mov	[bp],al
g14hm:	mov	[di],cx
	call	udi
	inc	word ptr [bp+1]
	jmp	short g14hte
g14hq:	cmp	byte ptr [bp],8
	jz	g14hqg
	call	ubp
	mov	byte ptr [bp],8
g14hqg:	mov	cl,[si]
	xor	ch,ch
	push	si
	add	si,cx
	lodsb
	pop	si
	cmp	al,22h
	jz	g14hqd
	cmp	al,27h
	jz	g14hqd
g14hfa:	mov	al,1
	jmp	fail
g14hqd:	cmp	cx,2
	jna	g14hfa
	sub	cx,2
	add	si,2
	add	[bp+1],cx
	rep	movsb
	jmp	short g14hte
udi:	mov	al,[opcode]
	xor	ah,ah
	add	di,ax
	inc	di
	ret
ubp:	or	byte ptr [bp],0
	jz	ubp0
	mov	bp,di
	add	di,3
	mov	byte ptr [bp],0
	mov	word ptr [bp+1],0
ubp0:	inc	word ptr [cache]
	mov	bx,word ptr [cache]
	shl	bx,1
	add	bx,offset cache
	mov	[bx],bp
	ret
g15h:	mov	byte ptr [flags],0
	call	ra
	cmp	byte ptr [args],4
	jz	g15h1
g15hf:	mov	al,1
	jmp	fail
g15h1:	cmp	byte ptr [func],2
	jnz	g15h0
	or	byte ptr [cache],0
	jz	g15hf
	mov	si,offset cache
	mov	di,offset symbs
	call	sl
	mov	ax,[imm]
	stosw
g15h0:	ret
g16h:	mov	byte ptr [flags],0
	call	gn
	call	fspec
	jc	g16h0
	mov	ax,3D00h
	mov	dx,offset element+1
	int	21h
	jc	g16h0
	inc	word ptr [inclev]
	mov	di,word ptr [inclev]
	shl	di,1
	add	di,offset inclev
	xchg	ax,[infile]
	stosw
	ret
g16h0:	mov	al,0Bh
	jmp	fail
g17h:	mov	byte ptr [flags],0
	mov	al,[si+1]
	call	isnum
	jc	g17h0
	call	val
	mov	[rsize],ax
	mov	sp,[stk]
	jmp	asml
g17h0:	mov	cl,[si]
	xor	ch,ch
	inc	cx
	mov	di,offset cache
	rep	movsb
	push	word ptr [next]
	call	gn
	pop	word ptr [next]
	jnc	g17h1
	mov	al,3
	jmp	fail
g17h1:	cmp	word ptr [si],3A01h
	jnz	g17h3
	call	gn
g17h3:	cmp	byte ptr [func],1
	jnz	g17h2
	mov	ax,[pc]
	add	ax,[vorg]
	mov	si,offset cache
	mov	di,offset symbs
	call	sa
	pushf
	mov	word ptr [cache],0
	popf
	jnc	g17h2
	mov	al,0Ah
	jmp	fail
g17h2:	mov	sp,[stk]
	jmp	asml
ln	dw	0
pc	dw	0
errs	dw	0
infile	dw	0
outfile	dw	0
func	db	0
vorg	dw	0100h
rsize	dw	0
usize	dw	0
next	dw	0
stk	dw	0
flags	db	0
wadj	db	0
op	db	0
args	db	0,0,0
prefix	db	0
segpref	db	0
opcode	db	0
modrm	db	0
disp	dw	0
imm	dw	0
rm	db	0Eh,7,6,0FFh,5,1,3,0FFh,4,0,2,0FFh,0FFh,0FFh,0FFh,0FFh
errm	dw	em0,em1,em2,em3,em4,em5,em6,em7,em8,em9,emA,emB
ihdl	dw	g0,g1,g2,g3,g4,g5,g6,g7
	dw	g8,g9,g0Ah,g0Bh,g0Ch,g0Dh,g0Eh,g0Fh
	dw	g10h,g11h,g12h,g13h,g14h,g15h,g16h,g17h
regs	db	"alcldlblahchdhbhaxcxdxbxspbpsidiescsssds"
i8086	dw	79h
	db	3,"aaa",37h,0
	db	3,"aad",0D5h,7
	db	3,"aam",0D4h,7
	db	3,"aas",3Fh,0
	db	3,"adc",10h,1
	db	3,"add",0,1
	db	3,"and",20h,1
	db	4,"call",10h,6
	db	3,"cbw",98h,0
	db	3,"clc",0F8h,0
	db	3,"cld",0FCh,0
	db	3,"cli",0FAh,0
	db	3,"cmc",0F5h,0
	db	3,"cmp",38h,1
	db	5,"cmpsb",0A6h,0
	db	5,"cmpsw",0A7h,0
	db	3,"cwd",99h,0
	db	3,"daa",27h,0
	db	3,"das",2Fh,0
	db	2,"db",0,14h
	db	3,"dec",8,4
	db	3,"div",30h,3
	db	2,"dw",1,14h
	db	3,"equ",0,15h
	db	3,"hlt",0F4h,0
	db	4,"idiv",38h,3
	db	4,"imul",28h,3
	db	2,"in",0E4h,11h
	db	3,"inc",0,4
	db	7,"include",0,16h
	db	3,"int",0CDh,0Ch
	db	4,"into",0CEh,0
	db	4,"iret",0CFh,0
	db	2,"ja",77h,5
	db	3,"jae",73h,5
	db	2,"jb",72h,5
	db	3,"jbe",76h,5
	db	2,"jc",72h,5
	db	4,"jcxz",0E3h,5
	db	2,"je",74h,5
	db	2,"jg",7Fh,5
	db	3,"jge",7Dh,5
	db	2,"jl",7Ch,5
	db	3,"jle",7Eh,5
	db	3,"jmp",20h,6
	db	3,"jna",76h,5
	db	4,"jnae",72h,5
	db	3,"jnb",73h,5
	db	4,"jnbe",77h,5
	db	3,"jnc",73h,5
	db	3,"jne",75h,5
	db	3,"jng",7Eh,5
	db	4,"jnge",7Ch,5
	db	3,"jnl",7Dh,5
	db	4,"jnle",7Fh,5
	db	3,"jno",71h,5
	db	3,"jnp",7Bh,5
	db	3,"jns",79h,5
	db	3,"jnz",75h,5
	db	2,"jo",70h,5
	db	2,"jp",7Ah,5
	db	3,"jpe",7Ah,5
	db	3,"jpo",7Bh,5
	db	2,"js",78h,5
	db	2,"jz",74h,5
	db	4,"lahf",9Fh,0
	db	3,"lds",0C5h,8
	db	3,"lea",8Dh,8
	db	3,"les",0C4h,8
	db	4,"lock",0F0h,0Ah
	db	5,"lodsb",0ACh,0
	db	5,"lodsw",0ADh,0
	db	4,"loop",0E2h,5
	db	5,"loope",0E1h,5
	db	6,"loopne",0E0h,5
	db	6,"loopnz",0E0h,5
	db	5,"loopz",0E1h,5
	db	3,"mov",0,9
	db	5,"movsb",0A4h,0
	db	5,"movsw",0A5h,0
	db	3,"mul",20h,3
	db	3,"neg",18h,3
	db	3,"nop",90h,0
	db	3,"not",10h,3
	db	2,"or",8,1
	db	3,"org",0,13h
	db	3,"out",0E6h,12h
	db	3,"pop",8Fh,0Eh
	db	4,"popf",9Dh,0
	db	4,"push",30h,0Dh
	db	5,"pushf",9Ch,0
	db	3,"rcl",10h,2
	db	3,"rcr",18h,2
	db	3,"rep",0F3h,0Ah
	db	4,"repe",0F3h,0Ah
	db	5,"repne",0F2h,0Ah
	db	5,"repnz",0F2h,0Ah
	db	4,"repz",0F3h,0Ah
	db	3,"ret",0C3h,0Bh
	db	3,"rol",0,2
	db	3,"ror",8,2
	db	4,"sahf",9Eh,0
	db	3,"sal",30h,2
	db	4,"salc",0D6h,0
	db	3,"sar",38h,2
	db	3,"sbb",18h,1
	db	5,"scasb",0AEh,0
	db	5,"scasw",0AFh,0
	db	3,"shl",20h,2
	db	3,"shr",28h,2
	db	3,"stc",0F9h,0
	db	3,"std",0FDh,0
	db	3,"sti",0FBh,0
	db	5,"stosb",0AAh,0
	db	5,"stosw",0ABh,0
	db	3,"sub",28h,1
	db	4,"test",0,0Fh
	db	4,"wait",9Bh,0
	db	4,"xchg",86h,10h
	db	5,"xlatb",0D7h,0
	db	3,"xor",30h,1
amsg	db	"A72  8086 assembler  Version 1.0  "
	db	"Copyright (c) 2002, 2006 PC-72"
	db	0Dh,0Ah,0Dh,0Ah,24h
usage	db	"Syntax:  A72 infile[.ASM] [outfile[.COM]]",0Dh,0Ah,24h
asmm1	db	"Reading: $"
asmm2	db	0Ch dup(20h),0Dh,0Ah,24h
asmm3	db	"Writing: $"
done	db	"Done",0Dh,0Ah,24h
errf	db	"Errors: $"
errn	db	6 dup(20h),0Dh,0Ah,24h
em0	db	"Wrong operand$"
em1	db	"Syntax error$"
em2	db	"Bad displacement$"
em3	db	"Unrecognised instruction$"
em4	db	"Undefined symbol$"
em5	db	"Jump out of range$"
em6	db	"Parameter size mismatch$"
em7	db	"Constant too large$"
em8	db	"Missing operand$"
em9	db	"Extraneous characters$"
emA	db	"Duplicate symbol$"
emB	db	"File I/O error$"
onlm	db	" on line $"
input	db	80h dup(?)
output	db	80h dup(?)
cache	db	80h dup(?)
element	db	60h dup(?)
inclev	db	20h dup(?)
symbs	db	2000h dup(?)
