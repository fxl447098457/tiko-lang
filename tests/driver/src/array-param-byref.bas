'' 'byref a( ) as T' -- a tiko extension (fbc's error 59). It is the plain descriptor
'' parameter, spelled out: the callee's REDIM, ERASE and writes reach the caller's array, a
'' DECLARE and its definition may differ in writing it, and a procedure type with it is the
'' same type as one without.

declare sub Grow( byref a( ) as int32 )
sub Grow( a( ) as int32 )
    redim a( 9 )
    a( 0 ) = 42
end sub

sub Fill( byref a( ) as string )
    redim a( 2 )
    a( 0 ) = "x"
    a( 1 ) = "yy"
    a( 2 ) = "zzz"
end sub

sub Wipe( byref a( ) as int32 )
    erase a
end sub

function Total( byref a( ) as const int32 ) as int32
    dim as int32 t = 0
    for i as int32 = lbound( a ) to ubound( a )
        t += a( i )
    next
    return t
end function

sub Two( byref m( any, any ) as int32 )
    m( 1, 2 ) = 7
end sub

dim as int32 v( any )
redim v( 2 )
Grow( v( ) )
print "grow"; ubound( v ); v( 0 )

dim as string s( any )
Fill( s( ) )
print "fill "; s( 0 ); s( 1 ); s( 2 )

print "total"; Total( v( ) )
dim as int32 f( 0 to 3 ) = { 1, 2, 3, 4 }
print "fixed"; Total( f( ) )

dim as sub( ( ) as int32 ) pg = @Grow
dim as sub( byref ( ) as int32 ) pw = @Wipe
redim v( 1 )
pg( v( ) )
print "ptr"; ubound( v )
pw( v( ) )
print "erased"; ubound( v )

dim as int32 m( 0 to 1, 0 to 2 )
Two( m( ) )
print "two"; m( 1, 2 )

for k as int32 = 1 to 1000
    Fill( s( ) )
next
print "loop "; s( 2 )
