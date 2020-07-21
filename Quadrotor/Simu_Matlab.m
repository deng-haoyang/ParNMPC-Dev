% initial state
x0 = [2,0,2,0,2,0,0,0,0].';

% parameters
yref = [0,0,1].';
p  = zeros(OCP.dim.p,solverOptions.N);
p(1:3,:) = repmat(yref,[1,solverOptions.N]);
p(end,:)  = 0.1; % W

% accurate initial guess
solution = [];
solution.u = [0,0,0,0,0].';
solution.x = [x0,zeros(OCP.dim.x,1)];
solution = solutionInterp(x0,p,solution);
[solution,output] = NMPC_Solve(x0,p,solution,solverOptions);

rec.x(1,:) = x0.';
Ts = 0.01;
for t=0:Ts:10
    % NMPC controller
    [solution,output] = NMPC_Solve_Wrapper_mex(x0,p,solution,solverOptions);
    
    % optimal control input
    uOpt = solution.u(:,1);
    
    % simulation
    x0 = sysSimu(uOpt,x0,p(:,1),Ts,10); % x(t) to x(t+ts)
    
    % log
    step            = round(t/Ts +1);
    rec.u(step,:)   = uOpt.';
    rec.x(step+1,:) = x0.';
    rec.iter(step,:)= output.iterations;
    rec.t(step,:)     = output.cpuTime*1e6; % computation time in us
end
plot(rec.x(:,[1 3 5]));