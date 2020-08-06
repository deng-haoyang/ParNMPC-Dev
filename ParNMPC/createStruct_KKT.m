function KKT = createStruct_KKT(N)
KKT.L        = zeros(1,N); % cost 
KKT.xEq      = zeros(1,N); % eq x
KKT.yEq      = zeros(1,N); % eq y
KKT.sEq      = zeros(1,N); % ineq
KKT.Hu       = zeros(1,N); % u opt
KKT.lambdaEq = zeros(1,N); % x opt
KKT.Hy       = zeros(1,N); % y opt
KKT.rhoEq    = zeros(1,N); % s opt
KKT.psi      = zeros(1,1); % psi
coder.cstructname(KKT,'KKTStruct'); 
end

