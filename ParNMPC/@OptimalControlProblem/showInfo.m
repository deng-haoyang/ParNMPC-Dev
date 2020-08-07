function showInfo(OCP)
    disp(' ');
    disp('--------------------OptimalControlProblem Information--------------------');
    disp(['Project name: ', OCP.projectName]);
    disp([num2str(OCP.dim.u) ' inputs (u), ',num2str(OCP.dim.x),' states (x), ',num2str(OCP.dim.y),' outputs (y)']);
    disp([num2str(OCP.dim.p) ' parameters (p), ',num2str(OCP.dim.G) ' inequality constraints (G)']);
    disp('Terminal constraint psi(uN,xN,yN,pN) = 0: ');
    if isempty(OCP.func.psi)
        disp('Empty');
        disp(' ');
    else
        disp(OCP.func.psi.');
    end
    disp('Input rate weights and bounds (diag(W), duMin, duMax): ');
    disp([OCP.W.';OCP.duMin.';OCP.duMax.']);
end
