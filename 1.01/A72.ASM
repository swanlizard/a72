	org	100h
main:	mov	ah,9
	mov	dx,offset amsg
	int	21h
	call	init
	call	cmdlin
	jnc	ginf
	mov	ah,9
	mov	dx,offset usage
	int	21h
	ret
ginf:	mov	ah,9
	mov	dx,offset asmm1
	int	21h
	mov	si,offset infn
	call	wfn
	mov	ax,3D00h
	mov	dx,offset infn
	int	21h
	jc	mierr
	mov	[infile],ax
	test	byte ptr [func],10h
	jz	unasm1
	call	asmf
	or	word ptr [errs],0
	jnz	errnum
	mov	ax,4200h
	xor	cx,cx
	xor	dx,dx
	mov	bx,[infile]
	int	21h
unasm1:	mov	ah,9
	mov	dx,offset asmm3
	int	21h
	mov	si,offset outfn
	call	wfn
	mov	ah,3Ch
	xor	cx,cx
	mov	dx,offset outfn
	int	21h
	jc	moerr
	mov	[outfile],ax
	test	byte ptr [func],10h
	jz	unasm2
	xor	byte ptr [func],0Eh
	call	asmf
	or	word ptr [errs],0
	jnz	errnum
	jmp	short over
unasm2:	call	disf
over:	mov	ah,3Eh
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
init:	mov	byte ptr [func],0
	mov	word ptr [symbs],0
	mov	si,80h
	cld
	lodsb
	xor	ah,ah
	add	si,ax
	mov	[si],ah
	mov	si,81h
	ret
cmdlin:	mov	di,offset element
	call	bss
	mov	bx,si
	mov	si,offset element
	mov	dx,offset usage+14h
	call	fspec
	jc	cmdl0
	mov	byte ptr [func],19h
	stc
	call	case
	mov	di,offset infn
	xor	ah,ah
	lodsb
	mov	cx,ax
	rep	movsb
	mov	[di],ah
	mov	di,offset infn
	mov	al,2Eh
	mov	cx,9
	repnz	scasb
	dec	di
	mov	ax,8
	sub	ax,cx
	mov	cx,4
	mov	si,offset usage+23h
	rep	cmpsb
	jnz	aflag
	and	byte ptr [func],0E3h
aflag:	mov	si,bx
	mov	di,offset element
	call	bss
	mov	bx,si
	mov	si,offset element
	mov	dx,offset usage+23h
	call	fspec
	jc	cmdl1
	stc
	call	case
	mov	di,offset outfn
	xor	ah,ah
	lodsb
	mov	cx,ax
	rep	movsb
	mov	[di],ah
	clc
	ret
cmdl1:	cld
	mov	cx,ax
	mov	si,offset infn
	mov	di,offset outfn
	rep	movsb
	mov	si,offset usage+14h
	test	byte ptr [func],10h
	jz	cmdl2
	add	si,0Fh
cmdl2:	movsw
	movsw
	mov	byte ptr [di],0
	clc
	ret
cmdl0:	stc
	ret
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
wfn:	cld
	mov	di,si
	mov	cx,0Ch
	xor	al,al
	repnz	scasb
	neg	cx
	add	cx,0Ch
	mov	di,offset asmm2
	rep	movsb
	mov	al,24h
	stosb
	mov	ah,9
	mov	dx,offset asmm2
	int	21h
	mov	ah,9
	mov	dx,offset done+4
	int	21h
	ret
bss:	cld
	push	ax
bssls:	lodsb
	cmp	al,20h
	jz	bssls
	cmp	al,9
	jz	bssls
	dec	si
	push	di
	inc	di
bssl:	mov	al,[si]
	cmp	al,21h
	jc	bsse
	movsb
	jmp	short bssl
bsse:	mov	ax,di
	pop	di
	sub	ax,di
	dec	ax
	mov	[di],al
	cmp	al,1
	pop	ax
	ret
rl:	mov	ax,4200h
	mov	cx,word ptr [count+2]
	mov	dx,word ptr [count]
	mov	bx,[infile]
	int	21h
	jc	rl0
	mov	ah,3Fh
	mov	cx,80h
	mov	dx,offset input
	mov	bx,[infile]
	int	21h
	jc	rl0
	or	ax,ax
	jz	rl0
	mov	cx,ax
	mov	di,offset input
	mov	al,0Dh
	cld
	repnz	scasb
	lea	ax,[di-input]
	cmp	ax,80h
	jnc	rle
	inc	word ptr [ln]
	cmp	byte ptr [di],0Ah
	jnz	rle
	inc	ax
rle:	add	word ptr [count],ax
	adc	word ptr [count+2],0
	ret
rl0:	xor	ax,ax
	ret
wr:	test	byte ptr [func],2
	jnz	wr1
	mov	word ptr [usize],0
	ret
wr1:	mov	cx,word ptr [index]
	jcxz	wlx
	mov	si,offset index+2
wroutl:	lodsw
	push	si
	mov	si,ax
	lodsb
	test	al,80h
	jz	wle
	test	al,40h
	jz	wrou
wrbin:	or	word ptr [usize],0
	jz	wrnbin
	mov	byte ptr [wadj],0
wrul:	mov	ah,40h
	mov	cx,1
	mov	dx,offset wadj
	mov	bx,[outfile]
	int	21h
	dec	word ptr [usize]
	jnz	wrul
wrnbin:	push	cx
	and	al,0Fh
	mov	cl,al
	lodsw
	mov	di,ax
	lodsb
	xor	ah,ah
	shl	ax,cl
	mov	bp,ax
wrbl:	mov	ah,40h
	mov	cx,bp
	mov	dx,si
	mov	bx,[outfile]
	int	21h
	dec	di
	jnz	wrbl
	pop	cx
	jmp	short wle
wrou:	push	cx
	and	al,0Fh
	mov	cl,al
	lodsw
	shl	ax,cl
	mov	cx,ax
	lodsb
	xor	ah,ah
	mul	cx
	add	[usize],ax
	pop	cx
wle:	pop	si
	loop	wroutl
