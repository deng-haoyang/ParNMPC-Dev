function B = lin_MM_ATDA(A,D_diag)
% B = A.'*D*A (D is diagonal)
% A: n*m 

[n,m] = size(A);

B = zeros(m,m);
for j=1:m % col
    A_j = A(:,j);
    AD_j = A_j.*D_diag;
    for i=j:m
        A_i = A(:,i);
        B(i,j) = A_i.'*AD_j;
        B(j,i) = B(i,j);
    end
end
end

