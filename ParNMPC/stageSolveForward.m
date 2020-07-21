function [dx,du,dlambda] = stageSolveForward(decompVars,KKTReduced)
% C_bar*x2 = b2_bar
% C_bar  = L2*D2*L2.'
% b2_bar = b2 - V2.'*b1

% A*x1 = b1 - B*x2
% A = L1*D1*L1.'

% rename
L1 = decompVars.L1;
D1 = decompVars.D1;
L2 = decompVars.L2;
D2 = decompVars.D2;
V1 = decompVars.V1;
B  = decompVars.B;
[xDim,uxDim] = size(V1);
uDim = uxDim - xDim;

b1 = KKTReduced(1:xDim);
b2 = KKTReduced(xDim+1:end);


% b2_bar
% b2_bar = b2 - V2.'*b1;
b1_bar = lin_solveL(L1,b1)./D1;
b1_bar = V1.'*b1_bar;
b2_bar = b2 - b1_bar;


% x2
tempv2 = lin_solveL(L2,b2_bar);
x2     = lin_solveLT(L2,tempv2./D2);

% x1
b1_bar = b1 - B*x2;
tempv3 = lin_solveL(L1,b1_bar);
x1     = lin_solveLT(L1,tempv3./D1);

% 
dx = x1;
du = x2(1:uDim);
dlambda = x2(uDim+1:end);


end