wlx:	ret
asmf:	mov	di,offset pc
	xor	ax,ax
	mov	cx,6
	rep	stosw
	mov	word ptr [inclev],0
asmfl:	call	rl
	or	ax,ax
	jz	asmf0
	call	asm
	call	wr
	jmp	short asmfl
asmf0:	or	word ptr [inclev],0
	jnz	asmf1
	ret
asmf1:	mov	ah,3Eh
	mov	bx,[infile]
	int	21h
	mov	cx,3
	mov	si,word ptr [inclev]
	shl	si,cl
	add	si,offset inclev
	lodsw
	mov	[infile],ax
	mov	di,offset ln
	rep	movsw
	dec	word ptr [inclev]
	mov	ah,9
	mov	dx,offset inco
	int	21h
	jmp	short asmfl
	ret
asm:	mov	word ptr [index],0
	mov	word ptr [output],0
	mov	word ptr [rsize],1
	mov	word ptr [next],offset input
	mov	[stk],sp
	xor	ax,ax
	mov	di,offset flags
	mov	cx,15
	cld
	rep	stosb
asml:	call	gn
	jnc	asm1
	ret
asm1:	mov	di,offset i8086
	call	sl
	jnc	isgood
	mov	ah,17h
isgood:	mov	[opcode],al
	or	byte ptr [flags],20h
	mov	bl,ah
	xor	bh,bh
	shl	bx,1
	lea	bx,[bx+ihdl]
	call	[bx]
	call	gn
	jnc	asmx
	or	byte ptr [flags],0
	jnz	write
	or	word ptr [index],0
	jnz	dar
	ret
asmx:	mov	al,9
	jmp	fail
write:	mov	di,offset output
	mov	word ptr [index],1
	mov	word ptr [index+2],di
	mov	al,0C0h
	stosb
	mov	ax,[rsize]
	stosw
	inc	di
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
	sub	ax,offset output+4
	mov	[output+3],al
	jmp	short wrd
dar:	mov	cx,word ptr [index]
	mov	si,cx
	shl	si,1
	add	si,offset index
darl:	std
	lodsw
	mov	bx,ax
	test	byte ptr [bx],40h
	jz	dard
	dec	cx
	jnz	darl
	jmp	short wrd
dard:	mov	si,offset index+2
ddl:	cld
	lodsw
	mov	bx,ax
	and	byte ptr [bx],0BFh
	loop	ddl
wrd:	mov	si,offset output
	mov	bx,word ptr [index]
wrdat:	cld
	lodsb
	test	al,80h
	jz	wrde
	mov	cl,al
	and	cl,0Fh
	lodsw
	shl	ax,cl
	mov	cx,ax
	lodsb
	xor	ah,ah
	add	si,ax
	mul	cx
	add	[pc],ax
	dec	bx
	jnz	wrdat
wrde:	ret
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
isnum:	cmp	al,30h
	jc	isnum0
	cmp	al,39h
	ja	isnum0
	clc
	ret
isnum0:	stc
	ret
cc:	cld
	push	ax
	push	dx
	push	di
	inc	di
	mov	dx,di
ccl:	mov	al,[si]
	mov	ah,al
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
	cmp	al,ah
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
	cmp	al,1
	pop	ax
	ret
case:	push	ax
	push	bx
	salc
	and	al,20h
	mov	ah,al
	mov	bl,[si]
	xor	bh,bh
casel:	mov	al,[bx+si]
	or	al,20h
	cmp	al,61h
	jc	casenl
	cmp	al,7Ah
	ja	casenl
	xor	al,ah
	mov	[bx+si],al
casenl:	dec	bx
	jnz	casel
	pop	bx
	pop	ax
	ret
gn:	mov	si,[next]
	push	di
	mov	di,offset element
	call	cc
	pop	di
	pushf
	mov	[next],si
	mov	si,offset element
	popf
	ret
tgn:	mov	si,[next]
	mov	di,offset element
	push	di
	call	cc
	pop	si
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
sa1:	push	bx
	xor	bh,bh
	mov	cx,[di]
	inc	word ptr [di]
	add	di,2
	jcxz	sa0
sa2:	mov	bl,[di]
	lea	di,[bx+di+3]
	loop	sa2
sa0:	mov	cl,[si]
	xor	ch,ch
	inc	cx
	cld
	rep	movsb
	stosw
	pop	bx
	clc
	ret
gl:	test	byte ptr [func],4
	jnz	gl1
	mov	ax,[pc]
	add	ax,[vorg]
	clc
	ret
gl1:	push	di
	mov	di,offset symbs
	call	sl
	pop	di
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
val:	cld
	xor	ah,ah
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
	jnc	val10
	cmp	al,68h
	jz	val16
	cmp	al,62h
	jz	val2
	xor	ax,ax
	ret
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
wa:	mov	al,[args+2]
	mov	ah,al
	mov	cl,4
	shr	ah,cl
	and	ax,0F0Fh
	jz	waz
	or	al,al
	jz	walz
	or	ah,ah
	jz	wahz
	cmp	al,ah
	jz	wahz
wa0:	mov	al,6
	jmp	fail
walz:	cmp	al,ah
	jz	waz
	mov	al,ah
wahz:	cmp	al,2
	ja	wa0
	dec	ax
waz:	mov	[wadj],al
	ret
comma:	call	gn
	jc	comma0
	cmp	word ptr [si],2C01h
	jnz	comma0
	ret
comma0:	mov	al,8
	jmp	fail
borw:	cmp	ax,6204h
	jz	borw1
	cmp	ax,7704h
	jz	borw2
	cmp	ax,6405h
	jz	borw3
borw0:	stc
	ret
borw1:	mov	di,offset _byte
	jmp	short borws
borw2:	mov	di,offset _word
	jmp	short borws
borw3:	mov	di,offset _dword
borws:	mov	cl,[di]
	xor	ch,ch
	inc	cl
	push	si
	rep	cmpsb
	pop	si
	jnz	borw0
	mov	cl,[di]
	mov	[wadj],cl
	call	gn
	jc	borwf
