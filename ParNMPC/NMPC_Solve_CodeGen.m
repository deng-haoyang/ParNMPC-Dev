function NMPC_Solve_CodeGen(OCP,solverOptions,codegenOptions)
uDim = OCP.dim.u;
xDim = OCP.dim.x;
pDim = OCP.dim.p;
GDim = OCP.dim.G;

yDim = OCP.dim.y;
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
    solution.mul_f = zeros(xDim,N);
    solution.mul_h = zeros(yDim,N);
    solution.mul_G = zeros(GDim,N);
    solution.s = zeros(GDim,N);
else
    solution = codegenOptions.solution_init;
    % interpolation
    solution = solutionInterp(x0,p,solution);
end
%% generate source files for NMPC_Solve
% solverOptions.timing = 
% solverOptions.OCP = coder.Constant(solverOptions.OCP);
args = {x0,p,solution,solverOptions};
globals = {'timing', coder.Constant(solverOptions.timing),...
           'N',coder.Constant(solverOptions.N),...
           'integrator',coder.Constant(solverOptions.integrator)};
targetLang              = upper(codegenOptions.targetLang);
supportNonFinite        = codegenOptions.supportNonFinite;
dynamicMemoryAllocation = codegenOptions.dynamicMemoryAllocation;
generateReport          = codegenOptions.generateReport;
isCppNamespace          = codegenOptions.cppNamespace;

buildMEXInterface       = codegenOptions.MEX_buildMEXInterface;
postCodeGenCommand      = codegenOptions.MEX_postCodeGenCommand;
customHeaderCode        = codegenOptions.MEX_customHeaderCode;
customInitializer       = codegenOptions.MEX_customInitializer;
customLibrary           = codegenOptions.MEX_customLibrary;
customSourceCode        = codegenOptions.MEX_customSourceCode;
customTerminator        = codegenOptions.MEX_customTerminator;
stackUsageMax           = codegenOptions.MEX_stackUsageMax;  %(OCP.dim.x + OCP.dim.u)*20/360*10000;

cfg = coder.config('lib');
cfg.FilePartitionMethod     = 'SingleFile';
cfg.BuildConfiguration      = 'Faster Runs';
cfg.GenerateExampleMain     = 'DoNotGenerate'; % DoNotGenerate

cfg.EnableOpenMP            = true;
% cfg.PreserveArrayDimensions = false;
cfg.PreserveVariableNames   = 'UserNames';
cfg.GenCodeOnly             = true;
cfg.GenerateComments        = false;
cppNamespace = [];
if isCppNamespace
    if verLessThan('matlab','9.7')
        % ver < MATLAB R2019b
        cppNamespace            = [];
        warning('cppNameSpace is supported in MATLAB R2019b and later');
    else
        switch targetLang
            case 'C'
                cppNamespace            = [];
            case 'C++'
                cppNamespace            = OCP.projectName;
                cfg.CppNamespace        = cppNamespace;
                cfg.HeaderGuardStyle    = 'UsePragmaOnce';
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
delete([codegenPath,'/*']);
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
%% try to generate mex interface for NMPC_Solve
if buildMEXInterface 
    if  isempty(cppNamespace)
        disp('Trying to generate mex interface for NMPC_Solve...');
        args = {x0,p,solution,solverOptions}; 
        cfg = coder.config('mex');
        cfg.GenerateReport       = false;
        cfg.LaunchReport         = false;
        cfg.IntegrityChecks      = false;
        cfg.ExtrinsicCalls       = false;
        cfg.ResponsivenessChecks = false;
        cfg.TargetLang           = targetLang;
        cfg.StackUsageMax        = stackUsageMax;
        cfg.GlobalDataSyncMethod = 'NoSync';
        cfg.DynamicMemoryAllocation = dynamicMemoryAllocation;
        
        cfg.CustomHeaderCode   = customHeaderCode;
        cfg.CustomInclude      = [OCP.path.codegen]; % also in postCodeGenCommand 
        cfg.CustomInitializer  = customInitializer;

        cfg.CustomLibrary      = customLibrary;
        % cfg.CustomSource % in postCodeGenCommand
        cfg.CustomSourceCode   = customSourceCode;
        cfg.CustomTerminator   = customTerminator;

        cfg.PostCodeGenCommand = postCodeGenCommand;
        
        myModelBuildInfo = RTW.BuildInfo;
        addCompileFlags(myModelBuildInfo,'-O3','OPTS');

        if isempty(timerSrc)
            cfg.CustomSource  = [OCP.path.codegen,'/NMPC_Solve.',srcType];
        else
            cfg.CustomSource  = [OCP.path.codegen,'/NMPC_Solve.',srcType, pathsep, OCP.path.codegen,'/',timerSrc];
        end
        try
            codegen -config cfg NMPC_Solve_Wrapper -args args
            disp('Done! MEX interface has been successfully generated as NMPC_Solve_Wrapper_mex!');
        catch
            disp('Failed building MEX interface!');
        end
    else
        warning('MEX interface cannot be generated when cppNameSpace is enabled');
    end
end