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
ginf:	mov	ah,9
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
	mov	byte ptr [func],0
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
	call	disf
	mov	ah,3Eh
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
	mov	dx,offset specs+4
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
	mov	dx,offset specs
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
	mov	si,offset specs
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
rbin:	mov	ax,4200h
	xor	cx,cx
	mov	dx,[pc]
	mov	bx,[infile]
	int	21h
	jc	rbin0
	mov	ah,3Fh
	mov	cx,20h
	mov	dx,offset input+1
	mov	bx,[infile]
	int	21h
	jc	rbin0
	mov	[input],al
	clc
rbin0:	ret
wrasm:	mov	cl,[output]
	xor	ch,ch
	jcxz	wrasm0
	mov	ah,40h
	mov	dx,offset output+1
	mov	bx,[outfile]
	int	21h
wrasm0:	ret
disf:	mov	word ptr [pc],0
disfl:	mov	byte ptr [input],0
	call	rbin
	jc	disf0
	or	byte ptr [input],0
	jz	disf0
	mov	byte ptr [output],0
	mov	si,offset input+1
	mov	di,offset output
	call	disasm
	call	wrasm
	jnc	disfl
disf0:	ret
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
whals:	or	al,al
	jns	whal
	neg	al
	mov	byte ptr [di],2Dh
	inc	di
whal:	cld
	cmp	al,9
	ja	whalg
	add	al,30h
	stosb
	ret
whalg:	call	halx
	cmp	al,39h
	jna	whald
	mov	byte ptr [di],30h
	inc	di
whald:	stosw
	mov	al,68h
	stosb
	ret
whaxs:	or	ax,ax
	jns	whax
	neg	ax
	mov	byte ptr [di],2Dh
	inc	di
whax:	cld
	or	ah,ah
	jz	whal
	push	ax
	mov	al,ah
	call	halx
	cmp	al,39h
	jna	whaxl
	mov	byte ptr [di],30h
	inc	di
whaxl:	stosw
	pop	ax
	call	halx
	stosw
	mov	al,68h
	stosb
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
disasm:	cld
	mov	bp,di
	mov	bx,si
	inc	di
	mov	byte ptr [segpref],0
	mov	[stk],sp
dsas:	mov	al,9
	stosb
	lodsb
	mov	[opcode],al
	mov	word ptr [wadj],0
	test	al,1
	jz	dsab
	mov	word ptr [wadj],10h
dsab:	xor	ah,ah
	shl	ax,1
	shl	ax,1
	push	si
	mov	si,offset bin86
	add	si,ax
	lodsw
	push	si
	mov	si,ax
	or	byte ptr [si],0
	jz	dsa0
	mov	cl,[si]
	xor	ch,ch
	inc	si
	rep	movsb
dsa0:	pop	si
	lodsw
	pop	si
	call	ax
dsax:	mov	ax,di
	sub	ax,bp
	dec	ax
	mov	[bp],al
	sub	si,bx
	add	[pc],si
	ret
endl:	mov	ax,0A0Dh
	stosw
	mov	byte ptr [di],24h
	ret
wreg:	cld
	push	si
	mov	si,ax
	and	si,38h
	shr	si,1
	shr	si,1
	add	si,offset regs
	add	si,[wadj]
	movsw
	pop	si
	ret
ptrp:	push	ax
	or	byte ptr [wadj],0
	jz	ptrpb
	mov	ax,6F77h
	stosw
	mov	ax,6472h
	stosw
	jmp	short ptrw
ptrpb:	mov	ax,7962h
	stosw
	mov	ax,6574h
	stosw
ptrw:	mov	ax,7020h
	stosw
	mov	ax,7274h
	stosw
	mov	al,20h
	stosb
	pop	ax
	ret
wdisp:	cld
	cmp	al,0C0h
	jc	wdrm
	push	si
	mov	si,ax
	and	si,7
	shl	si,1
	add	si,offset regs
	add	si,[wadj]
	movsw
	pop	si
	ret
wdrm:	push	ax
	xor	ch,ch
	or	byte ptr [segpref],0
	jz	wdns
	push	si
	mov	si,word ptr [segpref]
	and	si,0FFh
	sub	si,26h
	shr	si,1
	shr	si,1
	add	si,offset regs+20h
	movsw
	pop	si
	mov	al,3Ah
	stosb
wdns:	mov	ax,5Bh
	stosb
	pop	ax
	push	ax
	and	al,0C7h
	cmp	al,6
	jnz	wdr
	lodsw
	call	whax
	jmp	short wdx