igptr:	cmp	word ptr [si],7003h
	jnz	borwe
	cmp	word ptr [si+2],7274h
	jnz	borwe
	call	gn
	jc	borwf
borwe:	clc
	ret
borwf:	mov	al,8
	jmp	fail
mmodrm:	or	byte ptr [flags],10h
	mov	ax,word ptr [args]
	mov	cl,4
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
	ror	ax,cl
	and	ax,0F0Fh
	cmp	al,1
	jz	mwr
	cmp	al,2
	jz	mwm
	ret
mwrs:	or	byte ptr [modrm],0C0h
mwrm:	rol	ah,cl
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
re:	xor	bx,bx
	cmp	ax,2401h
	jz	recu
	cmp	ax,2D01h
	jz	remi
	cmp	ax,6F06h
	jz	reof
	cmp	ax,7203h
	jz	rere
	xchg	al,ah
	call	isnum
	jnc	reim
	call	isltr
	jnc	relb
re0:	xor	al,al
	jmp	fail
re4:	mov	al,4
	jmp	fail
re8:	mov	al,8
	jmp	fail
recu:	mov	ax,[pc]
	add	ax,[vorg]
	mov	bx,304h
	ret
remi:	call	gn
	jc	re8
	mov	al,[si+1]
	call	isnum
	jc	re0
	call	val
	neg	ax
	mov	bx,4
	ret
reof:	cmp	word ptr [si+2],6666h
	jnz	relb
	cmp	word ptr [si+4],6573h
	jnz	relb
	cmp	byte ptr [si+6],74h
	jnz	relb
	call	gn
	jc	re8
	cmp	word ptr [si],2401h
	jz	recu
relb:	call	gl
	jc	re4
	mov	bx,104h
	ret
reim:	call	val
	mov	bx,4
	ret
rere:	cmp	word ptr [si+2],6C65h
	jnz	relb
	call	gn
	jc	re8
	call	gl
	jc	re4
	sub	ax,[pc]
	sub	ax,[vorg]
	mov	bx,204h
	ret
rq:	cmp	ah,22h
	jz	rqm
	cmp	ah,27h
	jz	rqm
	stc
	ret
rqm:	cmp	al,2
	jna	rq8
	mov	cl,al
	xor	ch,ch
	push	si
	add	si,cx
	mov	cl,[si]
	pop	si
	cmp	cl,ah
	jnz	rq1
	inc	si
	sub	al,2
	mov	[si],al
	clc
	ret
rq1:	mov	al,1
	jmp	fail
rq8:	mov	al,8
	jmp	fail
ra8f:	mov	al,8
	jmp	fail
ra:	call	gn
	jc	ra8f
	xor	dx,dx
	mov	byte ptr [wadj],0
	mov	byte ptr [op],0
	cmp	byte ptr [si],2
	jnz	rarg
	mov	ax,[si+1]
	mov	cx,14h
	mov	di,offset regs+26h
	std
	repnz	scasw
	jz	rregs
rarg:	mov	ax,[si]
	cmp	ax,5B01h
	jz	rdisp
	call	borw
	jnc	rbwps
	call	rq
	jnc	rquos
	call	re
	jmp	riax
rregs:	jmp	rreg
rbwps:	jmp	rbwp
rquos:	jmp	rquo
rdminu:	call	gn
	mov	al,[si+1]
	call	isnum
	jc	raf
	call	val
	neg	ax
	jmp	short rdtpm
rdps:	and	byte ptr [op],0FDh
	not	ah
	and	ah,2
	or	[op],ah
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
	jz	rdminu
	call	isnum
	jnc	rdimmd
	call	isltr
	jnc	lbd
raf:	mov	al,1
	jmp	fail
sid:	shl	dl,1
did:	shl	dl,1
bpd:	shl	dl,1
bxd:	test	dh,dl
	jnz	rdfail
	or	dh,dl
	test	byte ptr [op],2
	jz	rdpm
rdimmd:	call	val
rdtpm:	or	byte ptr [flags],8
	test	byte ptr [op],2
	jz	dispdp
	neg	ax
dispdp:	add	[disp],ax
rdpm:	call	gn
	mov	ax,[si]
	cmp	ax,2D01h
	jz	rdps
	cmp	ax,2B01h
	jz	rdps
	cmp	ax,5D01h
	jnz	rdfail
	mov	al,dh
	mov	bx,offset rm
	xlatb
	test	al,0F0h
	jnz	rdfail
	mov	dh,al
	mov	dl,2	
	jmp	warg
lbd:	call	gl
	jc	lbdf
	or	byte ptr [flags],4
	jmp	short rdtpm
lbdf:	mov	al,4
	jmp	fail
rdfail:	mov	al,2
	jmp	fail
rbwp:	mov	ax,[si]
	cmp	al,2
	jz	rregp
	cmp	ax,5B01h
	jnz	srf
	jmp	rdisp
rregp:	mov	ax,[si+1]
	mov	cx,4
	mov	di,offset regs+26h
	std
	repnz	scasw
	jnz	srf
	mov	dh,cl
	call	tgn
	cmp	word ptr [si],3A01h
	jz	rsp
srf:	mov	al,2
	jmp	fail
rreg:	xor	dl,dl
	mov	dh,cl
	and	dh,7
	or	byte ptr [wadj],1
	cmp	cl,8
	jc	rgpr
	shl	byte ptr [wadj],1
	cmp	cl,10h
	jc	rgpr
	call	tgn
	cmp	word ptr [si],3A01h
	jnz	rsr
rsp:	mov	cl,3
	shl	dh,cl
	add	dh,26h
	mov	[segpref],dh
	or	byte ptr [flags],40h
	call	gn
	call	gn
	cmp	word ptr [si],5B01h
	jnz	srf
	xor	dx,dx
	mov	byte ptr [wadj],0
	jmp	rdisp
rsr:	or	dl,2
rgpr:	or	dl,1
	jmp	warg
ripsf:	mov	al,8
	jmp	fail
