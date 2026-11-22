#!/bin/sh
# bootstrap.sh -- the self-hosting fixpoint: tiko-lang compiles itself, twice.
#
#   build/bootstrap.sh [-O<n>] [--target <name>] [--stage1 <tiko>] [--seed <tiko>] [--gate]
#
# docs/plan/13 section 8 and D11, as one command. The Windows peer is
# build/bootstrap.bat and is kept line-for-line analogous.
#
#   stage0  the seed builds tiko-lang                          -> stage1
#   stage1  compiles tiko-lang's own sources                   -> stage2
#   stage2  compiles them again                                -> stage3
#
# and asserts, in this order:
#
#   1. stage1 LOWERS EVERY STATEMENT of every module, and every module verifies. A
#      build reports no decline, so a statement tiko gives up on vanishes from the
#      compiler it is building and nothing says so. That is not hypothetical:
#      'Tko.TKO_VERSION_SUFFIX' in cmdline.tiko declined twice, and the self-built
#      compiler's --version lost its suffix and its whole target line.
#   2. stage2 AND stage3 ARE BYTE-IDENTICAL FILES. Nothing is zeroed and nothing is
#      masked: the link is reproducible (HANDOFF 8m). stage1 == stage2 too, below:
#      the seed builds stage1 with stage2's own command.
#   3. stage3 COMPILES A PROGRAM AND IT PRINTS WHAT THE SEED'S BUILD OF IT PRINTS.
#   4. With --gate, THE SUITE AGAINST stage2 FAILS EXACTLY WHAT IT FAILS AGAINST
#      stage1. A fixpoint says the compiler reproduces itself; it says nothing about
#      code tiko-lang's own source never exercises. The suite does: a paren-less
#      'cast( ulong, flds.Count )' passed byref gave every threadcall descriptor a
#      CODE ADDRESS for its field count, in stage2 and stage3 alike, and only the
#      suite run against stage2 could see it. "The same failures" rather than "none",
#      because a worktree has an environmental one or two (see HANDOFF).
#
# -O<n> is passed to the stage1 and stage2 compiles of tiko-lang; Phase 10's
# criterion is the fixpoint at -O0 AND -O2. --stage1 skips the stage0 build and
# uses the given compiler. --target defaults to the host's default target.
#
# Headers: the tree's own inc/ (phase H), else the seed's, or TIKO_BOOT_INC. Libraries: per target below, or TIKO_BOOT_LIBDIRS (space-separated).
# TIKO_LIBPATH and TIKO_INCLUDE from the caller are NOT inherited: a variable exported
# for some earlier probe would otherwise decide what this links (see Learnings).
#
# Everything lands in build/.bootstrap/, which is cleared first: a stage binary
# left by an earlier run would compare equal to itself and prove nothing.
#
# STAGE0 IS A SEED: '--seed <tiko>' (or TIKO_SEED), else build/defaultseed.sh's pick --
# a packaged tiko, where FBC-Modern was until 2026-10-10; nothing here runs or reads fbc.
# (Diverse double-compiling, which does build with fbc, is the bootstrap plan's
# scripts/ddc.sh, through build.sh's TIKO_ORACLE_FBC.) The seed builds stage1 with EXACTLY
# the command stage1 builds stage2 with, so a fifth assertion holds and is checked:
# stage1 == stage2 -- a correct tiko of commit X reproduces X's compiler on its first
# step (measured, tiko-bootstrap VERIFICATION.md). Headers and libraries default to
# the seed's own inc/ and lib/<target>/, and hello's reference output is the seed's.

set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) HOSTWIN=1; EXT=".exe" ;;
    *)                    HOSTWIN=0; EXT="" ;;
esac

OPT=""
TARGET=""
STAGE1=""
GATE=0
while [ $# -gt 0 ]; do
    case "$1" in
        -O[0-3])  OPT="$1" ;;
        --target) shift; TARGET="$1" ;;
        --stage1) shift; STAGE1="$1" ;;
        --seed)   shift; TIKO_SEED="$1" ;;
        --gate)   GATE=1 ;;
        *) echo "bootstrap: unknown argument '$1'" >&2; exit 2 ;;
    esac
    shift
done

# THE SEED IS STAGE0, as in build.sh: TIKO_SEED or --seed, else build/defaultseed.sh's pick.
# TKO_STAGE0 -- fbc, until 2026-10-10 -- is ignored, and said so.
. "$ROOT/build/defaultseed.sh"
[ -z "${TKO_STAGE0:-}" ] || echo "bootstrap: TKO_STAGE0 is retired and ignored -- the seed is stage0" >&2
if [ -z "${TIKO_SEED:-}" ]; then
    TIKO_SEED=$(default_seed "$ROOT" "$HOSTWIN") || {
        echo "bootstrap: no seed compiler -- seed/fetch-seed.sh, or --seed <tiko>" >&2; exit 3; }
