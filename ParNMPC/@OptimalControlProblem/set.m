function set(OCP,varargin)
    field = varargin{1};
    value = varargin{2};
    % UXP_parIdx
    parIdx = sym('parIdx',[1,1]);
    UXP_parIdx = {OCP.u;OCP.x;OCP.p;parIdx};
    % UXYP
    UXYP = {OCP.u;OCP.x;OCP.y;OCP.p};
    switch field
        % functions
        case 'L'
            L = value;
            OCP.func.L = formula(L);
            matlabFunction(L,...
                'File',[OCP.path.funcgen,'/func_L'],...
                'Vars',UXYP,...
                'Outputs',{'L'},...
                'Optimize',true);
        case 'f'
            f = value;
            if  isa(f,'char')
                OCP.func.f = 'external';
                
                isExistf = exist([OCP.path.funcgen,'/func_f.m'],'file');
                if isExistf ~= 2
                    copyfile('../ParNMPC/externalfunc/func_f.m',OCP.path.funcgen);
                    disp(['Please specify your own f(u,x,p) function in ', OCP.path.funcgen,'/func_f.m']);
                else
                    disp([OCP.path.funcgen,'/func_f.m already exists and will be kept']);
                end
            else
                OCP.func.f = formula(f);
                matlabFunction(OCP.func.f,...
                    'File',[OCP.path.funcgen,'/func_f'],...
                    'Vars',UXP_parIdx,...
                    'Outputs',{'f'},...
                    'Optimize',true);
            end
        case 'h'
            h = value;
            if  isa(h,'char')
                OCP.func.h = 'external';
                isExisth = exist([OCP.path.funcgen,'/func_h.m'],'file');
                if isExisth ~= 2
                    copyfile('../ParNMPC/externalfunc/func_h.m',OCP.path.funcgen);
                    disp(['Please specify your own h(u,x,p) function in ', OCP.path.funcgen,'/func_h.m']);
                else
                    disp([OCP.path.funcgen,'/func_h.m already exists and will be kept']);
                end
            else
                hDim = length(h);
                if hDim == 0
                   OCP.func.h = sym(zeros(0,1));
                else
                   OCP.func.h = formula(h);
                end
                matlabFunction(OCP.func.h,...
                    'File',[OCP.path.funcgen,'/func_h'],...
                    'Vars',UXP_parIdx,...
                    'Outputs',{'h'},...
                    'Optimize',true);
            end
        case 'C'
            C = value;
            CDim = length(C);
            
            OCP.dim.C  = CDim;
            OCP.multiplier.C = sym('mu',[CDim,1]);
            if CDim == 0
               OCP.func.C = sym(zeros(0,1));
            else
               OCP.func.C = formula(C);
            end
            matlabFunction(OCP.func.C,...
                'File',[OCP.path.funcgen,'/func_C'],...
                'Vars',UXYP,...
                'Outputs',{'C'},...
                'Optimize',true);
            
        case 'G'
            G = value;
            GDim = length(G);

            OCP.dim.G  = GDim;
            if GDim == 0
               OCP.func.G = sym(zeros(0,1));
            else
               OCP.func.G = formula(G);
            end
            matlabFunction(OCP.func.G,...
                'File',[OCP.path.funcgen,'/func_G'],...
                'Vars',UXYP,...
                'Outputs',{'G'},...
                'Optimize',true);
        case 'psi'
            psi = value;
            psiDim = length(psi);

            OCP.dim.psi  = psiDim;
            if psiDim == 0
               OCP.func.psi = sym(zeros(0,1));
            else
               OCP.func.psi = formula(psi);
            end
            matlabFunction(OCP.func.psi,...
                'File',[OCP.path.funcgen,'/func_psi'],...
                'Vars',UXYP,...
                'Outputs',{'psi'},...
                'Optimize',true);
        case 'W'
            W = value;
            OCP.W = W;
        case 'duMax'
            duMax = value;
            OCP.duMax = duMax;
        case 'duMin'
            duMin = value;
            OCP.duMin = duMin;

        otherwise
            error([field ' is not a recognized parameter.']);
    end
end