rips:	and	byte ptr [op],0FEh
	shr	ah,1
	not	ah
	and	ah,1
	or	[op],ah
	call	gn
	call	gn
	jc	ripsf
	mov	ax,[si]
	call	re
riax:	or	dl,dl
	jnz	riax1
	mov	dx,bx
riax1:	or	byte ptr [flags],2
	test	byte ptr [op],1
	jz	rimp
	neg	ax
rimp:	add	[imm],ax
	call	tgn
	mov	ax,[si]
	cmp	ax,2D01h
	jz	rips
	cmp	ax,2B01h
	jz	rips
	jmp	warg
rquo:	lodsb
	cmp	al,2
	ja	rquo7
	mov	dx,404h
	or	byte ptr [flags],3
	mov	di,offset imm
	movsw
	cmp	al,1
	jna	rquob
	jmp	warg
rquob:	and	byte ptr [flags],0FEh
	mov	byte ptr [imm+1],0
	jmp	warg
rquo7:	mov	al,7
	jmp	fail
warg:	mov	cl,4
	mov	al,[wadj]
	test	byte ptr [args],0Fh
	jz	warg1
	shl	al,cl
	shl	dx,cl
warg1:	or	[args+2],al
	or	word ptr [args],dx
	mov	ax,[disp]
	or	ax,ax
	jns	warg2
	cmp	ax,0FF80h
	salc
	and	al,4
	or	[flags],al
	ret
warg2:	cmp	ax,80h
	cmc
	salc
	and	al,4
	or	[flags],al
	ret
norf:	mov	ax,[si]
	cmp	ax,6603h
	jz	norff
	cmp	ax,6E04h
	jz	norfn
	cmp	ax,7305h
	jz	norfs
norfe:	xor	ax,ax
	ret
norff:	mov	di,offset _far
	jmp	short norfl
norfn:	mov	di,offset _near
	jmp	short norfl
norfs:	mov	di,offset _short
norfl:	mov	al,[di]
	xor	ah,ah
	mov	cx,ax
	inc	cx
	push	si
	cld
	rep	cmpsb
	pop	si
	jnz	norfe
	ret
fail:	cld
	inc	word ptr [errs]
	mov	word ptr [index],0
	mov	byte ptr [output],0
	mov	sp,[stk]
	xor	ah,ah
	shl	ax,1
	add	ax,offset errm
	mov	di,ax
	mov	ah,9
	mov	dx,[di]
	int	21h
	test	byte ptr [func],1
	jz	fail0
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
	ret
fail0:	mov	ah,9
	mov	dx,offset done+4
	int	21h
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
	xor	al,al
	jmp	fail
g1ri:	and	ah,7
	jz	g1ai
g1mi:	mov	al,[opcode]
	or	[modrm],al
	mov	al,[wadj]
	or	[flags],al
	or	al,80h
	mov	[opcode],al
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
	jnz	g2f
	lodsb
	cmp	al,6Ch
	jnz	g2f
	add	byte ptr [opcode],2
g2n:	jmp	mmodrm
g2f:	mov	al,0
	jmp	fail
g2mp:	mov	al,8
	jmp	fail
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
	or	ah,ah
	jz	g5i0
	cmp	ah,1
	jz	g5i1
	cmp	ah,2
	jz	g5i2
	cmp	ah,3
	jnz	g5f0
	add	dx,2
g5i1:	sub	dx,[pc]
	sub	dx,[vorg]
g5i2:	sub	dx,2
	mov	[imm],dx
g5i0:	mov	ax,dx
	or	ah,ah
	jnz	g5inz
	cbw
g5inz:	or	ax,ax
	jns	g5ins
	cmp	ax,0FF80h
	jc	g5f5
	ret
g5ins:	cmp	ax,80h
	jnc	g5f5
	ret
g5f0:	mov	al,0
	jmp	fail
g5f5:	mov	al,5
	jmp	fail
g6:	call	tgn
	jc	g6f8
	call	norf
	cmp	al,3
	jz	g6f
	cmp	al,4
	jz	g6n
	cmp	al,5
	jz	g6s
g6l:	call	ra
	mov	ax,word ptr [args]
	cmp	al,4
	jz	g6i
	cmp	al,1
	jz	g6rm
	cmp	al,2
	jnz	g6f0
g6rm:	mov	al,[args+2]
	or	al,al
	jz	g6rn
	cmp	al,2
	jz	g6rn
	cmp	al,3
	jz	g6rf
	mov	al,6
	jmp	fail
g6s:	call	gn
	call	igptr
	cmp	byte ptr [opcode],20h
	jnz	g6f0
	mov	byte ptr [opcode],0EBh
	jmp	g5
g6f:	or	byte ptr [opcode],8
g6n:	call	gn
	call	igptr
	jmp	short g6l
g6rf:	or	byte ptr [opcode],8
g6rn:	mov	al,[opcode]
	or	[modrm],al
	mov	byte ptr [opcode],0FFh
	jmp	mmodrm
g6f8:	mov	al,8
	jmp	fail
g6f0:	xor	al,al
	jmp	fail
g6i:	call	tgn
	cmp	word ptr [si],3A01h
	jz	g6if
	mov	al,[opcode]
	test	al,8
	jnz	g6f8
	mov	cl,3
	rol	al,cl
	and	al,1
	add	al,0E8h
	mov	[opcode],al
	mov	dx,[imm]
	or	ah,ah
	jz	g6i0
	cmp	ah,1
	jz	g6i1
	cmp	ah,2
	jz	g6i2
	cmp	ah,3
	jnz	g6f0
	add	dx,3
g6i1:	sub	dx,[pc]
	sub	dx,[vorg]
g6i2:	sub	dx,3
	mov	[imm],dx
g6i0:	or	byte ptr [flags],3
	ret
g6if:	call	gn
	call	gn
	jc	g6f0
	mov	al,[si+1]
	call	isnum
	jc	g6f0
	call	val
	mov	[disp],ax
	or	byte ptr [flags],0Fh
	xor	al,al
	xchg	al,byte ptr [opcode]
	cmp	al,20h
	jc	g6iop
	add	byte ptr [opcode],50h
