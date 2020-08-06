#include <windows.h>
#include "timer_win.h"

double timer_win(void)
{

	LARGE_INTEGER nFreq;
	LARGE_INTEGER nTime;

	double time;




	QueryPerformanceFrequency(&nFreq);

	QueryPerformanceCounter(&nTime);

	time = (double)(nTime.QuadPart)/ (double)nFreq.QuadPart;
	return time;
}