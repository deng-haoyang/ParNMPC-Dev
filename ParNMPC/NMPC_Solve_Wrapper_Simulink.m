function [solution_c,output]  = NMPC_Solve_Wrapper_Simulink(x0,p,solverOptions)%#codegen
% solution
solution_c = createStruct_NonEmptySolution();
coder.cstructname(solution_c, 'Solution', 'extern', 'HeaderFile', 'NMPC_Solve_types.h');
% options
coder.cstructname(solverOptions, 'SolverOptions', 'extern', 'HeaderFile', 'NMPC_Solve_types.h');
% output
[uDim,~] = size(solution_c.u);
xDim     = length(x0);
output   = createStruct_output(uDim,xDim);
coder.cstructname(output,'Output', 'extern', 'HeaderFile', 'NMPC_Solve_types.h'); 
%% call the generated code
[pDim,~]   = size(p);
coder.cinclude('NMPC_Solve_WithInitSolution.h');
if pDim == 0
    coder.ceval('NMPC_Solve_WithInitSolution',...
                 x0,...
                 coder.rref(solverOptions),...
                 coder.ref(solution_c),...
                 coder.ref(output));
else
    coder.ceval('NMPC_Solve_WithInitSolution',...
             x0,...
             p,...
             coder.rref(solverOptions),...
             coder.ref(solution_c),...
             coder.ref(output));
end
end