g6iop:	add	byte ptr [opcode],9Ah
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
	mov	cl,3
	shl	al,cl
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
	jnc	g0Bh1
	ret
g0Bh1:	mov	al,[si+1]
	call	isnum
	jc	g0Bh2
g0Bhv:	call	val
	mov	[imm],ax
	or	byte ptr [flags],3
	dec	byte ptr [opcode]
	ret
g0Bh2:	call	norf
	cmp	al,3
	jz	g0Bhf
	cmp	al,4
	jz	g0Bhn
	xor	al,al
	jmp	fail
g0Bhf:	mov	byte ptr [opcode],0CBh
	call	gn
	jnc	g0Bhg
	ret
g0Bhn:	call	gn
	jnc	g0Bhg
	ret
g0Bhg:	mov	al,[si+1]
	call	isnum
	jnc	g0Bhv
	xor	al,al
	jmp	fail
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
g0Dhs:	mov	cl,3
	and	ah,cl
	shl	ah,cl
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
g0Ehs:	mov	cl,3
	and	ah,cl
	shl	ah,cl
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
g10har:	mov	cl,4
	shr	ah,cl
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
	mov	di,offset output+4
	mov	word ptr [bp],0
	mov	word ptr [bp+2],0
	mov	word ptr [index],0
g14hg:	cld
	call	gn
	jc	g14hf8
	mov	ax,[si]
	call	rq
	jnc	g14hs
	cmp	ax,3F01h
	jz	g14hu
	call	re
	jmp	short g14hd
g14hs:	mov	al,0C0h
	mov	cx,1
	call	ubp
	lodsb
	add	[bp+3],al
	xor	ah,ah
	mov	cx,ax
	rep	movsb
	jmp	short g14hc
g14hu:	mov	al,[opcode]
	or	al,80h
	mov	cx,1
	xor	dx,dx
	jmp	short g14hv
g14hd:	mov	cx,1
	mov	dx,ax
	push	di
	call	tgn
	pop	di
	mov	ax,[si]
	cmp	ax,6403h
	jz	g14hdu
	cmp	ax,2801h
	jz	g14hp
	mov	al,[opcode]
	or	al,0C0h
g14hv:	call	ubp
	call	udi
g14hc:	call	gn
	jc	g14he
	cmp	word ptr [si],2C01h
	jnz	g14hf0
	jmp	g14hg
g14he:	ret
g14hf0:	xor	al,al
	jmp	fail
g14hf1:	mov	al,1
	jmp	fail
g14hf8:	mov	al,8
	jmp	fail
g14hdu:	cmp	word ptr [si+2],7075h
	jnz	g14hf1
	call	gn
g14hp:	call	gn
	cmp	word ptr [si],2801h
	jnz	g14hf1
	call	gn
	jc	g14hf8
	cmp	bx,4
	jnz	g14hf1
	mov	ax,[si]
	mov	bl,[opcode]
	or	bl,80h
	mov	cx,dx
	xor	dx,dx
	cmp	ax,3F01h
	jz	g14hdd
	xchg	ah,al
	call	isnum
	jc	g14hf0
	or	bl,40h
	call	val
	mov	dx,ax
g14hdd:	mov	al,bl
	call	ubp2
	call	udi
	call	gn
	jc	g14hf1
	mov	bp,di
	add	di,4
	mov	byte ptr [bp],0
	cmp	word ptr [si],2901h
	jnz	g14hf1
	jmp	g14hc
ubp:	cmp	al,[bp]
	jz	ubp0
ubp2:	or	byte ptr [bp],0
	jz	ubp1
	mov	bp,di
	add	di,4
ubp1:	mov	[bp],al
	mov	[bp+1],cx
	mov	byte ptr [bp+3],0
	inc	word ptr [index]
	mov	bx,word ptr [index]
	shl	bx,1
	mov	word ptr [bx+index],bp
ubp0:	ret
udi:	inc	byte ptr [bp+3]
	mov	cl,[opcode]
	mov	ax,1
	shl	ax,cl
	mov	[di],dx
	cmp	ax,2
	ja	udi1
	add	di,ax
	ret
udi1:	sub	ax,2
	inc	di
	inc	di
	mov	cx,ax
	mov	ax,dx
	rcl	ax,1
	salc
	rep	stosb
	ret
g15h:	mov	byte ptr [flags],0
	call	ra
	cmp	byte ptr [args],4
	jz	g15h1
g15hf:	mov	al,1
	jmp	fail
g15h1:	cmp	byte ptr [func],2
	jnz	g15h0
	or	byte ptr [temp],0
	jz	g15hf
	mov	si,offset temp
	mov	di,offset symbs
	call	sl
	mov	ax,[imm]
	stosw
g15h0:	ret
g16h:	mov	byte ptr [flags],0
	mov	si,[next]
	mov	di,offset element
	call	bss
	mov	[next],si
	mov	si,di
	mov	dx,offset _grp
	call	fspec
	jc	g16h0
	mov	ah,9
	mov	dx,offset asmm4
	int	21h
	mov	si,offset element
	stc
	call	case
	inc	si
	call	wfn
	mov	ax,3D00h
	mov	dx,offset element+1
	int	21h
	jc	g16h0
	inc	word ptr [inclev]
	mov	di,word ptr [inclev]
	mov	cx,3
	shl	di,cl
	add	di,offset inclev
	xchg	ax,[infile]
	stosw
	push	si
	mov	si,offset ln
	rep	movsw
	pop	si
	mov	cx,3
	xor	ax,ax
	mov	di,offset ln
	rep	stosw
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
g17h0:	cmp	byte ptr [si],2
	jnz	g17h1
	mov	ax,[si+1]
	mov	di,offset regs+26h
	mov	cl,14h
	std
	repnz	scasw
	jnz	g17h1
	cmp	cl,10h
	jc	g17hfw
	call	gn
	cmp	word ptr [si],3A01h
	jnz	g17hfw
	mov	ch,3
	xchg	cl,ch
	shl	ch,cl
	add	ch,26h
	mov	[opcode],ch
	or	byte ptr [flags],20h
	ret
