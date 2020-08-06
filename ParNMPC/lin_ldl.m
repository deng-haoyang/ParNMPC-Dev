function [L,d]=lin_ldl(A)%#codegen
   n = length(A);
   L = eye(n);
   d = zeros(n,1);
   sigma = 1e-8;
   % original
%    for k=1:n
%        d(k,1) = A(k,k) - (L(k,1:k-1).*L(k,1:k-1))*d(1:k-1,1);
%        for j=k+1:n
%            L(j,k) = (A(j,k) - (L(j,1:k-1).*L(k,1:k-1))*d(1:k-1,1))/d(k,1);
%        end
%    end
   % optimized
   u = zeros(n,n);
   for k=1:n
       LAfter = L(k,1:k-1).';
       d(k,1) = A(k,k) - u(k,1:k-1)*LAfter;
       % avoid if |d_k| is too small
       if d(k,1)>=0 && d(k,1)<sigma
           d(k,1) = sigma;
       elseif d(k,1)<0 && d(k,1)>-sigma
           d(k,1) = -sigma;
       end
       for j=k+1:n
           u(j,k) = A(j,k)  - u(j,1:k-1)*LAfter;
           L(j,k) = u(j,k)/d(k,1);
       end
   end
   % optimized u transposed
%   u = zeros(n,n);
%    for k=1:n
%        d(k,1) = A(k,k) - L(k,1:k-1)*u(1:k-1,k);
%        for j=k+1:n
%            u(k,j) = A(j,k)  - L(k,1:k-1)*u(1:k-1,j);
%            L(j,k) = u(k,j)/d(k,1);
%        end
%    end
end
