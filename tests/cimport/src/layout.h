/* layout.h -- records whose layout tiko's frontend must be checked against clang's.
   Freestanding: nothing beyond the compiler's own <stddef.h>. */

/* SysV packs 'tail' into the bit-fields' storage unit (bit 8, size 4); Windows starts a
   new unit (bit 32, size 8). 'extern "c"' says both, each on its own target. */
struct lay_bits {
    unsigned int lo : 3;
    unsigned int hi : 5;
    unsigned char tail;
};

/* ...and what holds one by value is laid out with it. */
struct lay_holds_bits {
    struct lay_bits b;
    int after;
};
struct lay_points_bits {
    struct lay_bits *b;
    int after;
};

/* A packed record is 1-aligned to C, and embeds at offset 1. */
#pragma pack(push, 1)
struct lay_packed {
    char c;
    int i;
};
#pragma pack(pop)
struct lay_holds_packed {
    char c;
    struct lay_packed p;
};
/* ...also in a record that is not packed: fbc's rule places a 'field = 1' type at its
   members' natural alignment -- 'p' at 4 where C has 1. 'extern "c"' places it at 1. */
struct lay_holds_packed4 {
    char c;
    struct lay_packed p;
    int x;
};

/* Over-aligned: C aligns it to 16. FreeBASIC aligns nothing past 8; the size is padded
   to C's and the record is kept. */
struct lay_over {
    long long a;
} __attribute__((aligned(16)));

struct lay_plain {
    char c;
    double d;
    short s;
};

/* A member over-aligned by an attribute has no FreeBASIC spelling: C puts 'x' at 16, tiko
   at 4 -- on every target. Refused, and what holds it by value goes with it. */
struct lay_member_aligned {
    char c;
    int x __attribute__((aligned(16)));
};
struct lay_holds_aligned {
    struct lay_member_aligned m;
    int after;
};

/* A '#pragma pack' that changes no alignment cannot be seen by the importer, yet SysV does
   not move a packed bit-field to its type's next boundary: 'b' is at bit 30 on linux-x86_64,
   32 everywhere else. Refused on linux-x86_64 only. */
#pragma pack(push, 8)
struct lay_pack8_bits {
    int a : 30;
    int b : 5;
};
#pragma pack(pop)

/* __int128 is 16-aligned in tiko as in C, so a record holding one is not over-aligned: 'v'
   at 16 and no pad, 'i' at 16 and tiko's own rounding reaches C's 32 -- no pad there
   either. One that holds such a record is padded as before ('w' ends at 33, C's size 48),
   a packed one is 'field = 4' at 20 bytes, and a union is 16. */
struct lay_wide { char c; __int128 v; };
struct lay_wide_tail { __int128 v; int i; };
struct lay_holds_wide_tail { struct lay_wide_tail w; char c; };
#pragma pack(push, 4)
struct lay_wide_pack4 { char c; unsigned __int128 v; };
#pragma pack(pop)
union lay_wide_union { __int128 v; char c[3]; };
