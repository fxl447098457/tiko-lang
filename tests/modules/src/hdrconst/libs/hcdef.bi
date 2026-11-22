'' hcdef.bi -- declares its constants only '#ifndef' the name, as win/windef.bi declares
'' NULL and MAX_PATH. Outside the package, as windows.bi is.
#ifndef HC_NULL
const HC_NULL = 0
#endif
#ifndef HC_MAX
const HC_MAX = &h104
#endif
#ifndef HC_NEG
const HC_NEG = -2
#endif
#ifndef HC_HALF
const HC_HALF = 0.5
#endif
'' A typed constant keeps its name in the interface.
const HC_TYPED as long = 7
