function createStruct_NonEmptySolution_codegen(OCP,N)
%     solution.u     = u;
%     solution.x     = x;
%     solution.y     = y;
%     solution.mul_f = lambda;
%     solution.mul_h = omega;
%     solution.mul_G = z;
%     solution.s     = s;

    dim = OCP.dim;
    fileID = fopen([OCP.path.funcgen,'/createStruct_NonEmptySolution.m'],'w');
    
    fprintf(fileID, 'function solution = createStruct_NonEmptySolution()\n');
    fprintf(fileID, '   solution.u = zeros(%d,%d);\n',dim.u,N);
    fprintf(fileID, '   solution.x = zeros(%d,%d);\n',dim.x,N);
    if dim.y ~= 0
        fprintf(fileID, '   solution.y = zeros(%d,%d);\n',dim.y,N);
    end
    fprintf(fileID, '   solution.mul_f = zeros(%d,%d);\n',dim.x,N);
    if dim.y ~= 0
        fprintf(fileID, '   solution.mul_h = zeros(%d,%d);\n',dim.y,N);
    end
    if dim.G ~= 0
        fprintf(fileID, '   solution.mul_G = zeros(%d,%d);\n',dim.G,N);
        fprintf(fileID, '   solution.s = zeros(%d,%d);\n',dim.G,N);
    end
    fprintf(fileID, 'end');

    fclose(fileID);

end
