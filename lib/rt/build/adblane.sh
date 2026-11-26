#!/bin/sh
# adblane.sh -- tiko-rt on android-x86_64 against tiko-rt on linux-x86_64: the same programs,
# built by tiko from the same tree, run on an Android device or emulator and in WSL, outputs
# compared.
#
#   lib/rt/build/adblane.sh [Debug|Release]      (default Release)
#
# darwinlane.sh's sibling (docs/tiko-android A1 step 6, D-A1-7). THE ORACLE IS tiko's OWN
# linux-x86_64 OUTPUT: fbc-modern's Android rtlib is not built, so diff.sh's comparison is not
# available. Every tests/abi/*-parity.bas is compiled with -c by bin/tiko on Windows for both
# targets, honouring its own NEEDS-MT / NEEDS-LANG-* markers as diff.sh does. UNLIKE THE MAC,
# ANDROID LINKS ON WINDOWS: the NDK is the whole link environment, so the android-x86_64 objects
# are linked here with the line tiko's own LinkExe writes for that target (the NDK's sysroot and
# its clang's resource directory, -lm -ldl) against this tree's lib/rt/lib/android-x86_64, and
# the linux-x86_64 ones in WSL against lib/rt/lib/linux-x86_64 -- both runtimes built from this
# tree first:
#
#     lib/rt/build/build.sh Release android-x86_64 linux-x86_64
#
# Each program runs in an empty directory, which is also its TEMP and TMPDIR, with no stdin and
# 60 seconds (toybox timeout on the device; a hang shows as exit=124 on both). Output and exit
# code are compared. A difference is either fixed or listed as platform-specific in
# docs/tiko-android FACTS. Exits 1 on any difference or failure.
#
# TIKO_ADB_TARGET picks the Android target (android-x86_64, the default, or android-arm64 --
# docs/tiko-android A3, D-A3-4); its runtime is this tree's lib/rt/lib/<target>.
# ADBLANE_GOLDEN, when set, is a directory of <name>.out files to compare with instead of the
# WSL run -- for android-arm64, lib/rt/build/armlane.sh's linux-arm64 outputs from the Lima VM
# (build/.armlane/arm/out, D-A3-2): the same CPU architecture, so only the OS differs.
#
# Needs: bin/tiko; the Android SDK's adb and an NDK (ANDROID_HOME, ANDROID_NDK_HOME, or their
# default places) with one device or emulator attached; WSL with clang.

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
RT="$ROOT/lib/rt"
CFG=${1:-Release}
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) EXT=".exe" ;;
    *) echo "adblane: run from Windows (it drives adb and WSL)" >&2; exit 3 ;;
esac
TKO="$ROOT/bin/tiko$EXT"
[ -x "$TKO" ] || { echo "adblane: build tiko first (build/build.sh)" >&2; exit 3; }
ATGT=${TIKO_ADB_TARGET:-android-x86_64}
case "$ATGT" in
    android-x86_64) ATRIPLE=x86_64-linux-android29 ;;
    android-arm64)  ATRIPLE=aarch64-linux-android29 ;;
    *) echo "adblane: TIKO_ADB_TARGET is android-x86_64 or android-arm64, not '$ATGT'" >&2; exit 3 ;;
esac
GOLDEN=${ADBLANE_GOLDEN:-}
NEED="$ATGT"; [ -z "$GOLDEN" ] && NEED="$ATGT linux-x86_64"
for t in $NEED; do
    [ -f "$RT/lib/$t/libfb.a" ] && [ -f "$RT/lib/$t/fbrt0.o" ] || \
        { echo "adblane: no $t runtime (lib/rt/build/build.sh $CFG $NEED)" >&2; exit 3; }
