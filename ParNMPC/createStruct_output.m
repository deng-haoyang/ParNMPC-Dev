function output = createStruct_output(uDim,xDim)
output.exitflag   = 0;
output.cost       = 0;
output.iterations = 0;
output.eqError    = 0;
output.ineqError  = 0;
output.optimality = 0;
output.cpuTime    = 0;
output.sens_du1dx0   = zeros(uDim,xDim);
output.sens_du1du0   = zeros(uDim,uDim);
coder.cstructname(output,'Output'); 
end

