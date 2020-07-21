%% options
solverOptions = createSolverOptions();
solverOptions.printLevel = 2;
solverOptions.T = 2;
solverOptions.N = 20;
solverOptions.integrator = 'euler';
solverOptions.barrierParam   = 1e-3;
solverOptions.tol_optimality = 1e-4;
%% x0, p, solution
x0 = [1;0];
p  = zeros(OCP.dim.p,solverOptions.N);
% initial guess
solution = [];
solution.u = 0.5;
solution.x = [x0,zeros(OCP.dim.x,1)];
solution = solutionInterp(x0,p,solution);
% solve 
[solution,output] = NMPC_Solve(x0,p,solution,solverOptions);
%% 
codegenOptions = createCodegenOptions();
% generate C code
codegenOptions.targetLang    = 'C';

% (optional) generate mex interface 
codegenOptions.MEX_buildMEXInterface = true;

% (optional) generate initial functions for solution
codegenOptions.solution_init = solution;
codegenOptions.x0_init       = [];
codegenOptions.p_init        = [];

NMPC_Solve_CodeGen(OCP,solverOptions,codegenOptions);