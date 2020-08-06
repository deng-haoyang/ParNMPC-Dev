function [du,dlambda] = stageSolveBackward(decompVars,KKTReduced)
%% naive 
% [xDim,uDim] = size(Hxu);
% % Reduced system (_Bar) Order B
% CM_KKT = [Hxx,Hxu,Fx.';...
%           Hxu.',Huu,Fu.';...
%           Fx,Fu,zeros(xDim,xDim)];
% CM_KKT(1:xDim+uDim,1:xDim+uDim) = CM_KKT(1:xDim+uDim,1:xDim+uDim) + LAMBDA;
% CM_KKT_inv = inv(CM_KKT);
% MU     = [zeros(xDim,xDim),zeros(xDim,uDim),eye(xDim);...
%           zeros(uDim,xDim),diag(duCoupling),zeros(uDim,xDim);...
%           zeros(xDim,xDim),zeros(xDim,uDim),zeros(xDim,xDim)];
% ML = MU.';
% 
% LAMBDA_0 = -MU*CM_KKT_inv*ML;
% LAMBDA_true = LAMBDA_0(1:xDim+uDim,1:xDim+uDim);
% dv  = CM_KKT_inv*KKTReduced;
% dx_true          = dv(1:xDim,1);
% du_true          = dv(xDim+1:xDim+uDim,1);
% dlambda_true     = dv(xDim+uDim+1:xDim+uDim+xDim,1);

%% sss
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
[xDim,uxDim] = size(V1);
uDim = uxDim - xDim;

b1 = KKTReduced(1:xDim);
b2 = KKTReduced(xDim+1:end);

% b2_bar
% tempv1 = linsolve(L1,b1,optL);
% b2_bar = b2 - V1.'*(tempv1./D1);
b1_bar = lin_solveL(L1,b1)./D1;
b1_bar = V1.'*b1_bar;
b2_bar = b2 - b1_bar;

% x2
tempv2 = lin_solveL(L2,b2_bar);
x2     = lin_solveLT(L2,tempv2./D2);

% x1
% b1_bar = b1 - B*x2;
% tempv3 = linsolve(L1,b1_bar,optL);
% x1     = linsolve(L1.',tempv3./D1,optU);

% 
% dx = x1;
du = x2(1:uDim);
dlambda = x2(uDim+1:end);

end