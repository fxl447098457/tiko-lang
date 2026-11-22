'' A byval cva_list parameter: on linux-x86_64 it is the CALLER'S list, passed by address
'' with no copy, as C's 'va_list' parameter is. See cva-list-byval-linux-x86_64.test.
declare sub c_vread cdecl( byval n as long, byval ap as cva_list )
type CB as sub cdecl( byval n as long, byval ap as cva_list )
function tk_vsum cdecl( byval n as long, byval ap as cva_list ) as longint
    dim as longint s = 0
    for k as long = 1 to n
        s += cva_arg( ap, longint )
    next
    c_vread( n, ap )
    return s
end function
function f cdecl( byval n as long, ... ) as longint
    dim as cva_list ap
    cva_start( ap, n )
    dim as longint s = tk_vsum( n, ap )
    dim as CB p = @c_vread
    p( n, ap )
    cva_end( ap )
    return s
end function
