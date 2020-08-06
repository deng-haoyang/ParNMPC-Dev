function V = lin_solveL(L,B)
% LV = B [n,n]*[n*m] = n*m

[n,m] = size(B);
V = zeros(n,m);
for i=1:n
    LPrev =  L(i,1:i-1);
    for j=1:m
        V(i,j) = (B(i,j)- LPrev*V(1:i-1,j))/L(i,i);
    end
end
% for i=1:n
%     V(i,1:m) = (B(i,1:m)- L(i,1:i-1)*V(1:i-1,1:m))/L(i,i);
% end
end

