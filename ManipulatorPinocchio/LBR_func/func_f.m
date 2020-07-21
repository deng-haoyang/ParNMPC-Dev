function f = func_f(u,x,p,parIdx)
% xdot = f(u,x,p)
% parIdx: index of the core (for reentrant purpose)
    if coder.target('MATLAB')
        % Specify your own f(u,x,p) function for normal excution
        tau = u(1:7,1);
        q   = x(1:7,1);
        dq  = x(8:14,1);
        ddq = ddq_lbr(q,dq,tau);
        f  = [dq;ddq];
    else
        % Specify your own f(u,x,p) function for code generation
        coder.cinclude('iiwa14.h');
        tau = u(1:7,1);
        q = x(1:7,1);
        qd = x(8:14,1);
        qdd = zeros(7,1);
        coder.ceval('qdd_cal',  coder.ref(q),...
                                coder.ref(qd),...
                                coder.ref(qdd),...
                                coder.ref(tau));
        f  = [qd;qdd];
    end
end