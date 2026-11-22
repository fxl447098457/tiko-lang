'' tiko's int128 / uint128, phase 2: literals past 64 bits, constants folded at 128 bits
'' (globals, a UDT literal, STR of a constant, DATA), HEX/OCT/BIN and the wide forms, WSTR,
'' PRINT USING, READ, and INPUT # from a file. Values checked against Python's integers.
dim as int128 a = 170141183460469231731687303715884105727
dim as uint128 b = 340282366920938463463374607431768211455
dim as int128 c = &h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
dim as int128 d = -170141183460469231731687303715884105728
print a; b; c; d
const K as int128 = cast( int128, 1 ) shl 100
const K2 = K * 3 + 7
const K3 = K2 \ 5
print K; K2; K3; K2 mod 1000; -K3
dim shared g as int128 = K2
dim shared h as uint128 = &hFFFFFFFFFFFFFFFFull
print g; h; str( K2 ); K2 > K
type T
    a as long
    b as int128
end type
dim shared tt as T = ( 5, K2 )
print tt.a; tt.b
dim as int128 e = 12345678901234567890123456789
print hex( e ); " "; oct( e ); " "; bin( cast( int128, 37 ) ); " "; hex( b ); " "; hex( d )
print hex( e, 8 ); " "; oct( b, 4 ); " "; hex( cast( int128, 0 ) )
dim as string ws = wstr( e ) & " " & wstr( d ) & " " & whex( b ) & " " & wbin( cast( uint128, 5 ) )
print ws
print using "################################"; e
print using "+##########################################"; d
print using "&"; b
print using "##.##^^^^"; e
dim as int128 r1
dim as uint128 r2
read r1, r2
print r1; " "; r2
data -98765432109876543210987654321, 340282366920938463463374607431768211455
open "int128-p2.tmp" for output as #1
print #1, "&hFFFFFFFFFFFFFFFFFFFF"
print #1, "-12345678901234567890123.7"
close #1
open "int128-p2.tmp" for input as #1
input #1, r1
input #1, r2
close #1
kill "int128-p2.tmp"
print r1; " "; r2
