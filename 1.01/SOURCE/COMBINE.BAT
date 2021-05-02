copy/b main+init+cmdlin+fspec+wfn+bss maincore
copy/b rl+wr+asmf+asm asmcore
copy/b asmcore+isltr+isnum+cc+case+gn+tgn+sl+sa+gl+decim+halx
copy/b asmcore+val+wa+comma+borw+mmodrm+re+rq+ra+warg+norf+fail
copy/b asmcore+g0+g1+g2+g3+g4+g5+g6+g7+g8+g9+g0Ah+g0Bh
copy/b asmcore+g0Ch+g0Dh+g0Eh+g0Fh+g10h+g11h+g12h+g13h+g14h+g15h+g16h
copy/b asmcore+g17h+g18h+g19h+g1Ah+g1Bh
copy/b rbin+wrasm+disf+disasm discore
copy/b discore+whals+whaxs+wreg+wdisp+wptr+wspr+grp
copy/b discore+mrd+rmd+accibd+acciwd+psrd+sprefd+endl+regwd+invd
copy/b discore+relbd+g01d+msd+smd+dispd+accrd+segofd+accmd+maccd+rimmd+g02d
copy/b discore+retd+rmid+intd+aamd+escd+apd+relwd+prefd+g03d+g04d
copy/b vars+tables+i8086+messages+buffers datacore
echo.	org	100h>a72.asm
copy/b a72.asm+maincore+asmcore+discore+datacore
del maincore
del asmcore
del discore
del datacore
