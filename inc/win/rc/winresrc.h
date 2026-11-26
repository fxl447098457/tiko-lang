/* tiko: the header Visual Studio's and many libraries' .rc files include in place
   of windows.h (SDL's do). The Windows SDK's version pulls in the resource
   subsets of the same headers windows.h does here. */
#ifndef _WINRESRC_H
#define _WINRESRC_H
#include "windows.h"
#endif
