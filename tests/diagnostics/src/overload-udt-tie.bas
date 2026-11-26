'' overload-udt-tie.test: ties over UDT arguments, and the calls beside them that bind.
type DT
    x as longint
end type
type BaseT
    b as long
end type
type MidT extends BaseT
    d as long
end type
type LeafT extends MidT
    l as long
end type
type LDay
    y as long
    declare constructor( byref a as const DT, byval b as long = 7 )
end type
constructor LDay( byref a as const DT, byval b as long = 7 ) : y = a.x + b : end constructor
type LE
    y as long
    declare constructor( byref a as const DT )
end type
constructor LE( byref a as const DT ) : y = a.x * 2 : end constructor
type LF
    y as long
    declare constructor( byval a as long )
end type
constructor LF( byval a as long ) : y = a : end constructor
type CL
    v as long
    declare operator cast( ) as LDay
    declare operator cast( ) as LE
end type
operator CL.cast( ) as LDay : dim as DT q : return LDay( q ) : end operator
operator CL.cast( ) as LE : dim as DT q : return LE( q ) : end operator
'' 1 two conversion ctors
sub A1 overload( byval f as LDay ) : print "A1 LDay" : end sub
sub A1( byval f as LE ) : print "A1 LE" : end sub
'' 2 two ctors, second arg tie-break by an exact builtin
sub A2 overload( byval f as LDay, byval n as long ) : print "A2 LDay" : end sub
sub A2( byval f as LE, byval n as double ) : print "A2 LE" : end sub
'' 3 same, second arg also tied
sub A3 overload( byval f as LDay, byval n as long ) : print "A3 LDay" : end sub
sub A3( byval f as LE, byval n as long ) : print "A3 LE" : end sub
'' 4 exact type vs conversion
sub A4 overload( byref f as DT ) : print "A4 DT" : end sub
sub A4( byval f as LE ) : print "A4 LE" : end sub
'' 5 base distances
sub A5 overload( byref f as BaseT ) : print "A5 BaseT" : end sub
sub A5( byref f as MidT ) : print "A5 MidT" : end sub
'' 6 base vs conversion ctor
sub A6 overload( byref f as BaseT ) : print "A6 BaseT" : end sub
sub A6( byval f as LE ) : print "A6 LE" : end sub
'' 7 crossed: each overload better on one argument
sub A7 overload( byref f as DT, byval g as LE ) : print "A7 a" : end sub
sub A7( byval f as LE, byref g as DT ) : print "A7 b" : end sub
'' 8 a UDT with two casts, two UDT overloads
sub A8 overload( byval f as LDay ) : print "A8 LDay" : end sub
sub A8( byval f as LE ) : print "A8 LE" : end sub
'' 9 ctor from long vs ctor from DT, given a DT
sub A9 overload( byval f as LF ) : print "A9 LF" : end sub
sub A9( byval f as LE ) : print "A9 LE" : end sub
dim as DT t : t.x = 5
dim as LeafT lfv
dim as CL clv
A1( t )
A2( t, 1 )
A3( t, 1 )
A4( t )
A5( lfv )
A6( lfv )
A7( t, t )
A8( clv )
A9( t )
