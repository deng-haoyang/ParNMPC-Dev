function V = lin_solveLTD(L,B,D_diag)
% L.'*V = D*B 
% [n,n]*[n*m] = n*m

[n,m] = size(B);
V = zeros(n,m);
for i=n:-1:1
    UAfter =  L(i+1:n,i).';
    for j=1:m
        V(i,j) = (D_diag(i)*B(i,j)- UAfter*V(i+1:n,j))/L(i,i);
    end
end
end

