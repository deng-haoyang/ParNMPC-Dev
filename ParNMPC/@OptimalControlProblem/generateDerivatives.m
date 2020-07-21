function generateDerivatives(OCP,varargin)
nParam = length(varargin);
% default parameters
isOptimize = true;
isSparse   = false;
hessianMethod = 'Lfh';
for i=1:1:nParam/2
    j = i*2-1;
    field = varargin{j};
    value = varargin{j+1};
    switch field
        case 'Optimize'
            isOptimize = value;
        case 'Sparse'
            isSparse   = value;
        case 'Hessian'
            hessianMethod = value;
            if ~ischar(hessianMethod)
                error([field ' is not a character array.']);
            end
        otherwise
            error([field ' is not a recognized parameter.']);
    end
end
lambda = sym('lambda',[OCP.dim.x,1]); % mul_f
omega  = sym('omega',[OCP.dim.y,1]);  % mul_h
z      = sym('z',[OCP.dim.G,1]);  % mul_G
s      = sym('s',[OCP.dim.G,1]); % G = s
rho    = sym('rho',[1,1]); % barrier parameter
dt     = sym('dt',[1,1]); % dt = T/N
%%
showInfo(OCP);
disp(['Hessian contains (cost L, dynamics f, output h, ineq G): ',hessianMethod]);
if isOptimize
    disp(['Optimize derivatives: ','yes']);
else
    disp(['Optimize derivatives: ','no']);
end
if isSparse
    disp(['Sparse derivatives: ','yes']);
else
    disp(['Sparse derivatives: ','no']);
end
disp('Generating derivatives...')
%% L(u,x,y,p)
UXYZP = {OCP.u;OCP.x;OCP.y;z;OCP.p};
LG = OCP.func.L - z.'*OCP.func.G;
LGu = jacobian(LG,OCP.u);
LGx = jacobian(LG,OCP.x);
LGy = jacobian(LG,OCP.y);
matlabFunction(LGu,LGx,LGy,...
    'File',[OCP.path.funcgen,'/func_Jacobian_LGu_LGx_LGy'],...
    'Vars',UXYZP,...
    'Outputs',{'LGu','LGx','LGy'},...
    'Optimize',isOptimize);
%% f(u,x,p,parIdx)
parIdx = sym('parIdx',[1,1]);
UXP_parIdx = {OCP.u;OCP.x;OCP.p;parIdx};
if isa(OCP.func.f,'char')
    isExist = exist([OCP.path.funcgen,'/func_Jacobian_fu_fx.m'],'file');
    if isExist ~= 2
        copyfile('../ParNMPC/externalfunc/func_Jacobian_fu_fx.m',OCP.path.funcgen);
        disp(['Please specify your own fu_fx(u,x,p) function in ', OCP.path.funcgen,'/func_Jacobian_fu_fx.m']);
    else
        disp([OCP.path.funcgen,'/func_Jacobian_fu_fx.m already exists and will be kept']);
    end
else
    fu = jacobian(OCP.func.f,OCP.u);
    fx = jacobian(OCP.func.f,OCP.x);
    matlabFunction(fu,fx,...
        'File',[OCP.path.funcgen,'/func_Jacobian_fu_fx'],...
        'Vars',UXP_parIdx,...
        'Outputs',{'fu','fx'},...
        'Optimize',isOptimize,'Sparse',isSparse);
end
%% h(u,x,p,parIdx)
if isa(OCP.func.h,'char')
    isExist = exist([OCP.path.funcgen,'/func_Jacobian_hu_hx.m'],'file');
    if isExist ~= 2
        copyfile('../ParNMPC/externalfunc/func_Jacobian_hu_hx.m',OCP.path.funcgen);
        disp(['Please specify your own hu_hx(u,x,p) function in ', OCP.path.funcgen,'/func_Jacobian_hu_hx.m']);
    else
        disp([OCP.path.funcgen,'/func_Jacobian_hu_hx.m already exists and will be kept']);
    end
else
    hu = jacobian(OCP.func.h,OCP.u);
    hx = jacobian(OCP.func.h,OCP.x);
    matlabFunction(hu,hx,...
        'File',[OCP.path.funcgen,'/func_Jacobian_hu_hx'],...
        'Vars',UXP_parIdx,...
        'Outputs',{'hu','hx'},...
        'Optimize',isOptimize,'Sparse',isSparse);
