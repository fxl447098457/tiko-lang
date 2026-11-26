'' overload-unbound-refused.test: a call Check cannot judge, so it neither binds nor reports.
type DT
    x as longint
end type
type LDay
    y as long
    declare constructor( byref a as const DT )
end type
constructor LDay( byref a as const DT ) : y = a.x : end constructor
type LE
    y as long
    declare constructor( byref a as const DT )
end type
constructor LE( byref a as const DT ) : y = a.x * 2 : end constructor
type CS
    v as long
    declare operator cast( ) as string
end type
operator CS.cast( ) as string : return "cs" : end operator
sub P4 overload( byval f as LDay ) : print "P4 LDay"; f.y : end sub
sub P4( byval f as LE ) : print "P4 LE"; f.y : end sub
dim as CS s
P4( s )
