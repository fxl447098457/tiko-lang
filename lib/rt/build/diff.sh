#!/bin/sh
# diff.sh -- the differential tests, mechanised.
#
#   build/diff.sh [Debug|Release|RelWithDebInfo]
#
# Every program in tests/abi/ is compiled and run TWICE on the host target: once
# against fbc's stock runtime, once with tiko-rt's objects linked ahead of it.
# The two outputs must be byte-identical.
#
# WHY THIS SCRIPT EXISTS. These programs were written from the start, but they
# were RUN BY HAND, and the project's status notes said "7 differentials
# IDENTICAL" on the strength of that. A check that depends on someone
# remembering to run it is a check that silently lapses -- and this project has
# already recorded two cases of a stale artefact producing a believable number
# rather than an error. Now it is one command, and it fails loudly.
#
# HOW THE OVERRIDE WORKS -- no archive surgery, unlike gate.sh. tiko-rt's .o
# files are named explicitly on the fbc command line, so ld resolves fb_TRIM (and
# the rest) from them and never pulls fbc's corresponding member, which stays
# undisturbed on disk. That only works because fbc gives each of these entry
# points a member of its own; where it does not -- fb_SPACE shares str_misc.o
# with four ustring entry points -- the member would be pulled for its OTHER
# symbols and the link would fail on a duplicate. A duplicate-symbol error here
# is therefore information: it means the batch was sized by symbol when it should
# have been sized by member.
#
# RUN IT IN BOTH CONFIGURATIONS. This defaults to Debug and gate.sh uses Release,
# so for fifteen batches the differential was only ever proving something about
# -O0 -- and two real defects sat in the shipped configuration the whole time: a
# jmp_buf local that Release placed at rsp+0x28 (mingw's longjmp needs 16-byte
# alignment for its MOVAPS restores, so GOSUB segfaulted), and LLVM's InstCombine
# folding realloc(NULL, n) into malloc(n) inside a provably-null branch, which
# moved two operations between columns in alloc-count. Neither reproduces at -O0.
#
# HOST TARGET ONLY. These are RUN tests; win32 and Linux behaviour is covered by
# gate.sh, which executes fbc's own suite on each target.

set -e

. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/oracle.sh"
rt_check_tools
rt_oracle_check diff.sh

CFG=${1:-Debug}
rt_cfg_flags "$CFG" > /dev/null || rt_die "unknown configuration '$CFG'"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) TARGET=win64 ;;
    *)                    TARGET=linux-x86_64 ;;
esac

OBJDIR="$RT_ROOT/obj/$TARGET/$CFG/st"
[ -d "$OBJDIR" ] || rt_die "no objects in $OBJDIR -- run build/build.sh $CFG first"

