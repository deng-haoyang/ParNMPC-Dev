function NMPC_Solve_CodeGen(OCP,solverOptions,codegenOptions)
uDim = OCP.dim.u;
xDim = OCP.dim.x;
yDim = OCP.dim.y;
pDim = OCP.dim.p;
GDim = OCP.dim.G;
psiDim = OCP.dim.psi;
N = solverOptions.N;

if isempty(codegenOptions.x0_init)
    x0 = zeros(xDim,1);
else
    x0 = codegenOptions.x0_init;
end
if isempty(codegenOptions.p_init)
    p  = zeros(pDim,N);
else
    p = codegenOptions.p_init;
end
if isempty(codegenOptions.solution_init)
    solution.u = zeros(uDim,N);
    solution.x = zeros(xDim,N);
    solution.y = zeros(yDim,N);
    solution.s      = ones(GDim,N);
    solution.mul_f = zeros(xDim,N);
    solution.mul_h = zeros(yDim,N);
    solution.mul_G = ones(GDim,N);
    solution.mul_psi = zeros(psiDim,1);
else
    solution = codegenOptions.solution_init;
end
% interpolation
solution = solutionInterp(x0,p,solution);
%% generate source files for NMPC_Solve
args = {x0,p,solution,solverOptions};
globals = {'timing', coder.Constant(solverOptions.timing),...
           'N',coder.Constant(solverOptions.N),...
           'integrator',coder.Constant(solverOptions.integrator)};
targetLang              = upper(codegenOptions.targetLang);
supportNonFinite        = codegenOptions.supportNonFinite;
dynamicMemoryAllocation = codegenOptions.dynamicMemoryAllocation;
generateReport          = codegenOptions.generateReport;
isCppNamespace          = codegenOptions.cppNamespace;
% mex
buildMEXInterface       = codegenOptions.MEX_buildMEXInterface;
postCodeGenCommand      = codegenOptions.MEX_postCodeGenCommand;
customHeaderCode        = codegenOptions.MEX_customHeaderCode;
customInitializer       = codegenOptions.MEX_customInitializer;
customLibrary           = codegenOptions.MEX_customLibrary;
customSourceCode        = codegenOptions.MEX_customSourceCode;
customTerminator        = codegenOptions.MEX_customTerminator;
stackUsageMax           = codegenOptions.MEX_stackUsageMax;  %(OCP.dim.x + OCP.dim.u)*20/360*10000;
% simulink
generateSimulinkInterface = codegenOptions.generateSimulinkInterface;

%
cfg = coder.config('lib');
cfg.FilePartitionMethod     = 'SingleFile';
cfg.BuildConfiguration      = 'Faster Runs';
cfg.GenerateExampleMain     = 'DoNotGenerate'; % DoNotGenerate

cfg.EnableOpenMP            = true;
% cfg.PreserveArrayDimensions = false;
cfg.PreserveVariableNames   = 'UserNames';
cfg.GenCodeOnly             = true;
cfg.GenerateComments        = false;
cppNamespace                = '';
if isCppNamespace
    if verLessThan('matlab','9.7')
        % ver < MATLAB R2019b
        cppNamespace            = [];
        warning('cppNameSpace is supported in MATLAB R2019b and later');
    else
        switch targetLang
            case 'C'
                cppNamespace            = '';
            case 'C++'
                cppNamespace            = OCP.projectName;
                cfg.CppNamespace        = cppNamespace;
%                 cfg.HeaderGuardStyle    = 'UsePragmaOnce';
        end
    end
end

cfg.DynamicMemoryAllocation = dynamicMemoryAllocation;
cfg.TargetLang              = targetLang;
cfg.StackUsageMax           = stackUsageMax;
cfg.SupportNonFinite        = supportNonFinite;
cfg.GenerateReport          = generateReport;

disp('Generating source files for NMPC_Solve (options timing, N, integrator will be frozen in the generated code)...');
codegen  -config cfg -args args -globals globals NMPC_Solve
% copy src
switch targetLang
    case 'C'
        srcType = 'c';
    case 'C++'
        srcType = 'cpp';
end
codegenPath = OCP.path.codegen;
[~,~,~] =rmdir(codegenPath,'s');
% delete([codegenPath,'/*']);
[~,~,~] = mkdir(codegenPath);
[~,~,~] = copyfile('./codegen/lib/NMPC_Solve/*.h',codegenPath);
[~,~,~] = copyfile(['./codegen/lib/NMPC_Solve/*.',srcType],codegenPath);

% copy timer
timerSrc = [];
switch solverOptions.timing
    case 'win'
        [~,~,~] = copyfile([OCP.path.ParNMPC,'/timersrc/timer_win.h'],codegenPath);
        [~,~,~] = copyfile([OCP.path.ParNMPC,'/timersrc/timer_win.',srcType],codegenPath);
        timerSrc = ['timer_win.',srcType];
    case 'unix'
        [~,~,~] = copyfile([OCP.path.ParNMPC,'/timersrc/timer_unix.h'],codegenPath);
        [~,~,~] = copyfile([OCP.path.ParNMPC,'/timersrc/timer_unix.',srcType],codegenPath);
        timerSrc = ['timer_unix.',srcType];
