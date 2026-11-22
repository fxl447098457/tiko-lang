/* shapes.h -- the declaration shapes the importer translates, FREESTANDING only
 * (stddef.h, stdint.h), so it parses for every target on any host. */
#include <stddef.h>
#include <stdint.h>

/* a record used through a pointer BEFORE it is defined: a forward alias */
struct later;
struct uses_later { struct later *next; int n; };
struct later { struct uses_later *back; double d; };

/* never defined anywhere: opaque */
typedef struct handle_s *handle_t;
struct handle_s;

/* const, pointers to const, const pointers, strings */
struct strings {
    const char *name;
    char *const fixed;
    const unsigned char *bytes;
    char buf[16];
    int grid[3][4];
    const void *raw;
    wchar_t *wide;
};

/* anonymous members: a union inside a struct and a struct inside a union */
struct variant {
    int kind;
    union { int i; double d; void *p; };
    struct { short lo, hi; } pair;
};

union anon_host {
    struct { uint16_t a, b; };
    uint32_t whole;
};

/* function pointers, a callback typedef and a record holding them */
typedef int (*compare_fn)(const void *a, const void *b);
typedef void (*notify_fn)(void *user, int code, ...);
struct vtable {
    int (*open)(const char *path, int flags);
    void (*close)(int fd);
    compare_fn cmp;
};

/* packing and alignment */
#pragma pack(push, 1)
struct packed1 { char c; int i; short s; };
#pragma pack(pop)
struct aligned8 { char c; long long ll; };

/* anonymous enum, named enum with negative and large values, typedef'd enum */
enum { SHAPES_ONE = 1, SHAPES_TWO };
enum signed_e { NEG = -5, ZERO = 0, BIG = 100000 };
typedef enum { MODE_A, MODE_B = 7 } mode_t2;

/* typedef of a typedef, of a pointer, of a function type */
typedef uint32_t word_t;
typedef word_t *word_ptr;
typedef int handler(int);

/* functions: void, unnamed parameters, records by value, variadic, pointer returns */
void shapes_init(void);
int shapes_sum(int, int, int);
struct aligned8 shapes_make(char c, long long v);
const char *shapes_name(handle_t h);
int shapes_log(int level, const char *fmt, ...);
void shapes_sort(void *base, size_t n, size_t size, compare_fn cmp);
static inline int shapes_twice(int x) { return x + x; }

/* globals */
extern int shapes_count;
extern const char *const shapes_version;
extern struct vtable shapes_ops;
extern int shapes_table[8];

/* names FreeBASIC reserves */
struct point { int x, y; };
int print(const char *s);
struct type_names { int mod; int next; int dim; int string; };

/* __int128: tiko's int128 / uint128, under both spellings clang has -- the keyword and its
   builtin typedefs. A record holding one is 16-aligned by its own rule, not over-aligned. */
typedef __int128 shapes_i128;
typedef unsigned __int128 shapes_u128;
typedef __int128_t shapes_i128t;
typedef __uint128_t shapes_u128t;
struct wide16 { char c; __int128 v; unsigned __int128 u; };
__int128 shapes_wide(__int128 a, unsigned __int128 *b, struct wide16 w);
/* a 128-bit macro value: libclang reads only its low 64 bits, so none is kept */
#define SHAPES_WIDE_BIG ((__int128)1 << 100)
#define SHAPES_WIDE_ONES (~(unsigned __int128)0)
