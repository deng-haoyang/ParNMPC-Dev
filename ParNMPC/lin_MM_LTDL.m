function B = lin_MM_LTDL(L,D_diag)
% B = L.'*D*L (D is diagonal)
% L: n*n is lower triangular 

n = length(L);

B = zeros(n,n);
for j=1:n % col
    A_j = L(:,j);
    AD_j = A_j.*D_diag;
    for i=j:n
        A_i = L(:,i);
        B(i,j) = A_i(i:end).'*AD_j(i:end);
        B(j,i) = B(i,j);
    end
end
end

