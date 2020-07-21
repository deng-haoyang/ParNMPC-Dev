function f = func_f(u,x,p,parIdx)
% xdot = f(u,x,p)
% parIdx: index of the core (for reentrant purpose)
    if coder.target('MATLAB') 
        % Specify your own f(u,x,p) function for normal excution

    else 
        % Specify your own f(u,x,p) function for code generation

    end
end