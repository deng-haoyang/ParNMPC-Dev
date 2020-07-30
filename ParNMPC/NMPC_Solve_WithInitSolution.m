function [solutionOut,output]  = NMPC_Solve_WithInitSolution(x0,p,solverOptions)%#codegen
persistent solution
% options
coder.cstructname(solverOptions, 'SolverOptions', 'extern', 'HeaderFile', 'NMPC_Solve_types.h');
coder.cinclude('init_solution.h');
% solution
if isempty(solution)
    solution = createStruct_NonEmptySolution();
    coder.cstructname(solution, 'Solution', 'extern', 'HeaderFile', 'NMPC_Solve_types.h');
    coder.ceval('init_solution',coder.ref(solution));
end
% output
[uDim,~] = size(solution.u);
xDim     = length(x0);
output   = createStruct_output(uDim,xDim);
coder.cstructname(output,'Output', 'extern', 'HeaderFile', 'NMPC_Solve_types.h'); 
%% call the generated code
pDim   = length(p);
coder.cinclude('NMPC_Solve.h');
if pDim == 0
    coder.ceval('NMPC_Solve',...
                 x0,...
                 coder.ref(solution),...
                 coder.rref(solverOptions),...
                 coder.ref(output));
else
    coder.ceval('NMPC_Solve',...
             x0,...
             p,...
             coder.ref(solution),...
             coder.rref(solverOptions),...
             coder.ref(output));
end
solutionOut = solution;
end
