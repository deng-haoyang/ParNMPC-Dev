function options = createSolverOptions()
% display: 0, 1, 2
options.printLevel = 0;

% timing: 'win', 'unix', 'off'
if ispc
    options.timing = 'win'; 
elseif isunix
    options.timing = 'unix'; 
else
    options.timing = 'off';
end
%% OCP options
% prediction horizon
options.T = 0.1;

% N grids
options.N = 10;

% integrator: 'euler', 'rk2', 'rk4'
options.integrator = 'euler';
%% Solver options
% degree of parallelism: 1,2,...,N
options.DOP = 1;

% max number of iterations
options.maxIterations = 20;

% barrier parameter (rho>0)
options.barrierParam = 1e-2;

% Hessian approximation (TB)
options.hessian = [];

% static regularization parameters
options.reg_min_u = 1e-7;
options.reg_min_x = 1e-7;
options.reg_min_y = 1e-7;
options.reg_eta_u = 1e-4;
options.reg_eta_x = 1e-4;
options.reg_eta_y = 1e-4;
options.reg_gamma = 1/3;
options.reg_beta  = 0.8;

% tolerance
options.tol_eq         = 1e-2;
options.tol_ineq       = 1e-2;
options.tol_optimality = 1e-2;

% re-evaluate KKT after each iteration?
options.checkKKTAferIteration = true;
end