wdr:	push	si
	mov	si,ax
	and	si,7
	shl	si,1
	add	si,offset _disp
	mov	dx,[si]
	mov	si,[si]
	and	si,0FFh
	add	si,offset regs
	movsw
	or	dh,dh
	jz	wd1r
	mov	al,2Bh
	stosb
	xor	dl,dl
	xchg	dl,dh
	mov	si,dx
	add	si,offset regs
	movsw
wd1r:	pop	si
	pop	ax
	push	ax
	cmp	al,40h
	jc	wdx
	cmp	al,80h
	jc	wd01
	lodsw
	jmp	short wdpm
wd01:	xor	ah,ah
	lodsb
wdpm:	or	ax,ax
	jz	wdx
	js	wdm
	mov	byte ptr [di],2Bh
	inc	di
wdm:	mov	dx,offset _grp
	call	whaxs
wdx:	mov	al,5Dh
	stosb
	pop	ax
	ret
wptr:	cmp al,0C0h
	jnc wnptr
	jmp ptrp
wnptr:	ret
grp:	mov	al,byte ptr [si]
	shr	al,1
	shr	al,1
	and	al,0Eh
	xor	ah,ah
	mov	si,ax
	ret
g01d:	push	si
	call	grp
	mov	si,word ptr [si+_g01d]
	mov	cl,[si]
	xor	ch,ch
	inc	si
	rep	movsb
	pop	si
	mov	al,9
	stosb
	lodsb
	call	wptr
	call	wdisp
	mov	al,2Ch
	stosb
	test	byte ptr [opcode],2
	jnz	g01db
	or	word ptr [wadj],0
	jnz	g01d1
g01db:	lodsb
	call	whal
	jmp	endl
g01d1:	lodsw
	call	whax
	jmp	endl
g02d:	push	si
	call	grp
	mov	si,word ptr [si+_g02d]
	mov	cl,[si]
	xor	ch,ch
	inc	si
	rep	movsb
	pop	si
	mov	al,9
	stosb
	lodsb
	call	wptr
	call	wdisp
	mov	al,2Ch
	stosb
	test	byte ptr [opcode],2
	jz	g02d1
	mov	ax,6C63h
	stosw
	jmp	endl
g02d1:	mov	al,31h
	stosb
	jmp	endl
g03d:	push	si
	call	grp
	mov	si,word ptr [si+_g03d]
	mov	cl,[si]
	xor	ch,ch
	inc	si
	rep	movsb
	pop	si
	mov	al,9
	stosb
	lodsb
	call	wptr
	call	wdisp
	test	al,30h
	jz	g03dt
	jmp	endl
g03dt:	mov	al,2Ch
	stosb
	test	byte ptr [opcode],1
	jz	g03dtb
	lodsw
	call	whax
	jmp	endl
g03dtb:	lodsb
	call	whal
	jmp	endl
g04d:	push	bx
	xor	ah,ah
	mov	al,byte ptr [si]
	shr	al,1
	shr	al,1
	and	al,0Eh
	mov	bx,ax
	mov	bx,word ptr [bx+_g04d]
	push	si
	push	ax
	mov	si,bx
	mov	cl,[si]
	inc	si
	xor	ch,ch
	rep	movsb
	mov	al,9
	stosb
	pop	ax
	pop	si
	pop	bx
	shr	al,1
	cmp	al,5
	jz	g04df
	cmp	al,3
	jz	g04df
	jmp	short g04dd
g04df:	mov	ax,6166h
	stosw
	mov	ax,2072h
	stosw
g04dd:	lodsb
	call	wptr
	call	wdisp
	jmp	endl
dispd:	mov	al,9
	stosb
	lodsb
	call	wdisp
	jmp	endl
retd:	cmp	byte ptr [opcode],0CAh
	jc	retnd
	mov	ax,6609h
	stosw
	mov	ax,7261h
	stosw
	test	byte ptr [opcode],1
	jnz	retdna
	mov	al,20h
	jmp	short retsp
retnd:	test	byte ptr [opcode],1
	jnz	retdna
	mov	al,9
retsp:	stosb
	lodsw
	call	whax
retdna:	jmp	endl
aamd:	mov	al,9
	stosb
	lodsb
	cmp	al,0Ah
	jz	aamd0
	call	whal
