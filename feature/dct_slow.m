function out = dct_slow(in)

N = length(in);

a = sqrt([1,2*ones(1, N-1)]/N);

k = 0:N-1;
n = 0:N-1;

[k, n] = meshgrid(k, n);

c = cos(2*pi*n.*(2*k+1)/4/N);
c = bsxfun(@times, c, a(:));

out = c * in(:);