g17h1:	mov	cl,[si]
	xor	ch,ch
	inc	cx
	mov	di,offset temp
	cld
	rep	movsb
	call	tgn
	jc	g17hf
	cmp	word ptr [si],3A01h
	jnz	g17h3
	call	gn
g17h3:	test	byte ptr [func],8
	jz	g17h2
	mov	ax,[pc]
	add	ax,[vorg]
	mov	si,offset temp
	mov	di,offset symbs
	call	sa
	jnc	g17h2
	mov	al,0Ah
	jmp	fail
g17h2:	mov	sp,[stk]
	jmp	asml
g17hf:	mov	al,3
	jmp	fail
g17hfw:	mov	al,0Ch
	jmp	fail
g18h:	call	ra
	call	comma
	call	ra
	mov	ax,word ptr [args]
	cmp	al,14h
	jz	g18hrm
	cmp	al,24h
	jz	g18hrm
g18hf:	xor	al,al
	jmp	g18hf
g18hrm:	mov	ax,[imm]
	cmp	ax,3Fh
	jna	g18hg
	mov	al,7
	jmp	fail
g18hg:	mov	cl,3
	mov	ah,al
	ror	al,cl
	and	ax,707h
	rol	ah,cl
	or	word ptr [opcode],ax
	and	byte ptr [flags],0FCh
	jmp	mmodrm
g19h:	mov	al,0Ch
	jmp	fail
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
	call	disasm
	call	wrasm
	jnc	disfl
disf0:	ret
disasm:	cld
	mov	[stk],sp
	mov	bp,offset output
	mov	bx,offset input
	mov	di,bp
	mov	si,bx
	inc	di
	inc	si
	mov	byte ptr [bp],0
	mov	byte ptr [segpref],0
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
	xor	ch,ch
	mov	cl,[si]
	jcxz	dsa0
	inc	si
	rep	movsb
dsa0:	pop	si
	lodsw
	pop	si
	call	ax
dsax:	mov	dl,[segpref]
	or	dl,dl
	jz	dsnsp
	push	si
	push	di
	dec	di
	mov	cx,di
	sub	cx,bp
	mov	si,di
	add	di,0Fh
	std
	rep	movsb
	mov	di,bp
	inc	di
	mov	al,9
	cld
	stosb
	call	wspr
	mov	ax,3B09h
	stosw
	mov	ax,[pc]
	dec	ax
	push	ax
	mov	al,ah
	call	halx
	stosw
	pop	ax
	call	halx
	stosw
	mov	al,20h
	stosb
	mov	al,dl
	call	halx
	stosw
	mov	ax,0A0Dh
	stosw
	pop	di
	pop	si
	add	di,0Fh
dsnsp:	mov	ax,si
	sub	ax,bx
	dec	ax
	add	[pc],ax
	mov	ax,di
	sub	ax,bp
	dec	ax
	add	[bp],al
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
wreg:	cld
	push	si
	mov	si,ax
	and	si,38h
	shr	si,1
	shr	si,1
	add	si,offset regs
	add	si,word ptr [wadj]
	movsw
	pop	si
	ret
wdisp:	cld
	cmp	al,0C0h
	jc	wdrm
	push	si
	mov	si,ax
	and	si,7
	shl	si,1
	add	si,offset regs
	add	si,word ptr [wadj]
	movsw
	pop	si
	ret
wdrm:	push	ax
	xor	ch,ch
	call	wspr
	mov	ax,5Bh
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
wd01:	lodsb
	cbw
wdpm:	or	ax,ax
	js	wdm
	jz	wdx
	mov	byte ptr [di],2Bh
	inc	di
wdm:	call	whaxs
wdx:	mov	al,5Dh
	stosb
	pop	ax
	ret
wptr:	cmp	al,0C0h
	jc	wptr1
	ret
wptr1:	push	ax
	or	byte ptr [wadj],0
	jz	wptrb
	mov	ax,6F77h
	stosw
	mov	ax,6472h
	stosw
	jmp	short wptrw
wptrb:	mov	ax,7962h
	stosw
	mov	ax,6574h
	stosw
wptrw:	mov	ax,7020h
	stosw
	mov	ax,7274h
	stosw
	mov	al,20h
	stosb
	pop	ax
	ret
wspr:	cld
	mov	al,[segpref]
	or	al,al
	jz	wspr0
	xor	ah,ah
	sub	al,26h
	shr	ax,1
	shr	ax,1
	add	ax,offset regs+20h
	push	si
	mov	si,ax
	movsw
	pop	si
	mov	byte ptr [segpref],0
	mov	al,3Ah
	stosb
wspr0:	ret
grp:	mov	al,byte ptr [si]
	shr	al,1
	shr	al,1
	and	al,0Eh
	xor	ah,ah
	mov	si,ax
	ret
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
sprefd:	mov	al,[opcode]
	mov	[segpref],al
	mov	sp,[stk]
	dec	di
	jmp	dsas
endl:	mov	ax,3B09h
	stosw
	mov	ax,[pc]
	add	ax,[vorg]
	push	ax
	mov	al,ah
	call	halx
	stosw
	pop	ax
	call	halx
	stosw
	push	si
	mov	cx,si
	sub	cx,bx
	mov	si,bx
	dec	cx
	inc	si
dops:	mov	al,20h
	stosb
	lodsb
	call	halx
	stosw
	loop	dops
	pop	si
	mov	ax,0A0Dh
	stosw
	mov	byte ptr [di],24h
	ret
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
invd:	mov	ax,6264h
	stosw
	mov	al,9
	stosb
	mov	al,[opcode]
	call	whal
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
msd:	mov	al,9
	stosb
	lodsb
	mov	word ptr [wadj],10h
	push	ax
	call	wdisp
	mov	al,2Ch
	stosb
	pop	ax
	shr	al,1
	shr	al,1
	and	ax,6
	add	ax,offset regs+20h
	push	si
	mov	si,ax
	movsw
	pop	si
	jmp	endl
