function h = func_h(u,x,p,parIdx)
% y = h(u,x,p)
% parIdx: index of the core (for reentrant purpose)
    if coder.target('MATLAB') 
        % Specify your own h(u,x,p) function for normal excution
        
    else 
        % Specify your own h(u,x,p) function for code generation
        
    end
end