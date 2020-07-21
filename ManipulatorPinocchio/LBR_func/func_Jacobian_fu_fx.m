function [fu,fx] = func_Jacobian_fu_fx(u,x,p,parIdx)
% Jacobians of f
% parIdx: index of the core (for reentrant purpose)
    if coder.target('MATLAB') 
        % Specify your own fu_fx(u,x,p) function for normal excution
        [xDim,~] = size(x);
        [uDim,~] = size(u);
        fu = zeros(xDim,uDim);
        fx = zeros(xDim,xDim);
        h  = 1e-8;
        f = func_f(u,x,p,parIdx);
        % fu
        for i=1:uDim
             ei = zeros(uDim,1);
             ei(i,1) = 1;
             fu(:,i) = (func_f(u+ei*h,x,p,parIdx) - f)/h;
        end
        % fx
        for i=1:xDim
             ei = zeros(xDim,1);
             ei(i,1) = 1;
             fx(:,i) = (func_f(u,x+ei*h,p,parIdx) - f)/h;
        end

    else 
%         % Specify your own fu_fx(u,x,p) function for normal excution
%         [xDim,~] = size(x);
%         [uDim,~] = size(u);
%         fu = zeros(xDim,uDim);
%         fx = zeros(xDim,xDim);
%         h  = 1e-8;
%         f = func_f(u,x,p,parIdx);
%         % fu
%         for i=1:uDim
%              ei = zeros(uDim,1);
%              ei(i,1) = 1;
%              fu(:,i) = (func_f(u+ei*h,x,p,parIdx) - f)/h;
%         end
%         % fx
%         for i=1:xDim
%              ei = zeros(xDim,1);
%              ei(i,1) = 1;
%              fx(:,i) = (func_f(u,x+ei*h,p,parIdx) - f)/h;
%         end

        % Specify your own fu_fx(u,x,p) function for code generation
        coder.cinclude('iiwa14.h');
        [xDim,~] = size(x);
        [uDim,~] = size(u);
        fu = zeros(xDim,uDim);
        fx = zeros(xDim,xDim);

        q = x(1:7,1);
        qd = x(8:end,1);
        tau = u(1:7,1);

        dq  = zeros(7,7);
        dqd = zeros(7,7);
        dtau= zeros(7,7);

        coder.ceval('derivatives_cal', ...
                    coder.ref(q),...
                    coder.ref(qd),...
                    coder.ref(tau),...
                    coder.ref(dq),...
                    coder.ref(dqd),...
                    coder.ref(dtau));
        fu(8:end,1:7) = dtau;
        fx = [zeros(7,7),eye(7);dq,dqd];
    end
end