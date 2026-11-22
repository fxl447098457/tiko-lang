/* layout.h -- records whose bit-fields MSVC and SysV lay out differently: written with
   'extern "c"', tiko lays each out by its target's C rule, and --verify agrees with clang. */
#ifndef LAYOUT_H
#define LAYOUT_H

struct Mixed { char a : 3; int b : 5; };        /* MSVC starts a new unit at 'int' */
struct Plain { unsigned x : 3; unsigned y : 5; char c; };
struct Holds { struct Mixed m; int n; };        /* holds one by value */
void take(struct Mixed *m, struct Plain *p);    /* and a pointer to each */

/* __int128 is 16-aligned in tiko as in C: not over-alignment, and --verify agrees */
struct Wide { char c; __int128 v; unsigned __int128 u; };
struct WideTail { __int128_t v; int i; };       /* tiko's rounding reaches C's 32 */
struct HoldsWide { char c; struct WideTail w; }; /* 'w' at 16 */
__uint128_t wide_sum(struct Wide *w, __int128 k);

#endif