fi
[ -x "$TIKO_SEED" ] || { echo "bootstrap: no seed compiler at $TIKO_SEED (a tiko executable)" >&2; exit 3; }
export TIKO_SEED
# The toolchain directory: tiko.exe sits at its top on Windows, bin/tiko below it on Linux.
SEEDDIR=$(dirname "$TIKO_SEED")
[ -d "$SEEDDIR/inc" ] || SEEDDIR=$(dirname "$SEEDDIR")

if [ -z "$TIKO_BOOT_INC" ]; then
    # The tree's own headers first (phase H) -- what build.sh builds stage1 against too.
    if [ -d "$ROOT/inc" ]; then
        TIKO_BOOT_INC="$ROOT/inc"
    else
        TIKO_BOOT_INC="$SEEDDIR/inc"
    fi
fi
[ -d "$TIKO_BOOT_INC" ] || { echo "bootstrap: no header directory $TIKO_BOOT_INC (set TIKO_BOOT_INC)" >&2; exit 3; }

if [ -z "$TARGET" ]; then
    if [ "$HOSTWIN" = "1" ]; then TARGET="windows-x86_64"
    elif [ "$(uname -s)" = "Darwin" ]; then TARGET="macos-arm64"
    elif [ "$(uname -m)" = "aarch64" ]; then TARGET="linux-arm64"
    else TARGET="linux-x86_64"; fi
fi
# THE SEED'S NAME FOR THE TARGET. windows-x86_64 was win64-msvc until 2026-10-12, and a
# seed from before then knows only the old name -- for -target and for its lib/ directory.
# The seed is asked: the second line of --version names its default target. Its lib/ is
# no answer, since a toolchain may carry both directories. Every later stage is this
# tree's compiler and is given $TARGET.
SEED_TARGET=$TARGET
if [ "$TARGET" = "windows-x86_64" ] && \
   [ "$("$TIKO_SEED" --version 2>/dev/null | sed -n 's/^target \([^,]*\),.*/\1/p')" = "win64-msvc" ]; then
    SEED_TARGET=win64-msvc
fi
if [ -z "$TIKO_BOOT_LIBDIRS" ]; then
    # The seed's runtime and import libraries, and for win64 the MinGW runtime beside
    # them where the seed ships one.
    TIKO_BOOT_LIBDIRS="$SEEDDIR/lib/$SEED_TARGET"
    [ -d "$SEEDDIR/lib/$SEED_TARGET-fb" ] && TIKO_BOOT_LIBDIRS="$TIKO_BOOT_LIBDIRS $SEEDDIR/lib/$SEED_TARGET-fb"
fi
if [ -z "$TIKO_BOOT_LIBDIRS" ]; then
    case "$TARGET" in
        windows-x86_64) TIKO_BOOT_LIBDIRS="$ROOT/toolchains/tiko-windows/lib/windows-x86_64" ;;
        # MinGW needs its CRT objects beside the runtime; see cmdline.tiko.
        win64)        TIKO_BOOT_LIBDIRS="$ROOT/toolchains/tiko-windows/lib/win64"
                      [ -d "$ROOT/toolchains/tiko-windows/lib/win64-fb" ] && TIKO_BOOT_LIBDIRS="$TIKO_BOOT_LIBDIRS $ROOT/toolchains/tiko-windows/lib/win64-fb" ;;
        linux-x86_64) TIKO_BOOT_LIBDIRS="$ROOT/lib/rt/lib/linux-x86_64" ;;
        linux-arm64)  TIKO_BOOT_LIBDIRS="$ROOT/lib/rt/lib/linux-arm64" ;;
        macos-arm64)  TIKO_BOOT_LIBDIRS="$ROOT/lib/rt/lib/macos-arm64" ;;
        *) echo "bootstrap: unknown target '$TARGET'" >&2; exit 2 ;;
    esac
fi
LIBP=""
for d in $TIKO_BOOT_LIBDIRS; do
    [ -d "$d" ] || { echo "bootstrap: no library directory $d (set TIKO_BOOT_LIBDIRS)" >&2; exit 3; }
    LIBP="$LIBP -p $d"
done