aamd0:	jmp	endl
mrd:	mov	al,9
	stosb
	lodsb
	call	wdisp
	mov	byte ptr [di],2Ch
	inc	di
	call	wreg
	jmp	endl
rmd:	mov	al,9
	stosb
	lodsb
	call	wreg
	mov	byte ptr [di],2Ch
	inc	di
	call	wdisp
	jmp	endl
msd:	mov	al,9
	stosb
	mov	al,[si]
	mov	word ptr [wadj],10h
	push	ax
	call	wdisp
	mov	al,2Ch
	stosb
	pop	ax
	shr	al,1
	shr	al,1
	and	al,0Eh
	xor	ah,ah
	add	ax,offset regs+20h
	push	si
	mov	si,ax
	movsw
	pop	si
	jmp	endl
smd:	mov	al,9
	stosb
	push	si
	mov	word ptr [wadj],10h
	call	grp
	add	si,offset regs+20h
	movsw
	pop	si
	mov	al,2Ch
	stosb
	lodsb
	call	wdisp
	jmp	endl
maccd:	mov	ax,5B09h
	stosw
	lodsw
	call	whax
	mov	ax,2C5Dh
	stosw
	push	si
	mov	si,offset regs
	add	si,[wadj]
	movsw
	pop	si
	jmp	endl
accmd:	mov	al,9
	stosb
	push	si
	mov	si,offset regs
	add	si,[wadj]
	movsw
	pop	si
	mov	ax,5B2Ch
	stosw
	lodsw
	call	whax
	mov	al,5Dh
	stosb
	jmp	endl
rmid:	mov	al,9
	stosb
	lodsb
	call	wptr
	call	wdisp
	mov	al,2Ch
	stosb
	or	word ptr [wadj],0
	jz	rmidb
	lodsw
	call	whax
	jmp	endl
rmidb:	lodsb
	call	whal
	jmp	endl
rimmd:	mov	al,9
	stosb
	mov	al,[opcode]
	and	ax,0Fh
	shl	ax,1
	add	ax,offset regs
	push	si
	mov	si,ax
	movsw
	pop	si
	mov	al,2Ch
	stosb
	test	byte ptr [opcode],8
	jz	rimmdb
	lodsw
	call	whax
	jmp	endl
rimmdb:	lodsb
	call	whal
	jmp	endl
regwd:	mov	al,9
	stosb
	mov	al,[opcode]
	and	ax,7
	shl	ax,1
	add	ax,offset regs+10h
	push	si
	mov	si,ax
	movsw
	pop	si
	jmp	endl
relbd:	mov	al,9
	stosb
	cmp	byte ptr [opcode],0EBh
	jnz	relbdl
	mov	ax,6873h
	stosw
	mov	ax,726Fh
	stosw
	mov	ax,2074h
	stosw
relbdl:	mov	ax,2B24h
	stosw
	lodsb
	or	al,al
	jns	rbnans
	dec	di
rbnans:	call	whals
	jmp	endl
relwd:	mov	ax,2409h
	stosw
	lodsw
	or	ax,ax
	js	relwdw
	mov	byte ptr [di],2Bh
	inc	di
relwdw:	call	whaxs
	jmp	endl
accibd:	mov	ax,6109h
	stosw
	mov	ax,2C6Ch
	stosw
	lodsb
	call	whal
	jmp	endl
acciwd:	mov	ax,6109h
	stosw
	mov	ax,2C78h
	stosw
	lodsw
	call	whax
	jmp	endl
accrd:	mov	ax,6109h
	stosw
	mov	ax,2C78h
	stosw
	mov	al,[opcode]
	and	al,7
	shl	al,1
	xor	ah,ah
	add	ax,offset regs+10h
	push	si
	mov	si,ax
	movsw
	pop	si
	jmp	endl
alibpd:	mov	ax,6C61h
	jmp	short aibpd
axibpd:	mov	ax,7861h
aibpd:	mov	byte ptr [di],9
	inc	di
	stosw
	mov	al,2Ch
	stosb
	lodsb
	call	whal
	jmp	endl
ibalpd:	mov	ax,6C61h
	jmp	short ibapd
ibaxpd:	mov	ax,7861h
ibapd:	push	ax
	mov	al,9
	stosb
	lodsb
	call	whal
	mov	al,2Ch
	stosb
	pop	ax
	stosw
	jmp	endl
aldxpd:	mov	ax,6C61h
	jmp	short adxpd
