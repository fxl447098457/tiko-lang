'' cva_arg of each va_list class on generic AAPCS64 (linux-arm64): GP 8 (longint, a pointer),
'' GP 16 (int128) and VR (double, single). See cva-arg-linux-arm64.test.
function readall cdecl( byval cnt as long, ... ) as double
    dim as cva_list ap
    cva_start( ap, cnt )
    dim as longint a = cva_arg( ap, longint )
    dim as any ptr p = cva_arg( ap, any ptr )
    dim as int128 q = cva_arg( ap, int128 )
    dim as double d = cva_arg( ap, double )
    dim as single s = cva_arg( ap, single )
    cva_end( ap )
    return a + cast( longint, p ) + clngint( q ) + d + s
end function
print readall( 5, 1ll, cast( any ptr, 0 ), cast( int128, 3 ), 4.0, 5.0 )