unset TIKO_LIBPATH
TIKO_INCLUDE="$TIKO_BOOT_INC"
export TIKO_INCLUDE
# THE TREE'S std MODULES: the compiler's source imports std/containers and std/fs (2026-10-10),
# and they are the tree's pkg/, as inc/ is -- never the seed's copy.
TIKO_PKG="$ROOT/pkg"
export TIKO_PKG
# ...and the same again under the seed's old TKO_* names (defaultseed.sh, seed_env).
seed_env

SOURCES=$(grep -v '^[[:space:]]*#' build/sources.txt | grep -v '^[[:space:]]*$')
NMOD=$(echo "$SOURCES" | wc -l | tr -d ' ')
MAINMOD=$(basename "$(echo "$SOURCES" | head -1)" .tiko)

OUT="$ROOT/build/.bootstrap"
rm -rf "$OUT"
mkdir -p "$OUT/stage1" "$OUT/stage2" "$OUT/stage3" "$OUT/hello"

now( ) { date +%s; }
say( ) { echo "bootstrap: $*"; }
fail( ) { echo "bootstrap: FAILED -- $*" >&2; exit 1; }
size_of( ) { wc -c < "$1" | tr -d ' '; }

say "target $TARGET ${OPT:--O0}, $NMOD modules, headers $TIKO_BOOT_INC"

# ------------------------------------------------------------------ stages
build_stage( ) {
    # $1 = the compiler, $2 = the stage it builds, $3 = its name for the target
    ts=$(now)
    # EACH STAGE COMPILES THE std MODULES ITSELF, into a cache of its own: one shared cache
    # would hand stage2 the objects stage1 made, and stage2 == stage3 would not cover them.
    TIKO_MODCACHE="$OUT/$2.modcache" TIKO_MODCACHE="$OUT/$2.modcache" "$1" $SOURCES -m "$MAINMOD" -i src -target "$3" $OPT $LIBP -o "$OUT/$2/tiko$EXT" \
        > "$OUT/$2.log" 2>&1 || { cat "$OUT/$2.log" >&2; fail "$2 did not build"; }
    [ -f "$OUT/$2/tiko$EXT" ] || fail "$2 reported success and wrote no compiler"
    # A build that says nothing is the only acceptable one: a warning in the
    # compiler's own source is either real or a divergence from what stage0 said.
    if [ -s "$OUT/$2.log" ]; then
        cat "$OUT/$2.log" >&2
        fail "$2's build printed diagnostics"
    fi
    say "$2  built by $(basename "$(dirname "$1")") in $(( $(now) - ts )) s, $(size_of "$OUT/$2/tiko$EXT") bytes"
}

# ------------------------------------------------------------------ stage1
t0=$(now)
if [ -n "$STAGE1" ]; then
    [ -x "$STAGE1" ] || fail "no stage1 compiler at $STAGE1"
    cp "$STAGE1" "$OUT/stage1/tiko$EXT"
    say "stage1  $STAGE1"
else
    # stage1 BY THE SEED, with stage2's own command -- see the header.
    build_stage "$TIKO_SEED" stage1 "$SEED_TARGET"
    if [ "$GATE" = "1" ]; then
        # --gate runs the suite, which needs a runner: the seed builds that too.
        sh build/build.sh Debug --test-runner --no-dll > "$OUT/runner.log" 2>&1 || { cat "$OUT/runner.log" >&2; fail "the seed could not build the test runner"; }
    fi
fi
S1="$OUT/stage1/tiko$EXT"

# -------------------------------------------- 1. every statement lowers
# One invocation over every module: 92 processes would re-read the shared headers
# 92 times. Only the summary lines are kept; the IR itself is tens of megabytes.
TIKO_MODCACHE="$OUT/lowered.modcache" "$S1" --dump-ir -target "$TARGET" -i src $SOURCES 2>&1 | grep -E '^(lowered|verify):' > "$OUT/lowered.txt" || true
NLOW=$(grep -c '^lowered:' "$OUT/lowered.txt" || true)
NVER=$(grep -c '^verify: ok' "$OUT/lowered.txt" || true)
NDEC=$(grep '^lowered:' "$OUT/lowered.txt" | grep -vc ' 0 statements not lowered' || true)
[ "$NLOW" = "$NMOD" ] || fail "--dump-ir reported $NLOW modules of $NMOD (see $OUT/lowered.txt)"
[ "$NVER" = "$NMOD" ] || fail "$(( NMOD - NVER )) modules did not verify (see $OUT/lowered.txt)"
[ "$NDEC" = "0" ]     || fail "$NDEC modules have statements stage1 does not lower (see $OUT/lowered.txt)"
say "stage1  lowers every statement of all $NMOD modules; all verify"