axdxpd:	mov	ax,7861h
adxpd:	mov	byte ptr [di],9
	inc	di
	stosw
	mov	al,2Ch
	stosb
	mov	ax,7864h
	stosw
	jmp	endl
dxalpd:	mov	ax,6C61h
	jmp	short dxapd
dxaxpd:	mov	ax,7861h
dxapd:	push	ax
	mov	al,9
	stosb
	mov	ax,5844h
	stosw
	mov	al,2Ch
	stosb
	pop	ax
	stosw
	jmp	endl
segofd:	mov	al,9
	stosb
	lodsw
	push	ax
	lodsw
	call	whax
	mov	al,3Ah
	stosb
	pop	ax
	call	whax
	jmp	endl
psrd:	mov	al,9
	stosb
	mov	al,[opcode]
	shr	al,1
	shr	al,1
	and	al,6
	xor	ah,ah
	add	ax,offset regs+20h
	push	si
	mov	si,ax
	movsw
	pop	si
	jmp	endl
prefd:	mov	sp,[stk]
	jmp	dsas
sprefd:	mov	al,[opcode]
	or	byte ptr [segpref],0
	jnz	spfdn
	sub	di,2
	mov	[segpref],al
	mov	sp,[stk]
	jmp	dsas
spfdn:	xchg	[segpref],al
	xor	ah,ah
	sub	al,26h
	shr	ax,1
	shr	ax,1
	add	ax,offset regs+20h
	push	si
	mov	si,ax
	movsw
	pop	si
	mov	ax,3Ah
	stosb
	jmp	endl
invd:	mov	ax,6264h
	stosw
	mov	al,9
	stosb
	mov	al,[opcode]
	call	whal
	jmp	endl
intd:	mov	al,9
	stosb
	lodsb
	cmp	byte ptr [opcode],0CCh
	jnz	intdb
	mov	al,3
intdb:	call	whal
	jmp	endl
