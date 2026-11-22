'' fabi3.bas -- tiko's int128 / uint128 against C's __int128 (cabi3.c). Values are printed as
'' their two 64-bit halves in hex, so this program needs nothing from the runtime that an older
'' tiko-rt lacks.

type S3
    c as byte
    v as int128
end type

type S16
    v as int128
end type

extern "C"
declare function c3_s16a( byval a as long, byval s as S16 ) as int128
declare function c3_s16x( byval a as long, byval b as long, byval c as long, byval d as long, byval e as long, byval s as S16 ) as int128
declare function c3_s16m( byval a as long, byval b as long, byval c as long, byval d as long, byval e as long, byval f as long, byval g as long, byval s as S16, byval h as long ) as int128
declare function c3_s16r( byval a as long, byval v as int128 ) as S16
declare function c3_take7( byval a as long, byval b as long, byval c as long, byval d as long, byval e as long, byval f as long, byval g as long, byval s as S3 ) as int128
declare function c3_calls_s16( ) as int128
declare function c3_mul( byval a as int128, byval b as int128, byval k as long ) as int128
declare function c3_shr( byval x as uint128, byval n as long ) as uint128
declare function c3_mix( byval a as long, byval b as int128, byval d as double, byval c as int128, byval e as longint ) as int128
declare function c3_many( byval a as int128, byval b as int128, byval c as int128, byval d as int128, byval e as int128 ) as int128
declare function c3_field( byval p as S3 ptr ) as int128
declare function c3_make( byval v as int128 ) as S3
declare function c3_take( byval s as S3 ) as int128
declare function c3_calls( byval v as int128 ) as int128
declare function c3_sizeof( ) as long
declare function c3_offsetof( ) as long
declare function c3_vmix( byval n as long, ... ) as int128
declare function c3_calls_vsum( ) as int128
declare function c3_calls_vsum6( ) as int128
end extern

function t3_vsum cdecl alias "T3_VSUM" ( byval n as long, ... ) as int128
    dim as cva_list ap
    cva_start( ap, n )
    dim as int128 s = 0
    for i as long = 1 to n
        s += cva_arg( ap, int128 )
    next
    cva_end( ap )
    return s
end function

function t3_s16 cdecl alias "T3_S16" ( byval a as long, byval s as S16, byval b as long ) as int128
    return s.v * a + b
end function

function t3_twice cdecl alias "T3_TWICE" ( byval v as int128 ) as int128
    return v * 2
end function

sub show( byref label as string, byval v as int128 )
    print label; " "; hex( culngint( v shr 64 ), 16 ); " "; hex( culngint( v and &hFFFFFFFFFFFFFFFFull ), 16 )
end sub

dim as int128 big = (cast( int128, 1 ) shl 80) + 3
show "mul", c3_mul( big, -2, 5 )
show "shr", c3_shr( cast( uint128, big ) shl 40, 100 )
show "mix", c3_mix( 1, big, 2.0, -big, 7 )
show "many", c3_many( big, 1, 2, 3, big )
dim as S3 s
s.c = 4
s.v = -big
show "field", c3_field( @s )
dim as S3 m = c3_make( big )
print "make.c"; m.c
show "make.v", m.v
show "take", c3_take( s )
show "calls", c3_calls( big )
print "sizeof"; c3_sizeof( ); sizeof( S3 )
print "offsetof"; c3_offsetof( ); offsetof( S3, v )
dim fp as function cdecl ( byval as int128, byval as int128, byval as long ) as int128 = @c3_mul
show "ptr", fp( 3, 4, 1 )
show "vmix", c3_vmix( 3, 9ll, big, -big + 1 )
show "vsum", c3_calls_vsum( )
show "vmix6", c3_vmix( 6, -3ll, big, -big + 1, cast( int128, 1 ) shl 120, cast( int128, 5 ), -( cast( int128, 1 ) shl 120 ) )
show "vsum6", c3_calls_vsum6( )
dim as S16 q
q.v = big
show "s16a", c3_s16a( 1, q )
show "s16x", c3_s16x( 1, 2, 3, 4, 5, q )
show "s16m", c3_s16m( 1, 2, 3, 4, 5, 6, 7, q, 8 )
show "s16r", c3_s16r( 3, big ).v
show "take7", c3_take7( 1, 2, 3, 4, 5, 6, 7, s )
show "calls16", c3_calls_s16( )
