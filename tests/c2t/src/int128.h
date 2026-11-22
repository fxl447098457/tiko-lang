/* int128.h -- C's __int128 in tiko c2t: tiko's int128 / uint128 under the keyword and
   clang's builtin typedefs; a cast to one in a function-like macro; a 128-bit macro value,
   which libclang reads only the low 64 bits of, refused with a TODO. */
#ifndef INT128_H
#define INT128_H

typedef __int128 i128;
typedef unsigned __int128 u128;
typedef __int128_t i128t;
typedef __uint128_t u128t;
struct Pair128 { __int128 lo; unsigned __int128 hi; };
u128 mul128(u128 a, u128 b, struct Pair128 *out);
#define WIDEN(x) ((__int128)(x))
#define UWIDEN(x) ((unsigned __int128)(x))
#define WIDE_BIG ((__int128)1 << 100)

#endif
