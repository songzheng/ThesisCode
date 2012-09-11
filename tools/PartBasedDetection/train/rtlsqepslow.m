function x = rtlsqepslow(A,b,L,delta,x0)
% RTLSQEPSLOW solves the regularized Total Least Squares problem
%             || Ax - b ||^2
%        min ---------------, subject to ||Lx||^2 = delta
%         x    ||x||^2 + 1
% 
% Input args:
%    A - mxn matrix of coefficients
%    b - mx1 right-hand-side vector 
%    L - pxn regularization matrix, (p<=n), full row rank
%    delta - regularization constant, i.e., 
%            the constraint ||Lx||^2 = delta is imposed
%    x0 - initial guess for the solution (can be empty)
%    typeL - specifies special structure of L:
%         'id' - identity matrix; 'der1' - first oder derivative; 
%         'der2' - second order derivative; 'full' - full matrix (default) 
%
% Output args:
%    x - solution of the RTLS problem
%
% Method:
% Iteratively, a quadratic eigenvalue problem is solved,
% equivalent to solving a system of the form:
%
%  (B(x_old) + lam Q)x = d(x_old),     x'Qx = delta,  where Q = L'*L.
%
%  Only largest quadratic eigenvalue and corresponding eigenvector
%  are needed; they are computed with Matlab's polyeig function.

% Contributor: Diana Sima, KU Leuven, october 2003.


% dimensions and arguments check
if nargin<4, error('There should be at least 4 input arguments'), end

[m,n] = size(A);
[mb,nb] = size(b);
if (nb~=1) 
  error('Only column vector RHS b is accepted.')
end
if (mb~=m) 
  error('b should have as many elements as number of rows in A')
end

[mL,nL] = size(L);
if (nL~=n) 
  error('L should have the same number of columns as A')
end

if ~isscalar(delta) | (delta<=0)
  error('delta should be a positive scalar')
end

if nargin<5 | isempty(x0)
  x0 = rand(n,1); 
elseif (size(x0,1)~=n) | (size(x0,2)~=1)
  error(['x0 should be a column vector of length ',num2str(n)])
end

