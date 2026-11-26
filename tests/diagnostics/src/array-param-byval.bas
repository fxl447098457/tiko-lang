'' BYVAL written on an array parameter: fbc's 59 at every BYVAL line below, in a
'' definition and a procedure type (fbc-modern 1.20, 2026-10-25). BYREF is fbc's 59 too,
'' but tiko accepts it (2026-11-24); the plain forms at the end are fine.
sub S1( byval a( ) as long )
end sub
declare sub S2( byref a( ) as long )
type PT as sub( byval a( ) as long )
sub S3( a( ) as long, byval n as long )
end sub
declare sub S4( ( ) as long )
declare sub S5( byval ( ) as long )