pc	dw	0
infile	dw	0
outfile	dw	0
func	db	0
stk	dw	0
wadj	dw	0
segpref	db	0
opcode	db	0
bin86	dw	_add,mrd
	dw	_add,mrd
	dw	_add,rmd
	dw	_add,rmd
	dw	_add,accibd
	dw	_add,acciwd
	dw	_push,psrd
	dw	_pop,psrd
	dw	_or,mrd
	dw	_or,mrd
	dw	_or,rmd
	dw	_or,rmd
	dw	_or,accibd
	dw	_or,acciwd
	dw	_push,psrd
	dw	_pop,psrd
	dw	_adc,mrd
	dw	_adc,mrd
	dw	_adc,rmd
	dw	_adc,rmd
	dw	_adc,accibd
	dw	_adc,acciwd
	dw	_push,psrd
	dw	_pop,psrd
	dw	_sbb,mrd
	dw	_sbb,mrd
	dw	_sbb,rmd
	dw	_sbb,rmd
	dw	_sbb,accibd
	dw	_sbb,acciwd
	dw	_push,psrd
	dw	_pop,psrd
	dw	_and,mrd
	dw	_and,mrd
	dw	_and,rmd
	dw	_and,rmd
	dw	_and,accibd
	dw	_and,acciwd
	dw	_grp,sprefd
	dw	_daa,endl
	dw	_sub,mrd
	dw	_sub,mrd
	dw	_sub,rmd
	dw	_sub,rmd
	dw	_sub,accibd
	dw	_sub,acciwd
	dw	_grp,sprefd
	dw	_das,endl
	dw	_xor,mrd
	dw	_xor,mrd
	dw	_xor,rmd
	dw	_xor,rmd
	dw	_xor,accibd
	dw	_xor,acciwd
	dw	_grp,sprefd
	dw	_aaa,endl
	dw	_cmp,mrd
	dw	_cmp,mrd
	dw	_cmp,rmd
	dw	_cmp,rmd
	dw	_cmp,accibd
	dw	_cmp,acciwd
	dw	_grp,sprefd
	dw	_aas,endl
	dw	_inc,regwd
	dw	_inc,regwd
	dw	_inc,regwd
	dw	_inc,regwd
	dw	_inc,regwd
	dw	_inc,regwd
	dw	_inc,regwd
	dw	_inc,regwd
	dw	_dec,regwd
	dw	_dec,regwd
	dw	_dec,regwd
	dw	_dec,regwd
	dw	_dec,regwd
	dw	_dec,regwd
	dw	_dec,regwd
	dw	_dec,regwd
	dw	_push,regwd
	dw	_push,regwd
	dw	_push,regwd
	dw	_push,regwd
	dw	_push,regwd
	dw	_push,regwd
	dw	_push,regwd
	dw	_push,regwd
	dw	_pop,regwd
	dw	_pop,regwd
	dw	_pop,regwd
	dw	_pop,regwd
	dw	_pop,regwd
	dw	_pop,regwd
	dw	_pop,regwd
	dw	_pop,regwd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_jo,relbd
	dw	_jno,relbd
	dw	_jc,relbd
	dw	_jnc,relbd
	dw	_jz,relbd
	dw	_jnz,relbd
	dw	_jna,relbd
	dw	_ja,relbd
	dw	_js,relbd
	dw	_jns,relbd
	dw	_jp,relbd
	dw	_jnp,relbd
	dw	_jl,relbd
	dw	_jnl,relbd
	dw	_jng,relbd
	dw	_jg,relbd
	dw	_grp,g01d
	dw	_grp,g01d
	dw	_grp,g01d
	dw	_grp,g01d
	dw	_test,mrd
	dw	_test,mrd
	dw	_xchg,mrd
	dw	_xchg,mrd
	dw	_mov,mrd
	dw	_mov,mrd
	dw	_mov,rmd
	dw	_mov,rmd
	dw	_mov,msd
	dw	_lea,rmd
	dw	_mov,smd
	dw	_pop,dispd
	dw	_nop,endl
	dw	_xchg,accrd
	dw	_xchg,accrd
	dw	_xchg,accrd
	dw	_xchg,accrd
	dw	_xchg,accrd
	dw	_xchg,accrd
	dw	_xchg,accrd
	dw	_cbw,endl
	dw	_cwd,endl
	dw	_call,segofd
	dw	_wait,endl
	dw	_pushf,endl
	dw	_popf,endl
	dw	_sahf,endl
	dw	_lahf,endl
	dw	_mov,accmd
	dw	_mov,accmd
	dw	_mov,maccd
	dw	_mov,maccd
	dw	_movsb,endl
	dw	_movsw,endl
	dw	_cmpsb,endl
	dw	_cmpsw,endl
	dw	_test,accibd
	dw	_test,acciwd
	dw	_stosb,endl
	dw	_stosw,endl
	dw	_lodsb,endl
	dw	_lodsw,endl
	dw	_scasb,endl
	dw	_scasw,endl
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_mov,rimmd
	dw	_grp,invd
	dw	_grp,invd
	dw	_ret,retd
	dw	_ret,retd
	dw	_les,rmd
	dw	_lds,rmd
	dw	_mov,rmid
	dw	_mov,rmid
	dw	_grp,invd
	dw	_grp,invd
	dw	_ret,retd
	dw	_ret,retd
	dw	_int,intd
	dw	_int,intd
	dw	_into,endl
	dw	_iret,endl
	dw	_grp,g02d
	dw	_grp,g02d
	dw	_grp,g02d
	dw	_grp,g02d
	dw	_aam,aamd
	dw	_aad,aamd
	dw	_salc,endl
	dw	_xlatb,endl
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_grp,invd
	dw	_loopnz,relbd
	dw	_loopz,relbd
	dw	_loop,relbd
	dw	_jcxz,relbd
	dw	_in,alibpd
	dw	_in,axibpd
	dw	_out,ibalpd
	dw	_out,ibaxpd
	dw	_call,relwd
	dw	_jmp,relwd
	dw	_jmp,segofd
	dw	_jmp,relbd
	dw	_in,aldxpd
	dw	_in,axdxpd
	dw	_out,dxalpd
	dw	_out,dxaxpd
	dw	_lock,prefd
	dw	_grp,invd
	dw	_repnz,prefd
	dw	_rep,prefd
	dw	_hlt,endl
	dw	_cmc,endl
	dw	_grp,g03d
	dw	_grp,g03d
	dw	_clc,endl
	dw	_stc,endl
	dw	_cli,endl
	dw	_sti,endl
	dw	_cld,endl
	dw	_std,endl
	dw	_grp,g04d
	dw	_grp,g04d
