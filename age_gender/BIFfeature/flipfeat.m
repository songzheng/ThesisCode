
function f = flipfeat(f, p)
f = f(:, end:-1:1, p);