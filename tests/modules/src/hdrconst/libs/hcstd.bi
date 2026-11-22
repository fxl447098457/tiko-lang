'' hcstd.bi -- defines the same names as MACROS, only '#ifndef' them, as crt/stddef.bi
'' defines NULL. Read first, it leaves hcdef.bi declaring nothing.
#ifndef HC_NULL
#define HC_NULL 0
#endif
#ifndef HC_MAX
#define HC_MAX 260
#endif
#ifndef HC_NEG
#define HC_NEG -2
#endif
#ifndef HC_HALF
#define HC_HALF 0.5
#endif