smd:	mov	al,9
	stosb
	mov	word ptr [wadj],10h
	lodsb
	push	ax
	shr	al,1
	shr	al,1
	and	ax,6
	add	ax,offset regs+20h
	push	si
	mov	si,ax
	movsw
	pop	si
	mov	al,2Ch
	stosb
	pop	ax
	call	wdisp
	jmp	endl
dispd:	mov	al,9
	stosb
	lodsb
	call	wdisp
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
accmd:	mov	al,9
	stosb
	mov	ax,word ptr [wadj]
	add	ax,offset regs
	push	si
	mov	si,ax
	movsw
	pop	si
	call	wspr
	mov	ax,5B2Ch
	stosw
	lodsw
	call	whax
	mov	al,5Dh
	stosb
	jmp	endl
maccd:	call	wspr
	mov	ax,5B09h
	stosw
	lodsw
	call	whax
	mov	ax,2C5Dh
	stosw
	push	si
	mov	si,offset regs
	add	si,word ptr [wadj]
	movsw
	pop	si
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
intd:	mov	al,9
	stosb
	lodsb
	cmp	byte ptr [opcode],0CCh
	jnz	intdb
	mov	al,3
intdb:	call	whal
	jmp	endl
aamd:	mov	al,9
	stosb
	lodsb
	cmp	al,0Ah
	jz	aamd0
	call	whal
aamd0:	jmp	endl
escd:	mov	al,9
	stosb
	mov	al,[opcode]
	mov	ah,[si]
	mov	cl,3
	ror	ah,cl
	and	ax,707h
	rol	al,cl
	or	al,ah
	call	whal
	mov	al,2Ch
	stosb
	lodsb
	call	wdisp
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
relwd:	mov	ax,2409h
	stosw
	lodsw
	or	ax,ax
	js	relwdw
	mov	byte ptr [di],2Bh
	inc	di
relwdw:	call	whaxs
	jmp	endl
prefd:	mov	sp,[stk]
	jmp	dsas
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
	or	byte ptr [bx],0
	jnz	g04d1
	pop	bx
	jmp	invd
g04d1:	push	si
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
	cmp	al,4
	jz	g04dd
	cmp	al,3
	jz	g04df
	cmp	al,2
	jz	g04dd
	lodsb
	call	wptr
	call	wdisp
	jmp	endl
g04df:	mov	al,[si]
	cmp	al,0C0h
	jc	g04dm
	mov	ax,6166h
	stosw
	mov	ax,2072h
	stosw
	lodsb
	call	wdisp
	jmp	endl
g04dm:	mov	ax,7764h
	stosw
	mov	ax,726Fh
	stosw
	mov	ax,2064h
	stosw
	mov	ax,7470h
	stosw
	mov	ax,2072h
	stosw
g04dd:	lodsb
	call	wdisp
	jmp	endl
pc	dw	0
ln	dw	0
count	dd	0
usize	dw	0
errs	dw	0
infile	dw	0
outfile	dw	0
func	db	0
vorg	dw	0100h
rsize	dw	0
next	dw	0
stk	dw	0
flags	db	0
wadj	db	0,0
op	db	0
args	db	0,0,0
prefix	db	0
segpref	db	0
opcode	db	0
modrm	db	0
disp	dw	0
imm	dw	0
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
	dw	_esc,escd
	dw	_esc,escd
	dw	_esc,escd
	dw	_esc,escd
	dw	_esc,escd
	dw	_esc,escd
	dw	_esc,escd
	dw	_esc,escd
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
	dw	_repz,prefd
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
_g04d	dw	_inc,_dec,_call,_call,_jmp,_jmp,_push,_grp
_disp	db	16h,1Ch
	db	16h,1Eh
	db	1Ah,1Ch
	db	1Ah,1Eh
	db	1Ch,0
	db	1Eh,0
	db	1Ah,0
	db	16h,0
_grp	db	0,0,0
rm	db	0Eh,7,6,0FFh,5,1,3,0FFh
	db	4,0,2,0FFh,0FFh,0FFh,0FFh,0FFh
errm	dw	em0,em1,em2,em3,em4,em5,em6,em7
	dw	em8,em9,emA,emB,emC
ihdl	dw	g0,g1,g2,g3,g4,g5,g6,g7
	dw	g8,g9,g0Ah,g0Bh,g0Ch,g0Dh,g0Eh,g0Fh
	dw	g10h,g11h,g12h,g13h,g14h,g15h,g16h,g17h
	dw	g18h,g19h
regs	db	"alcldlblahchdhbhaxcxdxbxspbpsidiescsssds"
i8086	dw	84h
_aaa	db	3,"aaa",37h,0
_aad	db	3,"aad",0D5h,7
_aam	db	3,"aam",0D4h,7
_aas	db	3,"aas",3Fh,0
_adc	db	3,"adc",10h,1
_add	db	3,"add",0,1
_and	db	3,"and",20h,1
_byte	db	4,"byte",1,19h
_call	db	4,"call",10h,6
_cbw	db	3,"cbw",98h,0
_clc	db	3,"clc",0F8h,0
_cld	db	3,"cld",0FCh,0
_cli	db	3,"cli",0FAh,0
_cmc	db	3,"cmc",0F5h,0
_cmp	db	3,"cmp",38h,1
_cmpsb	db	5,"cmpsb",0A6h,0
_cmpsw	db	5,"cmpsw",0A7h,0
_cwd	db	3,"cwd",99h,0
_daa	db	3,"daa",27h,0
_das	db	3,"das",2Fh,0
_db	db	2,"db",0,14h
	db	2,"dd",2,14h
_dec	db	3,"dec",8,4
_div	db	3,"div",30h,3
	db	2,"dw",1,14h
_dword	db	5,"dword",3,19h
	db	3,"equ",0,15h
_esc	db	3,"esc",0D8h,18h
_far	db	3,"far",3,19h
_hlt	db	3,"hlt",0F4h,0
_idiv	db	4,"idiv",38h,3
_imul	db	4,"imul",28h,3
_in	db	2,"in",0E4h,11h
_inc	db	3,"inc",0,4
	db	7,"include",0,16h
