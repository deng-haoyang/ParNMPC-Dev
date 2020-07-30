function options = createCodegenOptions()
%% C/C++ source code generation
options.targetLang              = 'C';
options.dynamicMemoryAllocation = 'off';
options.supportNonFinite  = false;
options.generateReport    = false;
options.cppNamespace      = false;
%% simulink interface generation
options.generateSimulinkInterface = false;
%% mex interface generation
options.MEX_buildMEXInterface = false;
options.MEX_customHeaderCode   = '';
options.MEX_customInitializer  = '';
options.MEX_customLibrary      = '';
options.MEX_customSourceCode   = '';
options.MEX_customTerminator   = '';
options.MEX_postCodeGenCommand = '';% include paths, source files
options.MEX_stackUsageMax      = 200000; 
%% init function generation
% generate function to initialize solution?
options.solution_init = [];
% generate function to initialize p?
options.p_init        = [];
% generate function to initialize x0?
options.x0_init       = [];