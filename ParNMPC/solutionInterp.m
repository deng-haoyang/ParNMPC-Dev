function solutionN  = solutionInterp(x0,p,solution)

[~,N] = size(p);
xDim  = length(x0);

% u
if isfield(solution,'u')
    if isempty(solution.u)
        error('Initial guess of u must be provided');
    else
        u = interpolation(solution.u,N);
    end
else
    error('Initial guess of u must be provided');
end
    

% x
if isfield(solution,'x')
    if isempty(solution.x)
        x = interpolation(x0,N);
    else
        x = interpolation(solution.x,N);
    end
else
    x = interpolation(x0,N);
end


Y = -func_h(u(:,1),x0,p(:,1));
G =  func_G(u(:,1),x0,Y,p(:,1));
yDim  = length(Y);
zDim  = length(G);


% y
if isfield(solution,'y')
    if isempty(solution.y)
        y = zeros(yDim,N);
    else
        y = interpolation(solution.y,N);
    end
else
    y = zeros(yDim,N);
end

% s
if isfield(solution,'s')
    if isempty(solution.s)
        s = ones(zDim,N);
    else
        s = interpolation(solution.s,N);
    end
else
    s = ones(zDim,N);
end

% z
if isfield(solution,'mul_G')
    if isempty(solution.mul_G)
        z = ones(zDim,N);
    else
        z = interpolation(solution.mul_G,N);
    end
else
    z = ones(zDim,N);
end

% omega
if isfield(solution,'mul_h')
    if isempty(solution.mul_h)
        omega = ones(yDim,N);
    else
        omega = interpolation(solution.mul_h,N);
    end
else
    omega = ones(yDim,N);
end

% lambda
if isfield(solution,'mul_f')
    if isempty(solution.mul_f)
        lambda = ones(xDim,N);
    else
        lambda = interpolation(solution.mul_f,N);
    end
else
    lambda = ones(xDim,N);
end

solutionN.u     = u;
solutionN.x     = x;
solutionN.y     = y;
solutionN.mul_f = lambda;
solutionN.mul_h = omega;
solutionN.mul_G = z;
solutionN.s     = s;
end

function x_N = interpolation(x_in,N)
    
    % x_in: [xDim,M]
    % x_N:  [xDim,N]
    [xDim,M] = size(x_in);
    if M == 1
        x_N = repmat(x_in,1,N);
    elseif M == N
        x_N = x_in;
    else
        XFile    = x_in(:);
        % Interpolation
        XInterp = zeros(N*xDim,1);
        if N == 1
            XInterp = XFile(1:xDim,1);
        else
            for i=1:xDim
                dataOrig = XFile(i:xDim:end);
                [sizeOrig,~] = size(dataOrig);
                interpStep = (sizeOrig-1)/(N-1);
                interpPoint = 1:interpStep:sizeOrig;
                dataInterp = interp1(dataOrig,interpPoint,'pchip');
                XInterp(i:xDim:end) = dataInterp.';
            end
        end
        x_N = reshape(XInterp,xDim,N);
    end
end