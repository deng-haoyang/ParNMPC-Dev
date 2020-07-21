function t = Timer(timing)
t = 0;
if coder.target('MATLAB')
    % count time
    t = cputime;
else
    switch timing
        case 'win'
            coder.cinclude('timer_win.h');
            t = coder.ceval('timer_win');
        case 'unix'
            coder.cinclude('timer_unix.h');
            t = coder.ceval('timer_unix');
        otherwise
            t = 0;
    end
end