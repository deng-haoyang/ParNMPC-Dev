function B = lin_MM_LTDA(L,D_diag,A)
% B = L.'*D*A (D is diagonal)
% L: n*n is lower triangular 

[n,m] = size(A);

B = zeros(n,m);
for j=1:m % col
    A_j = A(:,j);
    AD_j = A_j.*D_diag;
    for i=1:n
        L_i = L(:,i);
        B(i,j) = L_i(i:end).'*AD_j(i:end);
    end
end
end

