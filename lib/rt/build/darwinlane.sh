#!/bin/sh
# darwinlane.sh -- tiko-rt on macos-arm64 against tiko-rt on linux-x86_64: the same programs,
# built by tiko from the same tree, run on the Mac and on Linux, outputs compared.
#
#   lib/rt/build/darwinlane.sh [Debug|Release]      (default Release)
#
# THE ORACLE IS tiko's OWN linux-x86_64 OUTPUT (docs/tiko-macos RFC-0001 D3, M5 D-M5-2): fbc
# has no aarch64 and does not run on the Mac, so diff.sh's fbc-against-tiko-rt comparison is
# not available there. Every tests/abi/*-parity.bas is compiled with -c by bin/tiko on Windows
# for both targets, honouring its own NEEDS-MT / NEEDS-LANG-* markers as diff.sh does. The
# macos-arm64 objects are linked on the Mac with tiko's own Mach-O line (ssh; Homebrew clang,
# the CLT SDK) against this tree's lib/rt/lib/macos-arm64, and the linux-x86_64 ones in WSL
# against lib/rt/lib/linux-x86_64 -- both runtimes built from this tree first:
#
#     lib/rt/build/build.sh Release macos-arm64 linux-x86_64
#
# Each program runs in an empty directory, which is also its TEMP, with no stdin and 60 seconds; its output and exit
# code are compared (a hang shows as exit=124 on Linux, exit=142 -- SIGALRM -- on the Mac). A difference is either fixed or listed as platform-specific in
# docs/tiko-macos FACTS. Exits 1 on any difference or failure.
#
# Needs: bin/tiko; ssh to the Mac (TIKO_MAC_HOST, default 'mac'; extra options in
# TIKO_MAC_SSH_OPTS); WSL with clang.

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
RT="$ROOT/lib/rt"
CFG=${1:-Release}
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) EXT=".exe" ;;
    *) echo "darwinlane: run from Windows (it drives ssh and WSL)" >&2; exit 3 ;;
esac
TKO="$ROOT/bin/tiko$EXT"
[ -x "$TKO" ] || { echo "darwinlane: build tiko first (build/build.sh)" >&2; exit 3; }
for t in macos-arm64 linux-x86_64; do
    [ -f "$RT/lib/$t/libfb.a" ] && [ -f "$RT/lib/$t/fbrt0.o" ] || \
        { echo "darwinlane: no $t runtime (lib/rt/build/build.sh $CFG macos-arm64 linux-x86_64)" >&2; exit 3; }
done
HOST=${TIKO_MAC_HOST:-mac}
SSHO=${TIKO_MAC_SSH_OPTS:-}

W="$ROOT/build/.darwinlane"
rm -rf "$W"
mkdir -p "$W/mac/obj" "$W/mac/lib" "$W/linux/obj" "$W/linux/lib"
cp "$RT/lib/macos-arm64/fbrt0.o" "$RT/lib/macos-arm64/libfb.a" "$RT/lib/macos-arm64/libfbmt.a" "$W/mac/lib/"
cp "$RT/lib/linux-x86_64/fbrt0.o" "$RT/lib/linux-x86_64/libfb.a" "$RT/lib/linux-x86_64/libfbmt.a" "$W/linux/lib/"