_int	db	3,"int",0CDh,0Ch
_into	db	4,"into",0CEh,0
_iret	db	4,"iret",0CFh,0
_ja	db	2,"ja",77h,5
	db	3,"jae",73h,5
	db	2,"jb",72h,5
	db	3,"jbe",76h,5
_jc	db	2,"jc",72h,5
_jcxz	db	4,"jcxz",0E3h,5
	db	2,"je",74h,5
_jg	db	2,"jg",7Fh,5
	db	3,"jge",7Dh,5
_jl	db	2,"jl",7Ch,5
	db	3,"jle",7Eh,5
_jmp	db	3,"jmp",20h,6
_jna	db	3,"jna",76h,5
	db	4,"jnae",72h,5
	db	3,"jnb",73h,5
	db	4,"jnbe",77h,5
_jnc	db	3,"jnc",73h,5
	db	3,"jne",75h,5
_jng	db	3,"jng",7Eh,5
	db	4,"jnge",7Ch,5
_jnl	db	3,"jnl",7Dh,5
	db	4,"jnle",7Fh,5
_jno	db	3,"jno",71h,5
_jnp	db	3,"jnp",7Bh,5
_jns	db	3,"jns",79h,5
_jnz	db	3,"jnz",75h,5
_jo	db	2,"jo",70h,5
_jp	db	2,"jp",7Ah,5
	db	3,"jpe",7Ah,5
	db	3,"jpo",7Bh,5
_js	db	2,"js",78h,5
_jz	db	2,"jz",74h,5
_lahf	db	4,"lahf",9Fh,0
_lds	db	3,"lds",0C5h,8
_lea	db	3,"lea",8Dh,8
_les	db	3,"les",0C4h,8
_lock	db	4,"lock",0F0h,0Ah
_lodsb	db	5,"lodsb",0ACh,0
_lodsw	db	5,"lodsw",0ADh,0
_loop	db	4,"loop",0E2h,5
	db	5,"loope",0E1h,5
	db	6,"loopne",0E0h,5
_loopnz	db	6,"loopnz",0E0h,5
_loopz	db	5,"loopz",0E1h,5
_mov	db	3,"mov",0,9
_movsb	db	5,"movsb",0A4h,0
_movsw	db	5,"movsw",0A5h,0
_mul	db	3,"mul",20h,3
_near	db	4,"near",2,19h
_neg	db	3,"neg",18h,3
_nop	db	3,"nop",90h,0
_not	db	3,"not",10h,3
	db	6,"offset",0,19h
_or	db	2,"or",8,1
	db	3,"org",0,13h
_out	db	3,"out",0E6h,12h
_pop	db	3,"pop",8Fh,0Eh
_popf	db	4,"popf",9Dh,0
	db	3,"ptr",0,19h
_push	db	4,"push",30h,0Dh
_pushf	db	5,"pushf",9Ch,0
_rcl	db	3,"rcl",10h,2
_rcr	db	3,"rcr",18h,2
	db	3,"rel",0,19h
	db	3,"rep",0F3h,0Ah
	db	4,"repe",0F3h,0Ah
	db	5,"repne",0F2h,0Ah
_repnz	db	5,"repnz",0F2h,0Ah
_repz	db	4,"repz",0F3h,0Ah
_ret	db	3,"ret",0C3h,0Bh
_rol	db	3,"rol",0,2
_ror	db	3,"ror",8,2
_sahf	db	4,"sahf",9Eh,0
_sal	db	3,"sal",30h,2
_salc	db	4,"salc",0D6h,0
_sar	db	3,"sar",38h,2
_sbb	db	3,"sbb",18h,1
_scasb	db	5,"scasb",0AEh,0
_scasw	db	5,"scasw",0AFh,0
_shl	db	3,"shl",20h,2
_short	db	5,"short",1,19h
_shr	db	3,"shr",28h,2
_stc	db	3,"stc",0F9h,0
_std	db	3,"std",0FDh,0
_sti	db	3,"sti",0FBh,0
_stosb	db	5,"stosb",0AAh,0
_stosw	db	5,"stosw",0ABh,0
_sub	db	3,"sub",28h,1
_test	db	4,"test",0,0Fh
_wait	db	4,"wait",9Bh,0
_word	db	4,"word",2,19h
_xchg	db	4,"xchg",86h,10h
_xlatb	db	5,"xlatb",0D7h,0
_xor	db	3,"xor",30h,1
amsg	db	"A72  8086 assembler  Version 1.01",20h,20h
	db	"Copyright (c) 2002, 2006 PC-72"
	db	0Dh,0Ah,0Dh,0Ah,24h
usage	db	"Syntax:  A72 infile[.ASM] [outfile[.COM]]",0Dh,0Ah,24h
asmm1	db	"Reading: $"
asmm2	db	0Dh dup(20h)
asmm3	db	"Writing: $"
asmm4	db	"Including: $"
inco	db	"Over",0Dh,0Ah,24h
done	db	"Done",0Dh,0Ah,24h
errf	db	"Errors: $"
errn	db	6 dup(20h),0Dh,0Ah,24h
em0	db	"Wrong operand$"
em1	db	"Syntax error$"
em2	db	"Malformed displacement$"
em3	db	"Unrecognised instruction$"
em4	db	"Undefined symbol$"
em5	db	"Jump out of range$"
em6	db	"Operand size mismatch$"
em7	db	"Constant too large$"
em8	db	"Missing operand$"
em9	db	"Characters past end$"
emA	db	"Duplicate symbol$"
emB	db	"File error$"
emC	db	"Reserved word misuse$"
onlm	db	" on line $"
inclev	db	40h dup(?)
infn	db	10h dup(?)
outfn	db	10h dup(?)
index	db	80h dup(?)
input	db	80h dup(?)
output	db	100h dup(?)
temp	db	40h dup(?)
element	db	60h dup(?)
symbs	db	2000h dup(?)
