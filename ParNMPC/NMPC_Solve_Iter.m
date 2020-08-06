function [uNew,xNew,yNew,lambdaNew,omegaNew,zNew,gammaNew,sNew,sens_du1dx0,sens_du1du0,KKT,t] = NMPC_Solve_Iter(x0,u0,p,u,x,y,lambda,omega,z,gamma,s,rho,dt,reg,integrator,timing) %#codegen
%% extract options
% regularization params
delta_u   = reg.u;
delta_x   = reg.x;
delta_y   = reg.y;
delta_psi = reg.psi;

[xDim,N] = size(x);
[uDim,~] = size(u);
[yDim,~] = size(y);
[zDim,~] = size(z);
[psiDim,~] = size(gamma);
%% init outputs
% new iterates
uNew      = u;
xNew      = x;
yNew      = y;
sNew      = s;
lambdaNew = lambda;
omegaNew  = omega;
zNew      = z;
gammaNew  = gamma;
% sensitivity 
sens_du1dx0 = zeros(uDim,xDim);
sens_du1du0 = zeros(uDim,uDim);
% KKT 
KKT = createStruct_KKT(N);
% cpu time
t  = 0;
%% local variables
lambdaEqCorrectionBack = zeros(xDim,N);
HuTCorrectionBack      = zeros(uDim,N);
KKTReduced_All         = zeros(2*xDim+uDim,N);

decompVars_struct.L1 = zeros(xDim,xDim);
decompVars_struct.D1 = zeros(xDim,1);
decompVars_struct.L2 = zeros(xDim+uDim,xDim+uDim);
decompVars_struct.D2 = zeros(xDim+uDim,1);
decompVars_struct.V1 = zeros(xDim,xDim+uDim);
decompVars_struct.B  = zeros(xDim,xDim+uDim);
decompVars = repmat(decompVars_struct,1,N);

Y_All          = zeros(yDim,N);
Yu_All         = zeros(yDim,uDim,N);
Yx_All         = zeros(yDim,xDim,N);
HyT_All        = zeros(yDim,N);
duCoupling_All = zeros(uDim,N);
G_All          = zeros(zDim,N);
%% get W
W = zeros(uDim,N);
for i=1:N
    W(:,i) = func_W(p(:,i));
end
%% prev next variables
WNext = [W(:,2:end),zeros(uDim,1)];
uNext = [u(:,2:end),u(:,end)];
uPrev = [u0,u(:,1:end-1)];
xPrev = [x0,x(:,1:end-1)];
lambdaNext = [lambda(:,2:end),zeros(xDim,1)];
%% 
LAMBDA   = zeros(xDim+uDim,xDim+uDim);
psi      = func_psi(x(:,N),y(:,N),p(:,N));
psix_bar = zeros(psiDim,xDim);
psiu_bar = zeros(psiDim,uDim);
psi_bar  = zeros(psiDim,1);