# ------------------------------------------------------------ stage2, stage3
build_stage "$S1" stage2 "$TARGET"
build_stage "$OUT/stage2/tiko$EXT" stage3 "$TARGET"

# ------------------------------------------------------------- 2. fixpoint
cmp -s "$OUT/stage2/tiko$EXT" "$OUT/stage3/tiko$EXT" || fail "stage2 and stage3 differ"
if [ -z "$STAGE1" ]; then
    cmp -s "$OUT/stage1/tiko$EXT" "$OUT/stage2/tiko$EXT" || fail "stage1 (the seed's build) and stage2 differ"
    say "fixpoint  stage1 == stage2 as well: the seed reproduces this commit's compiler"
fi
if command -v sha256sum > /dev/null 2>&1; then
    say "fixpoint  stage2 == stage3, sha256 $(sha256sum "$OUT/stage3/tiko$EXT" | cut -c1-16)..."
else
    say "fixpoint  stage2 == stage3"
fi

# ------------------------------------------ 3. stage3 builds a working program
cat > "$OUT/hello/hello.tiko" <<'EOF'
namespace Boot
    const WHO as string = "stage3"
end namespace
function Twice( byval n as long ) as long
    return n * 2
end function
dim as string s = "hello from " & Boot.WHO
print s; Twice( 21 ); " "; len( s )
EOF
"$OUT/stage3/tiko$EXT" "$OUT/hello/hello.tiko" -target "$TARGET" $LIBP -o "$OUT/hello/hello3$EXT" \
    > "$OUT/hello/build3.log" 2>&1 || { cat "$OUT/hello/build3.log" >&2; fail "stage3 could not build hello.tiko"; }
"$OUT/hello/hello3$EXT" > "$OUT/hello/out3.txt" 2>&1 || fail "stage3's hello did not run"
( cd "$OUT/hello" && "$TIKO_SEED" hello.tiko -target "$SEED_TARGET" $LIBP -o "hello0$EXT" > build0.log 2>&1 ) || fail "the seed could not build hello.tiko"
"$OUT/hello/hello0$EXT" > "$OUT/hello/out0.txt" 2>&1 || fail "the seed's hello did not run"
cmp -s "$OUT/hello/out0.txt" "$OUT/hello/out3.txt" || fail "stage3's hello prints '$(cat "$OUT/hello/out3.txt")', the seed's '$(cat "$OUT/hello/out0.txt")'"
say "stage3  builds hello.tiko, and it prints what the seed's build prints"

# ------------------------------------------------- 4. the suite, both ways
if [ "$GATE" = "1" ]; then
    [ -x "bin/tiko-test$EXT" ] || fail "--gate needs bin/tiko-test$EXT (build.sh Debug --test-runner)"
    unset TIKO_INCLUDE
    # THE PACKAGE TREE, NAMED: a stage lives in build/.bootstrap/stageN/, where its
    # default '<exe-dir>/../pkg' is no package tree, so every '#import "std/..."' test --
    # 23 of them -- failed on both sides alike and the comparison could see none of them.
    # Measured 2026-10-09: with it, stage2 passes the whole suite.
    TIKO_PKG="$ROOT/pkg"; export TIKO_PKG
    sh build/test.sh --no-build --tiko-lang "$S1" > "$OUT/gate1.log" 2>&1 || true
    sh build/test.sh --no-build --tiko-lang "$OUT/stage2/tiko$EXT" > "$OUT/gate2.log" 2>&1 || true
    grep '^FAIL ' "$OUT/gate1.log" | sort > "$OUT/fail1.txt" || true
    grep '^FAIL ' "$OUT/gate2.log" | sort > "$OUT/fail2.txt" || true
    SUM1=$(grep '^tiko-test' "$OUT/gate1.log" | tail -1)
    SUM2=$(grep '^tiko-test' "$OUT/gate2.log" | tail -1)
    [ -n "$SUM1" ] && [ -n "$SUM2" ] || fail "the suite did not report a result (see $OUT/gate1.log, gate2.log)"
    say "suite   stage1: ${SUM1#*: }"
    say "suite   stage2: ${SUM2#*: }"
    if ! cmp -s "$OUT/fail1.txt" "$OUT/fail2.txt"; then
        diff "$OUT/fail1.txt" "$OUT/fail2.txt" >&2 || true
        fail "the suite fails differently against stage2 than against stage1"
    fi
    say "suite   stage2 fails exactly what stage1 fails"
fi

say "ok"
