x0 = [1;0];
p  = 0.0*ones(OCP.dim.p,solverOptions.N); % R
solution   = [];
solution.u = 0.5;
solution.x = [x0,zeros(OCP.dim.x,1)];
solution   = solutionInterp(x0,p,solution);


rec.x(1,:) = x0.';
Ts     = 0.01;


for t=0:Ts:20
    % there are two ways to solve the NMPC problem:
    % 1: by using the generated mex interface, which is fast
    [solution,output] = NMPC_Solve_Wrapper_mex(x0,p,solution,solverOptions);
    % 2: by using the m code, which is good for debugging
    % [solution,output] = NMPC_Solve(x0,p,solution,solverOptions);
    
    % simulation
    uOpt = solution.u(:,1);
    x0   = sysSimu(uOpt,x0,p(:,1),Ts,10); % x(t+ts), 10 steps
    
    % log
    step            = round(t/Ts +1);
    rec.u(step,:)   = uOpt.';
    rec.x(step+1,:) = x0.';
    rec.iter(step,:)= output.iterations; 
    rec.t(step,:)     = output.cpuTime*1e6; % computation time in us
end
