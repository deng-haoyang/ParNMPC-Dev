classdef OptimalControlProblem < handle
   properties (Constant)
       version = 'Dev-1';
   end
   properties (SetAccess = private)
      % 
      projectName
      path
      % dim.[u,x,y,p,f,h,G,psi]
      dim
      % L f h G psi
      func
      % var
      u
      x
      y
      p
      % delta_u
      W
      duMax
      duMin
      % Hessian
      Hessian
   end
   methods
      function OCP = OptimalControlProblem(projectName,...
                                           uDim,...
                                           xDim,...
                                           yDim,...
                                           pDim)
        % project name
        OCP.projectName = projectName;
        % init dim
        OCP.dim.u = uDim;
        OCP.dim.x = xDim;
        OCP.dim.y = yDim;
        OCP.dim.p = pDim;
        
        OCP.dim.f = xDim;
        OCP.dim.h = yDim;
        OCP.dim.G   = 0;
        OCP.dim.psi = 0;
        
        % init func
        OCP.func.L = [];
        OCP.func.f = [];
        OCP.func.h = [];
        OCP.func.G = [];
        OCP.func.psi = [];
        
        % init variables
        OCP.u = sym('u',[OCP.dim.u,1]);
        OCP.x = sym('x',[OCP.dim.x,1]);
        OCP.y = sym('y',[OCP.dim.y,1]);
        OCP.p = sym('p',[OCP.dim.p,1]);
        
        % du
        OCP.W     =  zeros(OCP.dim.u,1);
        OCP.duMax =  Inf*ones(OCP.dim.u,1);
        OCP.duMin = -Inf*ones(OCP.dim.u,1);
        
        % Hessian
        OCP.Hessian.value = 'Lfh';
        OCP.Hessian.sparse = false;
        OCP.Hessian.optimize = true;

        % matlab function generation path
        funcgenPath = ['./',projectName,'_func'];
        [~,~,~] = mkdir(funcgenPath);
        addpath(funcgenPath);
        OCP.path.funcgen = funcgenPath;
        % ParNMPC path
        solverPath = which('NMPC_Solve.m');
        [filepath,~,~] = fileparts(solverPath);
        OCP.path.ParNMPC = filepath;
        % C/C++ code generation path
        OCP.path.codegen = ['./',projectName,'_codegen'];
      end
      set(OCP,varargin)
      generateDerivatives(OCP,varargin)
      opt = getParNMPCOptions(OCP)
      showInfo(OCP)
   end
end