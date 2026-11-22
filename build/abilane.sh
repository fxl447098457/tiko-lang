#!/bin/sh
# abilane.sh -- the SysV ABI lane: tiko-compiled code against a gcc-built C library.
#
#   build/abilane.sh          SysV in WSL, then win64
#   build/abilane.sh --mac    ...and fabi3 on the Mac over ssh
#
# tests/abi/fabi*.bas call into, and are called back from, tests/abi/cabi*.c: UDTs of
# 1..24 bytes by value, mixed float/int eightbytes, odd sizes 3/5/13, variadics, and
# many-scalar prefixes that exhaust the argument registers ('regx( 7 doubles, struct{
# double, double }, double )'). Each .bas is compiled by bin/tiko for linux-x86_64, the
# C side by gcc in WSL, linked there against the Linux tiko-rt, run, and the output
# compared with tests/abi/expected/ -- fbc's output for the same program, or the
# expectation the program prints beside each value.
#
# WHY: every Windows test passed while SysV register classification was wrong (audit
# F-02, F-19): a 3-byte argument was loaded past its slot, and an aggregate split across
# xmm7 and the stack. Only a real System V caller and callee find that.
#
# fabi3/cabi3 is int128 against C's __int128, and runs TWICE: the SysV lane as above, then
# windows-x86_64 with the C side built by clang for x86_64-pc-windows-msvc -- win64 passes
# __int128 by address and returns it in XMM0 (src/codegen/abiint128.tiko), which only a real
# MSVC-ABI callee checks. With --mac it runs a third time, on the Mac (macos-arm64, AAPCS64).
# Needs WSL with gcc, and a Linux tiko-rt: TIKO_LINUX_LIB, else the tree's own
# toolchains/tiko-linux/lib, else C:\dev\tiko-lang's. Exits 1 on any difference.

ROOT=$(cd "$(dirname "$0")/.." && pwd)
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) EXT=".exe" ;;
    *) echo "abilane: run from Windows (it drives WSL)" >&2; exit 3 ;;
esac
TKO="$ROOT/bin/tiko$EXT"
[ -x "$TKO" ] || { echo "abilane: build tiko first (build/build.sh)" >&2; exit 3; }
command -v wsl > /dev/null 2>&1 || { echo "abilane: needs WSL" >&2; exit 3; }

L=${TIKO_LINUX_LIB:-}
[ -n "$L" ] || { [ -d "$ROOT/toolchains/tiko-linux/lib" ] && L="$ROOT/toolchains/tiko-linux/lib"; }
[ -n "$L" ] || L=/c/dev/tiko-lang/toolchains/tiko-linux/lib
[ -f "$L/linux-x86_64/libfb.a" ] || { echo "abilane: no Linux tiko-rt under $L (set TIKO_LINUX_LIB)" >&2; exit 3; }

W="$ROOT/build/.abilane"
mkdir -p "$W"
# A Windows path as WSL sees it: /c/x -> /mnt/c/x.
mnt( ) { echo "$1" | sed 's#^/\([a-zA-Z]\)/#/mnt/\L\1/#'; }

fail=0
for b in fabi fabi2 fabi3; do
    c=$(echo $b | sed 's/^f/c/')
    if ! "$TKO" -target linux-x86_64 -c -m $b "$ROOT/tests/abi/$b.bas" -o "$W/$b.o" > "$W/$b.tiko.log" 2>&1; then
        echo "FAIL $b: tiko did not compile it"; head -5 "$W/$b.tiko.log"; fail=1; continue
    fi
    MSYS_NO_PATHCONV=1 wsl bash -c "cd '$(mnt "$W")' && gcc -O1 -c '$(mnt "$ROOT/tests/abi/$c.c")' -o $c.o && \
        gcc -no-pie '$(mnt "$L")/linux-x86_64/fbrt0.o' $b.o $c.o '$(mnt "$L")/linux-x86_64/libfb.a' \
            -lm -lpthread -ltinfo -o $b && ./$b" > "$W/$b.out" 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "FAIL $b: link or run exited $rc"; tail -5 "$W/$b.out"; fail=1; continue
    fi
    if tr -d '\r' < "$W/$b.out" | cmp -s - "$ROOT/tests/abi/expected/$b.txt"; then
        echo "PASS $b"
    else
        echo "FAIL $b: output differs (< expected  > tiko)"
        tr -d '\r' < "$W/$b.out" | diff "$ROOT/tests/abi/expected/$b.txt" - | head -20
        fail=1
    fi
done
# THE WIN64 HALF, int128 only: clang compiles the C, tiko links it for windows-x86_64.
CLANG=${TIKO_CLANG:-"/c/Program Files/LLVM/bin/clang.exe"}
WRT="$ROOT/build/obj/rtlib/windows-x86_64"
if [ ! -x "$CLANG" ]; then
    echo "FAIL fabi3-win64: no clang at $CLANG (set TIKO_CLANG)"; fail=1
elif [ ! -d "$WRT" ]; then
    echo "FAIL fabi3-win64: no $WRT (build/test.sh builds it)"; fail=1
