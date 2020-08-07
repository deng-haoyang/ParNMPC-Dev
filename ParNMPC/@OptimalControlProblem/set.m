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
                assert(OCP.dim.x==length(OCP.func.f),['Function f is supposed to have dimensions of ', num2str(OCP.dim.x),'.']);
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
                assert(OCP.dim.y==length(OCP.func.h),['Function y is supposed to have dimensions of ', num2str(OCP.dim.y),'.']);
            end            
        case 'G'
            G = value;
            GDim = length(G);

            OCP.dim.G  = GDim;
            if GDim == 0
               OCP.func.G = sym(zeros(0,1));
            else
               OCP.func.G = formula(G);
            end
        case 'psi'
            psi = value;
            psiDim = length(psi);

            OCP.dim.psi  = psiDim;
            if psiDim == 0
               OCP.func.psi = sym(zeros(0,1));
            else
               OCP.func.psi = formula(psi);
            end
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