done
[ -z "$GOLDEN" ] || [ -d "$GOLDEN" ] || { echo "adblane: ADBLANE_GOLDEN '$GOLDEN' is not a directory" >&2; exit 3; }
# MSYS rewrites /data/local/tmp into a Windows path in adb's arguments; once it is told not to,
# every path a native tool is handed must be written C:/... (cygpath -m).
export MSYS_NO_PATHCONV=1
SDK=${ANDROID_HOME:-${LOCALAPPDATA:-}/Android/Sdk}
NDK=${TIKO_ANDROID_NDK:-${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-$(ls -d "$SDK"/ndk/* 2>/dev/null | sort -V | tail -1)}}}
PRE=$NDK/toolchains/llvm/prebuilt/windows-x86_64
RES=$(ls -d "$PRE"/lib/clang/* 2>/dev/null | tail -1)
ADB=$SDK/platform-tools/adb.exe
CLANG=${TIKO_CLANG:-C:/Program Files/LLVM/bin/clang.exe}
[ -d "$PRE/sysroot" ] && [ -n "$RES" ] || { echo "adblane: no NDK at '$NDK' (set ANDROID_NDK_HOME)" >&2; exit 3; }
[ -x "$ADB" ] || { echo "adblane: no adb at '$ADB' (set ANDROID_HOME)" >&2; exit 3; }
"$ADB" get-state > /dev/null 2>&1 || { echo "adblane: adb reaches no device" >&2; exit 3; }

W="$ROOT/build/.adblane"
rm -rf "$W"
mkdir -p "$W/android/obj" "$W/android/run" "$W/android/out" "$W/linux/obj" "$W/linux/lib"
[ -z "$GOLDEN" ] && cp "$RT/lib/linux-x86_64/fbrt0.o" "$RT/lib/linux-x86_64/libfb.a" "$RT/lib/linux-x86_64/libfbmt.a" "$W/linux/lib/"
WM=$(cygpath -m "$W")
ALIB=$(cygpath -m "$RT/lib/$ATGT")

# ------------------------------------------------------------------ compile both; link Android
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
    TGTS="$ATGT"; [ -z "$GOLDEN" ] && TGTS="$ATGT linux-x86_64"
    for t in $TGTS; do
        d=android; [ "$t" = linux-x86_64 ] && d=linux
        # shellcheck disable=SC2086
        if ! "$TKO" -c -m "$name" -target $t $LANGOPT -i "$(cygpath -m "$RT/src")" "$(cygpath -m "$src")" \
                -o "$WM/$d/obj/$name.o" > "$W/$d/obj/$name.build" 2>&1; then
            echo "adblane: FAIL $name -- tiko did not compile it for $t" >&2
            sed 's/^/    /' "$W/$d/obj/$name.build" | head -5 >&2
            ok=0
        fi
    done
    if [ "$ok" = 1 ]; then
        echo "$name $lib" >> "$W/list"
        # tiko's LinkExe line for android-x86_64 (codegen/toolchain.tiko), with fbrt0.o first.
        if ! "$CLANG" -target $ATRIPLE -fuse-ld=lld --sysroot="$PRE/sysroot" \
                -resource-dir "$RES" -s -Wl,--gc-sections "$ALIB/fbrt0.o" "$WM/android/obj/$name.o" \
                -o "$WM/android/run/$name" -L"$ALIB" -Xlinker --start-group -l$lib -lm -ldl \
                -Xlinker --end-group > "$W/android/out/$name.link" 2>&1; then
            echo "LINKFAIL" > "$W/android/out/$name.out"
        fi
    else
        buildfail=$((buildfail + 1))
    fi
done

# ------------------------------------------------------------------ the device
cat > "$W/android/run.sh" <<'EOF'
cd /data/local/tmp/adblane || exit 2
mkdir -p out
while read -r name lib; do
    [ -f "run/$name" ] || continue
    chmod 755 "run/$name"
    rm -rf w; mkdir w
    ( cd w && TEMP=$PWD TMPDIR=$PWD timeout 60 ../run/$name < /dev/null > ../out/$name.out 2>&1; echo "exit=$?" >> ../out/$name.out )
done < list
rm -rf w
echo "rc=0"
EOF
sed -i 's/\r$//' "$W/android/run.sh"
cp "$W/list" "$W/android/list"
"$ADB" shell 'rm -rf /data/local/tmp/adblane && mkdir -p /data/local/tmp/adblane/run' > /dev/null
"$ADB" push "$WM/android/list" "$WM/android/run.sh" /data/local/tmp/adblane/ > /dev/null
"$ADB" push "$WM/android/run/." /data/local/tmp/adblane/run/ > /dev/null
"$ADB" shell 'sh /data/local/tmp/adblane/run.sh' > "$W/android/run.log" 2>&1
"$ADB" pull /data/local/tmp/adblane/out/. "$WM/android/out/" > /dev/null
"$ADB" shell 'rm -rf /data/local/tmp/adblane' > /dev/null

# ------------------------------------------------------------------ Linux (the golden)
cat > "$W/linux/run.sh" <<'EOF'
set -u
cd "$1" || exit 2
LD=""
command -v ld.lld > /dev/null 2>&1 && LD="-fuse-ld=lld"
CC=clang
command -v clang > /dev/null 2>&1 || CC=clang-18
mkdir -p out run
while read -r name lib; do
    if ! $CC -target x86_64-pc-linux-gnu $LD -s -Wl,--gc-sections lib/fbrt0.o obj/$name.o -o run/$name \
            -Llib lib/lib$lib.a -lm -lpthread -ltinfo > out/$name.link 2>&1; then
        echo "LINKFAIL" > out/$name.out; continue
    fi
    rm -rf w; mkdir w; ( cd w && TEMP=$PWD TMPDIR=$PWD timeout 60 ../run/$name < /dev/null > ../out/$name.out 2>&1; echo "exit=$?" >> ../out/$name.out )
done < list
echo "rc=0"
EOF
sed -i 's/\r$//' "$W/linux/run.sh"
cp "$W/list" "$W/linux/list"
mnt( ) { echo "$1" | sed 's#^/\([a-zA-Z]\)/#/mnt/\L\1/#'; }
if [ -n "$GOLDEN" ]; then
    rm -rf "$W/linux/out"; mkdir -p "$W/linux/out"; cp "$GOLDEN"/*.out "$W/linux/out/" 2>/dev/null
else
wsl.exe -- bash -c "rm -rf ~/adblane && cp -r '$(mnt "$W/linux")' ~/adblane && bash ~/adblane/run.sh ~/adblane > ~/adblane/run.log 2>&1; tar -C ~/adblane -cf - out" \
    < /dev/null 2> "$W/linux/run.log" | tar -C "$W/linux" -xf -
fi

# ------------------------------------------------------------------ compare
pass=0; diffs=0; crash=0; na=0
while read -r name lib; do
    a="$W/android/out/$name.out"; l="$W/linux/out/$name.out"
    if [ ! -f "$a" ] || [ ! -f "$l" ]; then
        echo "adblane: FAIL $name -- no output from $( [ -f "$a" ] || echo android ) $( [ -f "$l" ] || echo linux )" >&2
        diffs=$((diffs + 1)); continue
    fi
    # A program that links on NEITHER side is Windows-only (it names a Windows-only entry
    # point): not applicable here, and not an Android failure.
    if grep -qx 'LINKFAIL' "$a" && grep -qx 'LINKFAIL' "$l"; then
        echo "adblane: n/a  $name -- links on neither POSIX target (Windows-only)" >&2
        na=$((na + 1)); continue
    fi
    if grep -qx 'LINKFAIL' "$a"; then
        echo "adblane: FAIL $name -- does not link for Android" >&2
        sed 's/^/    /' "$W/android/out/$name.link" | head -5 >&2
        diffs=$((diffs + 1)); continue
    fi
    if ! grep -qx 'exit=0' "$a"; then crash=$((crash + 1)); fi
    if diff -u "$l" "$a" > "$W/$name.diff"; then
        pass=$((pass + 1))
    else
        echo "adblane: DIFF $name (linux -> android)" >&2
        head -30 "$W/$name.diff" >&2
        diffs=$((diffs + 1))
    fi
done < "$W/list"

echo "adblane: [$ATGT against ${GOLDEN:-linux-x86_64 in WSL}] $pass identical, $diffs different, $na n/a, $buildfail not built, $crash exited non-zero on Android (of $(ls "$RT"/tests/abi/*-parity.bas | wc -l))"
[ "$diffs" = 0 ] && [ "$buildfail" = 0 ]
