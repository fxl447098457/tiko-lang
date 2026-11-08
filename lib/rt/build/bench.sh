#!/bin/sh
# bench.sh -- C libfb vs FreeBASIC libfb, which is the whole question.
#
#   build/bench.sh [target] [runs]
#
# This is Gate 4 of docs/tiko-rt/RFC-0004 section 4.
#
# GATE:  <=5% geomean regression, and no single benchmark worse than 20%.
#
# WHAT MAKES THE COMPARISON VALID
#
# Both binaries are built by the SAME compiler with the SAME flags and the SAME
# backend. The only difference is which libfb.a the linker finds, which -p
# decides. If anything else differs, the number measures that instead.
#
# Each benchmark times itself and prints one or more "<name> <seconds>" lines,
# so process startup stays outside the measurement. EACH LINE IS ITS OWN RESULT.
# The first version of this script piped a whole benchmark's output through a
# single median, which silently mixed str_micro's four unrelated timings into one
# meaningless number.
#
# Runs are repeated and the MEDIAN is taken -- not the mean, which one scheduling
# hiccup moves, and not the minimum, which hides variance that matters.
#
# IMPROVEMENTS ARE REPORTED BUT EXCLUDED FROM THE GEOMEAN. A rewrite can beat the
# original, but that is a rewrite dividend rather than a language dividend, and
# averaging it in would make the number measure the wrong thing.
#
# AND A FASTER RESULT IS A FINDING TO EXPLAIN, NOT TO BANK. The first PASS this
# script produced showed tiko-rt 4.9x faster on one case; the cause turned out to
# be that it was doing far less allocator work than fbc, i.e. a different
# allocation policy. See RFC-0004 section 5.
#
# DO NOT RUN THIS CONCURRENTLY WITH ANYTHING. A 5% budget is smaller than the
# noise from a competing build.

set -eu

. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/oracle.sh"
rt_check_tools
rt_oracle_check bench.sh

TARGET=${1:-win64}
RUNS=${2:-5}
rt_is_target "$TARGET" || rt_die "unsupported target '$TARGET'"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) HOST=win64; EXT=".exe" ;;
    *)                    HOST=linux-x86_64; EXT="" ;;
esac
[ "$TARGET" = "$HOST" ] || rt_die "bench must run natively; host is $HOST, asked for $TARGET"

GATE_FBC=${GATE_FBC:-"$FBC_TREE/src/fbc.exe"}
[ -x "$GATE_FBC" ] || rt_die "compiler not found at $GATE_FBC"

# The C side of the comparison. By default fbc's own archive -- which is built
# with GCC at -O2, while tiko-rt goes through clang at -O2, so the default
# comparison contains a compiler difference as well as a language one.
#
# CBASE points at a clang-built baseline (build/cbase.sh) and removes that
# confound. Until it is used, a result here is "FreeBASIC through clang versus C
# through gcc", which is not the question. RFC-0004 section 5.4.4.
CLIB=${CBASE:-$(rt_reflib "$TARGET")} || rt_die "no reference libfb.a for $TARGET"
case "${CBASE:-}" in
    "") echo "bench: WARNING -- C side is fbc's GCC-built archive; set CBASE for a clang baseline" >&2 ;;
    *)  echo "bench: C side is the clang baseline at $CLIB" >&2 ;;
esac
FLIB="$RT_ROOT/obj/gate/$TARGET/lib"
[ -f "$FLIB/libfb.a" ] || rt_die "no merged tiko-rt runtime at $FLIB -- run build/gate.sh first"

WORK="$RT_ROOT/obj/bench/$TARGET"
rm -rf "$WORK"; mkdir -p "$WORK"

benches=$(find "$RT_ROOT/tests/bench" -name '*.bas' 2>/dev/null | sort)
[ -n "$benches" ] || rt_die "no benchmarks in tests/bench"

# ------------------------------------------------------------------ build

# NO PRINTER/GDI IMPORT LIBRARIES. Both sides used to take `-l winspool
# -l gdi32`: the FB side's file layer pulls io_openqb.o, which takes the
# address of fb_DevLptOpen, which pulls io_printerwin.o, which imported
# WritePrinter/CreateDCA and a dozen others statically. The C side never
# needed them, but BOTH sides got the same flags so the comparison stayed
# symmetric. io/printerwin.tiko now resolves all of them through
# LoadLibrary/GetProcAddress, so a freshly built runtime has nothing left
# for either -l to resolve. No benchmark prints anything.