elif ! "$CLANG" --target=x86_64-pc-windows-msvc -O1 -c "$ROOT/tests/abi/cabi3.c" -o "$W/cabi3-win.o" > "$W/cabi3-win.log" 2>&1; then
    echo "FAIL fabi3-win64: clang did not compile cabi3.c"; head -5 "$W/cabi3-win.log"; fail=1
elif ! TIKO_LIBPATH="$WRT" "$TKO" -target windows-x86_64 "$ROOT/tests/abi/fabi3.bas" "$W/cabi3-win.o"         -o "$W/fabi3-win.exe" > "$W/fabi3-win.tiko.log" 2>&1; then
    echo "FAIL fabi3-win64: tiko did not build it"; head -5 "$W/fabi3-win.tiko.log"; fail=1
else
    "$W/fabi3-win.exe" > "$W/fabi3-win.out" 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "FAIL fabi3-win64: run exited $rc"; tail -5 "$W/fabi3-win.out"; fail=1
    elif tr -d '\r' < "$W/fabi3-win.out" | cmp -s - "$ROOT/tests/abi/expected/fabi3.txt"; then
        echo "PASS fabi3-win64"
    else
        echo "FAIL fabi3-win64: output differs (< expected  > tiko)"
        tr -d '\r' < "$W/fabi3-win.out" | diff "$ROOT/tests/abi/expected/fabi3.txt" - | head -20
        fail=1
    fi
fi
# THE MAC HALF, int128 only, with --mac: fabi3 for macos-arm64 against cabi3.c built by the
# Mac's own Homebrew clang. AAPCS64 puts a 16-aligned 16-byte struct on an EVEN register pair
# or a 16-aligned stack slot (codegen/abi.tiko, TKO_AA_ALIGN16) -- only a real callee there
# proves it. The Mac's tiko-lang checkout is left alone: this builds the macos-arm64
# runtime here (lib/rt/build/build.sh) and sends the objects, the archive and cabi3.c to
# ~/tkm/abilane on TIKO_MAC_HOST (default 'mac'), the way build/aapcslane.sh does.
if [ "${1:-}" = "--mac" ]; then
    HOST=${TIKO_MAC_HOST:-mac}
    MW="$W/mac"
    mkdir -p "$MW"
    if ! TKORT_TIKO="$TKO" bash "$ROOT/lib/rt/build/build.sh" Release macos-arm64 > "$MW/rt.log" 2>&1; then
        echo "FAIL fabi3-mac: the macos-arm64 runtime did not build"; tail -3 "$MW/rt.log"; fail=1
    elif ! "$TKO" -c -m fabi3 -target macos-arm64 "$ROOT/tests/abi/fabi3.bas" -o "$MW/fabi3.o" > "$MW/tiko.log" 2>&1; then
        echo "FAIL fabi3-mac: tiko did not compile fabi3.bas"; head -5 "$MW/tiko.log"; fail=1
    else
        cp "$ROOT/tests/abi/cabi3.c" "$ROOT/lib/rt/lib/macos-arm64/libfb.a" "$ROOT/lib/rt/lib/macos-arm64/fbrt0.o" "$MW/"
        cat > "$MW/mac.sh" <<'EOF'
set -u
cd ~/tkm/abilane || exit 2
CC=/opt/homebrew/opt/llvm/bin/clang
[ -x $CC ] || CC=/usr/bin/clang
SDK=$(xcrun --show-sdk-path)
$CC -target arm64-apple-macosx13.0 -isysroot $SDK -O1 -c cabi3.c -o cabi3.o || { print "rc=2 clang"; exit 2; }
$CC -target arm64-apple-macosx13.0 -isysroot $SDK fbrt0.o fabi3.o cabi3.o libfb.a -lncurses -o fabi3 || { print "rc=2 link"; exit 2; }
./fabi3
print "rc=$?"
EOF
        sed -i 's/\r$//' "$MW/mac.sh"
        if ssh -o BatchMode=yes "$HOST" 'mkdir -p ~/tkm/abilane' < /dev/null && \
           scp -q -o BatchMode=yes "$MW/cabi3.c" "$MW/libfb.a" "$MW/fbrt0.o" "$MW/fabi3.o" "$MW/mac.sh" "$HOST:tkm/abilane/"; then
            ssh -o BatchMode=yes "$HOST" zsh -l tkm/abilane/mac.sh < /dev/null > "$MW/mac.out" 2>&1
            if ! grep -q '^rc=0$' "$MW/mac.out"; then
                echo "FAIL fabi3-mac: link or run"; tail -5 "$MW/mac.out"; fail=1
            elif grep -v '^rc=' "$MW/mac.out" | tr -d '\r' | cmp -s - "$ROOT/tests/abi/expected/fabi3.txt"; then
                echo "PASS fabi3-mac"
            else
                echo "FAIL fabi3-mac: output differs (< expected  > tiko)"
                grep -v '^rc=' "$MW/mac.out" | tr -d '\r' | diff "$ROOT/tests/abi/expected/fabi3.txt" - | head -20
                fail=1
            fi
        else
            echo "FAIL fabi3-mac: no ssh/scp to $HOST"; fail=1
        fi
    fi
fi
[ $fail -eq 0 ] && echo "abilane: ok"
exit $fail
