function solution = init_solution(solutionInit)

solution = solutionInit;
coder.cstructname(solution, 'Solution', 'extern', 'HeaderFile', 'NMPC_Solve_types.h');
