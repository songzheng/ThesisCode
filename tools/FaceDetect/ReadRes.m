function [res, rem] = ReadRes(input)
n = input(1);

res.n = n;
res.res = input(2:n+1);
res.conf = input(n+2);
rem = input(n+3:end);