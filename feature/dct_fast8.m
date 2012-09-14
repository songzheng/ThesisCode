function out = dct_fast8(in)

[i0,i1,i2,i3,i4,i5,i6,i7] = deal(1,2,3,4,5,6,7,8);

cpi4 = cos(pi/4);
spi8 = sin(pi/8);
cpi8 = cos(pi/8);
spi38 = sin(pi*3/8);
cpi38 = cos(pi*3/8);
spi16 = sin(pi/16);
cpi16 = cos(pi/16);
cpi316 = cos(3*pi/16);
spi316 = sin(3*pi/16);

assert(length(in) == 8);
out = zeros(8,1);

% stage 1
out(i0) = in(i0) + in(i7);
out(i1) = in(i1) + in(i6);
out(i2) = in(i2) + in(i5);
out(i3) = in(i3) + in(i4);
out(i4) = -in(i4) + in(i3);
out(i5) = -in(i5) + in(i2);
out(i6) = -in(i6) + in(i1);
out(i7) = -in(i7) + in(i0);
in = out;

% stage 2
out(i0) = in(i0) + in(i3);
out(i1) = in(i1) + in(i2);
out(i2) = -in(i2) + in(i1);
out(i3) = -in(i3) + in(i0);
out(i4) = in(i4);
out(i5) = (-in(i5) + in(i2)) * cpi4;
out(i6) = (in(i6) + in(i5)) * cpi4;
out(i7) = in(i7);
in = out;

% stage 3
out(i0) = (in(i0) + in(i1)) * cpi4;
out(i1) = (-in(i1) + in(i0)) * cpi4;
out(i2) = in(i2)*spi8 + in(i3) * (-cpi8);
out(i3) = in(i3)*spi8 + in(i2) * (+cpi8);
out(i4) = in(i4) + in(i5);
out(i5) = -in(i5) + in(i4);
out(i6) = -in(i6) + in(i7);
out(i7) = in(i7) + in(i6);  
in = out;


% stage 4
out(i0) = in(i0);
out(i1) = in(i1);
out(i2) = in(i2);
out(i3) = in(i3);
out(i4) = in(i4)*spi16 + in(i7)*(+cpi16);
out(i5) = in(i5)*cpi316 + in(i6)*(+spi316);
out(i6) = in(i6)*cpi316 + in(i5)*(-spi316);
out(i7) = in(i7)*spi16 + in(i4)*(-cpi16);

out([i0,i4,i2,i6,i1,i5,i3,i7]) = out/2;