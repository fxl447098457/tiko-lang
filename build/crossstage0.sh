#!/bin/sh
# crossstage0.sh -- a stage0 compiler for a target no seed can build yet: compiled here by
# bin/tiko, LINKED ON THE TARGET.
#
#   build/crossstage0.sh linux-arm64 [outdir]      (default outdir: build/.crossstage0/<target>)
#
# docs/tiko-linux-arm64 L3 (D-L3-1: no linux-arm64 seed until L5), as docs/tiko-macos M6 did by
# hand for the Mac. This host's bin/tiko compiles the whole compiler -- build/sources.txt, main
# first, with the module objects of everything it imports -- for <target> in ONE call, exactly
# as build/build.sh's seeded path does, at Release's flags plus -mt. The link then fails here
# (no sysroot for the target), which is expected: -v printed tiko's own link line and
# --keep-temps kept every object, and those are what the target needs.
#
# <outdir> holds, ready to copy to the target as one directory:
#     obj/NNN.o      the objects, in link order
#     lib/           fbrt0.o and libfbmt.a from this tree's lib/rt/lib/<target> (build them
#                    first: lib/rt/build/build.sh Release <target>)
#     link.sh        tiko's link line with those paths: 'sh link.sh [clang]' writes ./tiko
#
# Then, on the target:  sh link.sh && ./tiko --version  (it must say 'target <target>'), and
# build/bootstrap.sh --seed <that tiko> runs to the fixpoint.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TGT=${1:-}
case "$TGT" in
    linux-arm64) ;;
    *) echo "crossstage0: target '$TGT' is not one this makes (linux-arm64)" >&2; exit 2 ;;
esac
OUT=${2:-$ROOT/build/.crossstage0/$TGT}
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) EXT=.exe ;; *) EXT="" ;; esac
TKO="$ROOT/bin/tiko$EXT"
[ -x "$TKO" ] || { echo "crossstage0: build tiko first (build/build.sh)" >&2; exit 3; }
RTL="$ROOT/lib/rt/lib/$TGT"
[ -f "$RTL/libfbmt.a" ] && [ -f "$RTL/fbrt0.o" ] || \
    { echo "crossstage0: no $TGT runtime (lib/rt/build/build.sh Release $TGT)" >&2; exit 3; }

rm -rf "$OUT"
mkdir -p "$OUT/obj" "$OUT/lib" "$OUT/work"
SOURCES=$(grep -v '^[[:space:]]*#' "$ROOT/build/sources.txt" | grep -v '^[[:space:]]*$')
MAINMOD=$(basename "$(echo "$SOURCES" | head -1)" .tiko)

# THE TREE'S OWN HEADERS AND PACKAGES, as build.sh gives a seed.
cd "$ROOT"
# shellcheck disable=SC2086
TIKO_INCLUDE="$ROOT/inc" TIKO_PKG="$ROOT/pkg" "$TKO" $SOURCES -m "$MAINMOD" -i src \
    -O 2 -w all -mt -target "$TGT" -p "lib/rt/lib/$TGT" -v --keep-temps -o "$OUT/work/tiko" \
    > "$OUT/build.log" 2>&1 || true
grep -qiE '(^|: )(error|warning) ' "$OUT/build.log" && \
    ! grep -q 'TKO0116' "$OUT/build.log" && \
    { echo "crossstage0: the compile did not succeed -- $OUT/build.log" >&2; tail -5 "$OUT/build.log" >&2; exit 1; }
if grep -E ': (warning|error) TKO' "$OUT/build.log" | grep -v TKO0116 | grep -q .; then
    echo "crossstage0: diagnostics other than the expected link failure -- $OUT/build.log" >&2
    grep -E ': (warning|error) TKO' "$OUT/build.log" | grep -v TKO0116 | head -5 >&2
    exit 1
fi
LINE=$(grep -E -- '-fuse-ld' "$OUT/build.log" | tail -1)
[ -n "$LINE" ] || { echo "crossstage0: no link line in $OUT/build.log" >&2; exit 1; }

# THE OBJECTS, in the link line's order, renamed to their position.
n=0
OBJS=""
for o in $(echo "$LINE" | grep -oE '"[^"]+\.o"' | tr -d '"'); do
    case "$o" in */fbrt0.o) continue ;; esac
    [ -f "$o" ] || { echo "crossstage0: the link line names $o, which is not there" >&2; exit 1; }
    n=$((n + 1))
    f=$(printf '%03d.o' "$n")
    cp "$o" "$OUT/obj/$f"
    OBJS="$OBJS obj/$f"
done
cp "$RTL/fbrt0.o" "$RTL/libfbmt.a" "$OUT/lib/"

# THE LINK LINE, as tiko printed it, over the copied files. The libraries are taken from it
# rather than assumed, so a runtime that grows a dependency carries it here too.
LIBS=$(echo "$LINE" | grep -oE -- ' -l[a-z0-9_+]+' | tr '\n' ' ')
TRIPLE=$(echo "$LINE" | sed -n 's/.* -target \([^ ]*\) .*/\1/p')
cat > "$OUT/link.sh" <<EOF
# link.sh -- written by build/crossstage0.sh: tiko's own link line for $TGT over these files.
set -eu
cd "\$(dirname "\$0")"
CC=\${1:-clang}
\$CC -target $TRIPLE -fuse-ld=lld -s -Wl,--gc-sections lib/fbrt0.o$OBJS -o tiko -L lib \\
    -Xlinker --start-group lib/libfbmt.a $LIBS-Xlinker --end-group
echo "link.sh: ./tiko"
EOF
sed -i 's/\r$//' "$OUT/link.sh"
rm -rf "$OUT/work"
echo "crossstage0: $TGT -- $n objects, $(du -sh "$OUT" | cut -f1) in $OUT"
