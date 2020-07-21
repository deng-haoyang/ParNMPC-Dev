function ddq = ddq_lbr(q,dq,tau)
persistent robot
if isempty(robot)
    robot = importrobot('./iiwa_pinocchio/iiwa14.urdf');
    robot.DataFormat = 'column';
    robot.Gravity = [0,0,-9.81].';
end
ddq = forwardDynamics(robot,q,dq,tau);
