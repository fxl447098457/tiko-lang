'' udt-ctor-default-tail-arg-run.test: a conversion constructor with a defaulted tail.
type DT
    x as longint
end type
type LDay
    y as long
    tag as string
    declare constructor( )
    declare constructor( byref a as const DT, byval b as long = 7, byref t as const string = "dflt" )
end type
constructor LDay( ) : y = -1 : tag = "none" : end constructor
constructor LDay( byref a as const DT, byval b as long = 7, byref t as const string = "dflt" )
    y = a.x + b : tag = t
end constructor
type DD
    y as short
end type
sub P1 overload( byref f as long, byref s as DD ) : print "P1 long" : end sub
sub P1( byref f as LDay, byref s as DD ) : print "P1 LDay "; f.y; " "; f.tag : end sub
sub Q1 overload( byref f as LDay, byref s as DD ) : print "Q1 LDay "; f.y; " "; f.tag : end sub
sub Q1( byref f as long, byref s as DD ) : print "Q1 long" : end sub
sub P2( byval f as LDay ) : print "P2 "; f.y; " "; f.tag : end sub
sub P3( byref f as const LDay ) : print "P3 "; f.y; " "; f.tag : end sub
function P4( byval f as LDay ) as long : return f.y * 2 : end function
dim as DT t : t.x = 5
dim as DD d
P1( t, d )
Q1( t, d )
P2( t )
P3( t )
print "P4 "; P4( t )
dim as LDay q = t
print "dim "; q.y; " "; q.tag
