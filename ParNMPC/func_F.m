function F = func_F(u,x,p,dt,integrator,parIdx) %#codegen

switch integrator
    case 'euler'
        fdt = func_f(u,x,p,parIdx)*dt;
        F  = fdt - x;
    case 'rk2'
        fdt   = func_f(u,x,p,parIdx)*dt;   
        f12dt = func_f(u,x-fdt/2,p,parIdx)*dt;   

        F  =  f12dt  - x;
    case 'rk4'
        fdt   = func_f(u,x,p,parIdx)*dt;   % k1
        f12dt = func_f(u,x-fdt/2,p,parIdx)*dt; % k2
        f22dt = func_f(u,x-f12dt/2,p,parIdx)*dt; % k3
        f3dt  = func_f(u,x-f22dt,p,parIdx)*dt; % k4

        F = (fdt+2*f12dt+2*f22dt+f3dt)/6 - x;

    otherwise % 'euler'
        fdt = func_f(u,x,p,parIdx)*dt;
        F  = fdt - x;
end

end