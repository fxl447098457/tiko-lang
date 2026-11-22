#!/usr/bin/env python3
"""aapcslane.py -- generate the RUNNING AAPCS64 (Apple) ABI lane: tests/abi/apple/lane.c and
lane.tiko, from one table of shapes, so both sides agree by construction.

    python build/aapcslane.py            write both files
    python build/aapcslane.py --check    exit 1 if either file differs from what it would write

The lane is built and run by build/aapcslane.sh. tiko calls C and C calls tiko, with every
shape passed and returned BY VALUE, and C checks every value it is handed or handed back --
so the tiko side needs no runtime at all (no print, no strings): only field stores, integer
arithmetic and calls. Each direction uses its own patterns, so a value that arrives from the
wrong register or stack slot cannot match by accident:

    tiko -> C     tiko passes pattern 1; C returns pattern 2 and tiko hands it back to check
    C -> tiko     C passes pattern 3; tiko hands the argument back to check and returns 4
    callbacks     tiko gives C '@t_take_X' and C calls through it (pattern 3 -> 4); tiko
                  calls c_take_X through a procedure pointer (pattern 1 -> 2)

Element k of a shape (declaration order, arrays and nested fields flattened; a union has its
first member only) under pattern p is base = (10p + k + 1), negated for odd k, then scaled
per type so every byte of a wider field matters: char base, short base*257, int base*65537,
long long base*0x100000001, float base + 0.5, double base + 0.25 -- all exact.

Then the register-exhausting prefixes (an aggregate that no longer fits the registers left
goes WHOLE to the stack, and the next scalar follows it there), and varargs in both
directions (Apple: every variadic argument on the stack). main checks that every expected
call happened, so a call that was skipped cannot pass.

THE LONG VARARG TAILS (t_va2, t_va3, t_va4; docs/tiko-linux-arm64 L1): generic AAPCS64 (linux-arm64)
passes a variadic argument in registers while any are left and walks a 32-byte va_list record
to read it back, so cva_arg is tiko's own sequence there. C hands tiko 12 longint/double pairs
with an int128 in the middle -- past x0-x7 and v0-v7 both, the int128 arriving when one GP
register is left (so it goes to the stack, 16-aligned, and every later integer follows it) --
and 10 pairs whose list tiko cva_copy's and hands BYVAL to a C 'va_list' reader; and the other
way, C's own va_list handed BYVAL to a tiko reader of 10 pairs (t_vread4). The same lane runs on
the Mac, where all of it is on the stack, and on the linux-x86_64 control -- where SysV's va_list
is an ARRAY, so a byval one is the caller's list by address both ways, and tiko's cva_arg through
that pointer is clang's sequence (LLVM's va_arg is miscompiled there at -O0).

NARROW INTEGERS: Apple packs a stack argument at its NATURAL size (bool at sp+0, a short
after it at sp+2), where AAPCS64, SysV and Win64 give each one an 8-byte slot -- so the
prefixes after eight pointers carry bool / char / short, signed and unsigned, with values
whose sign or high bit shows a wrong extension; those prefixes are also called through a
procedure pointer. And the narrow RESULTS both ways: tiko returns a value truncated from a
wider one, so a result whose upper bits were never cleared reads back wrong in C.
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_C = os.path.join(ROOT, "tests", "abi", "apple", "lane.c")
OUT_T = os.path.join(ROOT, "tests", "abi", "apple", "lane.tiko")

C_TYPE = {"c": "signed char", "s": "short", "i": "int", "l": "long long", "f": "float", "d": "double",
          "b": "bool", "C": "unsigned char", "S": "unsigned short", "p": "void *"}
T_TYPE = {"c": "byte", "s": "short", "i": "long", "l": "longint", "f": "single", "d": "double",
          "b": "boolean", "C": "ubyte", "S": "ushort", "p": "any ptr"}
NARROW = "bcsCS"
VA2_PAIRS = 12   # t_va2: longint/double pairs, the int128 after the first half
VA3_PAIRS = 10   # t_va3: pairs read, then re-read in C through a cva_copy
VA4_PAIRS = 10   # t_va4: C's va_list handed byval to tiko, which reads the pairs

# name -> (kind, [(field, type, count)]); a type is a scalar code or an earlier shape's name
SHAPES = {}
ORDER = []


def shape(name, fields, kind="struct"):
    SHAPES[name] = (kind, fields)
    ORDER.append(name)


# the static lane's shapes (tests/abi/apple/sig.c)
shape("C1", [("a", "c", 1)])
shape("C3", [("a", "c", 1), ("b", "c", 1), ("c", "c", 1)])
shape("S3", [("a", "s", 1), ("b", "c", 1)])
shape("HS", [("a", "s", 3)])
shape("I1", [("a", "i", 1)])
shape("I5", [("a", "i", 1), ("b", "c", 1)])
shape("I2", [("a", "i", 1), ("b", "i", 1)])
shape("I3", [("a", "i", 1), ("b", "i", 1), ("c", "i", 1)])
shape("L2", [("a", "l", 1), ("b", "l", 1)])
shape("L12", [("a", "l", 1), ("b", "i", 1)])
shape("L3", [("a", "l", 1), ("b", "l", 1), ("c", "l", 1)])
for n in range(1, 6):
    shape("F%d" % n, [("abcde"[k], "f", 1) for k in range(n)])
for n in range(1, 6):
    shape("D%d" % n, [("abcde"[k], "d", 1) for k in range(n)])
shape("FD", [("a", "f", 1), ("b", "d", 1)])
shape("FI", [("a", "f", 1), ("b", "i", 1)])
shape("FA3", [("a", "f", 3)])
shape("NF4", [("x", "F2", 1), ("y", "F2", 1)])
shape("DA2", [("a", "d", 2)])
shape("UF", [("a", "f", 1), ("b", "f", 1)], "union")
shape("UD", [("a", "d", 1), ("b", "l", 1)], "union")
# every size from 1 to 33 bytes
for n in range(1, 34):
    shape("B%d" % n, [("a", "c", n)])
# mixed and nested
shape("MX", [("a", "c", 1), ("b", "i", 2), ("c", "s", 1)])
shape("ND", [("x", "D2", 1), ("y", "d", 1)])
shape("NFA", [("x", "F2", 1), ("y", "f", 2)])
shape("FFD", [("x", "F2", 1), ("y", "d", 1)])
shape("MIX24", [("a", "d", 1), ("b", "f", 1), ("c", "i", 1), ("d", "l", 1)])

# register-exhausting prefixes: (name, params); a param is a scalar code or a shape name
PREFIXES = [
    ("hfa9", ["d", "d", "d", "d", "d", "d", "D3", "d"]),     # 6 V regs used, D3 needs 3: stack
    ("hfaf", ["f", "f", "f", "f", "f", "f", "f", "F2", "f"]),  # 7 used, F2 needs 2: stack
    # float HFAs ON the stack, back to back: generic AAPCS64 starts each at an 8-byte boundary
    # (the second F3 at sp+16, not sp+12), Apple packs them at natural alignment -- the case
    # clang's alignstack(8) on aarch64-linux describes (docs/tiko-linux-arm64 L1)
    ("p8hf", ["d"] * 8 + ["F3", "F3", "F1", "f", "F3"]),
    ("gpr7", ["l", "l", "l", "l", "l", "l", "l", "L2", "l"]),  # 7 GPRs used, L2 needs 2: stack
    ("mix", ["i"] * 8 + ["d"] * 8 + ["I3", "D2", "i", "d"]),   # everything after on the stack
    ("big", ["i"] * 7 + ["B33", "i", "MIX24"]),                # indirect ones: pointers in x7, stack
    # narrow integers: in registers, then packed on the stack after eight pointers
    ("nreg", ["b", "c", "C", "s", "S", "b"]),
    ("p8bs", ["p"] * 8 + ["b", "S"]),                          # NSEvent keyEvent's tail: sp+0, sp+2
    ("p8mix", ["p"] * 8 + ["b", "c", "C", "s", "S", "b", "c", "S"]),
    ("p8int", ["p"] * 8 + ["c", "i", "s", "l", "C", "d", "S", "b"]),
]

# narrow results: (code, the wider value tiko truncates, what C must read back)
RETS = [("bool", 5, 1), ("schar", 0x1FD, -3), ("uchar", 0x1C8, 200), ("short", 0x1FFF0, -16),
        ("ushort", 0x1FFF0, 0xFFF0)]
RCODE = {"bool": "b", "schar": "c", "uchar": "C", "short": "s", "ushort": "S"}
T_CONV = {"b": "cbool", "c": "cbyte", "C": "cubyte", "s": "cshort", "S": "cushort"}
# (names, not codes: tiko identifiers ignore case)


def pval(t, k):
    """The value prefix scalar k of code t carries (both directions)."""
    if t == "c":
        return -(k + 1)
    if t == "s":
        return -(1000 + k)
    if t == "C":
        return 200 + k
    if t == "S":
        return 65000 + k
    if t == "b":
        return 1 if k % 2 == 0 else 0
    return k + 1


def c_lit(t, k):
    if t == "b":
        return "true" if pval(t, k) else "false"
    if t == "p":
        return "(void *)%d" % pval(t, k)
    return str(pval(t, k))


def t_lit(t, k):
    if t == "b":
        return "true" if pval(t, k) else "false"
    if t == "p":
        return "cast( any ptr, %d )" % pval(t, k)
    return str(pval(t, k))


def viaptr(params):
    return any(t in NARROW for t in params)


def elems(name, path):
    """[(access path, scalar code)] in declaration order."""
    kind, fields = SHAPES[name]
    if kind == "union":
        fields = fields[:1]
    out = []
    for fname, ftype, count in fields:
        for j in range(count):
            p = path + [(fname, j if count > 1 else None)]
            if ftype in C_TYPE:
                out.append((p, ftype))
            else:
                out.extend(elems(ftype, p))
    return out


def c_access(p):
    return ".".join(f + ("[%d]" % j if j is not None else "") for f, j in p)


def t_access(p):
    return ".".join(f + ("(%d)" % j if j is not None else "") for f, j in p)


def gen_c():
    L = []
    w = L.append
    w("/* tests/abi/apple/lane.c -- GENERATED by build/aapcslane.py: do not edit; regenerate.")
    w("   The C side of the running AAPCS64 (Apple) lane (build/aapcslane.sh). It owns main and")
    w("   makes every check; lane.tiko calls it and is called by it. */")
    w("#include <stdbool.h>")
    w("#include <stdio.h>")
    w("#include <stdarg.h>")
    w("#include <string.h>")
    w("")
    w("static int checks, fails, calls;")
    w("static long long pb( int p, int k ) { long long b = 10 * p + k + 1; return ( k & 1 ) ? -b : b; }")
    w("static signed char pc( int p, int k ) { return (signed char)pb( p, k ); }")
    w("static short ps( int p, int k ) { return (short)( pb( p, k ) * 257 ); }")
    w("static int pi( int p, int k ) { return (int)( pb( p, k ) * 65537 ); }")
    w("static long long pl( int p, int k ) { return pb( p, k ) * 0x100000001LL; }")
    w("static float pf( int p, int k ) { return (float)pb( p, k ) + 0.5f; }")
    w("static double pd( int p, int k ) { return (double)pb( p, k ) + 0.25; }")
    w("static void ck_i( const char *ctx, const char *f, long long got, long long want ) {")
    w("    checks++;")
    w("    if( got != want ) { fails++; printf( \"FAIL %s .%s: got %lld want %lld\\n\", ctx, f, got, want ); }")
    w("}")
    w("static void ck_d( const char *ctx, const char *f, double got, double want ) {")
    w("    checks++;")
    w("    if( got != want ) { fails++; printf( \"FAIL %s .%s: got %g want %g\\n\", ctx, f, got, want ); }")
    w("}")
    w("static int marker;")
    w("void *c_marker( void ) { return &marker; }")
    w("")
    for name in ORDER:
        kind, fields = SHAPES[name]
        w("typedef %s {" % kind)
        for fname, ftype, count in fields:
            ct = C_TYPE.get(ftype, ftype)
            w("    %s %s%s;" % (ct, fname, "[%d]" % count if count > 1 else ""))
        w("} %s;" % name)
    w("")
    for name in ORDER:
        es = elems(name, [])
        w("static void fill_%s( %s *v, int p ) {" % (name, name))
        w("    memset( v, 0, sizeof *v );")
        for k, (p, t) in enumerate(es):
            w("    v->%s = p%s( p, %d );" % (c_access(p), t, k))
        w("}")
        w("static void ck_%s( const char *ctx, const %s *v, int p ) {" % (name, name))
        for k, (p, t) in enumerate(es):
            fn = "ck_d" if t in "fd" else "ck_i"
            w("    %s( ctx, \"%s\", v->%s, p%s( p, %d ) );" % (fn, c_access(p), c_access(p), t, k))
        w("}")
        w("%s c_take_%s( int n, %s v ) {" % (name, name, name))
        w("    calls++; ck_i( \"c_take_%s\", \"n\", n, 7 ); ck_%s( \"c_take_%s arg\", &v, 1 );" % (name, name, name))
        w("    %s r; fill_%s( &r, 2 ); return r;" % (name, name))
        w("}")
        w("void c_chk_%s( const %s *r ) { calls++; ck_%s( \"c_take_%s result, in tiko\", r, 2 ); }" % (name, name, name, name))
        w("void c_seen_%s( int n, const %s *v ) {" % (name, name))
        w("    calls++; ck_i( \"t_take_%s\", \"n\", n, 7 ); ck_%s( \"t_take_%s arg, in tiko\", v, 3 );" % (name, name, name))
        w("}")
        w("%s t_take_%s( int n, %s v );" % (name, name, name))
        w("void c_cb_%s( %s ( *cb )( int, %s ) ) {" % (name, name, name))
        w("    calls++; %s a; fill_%s( &a, 3 ); %s r = cb( 7, a ); ck_%s( \"callback t_take_%s result\", &r, 4 );" % (name, name, name, name, name))
        w("}")
        w("static void c_call_%s( void ) {" % name)
        w("    %s a; fill_%s( &a, 3 ); %s r = t_take_%s( 7, a ); ck_%s( \"t_take_%s result\", &r, 4 );" % (name, name, name, name, name, name))
        w("}")
    w("")
    # prefixes
    for pname, params in PREFIXES:
        decl = ", ".join("%s a%d" % (C_TYPE.get(t, t), k) for k, t in enumerate(params))
        pdecl = ", ".join(("%s a%d" % (C_TYPE[t], k)) if t in C_TYPE else ("const %s *a%d" % (t, k))
                          for k, t in enumerate(params))
        def body(ctx, pat, deref):
            out = []
            for k, t in enumerate(params):
                if t in C_TYPE:
                    fn = "ck_d" if t in "fd" else "ck_i"
                    got = "(long long)a%d" % k if t == "p" else "a%d" % k
                    out.append("%s( \"%s\", \"a%d\", %s, %d );" % (fn, ctx, k, got, pval(t, k)))
                else:
                    out.append("ck_%s( \"%s a%d\", %sa%d, %d );" % (t, ctx, k, deref, k, pat))
            return " ".join(out)
        w("void c_%s( %s ) { calls++; %s }" % (pname, decl, body("c_" + pname, 1, "&")))
        w("void c_seen_%s( %s ) { calls++; %s }" % (pname, pdecl, body("t_" + pname + ", in tiko", 3, "")))
        w("void t_%s( %s );" % (pname, decl))
        w("static void c_call_%s( void ) {" % pname)
        args = []
        for k, t in enumerate(params):
            if t in C_TYPE:
                args.append(c_lit(t, k))
            else:
                w("    %s s%d; fill_%s( &s%d, 3 );" % (t, k, t, k))
                args.append("s%d" % k)
        w("    t_%s( %s );" % (pname, ", ".join(args)))
        w("}")
    w("")
    # narrow results
    for t, wide, want in RETS:
        ct = C_TYPE[RCODE[t]]
        w("%s c_ret_%s( long long x ) { calls++; return (%s)x; }" % (ct, t, ct))
        w("void c_chk_ret_%s( %s r ) { calls++; ck_i( \"c_ret_%s result, in tiko\", \"r\", r, %d ); }" % (t, ct, t, want))
        w("%s t_ret_%s( long long x );" % (ct, t))
    w("")
    # varargs
    w("long long c_va( int n, ... ) {")
    w("    va_list ap; va_start( ap, n ); calls++;")
    w("    ck_i( \"c_va\", \"n\", n, 7 );")
    w("    ck_i( \"c_va\", \"long\", va_arg( ap, int ), 11 );")
    w("    ck_i( \"c_va\", \"longint\", va_arg( ap, long long ), 12 );")
    w("    ck_d( \"c_va\", \"double\", va_arg( ap, double ), 13.5 );")
    w("    ck_i( \"c_va\", \"ptr\", (long long)va_arg( ap, void * ), (long long)&marker );")
    w("    ck_d( \"c_va\", \"single (promoted)\", va_arg( ap, double ), 14.5 );")
    w("    ck_i( \"c_va\", \"byte (promoted)\", va_arg( ap, int ), -15 );")
    w("    ck_i( \"c_va\", \"short (promoted)\", va_arg( ap, int ), -16 );")
    w("    ck_i( \"c_va\", \"integer\", va_arg( ap, long long ), 17 );")
    w("    va_end( ap );")
    w("    return 99;")
    w("}")
    w("void c_va_ret( long long r ) { calls++; ck_i( \"c_va\", \"result, in tiko\", r, 99 ); }")
    w("void c_seen_va( int n, int a, long long b, double c, void *p ) {")
    w("    calls++; ck_i( \"t_va\", \"n\", n, 7 ); ck_i( \"t_va\", \"long\", a, 11 );")
    w("    ck_i( \"t_va\", \"longint\", b, 12 ); ck_d( \"t_va\", \"double\", c, 13.5 );")
    w("    ck_i( \"t_va\", \"ptr\", (long long)p, (long long)&marker );")
    w("}")
    w("long long t_va( int n, ... );")
    w("void c_seen_va2( int k, long long i, double d ) {")
    w("    calls++; ck_i( \"t_va2\", \"longint\", i, 1000 + k ); ck_d( \"t_va2\", \"double\", d, k + 0.5 );")
    w("}")
    w("void c_seen_va128( long long lo, long long hi ) {")
    w("    calls++; ck_i( \"t_va2\", \"int128 lo\", lo, 0x1122334455667788LL ); ck_i( \"t_va2\", \"int128 hi\", hi, -2 );")
    w("}")
    w("long long t_va2( int n, ... );")
    w("void c_seen_va3( int k, long long i, double d ) {")
    w("    calls++; ck_i( \"t_va3\", \"longint\", i, 2000 + k ); ck_d( \"t_va3\", \"double\", d, k + 0.25 );")
    w("}")
    w("static void c_vread_( int n, va_list ap ) {")
    w("    calls++;")
    w("    for( int k = 0; k < n; k++ ) {")
    w("        ck_i( \"t_va3 c_vread\", \"longint\", va_arg( ap, long long ), 2000 + k );")
    w("        ck_d( \"t_va3 c_vread\", \"double\", va_arg( ap, double ), k + 0.25 );")
    w("    }")
    w("}")
    w("void c_vread( int n, va_list ap ) { c_vread_( n, ap ); }")
    w("void c_vreadp( int n, va_list *ap ) { c_vread_( n, *ap ); }")
    w("long long t_va3( int n, ... );")
    w("void c_seen_va4( int k, long long i, double d ) {")
    w("    calls++; ck_i( \"t_va4\", \"longint\", i, 3000 + k ); ck_d( \"t_va4\", \"double\", d, k + 0.75 );")
    w("}")
    w("long long t_vread4( int n, va_list ap );")
    w("static long long c_va4( int n, ... ) {")
    w("    va_list ap; va_start( ap, n ); long long r = t_vread4( n, ap ); va_end( ap ); return r;")
    w("}")
    w("")
    w("void trun_all( void );")
    expected = 7 * len(ORDER) + sum(3 if viaptr(p) else 2 for _, p in PREFIXES) + 2 * len(RETS) + 3
    expected += VA2_PAIRS + 1 + VA3_PAIRS + 2 + VA4_PAIRS
    w("#define EXPECTED_CALLS %d" % expected)
    w("#define VA2_Q ((__int128)-2 * ((__int128)1 << 64) + (__int128)0x1122334455667788LL)")
    w("int main( void ) {")
    w("    trun_all( );")
    for name in ORDER:
        w("    c_call_%s( );" % name)
    for pname, _ in PREFIXES:
        w("    c_call_%s( );" % pname)
    for t, wide, want in RETS:
        w("    ck_i( \"t_ret_%s\", \"result\", t_ret_%s( %d ), %d );" % (t, t, wide, want))
    w("    ck_i( \"t_va\", \"result\", t_va( 7, 11, 12LL, 13.5, &marker ), 99 );")
    half = VA2_PAIRS // 2
    a = ", ".join("%dLL, %d.5" % (1000 + k, k) for k in range(half))
    b = ", ".join("%dLL, %d.5" % (1000 + k, k) for k in range(half, VA2_PAIRS))
    w("    ck_i( \"t_va2\", \"result\", t_va2( %d, %s, VA2_Q, %s ), 77 );" % (VA2_PAIRS, a, b))
    c = ", ".join("%dLL, %d.25" % (2000 + k, k) for k in range(VA3_PAIRS))
    w("    ck_i( \"t_va3\", \"result\", t_va3( %d, %s ), 55 );" % (VA3_PAIRS, c))
    c = ", ".join("%dLL, %d.75" % (3000 + k, k) for k in range(VA4_PAIRS))
    w("    ck_i( \"t_va4\", \"result\", c_va4( %d, %s ), 44 );" % (VA4_PAIRS, c))
    w("    ck_i( \"main\", \"calls\", calls, EXPECTED_CALLS );")
    w("    printf( \"aapcs lane: %d shapes, %d checks, %d failed\\n\", " + str(len(ORDER)) + ", checks, fails );")
    w("    return fails ? 1 : 0;")
    w("}")
    return "\n".join(L) + "\n"


def gen_t():
    L = []
    w = L.append
    w("'' tests/abi/apple/lane.tiko -- GENERATED by build/aapcslane.py: do not edit; regenerate.")
    w("'' tiko's side of the running AAPCS64 (Apple) lane (build/aapcslane.sh). No runtime: C owns")
    w("'' main and makes every check; this file only stores fields and calls.")
    w("")
    for name in ORDER:
        kind, fields = SHAPES[name]
        w("%s %s" % ("type" if kind == "struct" else "union", name))
        for fname, ftype, count in fields:
            tt = T_TYPE.get(ftype, ftype)
            w("    %s%s as %s" % (fname, "(0 to %d)" % (count - 1) if count > 1 else "", tt))
        w("end %s" % ("type" if kind == "struct" else "union"))
    w("")
    w("extern \"C\"")
    w("declare function c_marker( ) as any ptr")
    for name in ORDER:
        w("declare function c_take_%s( byval n as long, byval v as %s ) as %s" % (name, name, name))
        w("declare sub c_chk_%s( byval r as %s ptr )" % (name, name))
        w("declare sub c_seen_%s( byval n as long, byval v as %s ptr )" % (name, name))
        w("declare sub c_cb_%s( byval cb as function( byval n as long, byval v as %s ) as %s )" % (name, name, name))
    for pname, params in PREFIXES:
        decl = ", ".join("byval a%d as %s" % (k, T_TYPE.get(t, t)) for k, t in enumerate(params))
        pdecl = ", ".join(("byval a%d as %s" % (k, T_TYPE[t])) if t in T_TYPE else ("byval a%d as %s ptr" % (k, t))
                          for k, t in enumerate(params))
        w("declare sub c_%s( %s )" % (pname, decl))
        w("declare sub c_seen_%s( %s )" % (pname, pdecl))
    for t, wide, want in RETS:
        w("declare function c_ret_%s( byval x as longint ) as %s" % (t, T_TYPE[RCODE[t]]))
        w("declare sub c_chk_ret_%s( byval r as %s )" % (t, T_TYPE[RCODE[t]]))
    w("declare function c_va cdecl( byval n as long, ... ) as longint")
    w("declare sub c_va_ret( byval r as longint )")
    w("declare sub c_seen_va( byval n as long, byval a as long, byval b as longint, byval c as double, byval p as any ptr )")
    w("declare sub c_seen_va2( byval k as long, byval i as longint, byval d as double )")
    w("declare sub c_seen_va128( byval lo as longint, byval hi as longint )")
    w("declare sub c_seen_va3( byval k as long, byval i as longint, byval d as double )")
    w("declare sub c_vread( byval n as long, byval ap as cva_list )")
    w("declare sub c_vreadp( byval n as long, byref ap as cva_list )")
    w("declare sub c_seen_va4( byval k as long, byval i as longint, byval d as double )")
    w("")
    w("function tk_pb( byval p as long, byval k as long ) as longint")
    w("    dim as longint b = 10 * p + k + 1")
    w("    if (k and 1) <> 0 then b = -b")
    w("    return b")
    w("end function")
    w("function tk_pc( byval p as long, byval k as long ) as byte")
    w("    return cbyte( tk_pb( p, k ) )")
    w("end function")
    w("function tk_ps( byval p as long, byval k as long ) as short")
    w("    return cshort( tk_pb( p, k ) * 257 )")
    w("end function")
    w("function tk_pi( byval p as long, byval k as long ) as long")
    w("    return clng( tk_pb( p, k ) * 65537 )")
    w("end function")
    w("function tk_pl( byval p as long, byval k as long ) as longint")
    w("    return tk_pb( p, k ) * &h100000001ll")
    w("end function")
    w("function tk_pf( byval p as long, byval k as long ) as single")
    w("    return csng( tk_pb( p, k ) ) + 0.5")
    w("end function")
    w("function tk_pd( byval p as long, byval k as long ) as double")
    w("    return cdbl( tk_pb( p, k ) ) + 0.25")
    w("end function")
    w("")
    for name in ORDER:
        es = elems(name, [])
        w("sub tfill_%s( byref v as %s, byval p as long )" % (name, name))
        for k, (p, t) in enumerate(es):
            w("    v.%s = tk_p%s( p, %d )" % (t_access(p), t, k))
        w("end sub")
        w("function t_take_%s( byval n as long, byval v as %s ) as %s" % (name, name, name))
        w("    c_seen_%s( n, @v )" % name)
        w("    dim as %s r" % name)
        w("    tfill_%s( r, 4 )" % name)
        w("    return r")
        w("end function")
        w("sub trun_%s( )" % name)
        w("    dim as %s v" % name)
        w("    tfill_%s( v, 1 )" % name)
        w("    dim as %s r = c_take_%s( 7, v )" % (name, name))
        w("    c_chk_%s( @r )" % name)
        w("    dim fp as function( byval n as long, byval v as %s ) as %s = @c_take_%s" % (name, name, name))
        w("    dim as %s r2 = fp( 7, v )" % name)
        w("    c_chk_%s( @r2 )" % name)
        w("    c_cb_%s( @t_take_%s )" % (name, name))
        w("end sub")
    w("")
    for pname, params in PREFIXES:
        decl = ", ".join("byval a%d as %s" % (k, T_TYPE.get(t, t)) for k, t in enumerate(params))
        w("sub t_%s( %s )" % (pname, decl))
        w("    c_seen_%s( %s )" % (pname, ", ".join(("a%d" % k) if t in T_TYPE else ("@a%d" % k)
                                                  for k, t in enumerate(params))))
        w("end sub")
        w("sub trun_%s( )" % pname)
        args = []
        for k, t in enumerate(params):
            if t in T_TYPE:
                args.append(t_lit(t, k))
            else:
                w("    dim as %s s%d" % (t, k))
                w("    tfill_%s( s%d, 1 )" % (t, k))
                args.append("s%d" % k)
        w("    c_%s( %s )" % (pname, ", ".join(args)))
        if viaptr(params):
            w("    dim fp as sub( %s ) = @c_%s" % (decl, pname))
            w("    fp( %s )" % ", ".join(args))
        w("end sub")
    w("")
    for t, wide, want in RETS:
        w("function t_ret_%s( byval x as longint ) as %s" % (t, T_TYPE[RCODE[t]]))
        w("    return %s( x )" % T_CONV[RCODE[t]])
        w("end function")
        w("sub trun_ret_%s( )" % t)
        w("    c_chk_ret_%s( c_ret_%s( %d ) )" % (t, t, wide))
        w("end sub")
    w("")
    w("function t_va cdecl( byval n as long, ... ) as longint")
    w("    dim as cva_list ap")
    w("    cva_start( ap, n )")
    w("    dim as long a = cva_arg( ap, long )")
    w("    dim as longint b = cva_arg( ap, longint )")
    w("    dim as double c = cva_arg( ap, double )")
    w("    dim as any ptr p = cva_arg( ap, any ptr )")
    w("    cva_end( ap )")
    w("    c_seen_va( n, a, b, c, p )")
    w("    return 99")
    w("end function")
    w("")
    w("function t_va2 cdecl( byval n as long, ... ) as longint")
    w("    dim as cva_list ap")
    w("    cva_start( ap, n )")
    w("    for k as long = 0 to n - 1")
    w("        if k = n \\ 2 then")
    w("            dim as int128 q = cva_arg( ap, int128 )")
    w("            c_seen_va128( clngint( q ), clngint( q shr 64 ) )")
    w("        end if")
    w("        dim as longint i = cva_arg( ap, longint )")
    w("        dim as double d = cva_arg( ap, double )")
    w("        c_seen_va2( k, i, d )")
    w("    next")
    w("    cva_end( ap )")
    w("    return 77")
    w("end function")
    w("")
    w("function t_va3 cdecl( byval n as long, ... ) as longint")
    w("    dim as cva_list ap, cp, cp2")
    w("    cva_start( ap, n )")
    w("    cva_copy( cp, ap )")
    w("    cva_copy( cp2, ap )")
    w("    for k as long = 0 to n - 1")
    w("        dim as longint i = cva_arg( ap, longint )")
    w("        dim as double d = cva_arg( ap, double )")
    w("        c_seen_va3( k, i, d )")
    w("    next")
    w("    cva_end( ap )")
    # BYVAL TO A C va_list ON EVERY TARGET. linux-x86_64 passed the 24-byte record by value
    # where C (SysV's va_list is an array) takes a pointer, and this lane segfaulted there,
    # until the list became the caller's, by address (master 2c61ce1f5, 2026-11-19). The
    # pointer form is called too, so both keep running.
    w("    c_vread( n, cp )")
    w("    c_vreadp( n, cp2 )")
    w("    cva_end( cp )")
    w("    cva_end( cp2 )")
    w("    return 55")
    w("end function")
    w("")
    # A BYVAL cva_list PARAMETER, C's list arriving: on linux-x86_64 a pointer to C's own record
    # (SysV's va_list is an array), on linux-arm64 a pointer to a copy of the 32-byte struct, on
    # the Mac the 'char *' itself. 10 pairs run past the registers on all three.
    w("function t_vread4 cdecl( byval n as long, byval ap as cva_list ) as longint")
    w("    for k as long = 0 to n - 1")
    w("        dim as longint i = cva_arg( ap, longint )")
    w("        dim as double d = cva_arg( ap, double )")
    w("        c_seen_va4( k, i, d )")
    w("    next")
    w("    return 44")
    w("end function")
    w("")
    w("sub trun_all( )")
    for name in ORDER:
        w("    trun_%s( )" % name)
    for pname, _ in PREFIXES:
        w("    trun_%s( )" % pname)
    for t, _, _ in RETS:
        w("    trun_ret_%s( )" % t)
    w("    c_va_ret( c_va( 7, clng( 11 ), clngint( 12 ), 13.5, c_marker( ), csng( 14.5 ), cbyte( -15 ), cshort( -16 ), 17 ) )")
    w("end sub")
    w("end extern")
    return "\n".join(L) + "\n"


def main():
    check = "--check" in sys.argv[1:]
    rc = 0
    for path, text in ((OUT_C, gen_c()), (OUT_T, gen_t())):
        if check:
            old = open(path, "rb").read().decode() if os.path.exists(path) else ""
            if old != text:
                print("aapcslane: %s is stale (run build/aapcslane.py)" % os.path.relpath(path, ROOT))
                rc = 1
        else:
            with open(path, "wb") as f:
                f.write(text.encode())
    if not check:
        print("aapcslane: %d shapes, %d prefixes -> %s, %s" % (len(ORDER), len(PREFIXES),
              os.path.relpath(OUT_C, ROOT), os.path.relpath(OUT_T, ROOT)))
    return rc


if __name__ == "__main__":
    sys.exit(main())
