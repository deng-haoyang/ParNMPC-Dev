function createStruct_NonEmptySolution_codegen(OCP,N)
%     solution.u     = u;
%     solution.x     = x;
%     solution.y     = y;
%     solution.s     = s;
%     solution.mul_f = lambda;
%     solution.mul_h = omega;
%     solution.mul_G = z;
%     solution.mul_psi = gamma;

    dim = OCP.dim;
    fileID = fopen([OCP.path.funcgen,'/createStruct_NonEmptySolution.m'],'w');
    
    fprintf(fileID, 'function solution = createStruct_NonEmptySolution()\n');
    fprintf(fileID, '   solution.u = zeros(%d,%d);\n',dim.u,N);
    fprintf(fileID, '   solution.x = zeros(%d,%d);\n',dim.x,N);
    if dim.y ~= 0
        fprintf(fileID, '   solution.y = zeros(%d,%d);\n',dim.y,N);
    end
    if dim.G ~= 0
        fprintf(fileID, '   solution.s = ones(%d,%d);\n',dim.G,N);
    end
    fprintf(fileID, '   solution.mul_f = ones(%d,%d);\n',dim.x,N);
    if dim.y ~= 0
        fprintf(fileID, '   solution.mul_h = ones(%d,%d);\n',dim.y,N);
    end
    if dim.G ~= 0
        fprintf(fileID, '   solution.mul_G = ones(%d,%d);\n',dim.G,N);
    end
    if dim.psi ~= 0
        fprintf(fileID, '   solution.mul_psi = ones(%d,%d);\n',dim.G,1);
    end
    fprintf(fileID, 'end');

    fclose(fileID);

end
