type U
    v as integer
    declare operator cast( ) as string
end type
operator U.cast( ) as string
    return "abcde"
end operator
type PL
    v as integer
end type
dim as U x
type TN
    v as integer
    declare operator cast( ) as long
end type
operator TN.cast( ) as long
    return 7
end operator
type TI
    v as integer
    declare operator cast( ) as integer
end type
operator TI.cast( ) as integer
    return 7
end operator
type CT
    v as integer
    declare constructor( byval as any ptr )
end type
constructor CT( byval a as any ptr )
end constructor
type BP
    v as integer
    declare operator cast( ) as any ptr
end type
operator BP.cast( ) as any ptr
    return 0
end operator
type DP extends BP
    w as integer
end type
type HP
    v as integer
    declare operator cast( ) as zstring ptr
end type
operator HP.cast( ) as zstring ptr
    return 0
end operator
dim as TN nn
dim as TI ni
dim as CT ct1 = CT( 0 )
dim as BP bp1
dim as DP dp1
dim as HP hp1
dim as const zstring ptr p1 = cast( zstring ptr, x )
dim as any ptr p2 = cast( any ptr, x )
dim as U ptr p3 = cast( U ptr, x )
dim as zstring ptr p4 = cptr( zstring ptr, x )
print cast( zstring ptr, x )
print *cast( zstring ptr, x )
var p7 = cast( zstring ptr, x )
dim as any ptr p8 = cast( any ptr, nn )
dim as any ptr p9 = cast( any ptr, ni )
dim as any ptr p10 = cast( any ptr, ct1 )
dim as any ptr p11 = cast( any ptr, dp1 )
