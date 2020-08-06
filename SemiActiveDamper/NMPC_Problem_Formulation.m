clear all
addpath('../ParNMPC/')

OCP = OptimalControlProblem('SemiActiveDamper',...
                               1,... % u
                               2,... % x
                               0,... % y
                               1);   % p
%%
% u
d  = OCP.u(1); % damping coefficient d

% x
z  = OCP.x(1); % displacement
dz = OCP.x(2);

% p
R  = OCP.p(1); % input weighting can be modified at runtime

% xdot = f(u,x,p)
f = [dz; -z-dz*d];

% y = h(u,x,p)
h = []; % no output

% L(u,x,y,p)
Q    = diag([10, 1]); 
xRef = [0;0];
uRef = 0;
L    =  0.5*(OCP.x-xRef).'*Q*(OCP.x-xRef)...
       +0.5*(OCP.u-uRef).'*R*(OCP.u-uRef);

% G(u,x,y,p) > 0
G = [d;...
     1 - d];
 
% psi(xN,yN,pN) = 0 (terminal constraint)
psi = [];
%%
OCP.set('L',L);
OCP.set('f',f);
OCP.set('h',h);
OCP.set('G',G);
OCP.set('psi',psi);
OCP.set('W',10*ones(OCP.dim.u,1)); % cost on input rate 
OCP.generateDerivatives('Hessian','LfGh'); % 'Sparse',false,'Optimize',true
