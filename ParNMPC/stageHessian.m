function [Hxx_bar,Hxu_bar,Huu_bar] = ...
    stageHessian(u,x,y,p,lambda,omega,z,s,W,uPrev,uNext,WNext,Yu,Yx,...
          dt,rho,delta_u,delta_x,delta_y,stateNum)

[uDim,~] = size(u);
% if stateNum == 1
%     couplingPrev = zeros(uDim,1);
% else
    couplingPrev =  func_Phiuu_Bar_diag(W,u,uPrev,rho);
% end
couplingNext = func_Phiuu_Bar_diag(WNext,uNext,u,rho);

% Hessian eval
[Hxx_bar,Hxu_bar,Huu_bar] = ...
    func_Hessian_Hxx_Hxu_Huu_Bar(u,x,y,p,lambda,omega,z,s,rho,dt,delta_u,delta_x,delta_y,Yu,Yx);
Huu_bar = Huu_bar + diag(couplingPrev) + diag(couplingNext);

% is BFGS?
hessFlag = func_HessianFlag();