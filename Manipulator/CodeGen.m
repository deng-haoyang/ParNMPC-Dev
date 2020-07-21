%%
solverOptions = createSolverOptions();
solverOptions.printLevel = 2;
solverOptions.T          = 1;
solverOptions.N          = 20;
solverOptions.maxIterations  = 10;
solverOptions.checkKKTAferIteration = false;
%%
codegenOptions = createCodegenOptions();
codegenOptions.targetLang             = 'C++';
% options for mex generation (only for linux,mac with pinocchio installed)
codegenOptions.MEX_buildMEXInterface  = true;
codegenOptions.MEX_customHeaderCode   = '#include "iiwa14.h"';
codegenOptions.MEX_customInitializer  = 'iiwa14_init();';
codegenOptions.MEX_postCodeGenCommand = 'setbuildargs(buildInfo)';

NMPC_Solve_CodeGen(OCP,solverOptions,codegenOptions);