end
%% G(u,x,y,p)
Gu = jacobian(OCP.func.G,OCP.u);
Gx = jacobian(OCP.func.G,OCP.x);
Gy = jacobian(OCP.func.G,OCP.y);
% Gu*v
v = sym('v',[OCP.dim.u,1]);
Gutimesv = Gu*v;
vars = {OCP.u;OCP.x;OCP.y;OCP.p;v};
matlabFunction(Gutimesv,...
    'File',[OCP.path.funcgen,'/func_Jv_Gutimesv'],...
    'Vars',vars,...
    'Outputs',{'Gutimesv'},...
    'Optimize',isOptimize,'Sparse',false);
% Gx*v
v = sym('v',[OCP.dim.x,1]);
Gxtimesv = Gx*v;
vars = {OCP.u;OCP.x;OCP.y;OCP.p;v};
matlabFunction(Gxtimesv,...
    'File',[OCP.path.funcgen,'/func_Jv_Gxtimesv'],...
    'Vars',vars,...
    'Outputs',{'Gxtimesv'},...
    'Optimize',isOptimize,'Sparse',false);
% Gy*v
v = sym('v',[OCP.dim.y,1]);
Gytimesv = Gy*v;
vars = {OCP.u;OCP.x;OCP.y;OCP.p;v};
matlabFunction(Gytimesv,...
    'File',[OCP.path.funcgen,'/func_Jv_Gytimesv'],...
    'Vars',vars,...
    'Outputs',{'Gytimesv'},...
    'Optimize',isOptimize,'Sparse',false);
% GyT*v
v = sym('v',[OCP.dim.G,1]);
GyTtimesv = Gy.'*v;
vars = {OCP.u;OCP.x;OCP.y;OCP.p;v};
matlabFunction(GyTtimesv,...
    'File',[OCP.path.funcgen,'/func_JTv_GyTtimesv'],...
    'Vars',vars,...
    'Outputs',{'GyTtimesv'},...
    'Optimize',isOptimize,'Sparse',false);
%% Hessian u x
delta_u     = sym('delta_u',[1,1]); % reg on u
delta_x     = sym('delta_x',[1,1]); % reg on x
delta_y     = sym('delta_y',[1,1]); % reg on y
% H(u,x,y,lambda,omega,mu,z,p)
F = OCP.func.f*dt - OCP.x; % use euler even for rk2/rk4 for Hessian approximation
Y = -OCP.func.h;
H = OCP.func.L;
hessFlag = sym(0);
if sum(hessianMethod == 'f')
    if ischar(OCP.func.f)
        hessFlag = hessFlag + sym(1);
        disp('Hessian of lambda.''*f will be approximated by using the BFGS method (TODO).');
    else
        H = H + lambda.'*F;
    end
end
if sum(hessianMethod == 'h')
    if ischar(OCP.func.h)
        hessFlag = hessFlag + sym(10);
        disp('Hessian of omega.''*h will be approximated by using the BFGS method (TODO).');
    else
        H = H + omega.'*(OCP.y + Y);
    end
end
if sum(hessianMethod == 'G')
    H = H - z.'*OCP.func.G;
end
Sigma = diag(z./s); % primal-dual interior point 
% 
Hu = jacobian(H,OCP.u); % Only used for Hessian calculation
Hx = jacobian(H,OCP.x); % Only used for Hessian calculation
Hy = jacobian(H,OCP.y); % Only used for Hessian calculation

Huu = jacobian(Hu,OCP.u) + delta_u*eye(OCP.dim.u); % with reglarization
Huy = jacobian(Hu,OCP.y);
Hux = jacobian(Hu,OCP.x);

Hxu = Hux.';
Hxy = jacobian(Hx,OCP.y);
Hxx = jacobian(Hx,OCP.x) + delta_x*eye(OCP.dim.x); % with reglarization

Hyu = Huy.';
Hyy = jacobian(Hy,OCP.y) + delta_y*eye(OCP.dim.y); % with reglarization
Hyx = Hxy.';

