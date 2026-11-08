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
type BP
    v as integer
    declare operator cast( ) as any ptr
end type
operator BP.cast( ) as any ptr
    return 0
end operator
type HP
    v as integer
    declare operator cast( ) as zstring ptr
end type
operator HP.cast( ) as zstring ptr
    return 0
end operator
dim as BP bp1
dim as HP hp1
dim as any ptr g1 = cast( any ptr, bp1 )
dim as const zstring ptr g2 = cast( zstring ptr, hp1 )
print g1 = 0, g2 = 0