end
[~,~,~] = copyfile([OCP.path.ParNMPC,'/timersrc/tmwtypes.h'],codegenPath);
%% generate init functions for x0, p, solution
% x0
if ~isempty(codegenOptions.x0_init)
    disp('Generating initialization function for x0...');
    args = {coder.Constant(x0)}; 
    codegen  -config cfg init_x0 -args args
    [~,~,~] = copyfile('./codegen/lib/init_x0/*.h',codegenPath);
    [~,~,~] = copyfile(['./codegen/lib/init_x0/*.',srcType],codegenPath);
end
% p
if ~isempty(codegenOptions.p_init)
    disp('Generating initialization function for p...');
    args = {coder.Constant(p)}; 
    codegen  -config cfg init_p -args args
    [~,~,~] = copyfile('./codegen/lib/init_p/*.h',codegenPath);
    [~,~,~] = copyfile(['./codegen/lib/init_p/*.',srcType],codegenPath);
end
% solution
if ~isempty(codegenOptions.solution_init)
    disp('Generating initialization function for solution...');
    args = {coder.Constant(solution)}; 
    cfg.CustomInclude = [OCP.path.codegen];
    codegen  -config cfg init_solution -args args
    [~,~,~] = copyfile('./codegen/lib/init_solution/*.h',codegenPath);
    [~,~,~] = copyfile(['./codegen/lib/init_solution/*.',srcType],codegenPath);
end
disp(['Done! All source files of the NMPC controller have been successfully generated to ',codegenPath]);
disp(' ');
%% generate simulink interface
if  isempty(cppNamespace)
    namespacestd = ' ';
else
    namespacestd = ['using namespace ',cppNamespace,';'];
end
if generateSimulinkInterface
    disp('Generating Simulink interface...');
    if isempty(codegenOptions.solution_init)
        disp('Failed! Simulink interface requires a non-empty initial solution (solution_init)!');
        disp(' ');
    else
        createStruct_NonEmptySolution_codegen(OCP,N);
        if ~verLessThan('matlab','9.7')
            cfg.CppNamespace = '';
        end
        cfg.CustomHeaderCode   = sprintf('%s\n\r%s\n\r%s',...
                                         '#include "NMPC_Solve.h"',...
                                         '#include "init_solution.h"',...
                                         namespacestd);
        cfg.CustomSourceCode   = namespacestd;
        cfg.GenerateReport     = false;

        args = {x0,p,solverOptions};
    %     -globals {'solutionInit', solution} 
        codegen  -config cfg  -args args ...
                 NMPC_Solve_WithInitSolution
        [~,~,~] = copyfile('./codegen/lib/NMPC_Solve_WithInitSolution/*.h',[codegenPath,'/simulink']);
        [~,~,~] = copyfile(['./codegen/lib/NMPC_Solve_WithInitSolution/*.',srcType],[codegenPath,'/simulink']);

        disp('Done! Simulink interface has been successfully generated!');
        disp(' ');
    end
end
%% try to generate mex interface for NMPC_Solve
if buildMEXInterface 
    disp('Trying to generate mex interface for NMPC_Solve...');
    args = {x0,p,solution,solverOptions}; 
    cfg_mex = coder.config('mex');
    cfg_mex.GenerateReport       = false;
    cfg_mex.LaunchReport         = false;
    cfg_mex.IntegrityChecks      = false;
    cfg_mex.ExtrinsicCalls       = false;
    cfg_mex.ResponsivenessChecks = false;
    cfg_mex.TargetLang           = targetLang;
    cfg_mex.StackUsageMax        = stackUsageMax;
    cfg_mex.GlobalDataSyncMethod = 'NoSync';
    cfg_mex.DynamicMemoryAllocation = dynamicMemoryAllocation;
    cfg_mex.CustomHeaderCode   = sprintf('%s\n\r%s',customHeaderCode,namespacestd);
    cfg_mex.CustomInclude      = [OCP.path.codegen]; % also in postCodeGenCommand 
    cfg_mex.CustomInitializer  = customInitializer;
    cfg_mex.CustomLibrary      = customLibrary;
    % cfg_mex.CustomSource % in postCodeGenCommand
    cfg_mex.CustomSourceCode   = sprintf('%s\n\r%s',customSourceCode,namespacestd);
    cfg_mex.CustomTerminator   = customTerminator;

    cfg_mex.PostCodeGenCommand = postCodeGenCommand;

    myModelBuildInfo = RTW.BuildInfo;
    addCompileFlags(myModelBuildInfo,'-O3','OPTS');

    if isempty(timerSrc)
        cfg_mex.CustomSource  = [OCP.path.codegen,'/NMPC_Solve.',srcType];
    else
        cfg_mex.CustomSource  = [OCP.path.codegen,'/NMPC_Solve.',srcType, pathsep, OCP.path.codegen,'/',timerSrc];
    end
    try
        codegen -config cfg_mex -args args NMPC_Solve_Wrapper
        disp('Done! MEX interface has been successfully generated as NMPC_Solve_Wrapper_mex!');
    catch
        disp('Failed building MEX interface!');
    end
end