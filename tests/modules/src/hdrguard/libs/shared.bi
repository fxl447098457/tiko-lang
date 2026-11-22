'' shared.bi -- one header two modules read, outside their package: hg/pub's public header
'' includes it, and hg/w's interface carries it for SharedT. Guarded, as crt's headers are.
#ifndef SHARED_BI_GUARD
#define SHARED_BI_GUARD
type SharedT
    as long v
end type
#endif
