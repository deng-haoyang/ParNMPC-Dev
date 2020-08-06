%% options
solverOptions = createSolverOptions();
solverOptions.printLevel = 2;
solverOptions.T      = 1;
solverOptions.N      = 20;
%% initial guess 
% initial state
x0 = [1,0,1,0,1,0,0,0,0].';

% parameters
yref = [0,0,0].';
p  = zeros(OCP.dim.p,solverOptions.N);
p(1:3,:) = repmat(yref,[1,solverOptions.N]);
p(end,:)  = 0.1; % W
% accurate initial guess
solution = [];
solution.u = [g,0,0,0,0.1].';
solution.x = [x0,zeros(OCP.dim.x,1)];
solution = solutionInterp(x0,p,solution);
[solution,output] = NMPC_Solve(x0,p,solution,solverOptions);
%%
% generate soure files
codegenOptions = createCodegenOptions();
codegenOptions.targetLang    = 'C++';
codegenOptions.cppNamespace  = false;

% generate mex interface
codegenOptions.MEX_buildMEXInterface = true;

% generate simulink interface
codegenOptions.solution_init = solution;
codegenOptions.generateSimulinkInterface = true;

NMPC_Solve_CodeGen(OCP,solverOptions,codegenOptions);