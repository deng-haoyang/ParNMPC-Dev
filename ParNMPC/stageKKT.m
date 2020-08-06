function [L,F,Y,G,Fu,Fx,Yu,Yx,HuT,HxT,HyT] = ...
    stageKKT(u,x,y,p,lambda,omega,z,gamma,W,uPrev,uNext,WNext,...
          dt,integrator,rho,parIdx,stageNum,N)

% func eval
L =  func_L(u,x,y,p);
Y = -func_h(u,x,p);
G =  func_G(u,x,y,p);

% Jacobian eval
[LGu,LGx,LGy] = func_Jacobian_LGu_LGx_LGy(u,x,y,z,p);% LGu = d(L - z.'*G)/du
[F,Fu,Fx]  = func_F_Fu_Fx(u,x,p,dt,integrator,parIdx);
[hu,hx] = func_Jacobian_hu_hx(u,x,p,parIdx);
Yu = -hu;
Yx = -hx;

% KKT 
HuT = LGu.' + (lambda.'*Fu).' + (omega.'*Yu).'; 
HxT = LGx.' + (lambda.'*Fx).' + (omega.'*Yx).'; 
HyT = LGy.' +  omega;
% [uDim,~] = size(u);
% if stageNum == 1
%     couplingPrev = zeros(uDim,1);
% else
    couplingPrev =  func_Phiu_Bar(W,u,uPrev,rho).';
% end
couplingNext = -func_Phiu_Bar(WNext,uNext,u,rho).';
HuT = HuT + couplingPrev + couplingNext;

if stageNum == N
    psixTtimesgamma = func_JTv_psixTtimesv(x,y,p,gamma);
    psiyTtimesgamma = func_JTv_psiyTtimesv(x,y,p,gamma);
    HxT = HxT + psixTtimesgamma;
    HyT = HyT + psiyTtimesgamma;        
end
