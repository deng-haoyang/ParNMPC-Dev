function [F,Fu,Fx] = func_F_Fu_Fx(u,x,p,dt,integrator,parIdx) %#codegen
    [xDim,~] = size(x);
    Ix = eye(xDim);
    switch integrator
        case 'euler'
            fdt = func_f(u,x,p,parIdx)*dt;
            [fu,fx] = func_Jacobian_fu_fx(u,x,p,parIdx);
            F  = fdt - x;
            Fu = fu*dt;
            Fx = fx*dt - Ix;
        case 'rk2'
            fdt = func_f(u,x,p,parIdx)*dt;
            f12dt = func_f(u,x-fdt/2,p,parIdx)*dt;
            
            [fu,fx] = func_Jacobian_fu_fx(u,x,p,parIdx);
            [fu12,fx12] = func_Jacobian_fu_fx(u,x-fdt/2,p,parIdx);
            F = f12dt  - x;
            Fu = fu12*dt - 0.5*dt*dt*fx12*fu;
            Fx = fx12*dt - 0.5*dt*dt*fx12*fx - Ix;
        case 'rk4'
            fdt   = func_f(u,x,p,parIdx)*dt;   % k1
            f12dt = func_f(u,x-fdt/2,p,parIdx)*dt; % k2
            f22dt = func_f(u,x-f12dt/2,p,parIdx)*dt; % k3
            f3dt  = func_f(u,x-f22dt,p,parIdx)*dt; % k4
            
            
            [fu,fx]     = func_Jacobian_fu_fx(u,x,p,parIdx);   
            [fu12,fx12] = func_Jacobian_fu_fx(u,x-fdt/2,p,parIdx); 
            [fu22,fx22] = func_Jacobian_fu_fx(u,x-f12dt/2,p,parIdx); 
            [fu3,fx3]   = func_Jacobian_fu_fx(u,x-f22dt,p,parIdx); 

            F = (fdt+2*f12dt+2*f22dt+f3dt)/6 - x;
            
            k1u =  fu*dt;
            k2u =  fu12*dt - fx12*k1u*dt/2;
            k3u =  fu22*dt - fx22*k2u*dt/2;
            k4u =  fu3*dt  - fx3*k3u*dt;
            Fu  =  (k1u+2*k2u+2*k3u+k4u)/6;

            k1x = fx*dt;
            k2x = fx12*dt - fx12*k1x*dt/2;
            k3x = fx22*dt - fx22*k2x*dt/2;
            k4x = fx3*(Ix - k3x)*dt;
            Fx  = (k1x+2*k2x+2*k3x+k4x)/6 - Ix;
        otherwise % 'euler'
            fdt = func_f(u,x,p,parIdx)*dt;
            [fu,fx] = func_Jacobian_fu_fx(u,x,p,parIdx);
            F  = fdt - x;
            Fu = fu*dt;
            Fx = fx*dt - Ix;
    end
end