OBJS=$(ls "$OBJDIR"/*.o 2>/dev/null) || rt_die "no objects in $OBJDIR"

# The -mt objects, for tests that say NEEDS-MT. They are a DIFFERENT BUILD of
# the same sources -- ENABLE_MT changes what the TLS table is, whether the
# thread-flag update takes a lock, and which symbols exist at all -- so a
# threading test linked against the st objects would be testing the wrong
# library and would report that TLS is not per-thread.
MTOBJDIR="$RT_ROOT/obj/$TARGET/$CFG/mt"
MTOBJS=$(ls "$MTOBJDIR"/*.o 2>/dev/null || true)

# NO EXTRA LIBRARIES. This harness names EVERY tiko-rt object on the command
# line, which is already unlike a real link: a real program pulls only the
# archive members it uses. Until io/printerwin.tiko moved its spooler and GDI
# calls behind LoadLibrary/GetProcAddress, that over-linking dragged
# io_printerwin.o -- and with it undefined EnumPrintersA, __imp_CreateDCA and
# a dozen more -- into all 72 differentials, so this script passed
# `-l winspool -l gdi32` on BOTH links. The rebuilt object has no undefined
# Win32 symbols beyond four from kernel32, and fbc's own driver never needed
# the two for a program that does not use LPRINT. Neither side does now.

WORK="$RT_ROOT/obj/diff"
rm -rf "$WORK"; mkdir -p "$WORK"

pass=0
fail=0
skip=0
crash=0

for src in "$RT_ROOT"/tests/abi/*.bas; do
    [ -e "$src" ] || continue
    name=$(basename "$src" .bas)

    # --wrap flags, DERIVED FROM THE SOURCE rather than listed here.
    #
    # alloc-count.bas and entry-count.bas count calls by interposing on the
    # allocator and on the entry points, which only links with the matching
    # --wrap options; without them ld cannot resolve __real_malloc and the
    # program does not build. The first version of this script SKIPPED both for
    # exactly that reason -- two of the most valuable tests in the suite, quietly
    # not running behind a green summary line. Reading the __real_ references out
    # of the source keeps flag and test together, so a new wrapper cannot forget
    # to bring its flag.
    # Stock: fbc's runtime, untouched.
    # Backend, per file. Aliasing a RESERVED entry point -- fb_StrDelete is one --
    # makes fbc emit two declarations of it in the generated C, with different
    # parameter types, and gcc rejects the translation unit. The same source
    # compiles under -gen llvm, which has no C type-checking layer to disagree
    # with. A file that needs it says so in its own text.
    #
    # Both sides are compiled the same way, so the comparison stays valid: the
    # backend is the harness, not the subject.
    GENOPT=""
    if grep -q 'NEEDS-GEN-LLVM' "$src"; then GENOPT="-gen llvm"; fi

    # Same idea for the language dialect. GOSUB/RETURN exist only under
    # -lang fblite or qb, and a test that needs one says so in its own text
    # rather than the dialect being applied to every file.
    LANGOPT=""
    if grep -q 'NEEDS-LANG-FBLITE' "$src"; then LANGOPT="-lang fblite"; fi
    if grep -q 'NEEDS-LANG-QB' "$src"; then LANGOPT="-lang qb"; fi

    # NEEDS-MT switches BOTH sides to -mt and libfbmt.a, and switches tiko-rt's
    # side to the mt objects. Anything less compares two different libraries.
    MTOPT=""
    THISOBJS="$OBJS"
    if grep -q 'NEEDS-MT' "$src"; then
        MTOPT="-mt"
        THISOBJS="$MTOBJS"
        if [ -z "$MTOBJS" ]; then
            echo "diff: SKIP $name -- NEEDS-MT and no objects in $MTOBJDIR" >&2
            skip=$((skip + 1))
            continue
        fi
    fi

    WRAP=""
    for sym in $(grep -oE '__real_[A-Za-z0-9_]+' "$src" | sed 's/^__real_//' | sort -u); do
        WRAP="$WRAP -Wl --wrap=$sym"
    done

    if ! "$TKORT_FBC" "$src" -x "$WORK/$name-stock.exe" $(rt_incflags) $GENOPT $LANGOPT $MTOPT $WRAP \
            > "$WORK/$name-stock.build" 2>&1; then
        echo "diff: SKIP $name -- does not build against fbc's runtime" >&2
        sed 's/^/    /' "$WORK/$name-stock.build" >&2
        skip=$((skip + 1))
        continue
    fi

    # Merged: the same program, tiko-rt's objects ahead of the archive.
    if ! "$TKORT_FBC" "$src" -x "$WORK/$name-rt.exe" $(rt_incflags) $GENOPT $LANGOPT $MTOPT $WRAP $THISOBJS \
            > "$WORK/$name-rt.build" 2>&1; then
        echo "diff: FAIL $name -- does not link over tiko-rt" >&2
        sed 's/^/    /' "$WORK/$name-rt.build" >&2
        fail=$((fail + 1))
        continue
    fi

    # A crash is a failure, not an empty output to be diffed against another
    # empty output. Both exit codes are recorded so that two matching crashes
    # cannot pass as "identical".
    # `|| rc=$?`, NOT `; echo exit=$?`. This script runs under set -e, so a
    # test executable that segfaults or exits non-zero used to ABORT THE WHOLE
    # RUN -- no summary line, no failure count, just the shell's own
    # "Segmentation fault" notice and a silent exit 0 from the script. That is
    # how a crashing test came to look like a clean pass. The exit code is
    # captured into the .out either way, so it still takes part in the
    # comparison.
    rc=0; "$WORK/$name-stock.exe" > "$WORK/$name-stock.out" 2>&1 || rc=$?
    echo "exit=$rc" >> "$WORK/$name-stock.out"
    rc=0; "$WORK/$name-rt.exe"    > "$WORK/$name-rt.out"    2>&1 || rc=$?
    echo "exit=$rc" >> "$WORK/$name-rt.out"

    if [ ! -s "$WORK/$name-stock.out" ]; then
        echo "diff: FAIL $name -- stock run produced no output at all" >&2
        fail=$((fail + 1))
        continue
    fi

    # A TEST THAT CRASHES THE SAME WAY ON BOTH SIDES COMPARES EQUAL AND PASSES.
    # The exit code is recorded inside each .out, so an identical segfault is an
    # identical output -- which is exactly what this script is built to accept.
    # It is still not a result anyone should read as "fine", so it is counted
    # and named separately. This exists because a run reported "0 differing"
    # while the shell was printing "Segmentation fault" beside it.
    if ! grep -qx 'exit=0' "$WORK/$name-rt.out"; then
        echo "diff: NOTE $name -- both sides exited non-zero ($(grep -o 'exit=[0-9]*' "$WORK/$name-rt.out" | tail -1))" >&2
        crash=$((crash + 1))
    fi

    if diff -u "$WORK/$name-stock.out" "$WORK/$name-rt.out" > "$WORK/$name.diff"; then
        pass=$((pass + 1))
    else
        echo "diff: FAIL $name" >&2
        head -40 "$WORK/$name.diff" >&2
        fail=$((fail + 1))
    fi
done

if [ $((pass + fail + skip)) -eq 0 ]; then
    rt_die "no differential programs found in tests/abi -- an empty pass is not a pass"
fi

crashnote=""
if [ "$crash" -gt 0 ]; then crashnote=", $crash exited non-zero on BOTH sides"; fi
echo "diff: $TARGET [$CFG] -- $pass identical, $fail differing, $skip skipped$crashnote"

# A SKIP IS A HARNESS FAILURE, not a neutral outcome. Every program in tests/abi
# is meant to run; one that will not build against fbc's own runtime means the
# driver is wrong, and a green line reading "2 skipped" is how a suite quietly
# shrinks. Counted separately from $fail so the message says which kind of wrong.
[ "$fail" -eq 0 ] && [ "$skip" -eq 0 ]
