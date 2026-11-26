'' overload-udt-arg-nomatch.test: a UDT argument no candidate takes, beside one that fits.
type DT
    x as longint
end type
type DD
    y as short
end type
type LDay
    y as long
    declare constructor( )
    declare constructor( byval a as long, byval b as long, byval c as long )
end type
constructor LDay( ) : end constructor
constructor LDay( byval a as long, byval b as long, byval c as long ) : end constructor
sub Pv overload( byval f as long, byval shown as double ) : end sub
sub Pv( byval f as DD, byval shown as DD ) : end sub
sub Pr overload( byref f as long, byref shown as long ) : end sub
sub Pr( byref f as DD, byref shown as DD ) : end sub
sub Pc overload( byref f as long, byref shown as DD ) : end sub
sub Pc( byref f as LDay, byref shown as DD ) : end sub
sub Pc( byref f as DD, byref shown as DD ) : end sub
dim as DT t
dim as DD d
dim as long n
Pv( t, d )
Pr( t, d )
Pc( t, d )
Pv( n, 1.5 )
Pr( d, d )
Pc( n, d )
