#!/bin/sh
# diffmsvc.sh -- the differentials, run against the MICROSOFT ABI runtime.
#
#   build/diffmsvc.sh [Debug|Release|RelWithDebInfo]
#
# RFC-0006 §8 step 5: *"run check-str before anything else that looks like
# progress. The stdio swap is the change most likely to be silently wrong, and
# the only one that produces no diagnostic at all."*
#
# CHECK-STR IS THE WRONG INSTRUMENT FOR IT, and RFC-0006 §3.3 named it in good
# faith. tools/gen/check-str.sh compares tiko-lang's COMPILE-TIME float folding
# against fbc's STR( ) truth; it never links libfb and cannot see which printf a
# runtime calls. It is worth running -- it says 1483/1483 -- and it says nothing
# about this.
#
# THIS is the instrument. Every program in tests/abi/ is built twice and run:
#
#   reference   fbc, its own stock MinGW runtime, exactly as diff.sh's is
#   subject     the same source through fbc -gen llvm -r, retargeted to
#               x86_64-pc-windows-msvc, linked against lib/windows-x86_64/libfb.a
#
# and the two outputs must be byte-identical. What that measures is the whole of
# the ABI change at once: UCRT against MinGW's stdio, __acrt_iob_func against
# __iob_func, _fseeki64 against fseeko, .CRT$XCU against .ctors, and every
# codegen difference the triple produces.
#
# WHY THE REFERENCE IS fbc AND NOT THE MinGW tiko-rt. The question here is not
# "do the two tiko-rt builds agree" -- abidelta.sh answers a version of that from
# the symbol tables. It is "does the MSVC build still behave like FreeBASIC",
# and fbc is the only thing that answers that. It is also the same reference
# diff.sh uses, so a failure here and a pass there localises to the ABI.
#
# /INCLUDE:tkort_msvc_init_ IS REQUIRED TOO, and for a subtler reason. An
# archive member is extracted only when it RESOLVES AN UNDEFINED SYMBOL, and
# nothing references a CRT initialiser -- the CRT walks a section, it does not
# call a name. So src/c/msvcinit.o sat in the archive and was never linked:
# measured, the locale stayed "C" with the object present. /INCLUDE: names it
# and is the supported way to pull one in.
#
# THE LINK IS gatemsvc.sh's AND tiko-lang's OWN: '-nostdlib', ucrtbase and
# kernel32 through the import libraries build/implibs.sh builds. This
# said '-llegacy_stdio_definitions IS REQUIRED' -- true until 2026-09-07, when
# src/c/msvccrt.c began supplying sprintf and mainCRTStartup itself and the
# target stopped reaching into Visual Studio. gatemsvc.sh moved with that change
# and this script did not: with clang's default libraries, msvccrt.o's
# mainCRTStartup meant libcmt was never pulled in, so nothing named the CRT and
# EVERY test failed to link on memset -- '0 identical, 112 differing', measured
# 2026-09-21, for two weeks, reading as an ABI failure it was not.
#
# ---------------------------------------------------------- KNOWN DIVERGENCES
#
# Three tests differ, two cannot be run at all and two do not link. None is an
# ABI defect, and they are listed so that a FOURTH difference is visible
# immediately.
#
#   alloc-count     STRUCTURALLY UNMEASURABLE, and it is the linker, not the
#   entry-count     runtime: both work by GNU ld's --wrap and lld-link has no
#                   equivalent. See the check in the loop below for the measured
#                   error. These are the only two of RFC-0004's gates that this
#                   differential cannot answer.
#
#   rnd-parity      2 lines   MSVCRT's printf is accurate to about fifteen
#   write-parity    1 line    significant digits and the UCRT's is exactly
#                             rounded, so past the fifteenth the MICROSOFT SIDE
#                             IS THE CORRECT ONE. All three values are dyadic
#                             rationals whose exact decimal expansion was
#                             computed; see src/inc/fmt.ti. No UCRT option bit
#                             makes it less accurate.
#
#   format-parity   2 values  NOT printf -- libm, and exactly one function of
#                             it. FORMAT$ scales by pow( 10, -n ) before
#                             rendering a value with more than 19 integer
#                             digits, and msvcrt's pow IS WRONG where the
#                             UCRT's is correctly rounded:
#
#                               pow(10,-2)   ...147C  msvcrt   ...147B  UCRT
#                               pow(10,-11)  ...649C           ...6495
#                               pow(10,-22)  ...5EF9           ...5EE6
#
#                             1 ulp at 10^-2 growing to about 19 at 10^-22,
#                             always high, and every negative power of 10 and
#                             of 5 is affected -- not a corner case.
#
#                             THE BOUNDARY WAS MEASURED, and it is narrow. The
#                             runtime imports six libm functions: ceil, exp2,
#                             floor, log10, modf, pow. Probed bit for bit
#                             against fbc's own binary, 28 of 45 values differ
#                             and ALL 28 are pow with a negative exponent.
#                             pow of an exact power of two, exp2, log10, ceil,
#                             floor and modf are identical on both CRTs, and
#                             pow is called from ONE file -- src/str/format.tiko,
#                             six sites, of which the two positive-exponent ones
#                             agree.
#
#                             NOT FIXED, DELIBERATELY. fbc imports pow from
#                             msvcrt.dll (ordinal 1169) and the MSVC build could
#                             import the same function and agree to the bit. It
#                             would mean loading msvcrt.dll into a UCRT process
#                             -- reintroducing the CRT this target exists to
#                             leave -- in order to inherit a 19-ulp bug, and the
#                             visible blast radius is FORMAT$ of a number with
#                             more than 19 integer digits. The option is cheap
#                             and stays open; it is recorded here so that
#                             choosing it later is a decision and not a
#                             discovery.
#
#   gosub-parity      DO NOT LINK, and neither is the runtime's doing: it is the
#   legacydir-parity  PROGRAM that asks. fbc's own IR for GOSUB calls _setjmp,
#                     which the UCRT does not export (tiko emits
#                     __intrinsic_setjmp for this target, HANDOFF 9c); and
#                     legacydir calls crt mkdir/rmdir by their POSIX names, which
#                     only oldnames.lib aliased -- '-nostdlib' drops it with the
#                     rest of Visual Studio. Measured 2026-09-21, the first run
#                     after the link recipe was brought in line with gatemsvc.sh.
#
# WIN64 HOST ONLY. There is no MSVC ABI to compare against anywhere else.

