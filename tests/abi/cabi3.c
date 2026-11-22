/* cabi3.c -- C's __int128 against tiko's int128 / uint128 (fabi3.bas).
   Every value crosses the boundary in both directions: as an argument, as a result, in a
   16-aligned struct field, through a struct passed and returned by value, after the
   argument registers run out, and back into tiko through a callback. gcc for SysV
   (build/abilane.sh), clang for x86_64-pc-windows-msvc (the same script's win64 half). */

#include <stdarg.h>

typedef __int128 i128;
typedef unsigned __int128 u128;

i128 c3_mul( i128 a, i128 b, int k ) { return a * b + k; }

u128 c3_shr( u128 x, int n ) { return x >> n; }

/* the int128s land after an int, beside a double, before an int64 */
i128 c3_mix( int a, i128 b, double d, i128 c, long long e ) { return a + b + (i128)d + c + e; }

/* five of them: SysV runs out of GPR pairs and puts the rest on the stack */
i128 c3_many( i128 a, i128 b, i128 c, i128 d, i128 e ) { return a - b + c - d + e; }

struct S3 { char c; i128 v; };

i128 c3_field( struct S3 *p ) { return p->v; }

struct S3 c3_make( i128 v ) { struct S3 s; s.c = 7; s.v = v; return s; }

i128 c3_take( struct S3 s ) { return s.v + s.c; }

extern i128 T3_TWICE( i128 v );

i128 c3_calls( i128 v ) { return T3_TWICE( v ) + 1; }

int c3_sizeof( void ) { return (int)sizeof( struct S3 ); }

int c3_offsetof( void ) { return (int)__builtin_offsetof( struct S3, v ); }

/* varargs both ways: an __int128 read with va_arg after a 64-bit one, and a tiko variadic
   (T3_VSUM, cva_arg) called from C. win64 passes the 16-byte ones by address. */
i128 c3_vmix( int n, ... )
{
    va_list ap;
    va_start( ap, n );
    long long k = va_arg( ap, long long );
    i128 s = k;
    for( int i = 1; i < n; i++ ) s += va_arg( ap, i128 );
    va_end( ap );
    return s;
}

extern i128 T3_VSUM( int n, ... );

i128 c3_calls_vsum( void ) { return T3_VSUM( 3, (i128)1 << 100, (i128)-5, (i128)7 ); }

/* six: the GP save area runs out, so the later ones come from the 16-aligned overflow area */
i128 c3_calls_vsum6( void ) { return T3_VSUM( 6, (i128)1 << 100, (i128)-5, (i128)7, (i128)1 << 90, -((i128)1 << 70), (i128)11 ); }

/* a 16-BYTE struct holding an __int128: 16-aligned, so AAPCS64 puts it on an EVEN register
   pair (after one int: x2:x3, not x1:x2) or a 16-aligned stack slot, and SysV puts its
   by-value copy in a 16-aligned slot. Both directions, and with the registers running out. */
struct S16 { i128 v; };
i128 c3_s16a( int a, struct S16 s ) { return s.v + a; }
i128 c3_s16x( int a, int b, int c, int d, int e, struct S16 s ) { return s.v + a + b + c + d + e; }
i128 c3_s16m( int a, int b, int c, int d, int e, int f, int g, struct S16 s, int h ) { return s.v + a + b + c + d + e + f + g + h; }
struct S16 c3_s16r( int a, i128 v ) { struct S16 s; s.v = v * a; return s; }
i128 c3_take7( int a, int b, int c, int d, int e, int f, int g, struct S3 s ) { return s.v + s.c + a + g; }
extern i128 T3_S16( int a, struct S16 s, int b );
i128 c3_calls_s16( void ) { struct S16 s; s.v = (i128)1 << 99; return T3_S16( 3, s, 4 ); }
