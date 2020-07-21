% options
solverOptions = createSolverOptions();
solverOptions.printLevel = 2;
solverOptions.T      = 1;
solverOptions.N      = 20;
%
codegenOptions = createCodegenOptions;
codegenOptions.targetLang    = 'C';
codegenOptions.MEX_buildMEXInterface = true;

NMPC_Solve_CodeGen(OCP,solverOptions,codegenOptions);