Yu = sym('Yu',[OCP.dim.y,OCP.dim.u]);
Yx = sym('Yx',[OCP.dim.y,OCP.dim.x]);
% Auu_j_i + Gu_j_i.'*(z_j_i./G_j_i.*Gu_j_i);
Huu_Bar = Huu + Gu.'*Sigma*Gu - Huy*Yu - (Huy*Yu).'...
              - Gu.'*Sigma*Gy*Yu - (Gu.'*Sigma*Gy*Yu).'...
              + Yu.'*(Hyy + Gy.'*Sigma*Gy)*Yu;
Hxx_Bar = Hxx + Gx.'*Sigma*Gx - Hxy*Yx - (Hxy*Yx).'...
              - Gx.'*Sigma*Gy*Yx - (Gx.'*Sigma*Gy*Yx).'...
              + Yx.'*(Hyy + Gy.'*Sigma*Gy)*Yx;
Hxu_Bar = Hxu + Gx.'*Sigma*Gu - (Hxy + Gx.'*Sigma*Gy)*Yu...
              - Yx.'*(Hyu+Gy.'*Sigma*Gu - (Hyy + Gy.'*Sigma*Gy)*Yu);
vars = {OCP.u;OCP.x;OCP.y;OCP.p;...
        lambda;omega;z;s;rho;dt;delta_u;delta_x;delta_y;Yu;Yx};
matlabFunction(Hxx_Bar,Hxu_Bar,Huu_Bar,...
    'File',[OCP.path.funcgen,'/func_Hessian_Hxx_Hxu_Huu_Bar'],...
    'Vars',vars,...
    'Outputs',{'Hxx_Bar','Hxu_Bar','Huu_Bar'},...
    'Optimize',isOptimize,'Sparse',isSparse);
matlabFunction(hessFlag,...
    'File',[OCP.path.funcgen,'/func_HessianFlag'],...
    'Outputs',{'hessFlag'},...
    'Optimize',isOptimize,'Sparse',false);
%% Hessian y
% Hyu*v
v = sym('v',[OCP.dim.u,1]);
Hyutimesv = Hyu*v;
vars =  {OCP.u;OCP.x;OCP.y;OCP.p;z;delta_y;v};
matlabFunction(Hyutimesv,...
    'File',[OCP.path.funcgen,'/func_Jv_Hyutimesv'],...
    'Vars',vars,...
    'Outputs',{'Hyutimesv'},...
    'Optimize',isOptimize,'Sparse',false);
% Hyx*v
v = sym('v',[OCP.dim.x,1]);
Hyxtimesv = Hyx*v;
vars =  {OCP.u;OCP.x;OCP.y;OCP.p;z;delta_y;v};
matlabFunction(Hyxtimesv,...
    'File',[OCP.path.funcgen,'/func_Jv_Hyxtimesv'],...
    'Vars',vars,...
    'Outputs',{'Hyxtimesv'},...
    'Optimize',isOptimize,'Sparse',false);
% Hyy*v
v = sym('v',[OCP.dim.y,1]);
Hyytimesv = Hyy*v;
vars =  {OCP.u;OCP.x;OCP.y;OCP.p;z;delta_y;v};
matlabFunction(Hyytimesv,...
    'File',[OCP.path.funcgen,'/func_Jv_Hyytimesv'],...
    'Vars',vars,...
    'Outputs',{'Hyytimesv'},...
    'Optimize',isOptimize,'Sparse',false);
%% Coefficient matrix times v
CM_Hu_GrhoZe = (Gu.' - Yu.'*Gy.')*Sigma;
CM_Klambda_GrhoZe = (Gx.' - Yx.'*Gy.')*Sigma;
CM_Hu_yY     = Yu.'*(Hyy + Gy.'*Sigma*Gy) - Huy - Gu.'*Sigma*Gy;
CM_Klambda_yY     = Yx.'*(Hyy + Gy.'*Sigma*Gy) - Hxy - Gx.'*Sigma*Gy;
%
v = sym('v',[OCP.dim.G,1]);
vars = {OCP.u;OCP.x;OCP.y;OCP.p;...
        lambda;omega;z;s;rho;dt;delta_y;v};
CM_Hu_GrhoZe_timesv      = CM_Hu_GrhoZe*v;
CM_Klambda_GrhoZe_timesv = CM_Klambda_GrhoZe*v;
matlabFunction(CM_Hu_GrhoZe_timesv,CM_Klambda_GrhoZe_timesv,...
    'File',[OCP.path.funcgen,'/CM_Hu_Klambda_timesvG'],...
    'Vars',vars,...
    'Outputs',{'CM_Hu_GrhoZe_timesv','CM_Klambda_GrhoZe_timesv'},...
    'Optimize',isOptimize,'Sparse',false);
%
v = sym('v',[OCP.dim.y,1]);
vars = {OCP.u;OCP.x;OCP.y;OCP.p;...
        lambda;omega;z;s;rho;dt;delta_y;Yu;Yx;v};
CM_Hu_yY_timesv      = CM_Hu_yY*v;
CM_Klambda_yY_timesv = CM_Klambda_yY*v;
matlabFunction(CM_Hu_yY_timesv,CM_Klambda_yY_timesv,...
    'File',[OCP.path.funcgen,'/CM_Hu_Klambda_timesvy'],...
    'Vars',vars,...
    'Outputs',{'CM_Hu_GrhoZe_timesv','CM_Klambda_GrhoZe_timesv'},...
    'Optimize',isOptimize,'Sparse',false);
%% du
% u_0 = \bar{u}_0
uPrev = sym('uPrev',[OCP.dim.u,1]);
% uNext = sym('uPrev',[OCP.dim.u,1]);
W     = sym('W',[OCP.dim.u,1]);  % W_i
% WNext = sym('WNext',[OCP.dim.u,1]);% W_{i+1}
du  = OCP.u - uPrev;
Phi = sym(0);
for i=1:OCP.dim.u
    if ~isinf(OCP.duMax(i))
       Phi = Phi -  log(OCP.duMax(i) - du(i));
    end
    if ~isinf(OCP.duMin(i))
       Phi = Phi -  log(du(i) - OCP.duMin(i));
    end
end
Gdu = sym([]);
for i=1:OCP.dim.u
    if ~isinf(OCP.duMax(i))
        Gdu = [Gdu;OCP.duMax(i) - du(i)];
    end
    if ~isinf(OCP.duMin(i))
        Gdu = [Gdu;du(i) - OCP.duMin(i)];
    end
end
matlabFunction(Gdu,...
    'File',[OCP.path.funcgen,'/func_Gdu'],...
    'Vars',{OCP.u;uPrev;OCP.p},...
    'Outputs',{'Gdu'},...
    'Optimize',isOptimize,'Sparse',false);
Phi_Bar = 1/2*du.'*diag(W)*du + rho*Phi;
Phiu_Bar          = jacobian(Phi_Bar,OCP.u);
PhiuPrev_Bar      = jacobian(Phi_Bar,uPrev);
Phiuu_Bar_diag         = diag(jacobian(Phiu_Bar,OCP.u));
PhiuPrevuPrev_Bar_diag = diag(jacobian(PhiuPrev_Bar,uPrev));
PhiuuPrev_Bar_diag     = diag(jacobian(Phiu_Bar,uPrev));
% Phiu_Bar = -PhiuPrev_Bar
% Phiuu_Bar_diag = PhiuPrevuPrev_Bar_diag
matlabFunction(sym(OCP.W),...
    'File',[OCP.path.funcgen,'/func_W'],...
    'Vars',{OCP.p},...
    'Outputs',{'W'},...
    'Optimize',isOptimize,'Sparse',false);
vars = {W;OCP.u;uPrev;rho};
matlabFunction(Phiu_Bar,...
    'File',[OCP.path.funcgen,'/func_Phiu_Bar'],...
    'Vars',vars,...
    'Outputs',{'Phiu_Bar'},...
    'Optimize',isOptimize,'Sparse',false);
matlabFunction(Phiuu_Bar_diag,...
    'File',[OCP.path.funcgen,'/func_Phiuu_Bar_diag'],...
    'Vars',vars,...
    'Outputs',{'Phiuu_Bar_diag'},...
    'Optimize',isOptimize,'Sparse',false);
matlabFunction(PhiuuPrev_Bar_diag,...
    'File',[OCP.path.funcgen,'/func_PhiuuPrev_Bar_diag'],...
    'Vars',vars,...
    'Outputs',{'PhiuuPrev_Bar_diag'},...
    'Optimize',isOptimize,'Sparse',false);
disp('Done!');