set -e

. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/oracle.sh"
rt_check_tools
rt_oracle_check diffmsvc.sh

CFG=${1:-Release}
rt_cfg_flags "$CFG" > /dev/null || rt_die "unknown configuration '$CFG'"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *) rt_die "win64 host only -- there is no MSVC ABI to compare against here" ;;
esac

LIB="$RT_ROOT/lib/windows-x86_64/libfb.a"
[ -f "$LIB" ] || rt_die "no archive at $LIB -- run build/build.sh $CFG windows-x86_64 first"

# AND IT MUST BE THE CONFIGURATION THIS RUN WAS ASKED FOR. lib/<target>/ holds
# ONE archive that every configuration overwrites, so without this check
# `diffmsvc.sh Release` run after a Debug build measures Debug and says Release.
rt_check_cfg_stamp( ) {
    _stamp="$1/.config"
    if [ ! -f "$_stamp" ]; then
        rt_die "no .config beside $1 -- rebuild with build/build.sh $CFG windows-x86_64"
    fi
    _have=$(cat "$_stamp")
    if [ "$_have" != "$CFG" ]; then
        rt_die "the archives in $1 were built [$_have], not [$CFG] -- run build/build.sh $CFG windows-x86_64"
    fi
}
rt_check_cfg_stamp "$RT_ROOT/lib/windows-x86_64"

# AND THE MT ARCHIVE, which is a DIFFERENT BUILD of the same sources rather than
# the same objects with a flag: ENABLE_MT changes what the TLS table is, whether
# the thread-flag update takes a lock, and which symbols exist at all. A NEEDS-MT
# test linked against the st archive would report that TLS is not per-thread and
# would be measuring the wrong library, which is the mistake diff.sh's own header
# records having made.
MTLIB="$RT_ROOT/lib/windows-x86_64/libfbmt.a"

# THE IMPORT LIBRARIES that stand in for the CRT at the link below -- gatemsvc.sh's
# variable and default, and refused for gatemsvc.sh's reason: without them every
# link fails on memset and reads as an ABI difference.
IMPLIBS=${TKORT_MSVC_IMPLIBS:-$(cd "$(dirname "$0")/../../.." && pwd)/toolchains/tiko-windows/lib/windows-x86_64}
[ -f "$IMPLIBS/ucrtbase.lib" ] || rt_die "no ucrtbase.lib in $IMPLIBS -- run build/implibs.sh build --out <dir>"
IMPLIBS=$(cygpath -m "$IMPLIBS")

