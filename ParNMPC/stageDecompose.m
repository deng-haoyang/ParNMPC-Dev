function [LAMBDA,decompVars,sens_du1dx0,sens_du1du0,t] = stageDecompose(Hxx,Hxu,Huu,LAMBDA,Fx,Fu,duCoupling,idx)
[xDim,uDim] = size(Hxu);
%% init outputs
sens_du1dx0 = zeros(uDim,xDim);
sens_du1du0 = zeros(uDim,uDim);
t = 0;
%% spliting
A =  Hxx + LAMBDA(1:xDim,1:xDim);
B = [Hxu+  LAMBDA(1:xDim,xDim+1:end),Fx.'];
C = [Huu+  LAMBDA(xDim+1:end,xDim+1:end),Fu.';Fu,zeros(xDim,xDim)];
%% A 
% A = L1*D1*L1.'
% A*x1 = b1 - B*x2
[L1,D1] = lin_ldl(A);
V1      = lin_solveL(L1,B);
%%  C_bar 
% C_bar = C - B.'*A*B
% C_bar  = L2*D2*L2.'
% C_bar*x2 = b2_bar
C_bar  = C - lin_MM_ATDA(V1,1./D1);
[L2,D2]= lin_ldl(C_bar); % 26 us
%% LAMBDA 
isduCoupling = ~(sum(duCoupling == 0) == uDim);
LAMBDA       = zeros(uDim+xDim,uDim+xDim);
if idx > 1
    tempL2Ix = lin_solveL(L2(uDim+1:end,uDim+1:end),eye(xDim));
    LAMBDA(1:xDim,1:xDim)  = - lin_MM_LTDL(tempL2Ix,1./D2(uDim+1:end));
    if isduCoupling
        tempv4_R = lin_solveL(L2,[diag(duCoupling);zeros(xDim,uDim)]);
        tempv4_RA  = tempv4_R(1:uDim,:);
        tempv4_RB  = tempv4_R(uDim+1:end,:);
        AD1A = lin_MM_ATDA(tempv4_RA,1./D2(1:uDim));
        BD2B = lin_MM_ATDA(tempv4_RB,1./D2(uDim+1:end));
        LAMBDA(xDim+1:end,xDim+1:end) = - AD1A - BD2B;
        LTD2B = lin_MM_LTDA(tempL2Ix,1./D2(uDim+1:end),tempv4_RB);
        LAMBDA(1:xDim,xDim+1:end) = - LTD2B;
        LAMBDA(xDim+1:end,1:xDim) = - LTD2B.';
    end
end
%% sensitivity du1
% if idx == 1
%     tempv6 = lin_solveL(L2,[eye(uDim);zeros(xDim,uDim)]);
%     sens_du1 = -lin_solveLTD(L2(uDim+1:end,uDim+1:end),tempv6(uDim+1:end,:),1./D2(uDim+1:end)).';
% end
if idx == 1
    tempv6 = lin_solveL(L2,[eye(uDim);zeros(xDim,uDim)]);
    tempv7 = lin_solveLTD(L2,tempv6,1./D2);
    sens_du1 = -tempv7.';
    sens_du1(:,1:uDim) = bsxfun(@times,sens_du1(:,1:uDim),duCoupling).';
    sens_du1du0 = sens_du1(:,1:uDim);
    sens_du1dx0 = sens_du1(:,uDim+1:end);
end
%%
decompVars.L1 = L1;
decompVars.D1 = D1;
decompVars.L2 = L2;
decompVars.D2 = D2;
decompVars.V1 = V1;
decompVars.B  = B;
end