# ------------------------------------------------------------------ compile, both targets
: > "$W/list"
buildfail=0
for src in "$RT"/tests/abi/*-parity.bas; do
    name=$(basename "$src" .bas)
    LANGOPT=""
    grep -q 'NEEDS-LANG-FBLITE' "$src" && LANGOPT="-lang fblite"
    grep -q 'NEEDS-LANG-QB' "$src" && LANGOPT="-lang qb"
    lib=fb
    grep -q 'NEEDS-MT' "$src" && lib=fbmt
    ok=1
    for t in macos-arm64 linux-x86_64; do
        d=mac; [ "$t" = linux-x86_64 ] && d=linux
        # shellcheck disable=SC2086
        if ! "$TKO" -c -m "$name" -target $t $LANGOPT -i "$RT/src" "$src" -o "$W/$d/obj/$name.o" \
                > "$W/$d/obj/$name.build" 2>&1; then
            echo "darwinlane: FAIL $name -- tiko did not compile it for $t" >&2
            sed 's/^/    /' "$W/$d/obj/$name.build" | head -5 >&2
            ok=0
        fi
    done
    if [ "$ok" = 1 ]; then echo "$name $lib" >> "$W/list"; else buildfail=$((buildfail + 1)); fi
done

# ------------------------------------------------------------------ the run script, one per side
# THE REMOTE STEPS ARE FILES (a login zsh on the Mac; bash in WSL): a non-login ssh shell has
# no Homebrew, and inline variables expand on the wrong side.
cat > "$W/mac/run.sh" <<'EOF'
set -u
cd ~/tkm/darwinlane || exit 2
CC=/opt/homebrew/opt/llvm/bin/clang
SDK=$(xcrun --show-sdk-path)
mkdir -p out run
while read -r name lib; do
    if ! $CC -target arm64-apple-macosx13.0 -isysroot $SDK -Wl,-S -Wl,-x -Wl,-dead_strip \
            lib/fbrt0.o obj/$name.o -o run/$name -Llib lib/lib$lib.a -lncurses > out/$name.link 2>&1; then
        print -r -- "LINKFAIL" > out/$name.out; continue
    fi
    # A HANG IS A RESULT, not a stall: 60 s, then SIGALRM. macOS has no timeout(1); perl's alarm
    # survives the exec.
    rm -rf w; mkdir w; ( cd w && TEMP=$PWD perl -e 'alarm shift; exec @ARGV' 60 ../run/$name < /dev/null > ../out/$name.out 2>&1; print -r -- "exit=$?" >> ../out/$name.out )
done < list
print -r -- "rc=0"
EOF
cat > "$W/linux/run.sh" <<'EOF'
set -u
cd "$1" || exit 2
# Ubuntu names it clang-18 when no unversioned clang is installed.
CC=clang; command -v clang > /dev/null 2>&1 || CC=clang-18
LD=""
command -v ld.lld > /dev/null 2>&1 && LD="-fuse-ld=lld"
mkdir -p out run
while read -r name lib; do
    if ! $CC -target x86_64-pc-linux-gnu $LD -s -Wl,--gc-sections lib/fbrt0.o obj/$name.o -o run/$name \
            -Llib lib/lib$lib.a -lm -lpthread -ltinfo > out/$name.link 2>&1; then
        echo "LINKFAIL" > out/$name.out; continue
    fi
    rm -rf w; mkdir w; ( cd w && TEMP=$PWD timeout 60 ../run/$name < /dev/null > ../out/$name.out 2>&1; echo "exit=$?" >> ../out/$name.out )
done < list
echo "rc=0"
EOF
sed -i 's/\r$//' "$W/mac/run.sh" "$W/linux/run.sh"
cp "$W/list" "$W/mac/list"
cp "$W/list" "$W/linux/list"

# ------------------------------------------------------------------ the Mac
# shellcheck disable=SC2086
ssh -o BatchMode=yes $SSHO "$HOST" 'rm -rf ~/tkm/darwinlane && mkdir -p ~/tkm/darwinlane' < /dev/null \
    || { echo "darwinlane: no ssh to $HOST" >&2; exit 3; }
# shellcheck disable=SC2086
tar -C "$W/mac" -cf - list run.sh obj lib | ssh -o BatchMode=yes $SSHO "$HOST" 'tar -C ~/tkm/darwinlane -xf -' \
    || { echo "darwinlane: copy to $HOST failed" >&2; exit 3; }
# shellcheck disable=SC2086
ssh -o BatchMode=yes $SSHO "$HOST" zsh -l tkm/darwinlane/run.sh < /dev/null > "$W/mac/run.log" 2>&1
# shellcheck disable=SC2086
ssh -o BatchMode=yes $SSHO "$HOST" 'tar -C ~/tkm/darwinlane -cf - out' < /dev/null | tar -C "$W/mac" -xf -

# ------------------------------------------------------------------ Linux (the golden)
mnt( ) { echo "$1" | sed 's#^/\([a-zA-Z]\)/#/mnt/\L\1/#'; }
MSYS_NO_PATHCONV=1 wsl.exe -- bash -c "rm -rf ~/darwinlane && cp -r '$(mnt "$W/linux")' ~/darwinlane && bash ~/darwinlane/run.sh ~/darwinlane > ~/darwinlane/run.log 2>&1; tar -C ~/darwinlane -cf - out" \
    < /dev/null 2> "$W/linux/run.log" | tar -C "$W/linux" -xf -

# ------------------------------------------------------------------ compare
pass=0; diffs=0; crash=0; na=0
while read -r name lib; do
    m="$W/mac/out/$name.out"; l="$W/linux/out/$name.out"
    if [ ! -f "$m" ] || [ ! -f "$l" ]; then
        echo "darwinlane: FAIL $name -- no output from $( [ -f "$m" ] || echo mac ) $( [ -f "$l" ] || echo linux )" >&2
        diffs=$((diffs + 1)); continue
    fi
    # A program that links on NEITHER side is Windows-only (it names a Windows-only entry
    # point): not applicable here, and not a Mac failure.
    if grep -qx 'LINKFAIL' "$m" && grep -qx 'LINKFAIL' "$l"; then
        echo "darwinlane: n/a  $name -- links on neither POSIX target (Windows-only)" >&2
        na=$((na + 1)); continue
    fi
    if grep -qx 'LINKFAIL' "$m"; then
        echo "darwinlane: FAIL $name -- does not link on the Mac" >&2
        sed 's/^/    /' "$W/mac/out/$name.link" | head -5 >&2
        diffs=$((diffs + 1)); continue
    fi
    if ! grep -qx 'exit=0' "$m"; then crash=$((crash + 1)); fi
    if diff -u "$l" "$m" > "$W/$name.diff"; then
        pass=$((pass + 1))
    else
        echo "darwinlane: DIFF $name (linux -> mac)" >&2
        head -30 "$W/$name.diff" >&2
        diffs=$((diffs + 1))
    fi
done < "$W/list"

echo "darwinlane: $pass identical, $diffs different, $na n/a, $buildfail not built, $crash exited non-zero on the Mac (of $(ls "$RT"/tests/abi/*-parity.bas | wc -l))"
[ "$diffs" = 0 ] && [ "$buildfail" = 0 ]
