function [solution,output] = NMPC_Solve_Wrapper(x0,p,solutionInitGuess,options)
%% options
coder.cstructname(options, 'SolverOptions', 'extern', 'HeaderFile', 'NMPC_Solve_types.h');
%% solution_c
solution_c.u = solutionInitGuess.u;
solution_c.x = solutionInitGuess.x;
if ~isempty(solutionInitGuess.y)
    solution_c.y = solutionInitGuess.y;
end
solution_c.mul_f = solutionInitGuess.mul_f;
if ~isempty(solutionInitGuess.y)
    solution_c.mul_h = solutionInitGuess.mul_h;
end
if ~isempty(solutionInitGuess.mul_G)
    solution_c.mul_G = solutionInitGuess.mul_G;
    solution_c.s = solutionInitGuess.s;
end
coder.cstructname(solution_c, 'Solution', 'extern', 'HeaderFile', 'NMPC_Solve_types.h');
%% output
[uDim,N] = size(solutionInitGuess.u);
[xDim,~] = size(solutionInitGuess.x);
[pDim,~] = size(p);
output = createStruct_output(uDim,xDim);
coder.cstructname(output,'Output', 'extern', 'HeaderFile', 'NMPC_Solve_types.h'); 
%%
coder.cinclude('NMPC_Solve.h');
if pDim == 0
    coder.ceval('NMPC_Solve',...
                 x0,...
                 coder.ref(solution_c),...
                 coder.rref(options),...
                 coder.ref(output));
else
    coder.ceval('NMPC_Solve',...
             x0,...
             p,...
             coder.ref(solution_c),...
             coder.rref(options),...
             coder.ref(output));
end
%%
solution.u = solution_c.u;
solution.x = solution_c.x;
if isempty(solutionInitGuess.y)
    solution.y = zeros(0,N);
else
    solution.y = solution_c.y;
end
solution.mul_f = solution_c.mul_f;
if isempty(solutionInitGuess.y)
    solution.mul_h = zeros(0,N);
else
    solution.mul_h = solution_c.mul_h;
end
if isempty(solutionInitGuess.mul_G)
    solution.mul_G = zeros(0,N);
    solution.s = zeros(0,N);
else
    solution.mul_G = solution_c.mul_G;
    solution.s     = solution_c.s;
end
end