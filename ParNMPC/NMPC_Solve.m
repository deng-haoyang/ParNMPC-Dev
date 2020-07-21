function [solution,output] = NMPC_Solve(x0,p,solution,options) %#codegen
%% extract options
coder.cstructname(solution,'Solution'); 
coder.cstructname(options, 'SolverOptions');

global timing N integrator
if coder.target('MATLAB')
    timing                = options.timing;
    N                     = options.N;
    integrator            = options.integrator;
end
printLevel            = options.printLevel;
T                     = options.T;
rho                   = options.barrierParam;
tolEq                 = options.tol_eq;
tolIneq               = options.tol_ineq;
tolOptimality         = options.tol_optimality;
maxIterations         = options.maxIterations;
reg_min_u             = options.reg_min_u;
reg_min_x             = options.reg_min_x;
reg_min_y             = options.reg_min_y;
reg_eta_u             = options.reg_eta_u;
reg_eta_x             = options.reg_eta_x;
reg_eta_y             = options.reg_eta_y;
reg_gamma             = options.reg_gamma;
reg_beta              = options.reg_beta;
checkKKTAferIteration = options.checkKKTAferIteration;
tStart                = Timer(timing); % start tic
%% init outputs
if coder.target('MATLAB')
    % generate initial guess with dim N
    solution = solutionInterp(x0,p,solution);
    printHeader = ['Iter      ','Cost      ','Equality  ','Inequality  ',['Optimality (rho = ',num2str(rho),')']];
    printStrFormat = '%10.1e';
end
[uDim,~] = size(solution.u);
[xDim,~] = size(x0);
output = createStruct_output(uDim,xDim);
%% unpack
u      = solution.u;
x      = solution.x;
y      = solution.y; % 
lambda = solution.mul_f;
omega  = solution.mul_h; %
z      = solution.mul_G; %
s      = solution.s; %
%% Check feasibility
% s
if sum(s(:)<=0)
    if coder.target('MATLAB')
        warning('Initial guess of s should be positive.');
    end
    output.exitflag = -1;
    return
end
% du
u0 = u(:,1);
uPrev = [u0,u(:,1:end-1)];
Gdu = func_Gdu(u,uPrev,p);
if sum(Gdu(:)<=0)
    if coder.target('MATLAB')
        warning('Initial guess of u does not satisify the input rate constraints.');
    end
    output.exitflag = -1;
    return
end
%% iteration
KKT_uOpt   = 1;
KKT_xOpt   = 1;
KKT_yOpt   = 1;
dt         = T/N;
cost       = 0;
KKT_eq     = 0;
KKT_ineq   = 0;
KKT_comp   = 0;
KKT_opt    = 0;
sens_du1dx0 = zeros(uDim,xDim);
sens_du1du0 = zeros(uDim,uDim);
for iter=1:maxIterations
    % regularization
    reg.u  = reg_min_u + reg_eta_u*min(1,KKT_uOpt)^reg_beta * iter^(-reg_gamma);
    reg.x  = reg_min_x + reg_eta_x*min(1,KKT_xOpt)^reg_beta * iter^(-reg_gamma);
    reg.y  = reg_min_y + reg_eta_y*min(1,KKT_yOpt)^reg_beta * iter^(-reg_gamma);
    
    % iteration
    [u,x,y,lambda,omega,z,s,sens_du1dx0,sens_du1du0,KKT,~] = NMPC_Solve_Iter(x0,u0,p,u,x,y,lambda,omega,z,s,rho,dt,...
                                               reg,integrator,timing);
    % callback function after each iteration
    % TODO
    
    % Check KKT
    if checkKKTAferIteration
        KKT = checkKKT(x0,u0,p,u,x,y,lambda,omega,z,s,rho,dt,integrator);
    end
    
    cost       = sum(KKT.L);
    KKT_eq     = max([norm(KKT.xEq,Inf),norm(KKT.yEq,Inf)]);
    KKT_ineq   = max(norm(KKT.sEq,Inf));
    KKT_uOpt   = norm(KKT.Hu,Inf);
    KKT_xOpt   = norm(KKT.lambdaEq,Inf);
    KKT_yOpt   = norm(KKT.Hy,Inf);
    KKT_comp   = norm(KKT.rhoEq,Inf);
    KKT_opt    = max([KKT_uOpt,KKT_xOpt,KKT_yOpt,KKT_comp]);
    % display
    if coder.target('MATLAB') % Normal excution
        if printLevel == 2
            if mod(iter,10)==1
                disp(printHeader);
            end
            disp([num2str(iter,printStrFormat),...
                  '   ',num2str(cost,printStrFormat),...
                  '   ',num2str(KKT_eq,printStrFormat),...
                  '   ',num2str(KKT_ineq,printStrFormat),...
                  '     ',num2str(KKT_opt,printStrFormat),...
                  ]);
        end
    end
    % check termination
    if(KKT_eq<tolEq && KKT_ineq<tolIneq && KKT_opt<tolOptimality)
        output.exitflag = 1;
        break;
    end
end
%% print info
iterations = iter;
if coder.target('MATLAB')
    if printLevel == 1
        disp(printHeader);
        disp([num2str(iterations,printStrFormat),...
              '   ',num2str(cost,printStrFormat),...
              '   ',num2str(KKT_eq,printStrFormat),...
              '   ',num2str(KKT_ineq,printStrFormat),...
              '     ',num2str(KKT_opt,printStrFormat),...
              ]);

    end
end

%% prepare outputs
% pack solution
solution.u     = u;
solution.x     = x;
solution.y     = y;
solution.mul_f = lambda;
solution.mul_h = omega;
solution.mul_G = z;
solution.s     = s;

tEnd = Timer(timing);
cpuTime = tEnd - tStart;

% pack output
output.cost          = cost;
output.iterations    = iterations;
output.eqError       = KKT_eq;
output.ineqError     = KKT_ineq;
output.optimality    = KKT_opt;
output.cpuTime       = cpuTime;
output.sens_du1dx0   = sens_du1dx0;
output.sens_du1du0   = sens_du1du0;
end

