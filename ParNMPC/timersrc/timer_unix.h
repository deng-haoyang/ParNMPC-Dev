#ifndef _TIMER_UNIX_H
#define _TIMER_UNIX_H

#if !defined(_POSIX_C_SOURCE) || _POSIX_C_SOURCE < 199309L
#define _POSIX_C_SOURCE 199309L
// #error Value of _POSIX_C_SOURCE must be at least: 199309L
#endif


#include <time.h>



double timer_unix(void);



#endif // _TIMER_UNIX_H

