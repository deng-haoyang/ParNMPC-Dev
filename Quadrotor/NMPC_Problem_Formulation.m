clear all
addpath('../ParNMPC/')

OCP = OptimalControlProblem('quadrotor',...
                               5,... % u
                               9,... % x
                               3,... % y
                               4);   % p
%%
% u
a      = OCP.u(1);
omegaX = OCP.u(2);
omegaY = OCP.u(3);
omegaZ = OCP.u(4);
slack  = OCP.u(5);

% x
X      = OCP.x(1);
dX     = OCP.x(2);
Y      = OCP.x(3);
dY     = OCP.x(4);
Z      = OCP.x(5);
dZ     = OCP.x(6);
Gamma  = OCP.x(7);
Beta   = OCP.x(8);
Alpha  = OCP.x(9);

% p
XSP = OCP.p(1);
YSP = OCP.p(2);
ZSP = OCP.p(3);
duW = OCP.p(4);% input rate weighting

% constant
g = 9.81;

% L(u,x,y,p)
Qy = diag([10, 10, 10]);
Qu = diag([1, 1, 1, 1])*0.01;
yRef = [XSP;YSP;ZSP];
uRef = [g;0;0;0];
L =    0.5*(OCP.y-yRef).'*Qy*(OCP.y-yRef)...
     + 0.5*(OCP.u(1:4)-uRef).'*Qu*(OCP.u(1:4)-uRef)...
     + 1e3*slack^2;
 
% xdot = f(u,x,p)
f = [dX;...
     a*(cos(Gamma)*sin(Beta)*cos(Alpha) + sin(Gamma)*sin(Alpha));...
     dY;...
     a*(cos(Gamma)*sin(Beta)*sin(Alpha) - sin(Gamma)*cos(Alpha));...
     dZ;...
     a*cos(Gamma)*cos(Beta) - g;...
    (omegaX*cos(Gamma) + omegaY*sin(Gamma))/cos(Beta);...
    -omegaX*sin(Gamma) + omegaY*cos(Gamma);...
     omegaX*cos(Gamma)*tan(Beta) + omegaY*sin(Gamma)*tan(Beta) + omegaZ];
 
% y = h(u,x,p)
h = [X;Y;Z];

% G(u,x,y,p) > 0
G = [OCP.u(1:4) + [0;1;1;1];...
    -OCP.u(1:4) + [11;1;1;1];...
     slack;...  
     Gamma + slack + 0.2;...
    -Gamma + slack + 0.2;...
     Beta  + slack + 0.2;...
    -Beta  + slack + 0.2;...
     Alpha + slack + 0.2;...
    -Alpha + slack + 0.2];

% psi(uN,xN,yN,pN) = 0 (terminal constraint)
psi = [];
%%
OCP.set('L',L);
OCP.set('f',f);
OCP.set('h',h);
OCP.set('G',G);
OCP.set('psi',psi);
OCP.set('W',duW*[1 10 10 10 0].');

OCP.generateDerivatives('Hessian','Lf'); % 'Sparse',false,'Optimize',true
