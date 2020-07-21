clear all
addpath('../ParNMPC/')

OCP = OptimalControlProblem('LBR',...
                           8,... % u
                           14,... % x
                           0,... % y
                           15);   % p
%%
% u
tau    = OCP.u(1:7);
slack  = OCP.u(8);

% x
q      = OCP.x(1:7);
qdot   = OCP.x(8:14);

% y

% p
qRef     = OCP.p(1:7);
tauRef   = OCP.p(8:14);
duW      = OCP.p(15);

% constant
g = 9.81;

% L(u,x,y,p)
% weighting matrices
Wq     = diag([1, 1, 1, 1, 1, 1, 1])*1;
Wqdot  = diag([1, 1, 1, 1, 1, 1, 1]*1e-3);
Wtau   = diag([1, 1, 1, 1, 1, 1, 1]*1e-3);
Wslack = 1e3;
% references
qdotRef  = zeros(7,1);
% L
L =    (q-qRef).'*Wq*(q-qRef) ...
     + (qdot-qdotRef).'*Wqdot*(qdot-qdotRef) ...
     + (tau-tauRef).'*Wtau*(tau-tauRef)...
     + Wslack*slack^2; 

% xdot = f(u,x,p)
f = 'external';

% y = h(u,x,p)
h = [];

% G(u,x,y,p) > 0
G = [tau + 50;...
    -tau + 50;...
     slack;...  
     qdot + pi/2  + slack;...
    -qdot + pi/2  + slack];
%%
OCP.set('L',L);
OCP.set('f',f);
OCP.set('h',h);
OCP.set('G',G);
OCP.set('W',duW*ones(OCP.dim.u,1));
OCP.generateDerivatives('Hessian','L'); % 'Sparse',false,'Optimize',true

