Simu_Simulink
set_param('Simu_Simulink', 'TargetLang', codegenOptions.targetLang)

switch codegenOptions.targetLang
    case 'C'
        filetype = '.c';
    case 'C++'
        filetype = '.cpp';
end

set_param('Simu_Simulink', 'SimParseCustomCode',false);

% sampling interval
Ts = 0.01;
set_param('Simu_Simulink', 'FixedStep',num2str(Ts));

% add source files
if ispc
    timer = 'timer_win'; 
elseif isunix
    timer = 'timer_unix'; 
end
set_param('Simu_Simulink', 'SimUserSources',['NMPC_Solve',filetype,' ',...
                                             'init_solution',filetype,' ',...
                                              timer,filetype,' ',...
                                             'NMPC_Solve_WithInitSolution',filetype]);
% add include paths
set_param('Simu_Simulink', 'SimUserIncludeDirs',    [OCP.path.codegen, ' ',...
                                                     OCP.path.codegen,'/simulink'])
                                                 
% RUN clear mex before running simulink so that simulink can be started from the
% provided inital solution 
clear mex