for i=N:-1:1
    u_i = u(:,i);
    x_i = x(:,i);
    y_i = y(:,i);
    p_i = p(:,i);
    lambda_i = lambda(:,i);
    omega_i  = omega(:,i);
    z_i      = z(:,i);
    s_i      = s(:,i);
    W_i      = W(:,i);
    uPrev_i  = uPrev(:,i);
    xPrev_i  = xPrev(:,i);
    uNext_i  = uNext(:,i);
    lambdaNext_i  = lambdaNext(:,i);
    WNext_i  = WNext(:,i);
    parIdx   = 1;
        
    % KKT
    [L,F,Y,G,Fu,Fx,Yu,Yx,HuT,HxT,HyT] = ...
    stageKKT(u_i,x_i,y_i,p_i,lambda_i,omega_i,z_i,gamma,W_i,uPrev_i,uNext_i,WNext_i,...
          dt,integrator,rho,parIdx,i,N);
    
    % reduced KKT
    [CM_Hu_GrhoZe_timesvG,CM_Klambda_GrhoZe_timesvG] = ...
    CM_Hu_Klambda_timesvG(u_i,x_i,y_i,p_i,lambda_i,omega_i,z_i,s_i,rho,dt,delta_y,G-rho./z_i);
    [CM_Hu_yY_timesvy,CM_Klambda_yY_timesvy] = ...
        CM_Hu_Klambda_timesvy(u_i,x_i,y_i,p_i,lambda_i,omega_i,z_i,s_i,rho,dt,delta_y,Yu,Yx,y_i+Y);
    HuT_bar = HuT - Yu.'*HyT + CM_Hu_GrhoZe_timesvG      + CM_Hu_yY_timesvy;
    HxT_bar = HxT - Yx.'*HyT + CM_Klambda_GrhoZe_timesvG + CM_Klambda_yY_timesvy;
    
    % reduced Hessian
    [Hxx_bar,Hxu_bar,Huu_bar] = ...
    stageHessian(u_i,x_i,y_i,p_i,lambda_i,omega_i,z_i,s_i,W_i,uPrev_i,uNext_i,WNext_i,Yu,Yx,...
          dt,rho,delta_u,delta_x,delta_y,i);
    
    % du coupling in ML & MU
    duCoupling = func_PhiuuPrev_Bar_diag(W_i,u_i,uPrev_i,rho);

    % terminal constraint psi(x,y,p) = 0
    if i == N
        psi_bar  = psi - func_Jv_psiytimesv(x_i,y_i,p_i,y_i+ Y);
        
        psiu_bar = func_psiu_m_psiyYu(x_i,y_i,p_i,Yu);
        psix_bar = func_psix_m_psiyYx(x_i,y_i,p_i,Yx);
        
        HxT_bar = HxT_bar + 1/delta_psi*(psix_bar.'*psi_bar);
        HuT_bar = HuT_bar + 1/delta_psi*(psiu_bar.'*psi_bar);
        
        Hxx_bar = Hxx_bar + 1/delta_psi*(psix_bar.'*psix_bar);
        Hxu_bar = Hxu_bar + 1/delta_psi*(psix_bar.'*psiu_bar);
        Huu_bar = Huu_bar + 1/delta_psi*(psiu_bar.'*psiu_bar);
    end
    
    KKTReduced = [HxT_bar + lambdaNext_i; HuT_bar; F + xPrev_i];

    % matrix decomposition 
    [LAMBDA,decompVars(i),sens_du1dx0_i,sens_du1du0_i,~] = stageDecompose(Hxx_bar,Hxu_bar,Huu_bar,LAMBDA,Fx,Fu,duCoupling,i);
    if i == 1
        sens_du1dx0 = sens_du1dx0_i;
        sens_du1du0 = sens_du1du0_i;
    end
        
    % backward correction
    if i == N
        lambdaEqCorrectionBackNext = zeros(xDim,1);
        HuCorrectionBackNext       = zeros(uDim,1);
    else
        lambdaEqCorrectionBackNext = lambdaEqCorrectionBack(:,i+1);
        HuCorrectionBackNext       = HuTCorrectionBack(:,i+1);
    end
    KKTReduced_corrected = KKTReduced - [lambdaEqCorrectionBackNext;HuCorrectionBackNext;zeros(xDim,1)];
    [du,dlambda]         = stageSolveBackward(decompVars(i),KKTReduced_corrected);
    lambdaEqCorrectionBack(:,i) = dlambda;
    HuTCorrectionBack(:,i) = duCoupling.*du;

    % save for the forward iteration
    HyT_All(:,i)  = HyT;
    G_All(:,i)    = G;
    Y_All(:,i)    = Y;
    Yu_All(:,:,i) = Yu;
    Yx_All(:,:,i) = Yx;
    KKTReduced_All(:,i) = KKTReduced;
    duCoupling_All(:,i) = duCoupling;

    % KKT
    KKT.L(1,i)        = L;
    KKT.xEq(1,i)      = norm(xPrev_i + F,        Inf);
    KKT.yEq(1,i)      = norm(y_i + Y,            Inf);
    KKT.sEq(1,i)      = norm(s_i - G,            Inf);
    KKT.Hu(1,i)       = norm(HuT,                Inf);
    KKT.lambdaEq(1,i) = norm(lambdaNext_i + HxT, Inf);
    KKT.Hy(1,i)       = norm(HyT,                Inf);
    KKT.rhoEq(1,i)    = norm(s_i.*z_i - rho,     Inf);
    if i == N
        KKT.psi       = norm(psi,                Inf);
    end
end
%% 
dx = zeros(xDim,1);
du = zeros(uDim,1);
dgamma = zeros(psiDim,1);
for i=1:1:N
    u_i = u(:,i);
    x_i = x(:,i);
    y_i = y(:,i);
    z_i = z(:,i);
    s_i = s(:,i);
    p_i = p(:,i);
    G =  G_All(:,i);

    KKTReduced = KKTReduced_All(:,i);
    duCoupling = duCoupling_All(:,i);
    % update 
    if i == N
        lambdaEqCorrectionBackNext = zeros(xDim,1);
        HuCorrectionBackNext       = zeros(uDim,1);
    else
        lambdaEqCorrectionBackNext = lambdaEqCorrectionBack(:,i+1);
        HuCorrectionBackNext       = HuTCorrectionBack(:,i+1);
    end
    KKTReduced_Corrected = KKTReduced - [lambdaEqCorrectionBackNext;HuCorrectionBackNext;zeros(xDim,1)]...
                                      - [zeros(xDim,1);duCoupling.*du;dx];
    [dx,du,dlambda] = stageSolveForward(decompVars(i),KKTReduced_Corrected);
    % recover
    % dy
    Yutimesdu = Yu_All(:,:,i)*du;
    Yxtimesdx = Yx_All(:,:,i)*dx;
    dy        = y_i + Y_All(:,i) - Yutimesdu - Yxtimesdx;
    
    % dz
    Sigma = z_i./s_i;
    Gudu = func_Jv_Gutimesv(u_i,x_i,y_i,p_i,du);
    Gxdx = func_Jv_Gxtimesv(u_i,x_i,y_i,p_i,dx);
    Gydy = func_Jv_Gytimesv(u_i,x_i,y_i,p_i,dy);
    dz   = (G - Gudu - Gxdx - Gydy - rho./z(:,i)).*Sigma;
    % ds
    ds = (z_i - rho./s_i - dz)./Sigma;
    % dgamma
    if i == N
        psiu_Bartimesdu = -func_Jv_psiytimesv(x_i,y_i,p_i,Yutimesdu);
        psix_Bartimesdx =  func_Jv_psixtimesv(x_i,y_i,p_i,dx)...
                          -func_Jv_psiytimesv(x_i,y_i,p_i,Yxtimesdx);
        dgamma   = 1/delta_psi*(psix_Bartimesdx +  psiu_Bartimesdu - psi_bar);
        gammaNew = gamma - dgamma;
    end

    % domega
    GyTdz = func_JTv_GyTtimesv(u_i,x_i,y_i,p_i,du);
    Hyudu = func_Jv_Hyutimesv(u_i,x_i,y_i,p_i,z_i,delta_y,du);
    Hyxdx = func_Jv_Hyxtimesv(u_i,x_i,y_i,p_i,z_i,delta_y,dx);
    Hyydy = func_Jv_Hyytimesv(u_i,x_i,y_i,p_i,z_i,delta_y,dy);
    domega = HyT_All(:,i) + GyTdz  - Hyudu - Hyxdx - Hyydy;
    if i == N
        domega   = domega - func_JTv_psiyTtimesv(x_i,y_i,p_i,dgamma);
    end
    % update
    uNew(:,i)      = u(:,i) - du;
    yNew(:,i)      = y_i    - dy;
    xNew(:,i)      = x(:,i) - dx;
    lambdaNew(:,i) = lambda(:,i) - dlambda;
    omegaNew(:,i)  = omega(:,i) - domega;
    
    zNew(:,i)      = z_i - dz;
    sNew(:,i)      = s_i - ds;
end
%% fraction to the boundary
% z
dz = zNew - z;
stepSizeZ = (0.05 - 1).*(z./dz);
stepSizeZ(stepSizeZ>1 | stepSizeZ<0) = 1;
stepSizeMinZ = min([stepSizeZ(:);1]);

% s
ds = sNew - s;
stepSizeS = (0.05 - 1).*(s./ds);
stepSizeS(stepSizeS>1 | stepSizeS<0) = 1;
stepSizeMinS = min([stepSizeS(:);1]);

% du
uPrev_i = [u0,u(:,1:end-1)];
Gdu = func_Gdu(u,uPrev_i,p);
u0 = uNew(:,1);
uPrevNew = [u0,uNew(:,1:end-1)];
GduNew = func_Gdu(uNew,uPrevNew,p);
dGdu = GduNew - Gdu;
stepSizedu = (0.05 - 1).*(Gdu./dGdu);
stepSizedu(stepSizedu>1 | stepSizedu<0) = 1;
stepSizeMindu = min([stepSizedu(:);1]);

% update
stepSizePrimal  = min(stepSizeMinS,stepSizeMindu);
uNew      = (1-stepSizePrimal)*u      + stepSizePrimal* uNew;
xNew      = (1-stepSizePrimal)*x      + stepSizePrimal* xNew;
yNew      = (1-stepSizePrimal)*y      + stepSizePrimal* yNew;
sNew      = (1-stepSizePrimal)*s      + stepSizePrimal* sNew;
lambdaNew = (1-stepSizePrimal)*lambda + stepSizePrimal* lambdaNew;
omegaNew  = (1-stepSizePrimal)*omega  + stepSizePrimal* omegaNew;
zNew      = (1-stepSizePrimal)*z      + stepSizePrimal* zNew;
gammaNew  = (1-stepSizePrimal)*gamma  + stepSizePrimal* gammaNew;

stepSizeDual = stepSizeMinZ;
zNew      = (1-stepSizeDual)*z      + stepSizeDual* zNew;
lambdaNew = (1-stepSizeDual)*lambda + stepSizeDual* lambdaNew;
omegaNew  = (1-stepSizeDual)*omega  + stepSizeDual* omegaNew;
gammaNew  = (1-stepSizeDual)*gamma  + stepSizeDual* gammaNew;

end


