'' tiko's int128 / uint128 (types/type.ti): arithmetic past 64 bits, the conversions, the
'' runtime's STR / PRINT / WRITE, procedures, fields and arrays. Values checked against
'' Python's integers.
function addq( byval a as int128, byval b as int128 ) as int128
    return a + b
end function
function negq( byref a as int128 ) as int128
    a = -a
    return a
end function
sub pick overload ( byval v as longint )
    print "longint"
end sub
sub pick overload ( byval v as int128 )
    print "int128"
end sub
type R
    c as byte
    v as int128
end type

dim as int128 a = 5, b = -7
print a * b; addq( a, b ); sizeof( int128 ); sizeof( uint128 )
dim as int128 mn = -(cast( int128, 1 ) shl 127)
dim as int128 mx = not mn
dim as uint128 umx = not cast( uint128, 0 )
print mn
print mx
print umx
dim as uint128 big = cast( uint128, 1 ) shl 100
print big; big - 1; big \ 3; big mod 1000
dim as int128 q = -(cast( int128, 1 ) shl 90)
print q \ 7; q mod 7; q shr 3; cast( uint128, q ) shr 3
print str( mn ); " "; str( umx ); " "; str( cast( int128, 0 ) )
write mn, umx, a
dim as double d = big
print d; cdbl( q ); csng( umx )
dim as int128 fd = -12345678901234567890.6
dim as uint128 fu = 1e30
print fd; fu
dim as int128 i64in = 9223372036854775807ll
dim as uint128 u64in = 18446744073709551615ull
print i64in + 1; u64in + 1
const KU as uint128 = &hFFFFFFFFFFFFFFFFull
const KN as int128 = -1
dim shared gu as uint128 = &hFFFFFFFFFFFFFFFFull
dim shared gn as uint128 = KN
print KU; KN; gu; gn
print -a; abs( b ); sgn( b ); a < b; big > big - 1
dim as uint128 sh = 1
print sh shl 127; (sh shl 127) shr 127
pick( 3ll )
pick( a )
dim as R rr
rr.v = q
print sizeof( R ); offsetof( R, v ); rr.v
dim as int128 arr( 1 to 3 ) = { 10, 20, 30 }
print arr( 1 ) * arr( 2 ) * arr( 3 ) * (cast( int128, 1 ) shl 64)
dim as int128 z = 4
print negq( z ); z
select case big
case cast( uint128, 1 ) shl 100 : print "case 2^100"
case else : print "case else"
end select
