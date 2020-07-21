function setbuildargs(buildInfo)

linkFlags = {'-lboost_system -lurdfdom_model -lpinocchio'};
definition = {'-DPINOCCHIO_URDFDOM_TYPEDEF_SHARED_PTR -DPINOCCHIO_WITH_URDFDOM'};
includePaths={[pwd,'/iiwa_pinocchio/'],...
               '/usr/include/eigen3/',...
               '/usr/local/include/'};
sourceFiles = {[pwd,'/iiwa_pinocchio/iiwa.cpp']};

buildInfo.addLinkFlags(linkFlags);
buildInfo.addDefines(definition);
buildInfo.addIncludePaths(includePaths);
buildInfo.addSourceFiles(sourceFiles);
buildInfo.addCompileFlags({'-O3'});