/* refused.h -- records the layout check refuses, reached through pointers. tiko has no
   spelling for an over-aligned member, so each of these lays out differently from C's on
   every target, and is skipped. Freestanding: no includes. */

struct ref_late;

struct ref_over { int k; _Alignas(16) int v; };
typedef struct ref_pun { int k; _Alignas(16) int v; } ref_pun;

/* a pointer to a record skipped EARLIER, as a parameter, a const one, and a field */
void ref_use(struct ref_over *p);
void ref_use_const(const ref_pun *p);
struct ref_points { struct ref_over *o; int after; };

/* a pointer to a record defined, and skipped, LATER */
void ref_early(struct ref_late *p);
struct ref_late { int k; _Alignas(16) int v; };

/* an inline function has no symbol: it claims its name, and is not in the rename ledger */
static inline int time(int x) { return x; }

/* a bit-field of __int128 -- clang takes one, tiko does not: refused, and a pointer to it
   is a pointer to the record introduced by an alias */
struct ref_wbits { __int128 x : 5; int y; };
void ref_wide(struct ref_wbits *p);
