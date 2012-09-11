function beta = getcoeffs(method, X, y)
switch lower(method)
  case 'default'
    % matlab's magic box of matrix inversion tricks
    beta = X\y;
  case 'minl2'
    % regularized LS regression
    lambda = 0.01;
    Xr = X'*X + eye(size(X,2))*lambda;
    iXr = inv(Xr);
    beta = iXr * (X'*y);
  case 'minl1'
    % require code from http://www.stanford.edu/~boyd/l1_ls/
    addpath('l1_ls_matlab');
    lambda = 0.01;
    rel_tol = 0.01;
    beta = l1_ls(X, y, lambda, rel_tol, true);
  case 'rtls'
    beta = rtlsqepslow(X, y, eye(size(X,2)), 0.2);
  otherwise
    error('unknown method');
end