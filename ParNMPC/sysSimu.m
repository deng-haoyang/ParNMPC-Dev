function x = sysSimu(u,x,p,dt,M)

parIdx = 1;
dt = dt/M;

for i=1:M
    f = func_f(u,x,p,parIdx);
    k1 = dt*f;

    f = func_f(u,x+k1/2,p,parIdx);
    k2 = dt*f;

    f = func_f(u,x+k2/2,p,parIdx);
    k3 = dt*f;

    f = func_f(u,x+k3,p,parIdx);
    k4 = dt*f;

    x = x + (k1+2*k2+2*k3+k4)/6;
end

end