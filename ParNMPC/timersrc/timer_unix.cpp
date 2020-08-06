#include "timer_unix.h"

double timer_unix(void)
{
 	double time;
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    
    time =  t.tv_sec + t.tv_nsec/1000000000.0;

	return time;
}