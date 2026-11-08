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
dim as const zstring ptr p1 = cast( string, x )
dim as zstring ptr p2 = cast( string, x )
dim as long ptr p3 = cast( string, x )
dim as long l4 = cast( string, x )
dim as double d5 = cast( string, x )
dim as PL q6 = cast( string, x )
dim as const zstring ptr p7 = cptr( string, x )
