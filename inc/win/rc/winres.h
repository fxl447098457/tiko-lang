/* tiko: the SDK's winres.h -- winresrc.h plus IDC_STATIC, which it redefines. */
#ifndef _WINRES_H
#define _WINRES_H
#include "winresrc.h"
#ifdef IDC_STATIC
#undef IDC_STATIC
#endif
#define IDC_STATIC (-1)
#endif