# THE PROBE PROGRAMS ARE BUILT UNOPTIMISED, ON BOTH SIDES. The archive keeps the
# configuration it was built with -- that is the thing under test -- but the
# tests/abi programs are the INSTRUMENT, and an instrument should not be the
# most complicated part of the measurement. At -O2 they go through fbc's LLVM
# backend miscompile described below, which zeroes the very input a test then
# converts, so utf-parity ended up comparing two heap buffers full of whatever
# had been there. Neither side was wrong about the ABI and neither agreed.
PROBE_OPT=0
WORK="$RT_ROOT/obj/diffmsvc"
rm -rf "$WORK"; mkdir -p "$WORK"

ident=0
differ=0
skip=0
bothnz=0

for src in $(ls "$RT_ROOT"/tests/abi/*.bas 2>/dev/null | sort); do
    name=$(basename "$src" .bas)

    # A TEST THAT WRAPS THE ALLOCATOR CANNOT BE RUN HERE, and the reason is the
    # LINKER, not the runtime. alloc-count and entry-count work by GNU ld's
    # --wrap, which redirects references to malloc -- including the ones inside
    # a static libfb.a -- to __wrap_malloc and leaves the original reachable as
    # __real_malloc. lld-link has no equivalent: /ALTERNATENAME renames one way
    # and supplies no __real_. Measured, x86_64-pc-windows-msvc:
    #
    #   error LNK2019: unresolved external symbol __real_malloc
    #                  referenced in function __wrap_malloc
    #
    # So these two are structurally unmeasurable across this pair of link
    # models, which is a different thing from "not wired yet" -- and until this
    # check existed they were reported as "does not build against fbc's
    # runtime", which points the reader at the runtime and is wrong.
    if grep -q '__real_' "$src"; then
        skip=$((skip + 1))
        echo "diffmsvc: SKIP $name -- wraps the allocator; the MSVC link has no --wrap" >&2
        continue
    fi

    # NEEDS-MT switches BOTH sides to -mt and the mt archive, exactly as diff.sh
    # does. Anything less compares two different libraries.
    MTOPT=""
    THISLIB="$LIB"
    if grep -q 'NEEDS-MT' "$src"; then
        if [ ! -f "$MTLIB" ]; then
            skip=$((skip + 1))
            echo "diffmsvc: SKIP $name -- NEEDS-MT and no archive at $MTLIB" >&2
            continue
        fi
        MTOPT="-mt"
        THISLIB="$MTLIB"
    fi

    ref="$WORK/$name-ref.exe"
    sub="$WORK/$name-msvc.exe"

    # THE SAME PER-TEST OPTIONS diff.sh READS, and for the same reasons. A first
    # version of this script passed none of them and skipped 22 of 114 as "does
    # not build against fbc's runtime" -- which was this harness failing, not a
    # finding, and it would have made the identical/differing split a ratio over a
    # biased subset. No -l winspool/-l gdi32: the reference links fbc's runtime
    # on demand, and the subject links a freshly built tiko-rt whose printer
    # driver resolves both DLLs at runtime.
    LANGOPT=""
    if grep -q 'NEEDS-LANG-FBLITE' "$src"; then LANGOPT="-lang fblite"; fi
    if grep -q 'NEEDS-LANG-QB' "$src"; then LANGOPT="-lang qb"; fi

    # ---------------------------------------------------------- reference
    #
    # -gen llvm AND THE SAME -O AS THE SUBJECT, so the only thing that differs
    # between the two sides is THE TRIPLE. The first version of this script
    # built the reference with fbc's default backend and the subject through
    # -gen llvm -O2, which compares the ABI, the backend and the optimisation
    # level all at once -- and utf-parity duly "failed" on something that has
    # nothing to do with the ABI:
    #
    #     fbc -gen llvm -O0  (gnu)   41 C3 A9 E2 82 AC   correct
    #     fbc -gen llvm -O2  (gnu)   00 00 00 00 00 00   WRONG
    #     fbc -gen gas64 -O2         41 C3 A9 E2 82 AC   correct
    #
    # -- an fbc LLVM-backend miscompile at -O2, reproduced in six lines: a SUB
    # taking "u( ) as ubyte" and writing u( 0 ) does not write it. It is not
    # tiko-rt's and tiko-rt is not exposed to it (it declares no array
    # parameter anywhere), but a harness that hides it inside an "ABI"
    # differential is worse than one that does not run at all.
    if ! "$TKORT_FBC" "$src" -x "$ref" $(rt_incflags) $LANGOPT $MTOPT \
            -gen llvm -O "$PROBE_OPT" > "$WORK/$name.reflog" 2>&1; then
        skip=$((skip + 1))
        echo "diffmsvc: SKIP $name -- does not build against fbc's runtime" >&2
        continue
    fi

    # ------------------------------------------------------------ subject
    #
    # -r stops fbc at the .ll and emits no object; clang is then given the
    # triple we want. The .ll is NOT edited -- clang's --target overrides the
    # module's own line, and the result is symbol-for-symbol identical to one
    # built from a rewritten file. RFC-0006 §12.
    ll="$WORK/$name.ll"
    obj="$WORK/$name.o"
    rm -f "$ll" "$obj"
    if ! "$TKORT_FBC" -c "$src" -m "$name" -target win64 -gen llvm -r \
            $(rt_incflags) $LANGOPT $MTOPT -o "$obj" > "$WORK/$name.sublog" 2>&1; then
        skip=$((skip + 1))
        echo "diffmsvc: SKIP $name -- does not compile for llvm" >&2
        continue
    fi
    [ -f "$ll" ] || { skip=$((skip + 1)); echo "diffmsvc: SKIP $name -- no .ll" >&2; continue; }

    if ! "$CLANG" --target=x86_64-pc-windows-msvc -march=x86-64 "-O$PROBE_OPT" \
            -Wno-override-module "$ll" -c -o "$obj" >> "$WORK/$name.sublog" 2>&1; then
        differ=$((differ + 1))
        echo "diffmsvc: FAIL $name -- does not assemble for msvc, see $WORK/$name.sublog" >&2
        continue
    fi

    # THISLIB is built from the current sources: no winspool/gdi32 import
    # libraries, because io/printerwin.tiko loads both DLLs at runtime.
    if ! "$CLANG" --target=x86_64-pc-windows-msvc "$obj" "$THISLIB" -o "$sub" \
            -nostdlib "-L$IMPLIBS" -lucrtbase -lkernel32 \
            -luser32 -ladvapi32 -lwinmm -lmsimg32 -lversion -limm32 -lws2_32 \
            -Xlinker /INCLUDE:tkort_msvc_init_ \
            >> "$WORK/$name.sublog" 2>&1; then
        differ=$((differ + 1))
        echo "diffmsvc: FAIL $name -- does not LINK against the msvc runtime, see $WORK/$name.sublog" >&2
        continue
    fi

    # ---------------------------------------------------------------- run
    #
    # A non-zero exit on BOTH sides is agreement, not failure: errdie-parity
    # ends in a runtime error on purpose, and diff.sh reports it the same way.
    "$ref" > "$WORK/$name.refout" 2>&1 || rrc=$? ; rrc=${rrc:-0}
    "$sub" > "$WORK/$name.subout" 2>&1 || src_rc=$? ; src_rc=${src_rc:-0}

    if cmp -s "$WORK/$name.refout" "$WORK/$name.subout"; then
        if [ "$rrc" != "0" ] && [ "$src_rc" = "$rrc" ]; then
            bothnz=$((bothnz + 1))
            echo "diffmsvc: NOTE $name -- both sides exited non-zero (exit=$rrc)"
        fi
        ident=$((ident + 1))
    else
        differ=$((differ + 1))
        echo "diffmsvc: DIFFER $name" >&2
        diff "$WORK/$name.refout" "$WORK/$name.subout" 2>&1 | head -6 | sed 's/^/    /' >&2
    fi
    unset rrc src_rc
done

echo "diffmsvc: windows-x86_64 [$CFG] -- $ident identical, $differ differing, $skip skipped, $bothnz exited non-zero on BOTH sides"

# A SKIP IS A HARNESS FAILURE, not a neutral outcome -- diff.sh says so and the
# same applies here. A differing result is a real one and fails the run.
[ "$differ" = "0" ] || exit 1
