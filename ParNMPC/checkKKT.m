function KKT = checkKKT(x0,u0,p,u,x,y,lambda,omega,z,gamma,s,rho,dt,integrator) %#codegen
    [xDim,N] = size(x);
    [uDim,~] = size(u);
    %% init output
    KKT = createStruct_KKT(N);
    %% get W
    W = zeros(uDim,N);
    for i=1:N
        W(:,i) = func_W(p(:,i));
    end
    %% prev next variables
%     u0 = u(:,1);
    WNext = [W(:,2:end),zeros(uDim,1)];
    uNext = [u(:,2:end),u(:,end)];
    uPrev = [u0,u(:,1:end-1)];
    xPrev = [x0,x(:,1:end-1)];
    lambdaNext = [lambda(:,2:end),zeros(xDim,1)];
    %% check KKT
    for i=N:-1:1
        u_i = u(:,i);
        x_i = x(:,i);
        y_i = y(:,i);
        p_i = p(:,i);
        lambda_i = lambda(:,i);
        omega_i  = omega(:,i);
        z_i      = z(:,i);
        s_i      = s(:,i);
        W_i = W(:,i);
        uPrev_i  = uPrev(:,i);
        xPrev_i  = xPrev(:,i);
        uNext_i  = uNext(:,i);
        lambdaNext_i  = lambdaNext(:,i);
        WNext_i  = WNext(:,i);
        parIdx   = 1;

        % KKT
        [L,F,Y,G,~,~,~,~,HuT,HxT,HyT] = ...
        stageKKT(u_i,x_i,y_i,p_i,lambda_i,omega_i,z_i,gamma,W_i,uPrev_i,uNext_i,WNext_i,...
              dt,integrator,rho,parIdx,i,N);
        % KKT
        KKT.L(1,i)        = L;
        KKT.xEq(1,i)      = norm(xPrev_i + F,      Inf);
        KKT.yEq(1,i)      = norm(y_i + Y,          Inf);
        KKT.sEq(1,i)      = norm(s_i - G,          Inf);
        KKT.Hu(1,i)       = norm(HuT,              Inf);
        KKT.lambdaEq(1,i) = norm(lambdaNext_i + HxT, Inf);
        KKT.Hy(1,i)       = norm(HyT,              Inf);
        KKT.rhoEq(1,i)    = norm(s_i.*z_i - rho,   Inf);
        
    end
end