_g01d	dw	_add,_or,_adc,_sbb,_and,_sub,_xor,_cmp
_g02d	dw	_rol,_ror,_rcl,_rcr,_shl,_shr,_sal,_sar
_g03d	dw	_test,_test,_not,_neg,_mul,_imul,_div,_idiv
_g04d	dw	_inc,_dec,_call,_call,_jmp,_jmp,_push,_db
_disp	db	16h,1Ch
	db	16h,1Eh
	db	1Ah,1Ch
	db	1Ah,1Eh
	db	1Ch,0
	db	1Eh,0
	db	1Ah,0
	db	16h,0
_grp	db	0,0,0
regs	db	"alcldlblahchdhbhaxcxdxbxspbpsidiescsssds"
_aaa	db	3,"aaa"
_aad	db	3,"aad"
_aam	db	3,"aam"
_aas	db	3,"aas"
_adc	db	3,"adc"
_add	db	3,"add"
_and	db	3,"and"
_call	db	4,"call"
_cbw	db	3,"cbw"
_clc	db	3,"clc"
_cld	db	3,"cld"
_cli	db	3,"cli"
_cmc	db	3,"cmc"
_cmp	db	3,"cmp"
_cmpsb	db	5,"cmpsb"
_cmpsw	db	5,"cmpsw"
_cwd	db	3,"cwd"
_daa	db	3,"daa"
_das	db	3,"das"
_db	db	2,"db"
_dec	db	3,"dec"
_div	db	3,"div"
_hlt	db	3,"hlt"
_idiv	db	4,"idiv"
_imul	db	4,"imul"
_in	db	2,"in"
_inc	db	3,"inc"
_int	db	3,"int"
_into	db	4,"into"
_iret	db	4,"iret"
_ja	db	2,"ja"
_jc	db	2,"jc"
_jcxz	db	4,"jcxz"
_jg	db	2,"jg"
_jl	db	2,"jl"
_jmp	db	3,"jmp"
_jna	db	3,"jna"
_jnc	db	3,"jnc"
_jng	db	3,"jng"
_jnl	db	3,"jnl"
_jno	db	3,"jno"
_jnp	db	3,"jnp"
_jns	db	3,"jns"
_jnz	db	3,"jnz"
_jo	db	2,"jo"
_jp	db	2,"jp"
_js	db	2,"js"
_jz	db	2,"jz"
_lahf	db	4,"lahf"
_lds	db	3,"lds"
_lea	db	3,"lea"
_les	db	3,"les"
_lock	db	4,"lock"
_lodsb	db	5,"lodsb"
_lodsw	db	5,"lodsw"
_loop	db	4,"loop"
_loopnz	db	6,"loopnz"
_loopz	db	5,"loopz"
_mov	db	3,"mov"
_movsb	db	5,"movsb"
_movsw	db	5,"movsw"
_mul	db	3,"mul"
_neg	db	3,"neg"
_nop	db	3,"nop"
_not	db	3,"not"
_or	db	2,"or"
_out	db	3,"out"
_pop	db	3,"pop"
_popf	db	4,"popf"
_push	db	4,"push"
_pushf	db	5,"pushf"
_rcl	db	3,"rcl"
_rcr	db	3,"rcr"
_rep	db	3,"rep"
_repnz	db	5,"repnz"
_ret	db	3,"ret"
_rol	db	3,"rol"
_ror	db	3,"ror"
_sahf	db	4,"sahf"
_sal	db	3,"sal"
_salc	db	4,"salc"
_sar	db	3,"sar"
_sbb	db	3,"sbb"
_scasb	db	5,"scasb"
_scasw	db	5,"scasw"
_shl	db	3,"shl"
_shr	db	3,"shr"
_stc	db	3,"stc"
_std	db	3,"std"
_sti	db	3,"sti"
_stosb	db	5,"stosb"
_stosw	db	5,"stosw"
_sub	db	3,"sub"
_test	db	4,"test"
_wait	db	4,"wait"
_xchg	db	4,"xchg"
_xlatb	db	5,"xlatb"
_xor	db	3,"xor"
amsg	db	"U72  8086 disassembler  Version 1.0  "
	db	"Copyright (c) 2002, 2006 PC-72"
	db	0Dh,0Ah,0Dh,0Ah,24h
usage	db	"Syntax:  U72 infile[.COM] [outfile[.ASM]]",0Dh,0Ah,24h
asmm1	db	"Reading: $"
asmm2	db	0Ch dup(20h),0Dh,0Ah,24h
asmm3	db	"Writing: $"
done	db	"Done",0Dh,0Ah,24h
emB	db	"File I/O error$"
input	db	40h dup(?)
output	db	80h dup(?)
element	db	40h dup(?)