for src in $benches; do
    name=$(basename "$src" .bas)
    for which in c fb; do
        case $which in c) libp="$CLIB" ;; fb) libp="$FLIB" ;; esac
        "$GATE_FBC" "$src" -i "$FBC_TREE/src/inc" -gen gcc -O 2 \
            -p "$libp" -x "$WORK/$name-$which$EXT" \
            > "$WORK/$name-$which.buildlog" 2>&1 \
            || rt_die "benchmark $name failed to build against the $which runtime; see $WORK/$name-$which.buildlog"
    done
done

# ------------------------------------------------------------------- run

: > "$WORK/ratios.txt"
: > "$WORK/rows.txt"

for src in $benches; do
    file=$(basename "$src" .bas)
    for which in c fb; do
        run=0
        while [ "$run" -lt "$RUNS" ]; do
            # The benchmarks are Windows programs and end their lines with CRLF,
            # so `read` hands the numeric filter a trailing carriage return and
            # every value is rejected as non-numeric. The table then printed
            # perfectly, with no rows, and reported PASS over zero results --
            # both halves fixed: the CR is stripped here, and an empty result set
            # is a hard failure below.
            "$WORK/$file-$which$EXT" 2>/dev/null | tr -d "\r" > "$WORK/out.tmp" || true
            while read -r nm val; do
                case "$val" in ''|*[!0-9.eE+-]*) continue ;; esac
                echo "$val" >> "$WORK/res.$file.$nm.$which"
            done < "$WORK/out.tmp"
            run=$((run + 1))
        done
    done

    for f in "$WORK/res.$file".*.c; do
        [ -e "$f" ] || continue
        nm=$(basename "$f" .c)
        nm=${nm#res.$file.}
        tc=$(sort -g "$WORK/res.$file.$nm.c"  | awk '{v[NR]=$1} END{ print (NR%2)? v[(NR+1)/2] : (v[NR/2]+v[NR/2+1])/2 }')
        tf=$(sort -g "$WORK/res.$file.$nm.fb" | awk '{v[NR]=$1} END{ print (NR%2)? v[(NR+1)/2] : (v[NR/2]+v[NR/2+1])/2 }')
        r=$(awk -v c="$tc" -v f="$tf" 'BEGIN{ printf "%.4f", (c>0)? f/c : 0 }')
        awk -v n="$nm" -v c="$tc" -v f="$tf" -v r="$r" \
            'BEGIN{ printf "%-28s %12.6f %12.6f %8.2fx\n", n, c, f, r }' >> "$WORK/rows.txt"
        echo "$nm $r" >> "$WORK/ratios.txt"
    done
done

awk 'BEGIN{ printf "%-28s %12s %12s %9s\n", "benchmark", "C (s)", "FB (s)", "ratio" }'
awk 'BEGIN{ printf "%-28s %12s %12s %9s\n", "----------------------------", "------------", "------------", "---------" }'
cat "$WORK/rows.txt"

# A harness that measured nothing must not report success. This exact failure --
# an empty table under a tidy "PASS within budget" -- is what a stray carriage
# return produced, and it is indistinguishable from a real pass at a glance.
[ -s "$WORK/ratios.txt" ] || rt_die "no results collected -- the benchmarks ran but nothing was parsed. See $WORK/out.tmp"

awk '
    { r = $2 + 0
      if (r > worst) { worst = r; worstname = $1 }
      if (r > 1.0)   { s += log(r); n++ }          # regressions only
    }
    END {
        if (worst == 0) { worst = 1; worstname = "-" }
        geo = (n > 0) ? exp(s / n) : 1.0
        printf "\ngeomean of regressions: %.4fx over %d result(s)\n", geo, n
        printf "worst single:           %.4fx (%s)\n", worst, worstname
        ok = 1
        if (geo > 1.05)   { printf "FAIL geomean %.2f%% > 5%% budget\n", (geo-1)*100; ok = 0 }
        if (worst > 1.20) { printf "FAIL %s %.2f%% > 20%% single-benchmark budget\n", worstname, (worst-1)*100; ok = 0 }
        if (ok) print "PASS within budget (RFC-0004 R5)"
        exit (ok ? 0 : 1)
    }
' "$WORK/ratios.txt"
