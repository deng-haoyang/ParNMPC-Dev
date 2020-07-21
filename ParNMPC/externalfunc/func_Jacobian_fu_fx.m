function [fu,fx] = func_Jacobian_fu_fx(u,x,p,parIdx)
% Jacobians of f
% parIdx: index of the core (for reentrant purpose)
    if coder.target('MATLAB') 
        % Specify your own fu_fx(u,x,p) function for normal excution

    else 
        % Specify your own fu_fx(u,x,p) function for code generation

    end
end