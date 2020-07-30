% x0
x0 = zeros(OCP.dim.x,1);
% p
q_ref = [1;1;1;1;1;1;1];
robot = importrobot('./iiwa_pinocchio/iiwa14.urdf');
robot.DataFormat = 'column';
robot.Gravity = [0,0,-9.81].';

gravTorq = gravityTorque(robot,q_ref);
p  = zeros(OCP.dim.p,solverOptions.N);
p(1:7,:)  = repmat(q_ref,[1,solverOptions.N]); % qref
p(8:14,:) = repmat(gravTorq,[1,solverOptions.N]); % uref
p(end,:)  = 1e-2;% W

% initial guess
solution = [];
solution.u = [zeros(7,1);0.1];
solution.x = [x0,[q_ref;zeros(7,1)]];
solution   = solutionInterp(x0,p,solution);

rec.x(1,:) = x0.';
Ts = 0.005;
for t=0:Ts:5
    % NMPC controller
    [solution,output] = NMPC_Solve_Wrapper_mex(x0,p,solution,solverOptions);
    
    % optimal control input
    uOpt = solution.u(:,1);
    
    % simulation (based on MATLAB robotics toolbox, slow)
    x0 = sysSimu(uOpt,x0,p(:,1),Ts,1); % x(t) to x(t+ts)

    % log
    step            = round(t/Ts +1);
    rec.u(step,:)   = uOpt.';
    rec.x(step+1,:) = x0.';
    rec.iter(step,:)= output.iterations;
    rec.t(step,:)   = output.cpuTime*1e6; % computation time in us
    
    % 
    disp(t);
end
plot(rec.x(:,1:7));