Q = full(L'*L);  
[U,S] = eig(Q); [S,ord] = sort(diag(S)); ord = ord(end:-1:1); U = U(:,ord);
S = diag(S(ord)); r = rank(S); 
S1 = S(1:r,1:r); 

% tol
tol = 1e-8;

% set maximum number of iterations
maxiter = 50; 

% initalizations
x  = x0;
xx = x'*x; I = eye(n); AA = A'*A; Ab = A'*b; 
B  = AA/(1+xx) - norm(A*x-b)^2*I/(1+xx)^2;
d  = Ab/(1+xx);
fx = norm(A*x-b)^2/(1+xx);

err = 1; count = 0; 

% main loop
while (err>tol & count<maxiter) 
  
  count = count + 1;
  x1 = x;
  
  x = xrlsqep(B,d,delta,U,S1);     
  
  xx = x'*x;
  B = AA/(1+xx) - norm(A*x-b)^2*I/(1+xx)^2; 
  d = Ab/(1+xx);

  err = norm(x1-x)/norm(x1); 

end
% count,err
% end rtlsqepslow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Auxiliary functions: %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x = xrlsqep(B,b,delta,U,S1)
% - solves the regularized Least Squares problem - general form case 
% via a Quadratic Eigenvalue problem
% - used to solve iteratively the RTLS problem


n = size(B,1); r = size(S1,1);

T = U'*B*U; d = U'*b;

if r<n 
    T1 = T(1:r,1:r); T2 = T(1:r,r+1:n); 
    T3 = T(r+1:n,1:r); T4 = T(r+1:n,r+1:n); 
    Tp = T1 - T2*inv(T4)*T3;
    d1 = d(1:r); d2 = d(r+1:n);
    dp = d1 - T2*inv(T4)*d2;
else
    T1 = T(1:r,1:r); T2 = zeros(n-1,1); 
    T3 = zeros(1,n-1); T4 = 1; 
    Tp = T1;
    d1 = d(1:r); d2 = 0;
    dp = d1;
end

S1_rad = inv(sqrt(S1));
Tt = S1_rad*Tp*S1_rad;
dt = S1_rad*dp;

A0 = Tt*Tt - dt*dt'/delta;    % coefficient matrices for QEP
A1 = -2*Tt;
A2 = eye(r);

[X, alpha, beta] = polyeigab(A0,A1,A2); 

smalltol = 1e-25;
i = find(abs(alpha)>smalltol & abs(beta)>smalltol);
X = X(:,i);
E = alpha(i)./beta(i);  
[l,j] = min(real(E));
i = j(1);

lambda = E(i);                % eigenvalue
u   = X(1:r,i);               % eigenvector
u   = delta*u/(dt'*u);        % to ensure quadr. constraint x'Qx=delta
u   = (Tt-lambda*eye(r))*u;

y1 = S1_rad*u; 
if r<n 
  y2 = -inv(T4)*(T3*y1 - d2); 
else 
  y2 = []; 
end
    
y = [y1;y2]; 
x = U*y;  

% end xrlsqep

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [X,alpha,beta] = polyeigab(varargin)
%POLYEIG Polynomial eigenvalue problem.
%   [X,E] = POLYEIG(A0,A1,..,Ap) solves the polynomial eigenvalue problem
%   of degree p:
%       (A0 + lambda*A1 + ... + lambda^p*Ap)*x = 0.
%   The input is p+1 square matrices, A0, A1, ..., Ap, all of the same
%   order, n.  The output is an n-by-n*p matrix, X, whose columns   
%   are the eigenvectors, and a vector of length n*p, E, whose
%   elements are the eigenvalues.
%       for j = 1:n*p
%          lambda = E(j)
%          x = X(:,j)
%          (A0 + lambda*A1 + ... + lambda^p*Ap)*x is approximately 0.
%       end
% 
%   E = POLYEIG(A0,A1,..,Ap) is a vector of length n*p whose
%   elements are the eigenvalues of the polynomial eigenvalue problem.
%
%   Special cases:
%       p = 0, polyeig(A), the standard eigenvalue problem, eig(A).
%       p = 1, polyeig(A,B), the generalized eigenvalue problem, eig(A,-B).
%       n = 1, polyeig(a0,a1,..,ap), for scalars a0, ..., ap, 
%       is the standard polynomial problem, roots([ap .. a1 a0])
%
%   If both A0 and Ap are singular the problem is potentially ill-posed.
%   Theoretically, the solutions might not exist or might not be unique.
%   Computationally, the computed solutions may be inaccurate.  An attempt
%   is made to detect this situation, and a warning message may result.
%   If one, but not both, of A0 and Ap is singular, the problem is well
%   posed, but some of the eigenvalues may be zero or "infinite".

%   Mofified: Nicholas J. Higham and Francoise Tisseur, 3-3-00.
%   C. Moler, 5-5-93, 12-29-93.
%   Copyright 1984-2000 The MathWorks, Inc.
%   $Revision: 5.9 $  $Date: 2000/06/01 02:04:19 $
%   Modified by D. Sima, 2003/10, to return alpha and beta, 
%            where E = alpha./beta. 
  
% Build two n*p-by-n*p matrices:
%    A = [A0   0   0   0]   B = [-A1 -A2 -A3 -A4]
%        [ 0   I   0   0]       [  I   0   0   0]
%        [ 0   0   I   0]       [  0   I   0   0]
%        [ 0   0   0   I]       [  0   0   I   0]

n = length(varargin{1});
p = nargin-1;
A = eye(n*p);
A(1:n,1:n) = varargin{1};
if p == 0
   B = eye(n);
   p = 1;
else
   B = diag(ones(n*(p-1),1),-n);
   j = 1:n;
   for k = 1:p
      B(1:n,j) = - varargin{k+1};
      j = j+n;
   end
end

% Use the QZ algorithm on the big matrix pair (A,B).
if nargout > 1
   [alpha,beta,Q,Z,X] = qz(A,B,'complex'); 
else
   [alpha,beta] = qz(A,B,'complex');
end

% Extract the eigenvalues.
alpha = diag(alpha);
beta = diag(beta);
atol = 100*n*max(abs(alpha))*eps;
btol = 100*n*max(abs(beta))*eps;
if any(abs(alpha) < atol & abs(beta) < btol)
   wrnstr = sprintf(['Rank deficient generalized eigenvalue problem.\n' ...
            '         Eigenvalues are not well determined.  Results may be inaccurate.']);
   warning(wrnstr);
end
E = alpha./beta;

if nargout <= 1, X = E; return, end
if p == 1, return; end

% For each eigenvalue, extract the eigenvector from whichever portion
% of the big eigenvector matrix X gives the smallest normalized residual.
V = zeros(n,p);
% Division by zero possible for zero eigenvalues, so turn off warnings.
warns = warning; warning('off');
for j = 1:p*n
   V(:) = X(:,j);
   R = varargin{p+1};
   for k = p:-1:1
       R = varargin{k} + E(j)*R;
   end
   R = R*V;
   res = sum(abs(R))./ sum(abs(V));  % Normalized residuals.
   [s,ind] = min(res);
   X(1:n,j) = V(:,ind)/norm(V(:,ind));  % Eigenvector with unit 2-norm.
end
X = X(1:n,:);
%warning(warns);

