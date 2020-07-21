function [hu,hx] = func_Jacobian_hu_hx(u,x,p,parIdx)
% Jacobians of h
% parIdx: index of the core (for reentrant purpose)
    if coder.target('MATLAB') 
        % Specify your own hu_hx(u,x,p) function for normal excution

    else 
        % Specify your own hu_hx(u,x,p) function for code generation

    end
end