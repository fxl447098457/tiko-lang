#!/bin/sh
# armlane.sh -- tiko-rt on linux-arm64 against tiko-rt on linux-x86_64: the same programs,
# built by tiko from the same tree, run in the Lima VM on the Mac and in WSL, outputs compared.
#
#   lib/rt/build/armlane.sh [Debug|Release]      (default Release)
#
# darwinlane.sh's sibling (docs/tiko-linux-arm64 L2, D-L2-2). THE ORACLE IS tiko's OWN
# linux-x86_64 OUTPUT, as on the Mac: fbc-modern refuses aarch64, so diff.sh's comparison is not
# available. Unlike on the Mac there IS an fbc on the arm64 side -- fbc 1.10.1, built natively in
# the VM (/home/pc.guest/fbc) -- and a difference is settled by running the program under it, by
# hand. Every tests/abi/*-parity.bas is compiled with -c by bin/tiko on Windows for both targets,
# honouring its own NEEDS-MT / NEEDS-LANG-* markers as diff.sh does. The linux-arm64 objects are
# linked in the VM by clang-23 with the ELF line linux-x86_64's uses, against this tree's
# lib/rt/lib/linux-arm64, and the linux-x86_64 ones in WSL against lib/rt/lib/linux-x86_64 -- both
# runtimes built from this tree first:
#
#     lib/rt/build/build.sh Release linux-arm64 linux-x86_64
#
# Each program runs in an empty directory, which is also its TEMP, with no stdin and 60 seconds;
# its output and exit code are compared (a hang shows as exit=124 on both). A difference is
# either fixed or listed as platform-specific in docs/tiko-linux-arm64/FACTS.md. Exits 1 on any
# difference or failure.
#
# THE VM: Lima instance TIKO_LIMA_VM (default 'tk') on the Mac (TIKO_MAC_HOST, default 'mac';
# extra ssh options in TIKO_MAC_SSH_OPTS). The files go to the Mac's ~/tkm/armlane, which the VM
# sees at the same path; the VM's own home is not the Mac's, so the path is handed to it.
#
# Needs: bin/tiko; ssh to the Mac with Lima and the VM (clang-23, lld); WSL with clang (or
# clang-18, Ubuntu's versioned name).

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
RT="$ROOT/lib/rt"
CFG=${1:-Release}
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) EXT=".exe" ;;
    *) echo "armlane: run from Windows (it drives ssh and WSL)" >&2; exit 3 ;;
esac
TKO="$ROOT/bin/tiko$EXT"
[ -x "$TKO" ] || { echo "armlane: build tiko first (build/build.sh)" >&2; exit 3; }
for t in linux-arm64 linux-x86_64; do
    [ -f "$RT/lib/$t/libfb.a" ] && [ -f "$RT/lib/$t/fbrt0.o" ] || \
        { echo "armlane: no $t runtime (lib/rt/build/build.sh $CFG linux-arm64 linux-x86_64)" >&2; exit 3; }
done
HOST=${TIKO_MAC_HOST:-mac}
SSHO=${TIKO_MAC_SSH_OPTS:-}
VM=${TIKO_LIMA_VM:-tk}

W="$ROOT/build/.armlane"
rm -rf "$W"
mkdir -p "$W/arm/obj" "$W/arm/lib" "$W/linux/obj" "$W/linux/lib"
cp "$RT/lib/linux-arm64/fbrt0.o" "$RT/lib/linux-arm64/libfb.a" "$RT/lib/linux-arm64/libfbmt.a" "$W/arm/lib/"
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
    for t in linux-arm64 linux-x86_64; do
        d=arm; [ "$t" = linux-x86_64 ] && d=linux
        # shellcheck disable=SC2086
        if ! "$TKO" -c -m "$name" -target $t $LANGOPT -i "$RT/src" "$src" -o "$W/$d/obj/$name.o" \
                > "$W/$d/obj/$name.build" 2>&1; then
            echo "armlane: FAIL $name -- tiko did not compile it for $t" >&2
            sed 's/^/    /' "$W/$d/obj/$name.build" | head -5 >&2
            ok=0
        fi
    done
    if [ "$ok" = 1 ]; then echo "$name $lib" >> "$W/list"; else buildfail=$((buildfail + 1)); fi
done

# ------------------------------------------------------------------ the run script, one per side
# THE SAME SCRIPT ON BOTH SIDES, the compiler and triple aside: it is handed its directory.
cat > "$W/run.sh" <<'EOF'
set -u
cd "$1" || exit 2
CC=$2; TRIPLE=$3
LD=""
command -v ld.lld > /dev/null 2>&1 && LD="-fuse-ld=lld"
mkdir -p out run
while read -r name lib; do
    if ! $CC -target $TRIPLE $LD -s -Wl,--gc-sections lib/fbrt0.o obj/$name.o -o run/$name \
            -Llib lib/lib$lib.a -lm -lpthread -ltinfo > out/$name.link 2>&1; then
        echo "LINKFAIL" > out/$name.out; continue
    fi
    rm -rf w; mkdir w; ( cd w && TEMP=$PWD timeout 60 ../run/$name < /dev/null > ../out/$name.out 2>&1; echo "exit=$?" >> ../out/$name.out )
done < list
echo "rc=0"
EOF
# The Mac side: limactl is Homebrew's, so a login zsh; the VM is handed the Mac's path. THE RUN
# IS ON THE VM's OWN DISK (ext4), not the Mac's ~/tkm it mounts: over virtiofs a directory's
# st_size is APFS's (96), where ext4 and WSL say 4096 -- fsops-parity differed on that alone.
cat > "$W/arm/vmrun.sh" <<'EOF'
limactl shell "$1" -- bash "$HOME/tkm/armlane/vm.sh" "$HOME/tkm/armlane"
EOF
cat > "$W/arm/vm.sh" <<'EOF'
D=/tmp/armlane
rm -rf $D && cp -r "$1" $D && bash $D/run.sh $D clang-23 aarch64-unknown-linux-gnu
rm -rf "$1/out" && cp -r $D/out "$1/out"
EOF
# WSL's side, as a file too: an argument with '$' in it does not survive wsl.exe intact.
cat > "$W/linux/wslrun.sh" <<'EOF'
CC=clang
command -v clang > /dev/null 2>&1 || CC=clang-18
rm -rf ~/armlane && cp -r "$1" ~/armlane && bash ~/armlane/run.sh ~/armlane $CC x86_64-pc-linux-gnu > ~/armlane/run.log 2>&1
tar -C ~/armlane -cf - out
EOF
sed -i 's/\r$//' "$W/run.sh" "$W/arm/vmrun.sh" "$W/arm/vm.sh" "$W/linux/wslrun.sh"
cp "$W/run.sh" "$W/arm/run.sh"
cp "$W/run.sh" "$W/linux/run.sh"
cp "$W/list" "$W/arm/list"
cp "$W/list" "$W/linux/list"

# ------------------------------------------------------------------ the VM
# shellcheck disable=SC2086
ssh -o BatchMode=yes $SSHO "$HOST" 'rm -rf ~/tkm/armlane && mkdir -p ~/tkm/armlane' < /dev/null \
    || { echo "armlane: no ssh to $HOST" >&2; exit 3; }
# shellcheck disable=SC2086
tar -C "$W/arm" -cf - list run.sh vmrun.sh vm.sh obj lib | ssh -o BatchMode=yes $SSHO "$HOST" 'tar -C ~/tkm/armlane -xf -' \
    || { echo "armlane: copy to $HOST failed" >&2; exit 3; }
# shellcheck disable=SC2086
ssh -o BatchMode=yes $SSHO "$HOST" zsh -l tkm/armlane/vmrun.sh "$VM" < /dev/null > "$W/arm/run.log" 2>&1
# shellcheck disable=SC2086
ssh -o BatchMode=yes $SSHO "$HOST" 'tar -C ~/tkm/armlane -cf - out' < /dev/null | tar -C "$W/arm" -xf -

# ------------------------------------------------------------------ Linux x86-64 (the golden)
mnt( ) { echo "$1" | sed 's#^/\([a-zA-Z]\)/#/mnt/\L\1/#'; }
MSYS_NO_PATHCONV=1 wsl.exe -- bash "$(mnt "$W/linux")/wslrun.sh" "$(mnt "$W/linux")" \
    < /dev/null 2> "$W/linux/run.log" | tar -C "$W/linux" -xf -

# ------------------------------------------------------------------ compare
pass=0; diffs=0; crash=0; na=0
while read -r name lib; do
    a="$W/arm/out/$name.out"; l="$W/linux/out/$name.out"
    if [ ! -f "$a" ] || [ ! -f "$l" ]; then
        echo "armlane: FAIL $name -- no output from $( [ -f "$a" ] || echo arm64 ) $( [ -f "$l" ] || echo x86_64 )" >&2
        diffs=$((diffs + 1)); continue
    fi
    # A program that links on NEITHER side is Windows-only (it names a Windows-only entry
    # point): not applicable here.
    if grep -qx 'LINKFAIL' "$a" && grep -qx 'LINKFAIL' "$l"; then
        echo "armlane: n/a  $name -- links on neither Linux target (Windows-only)" >&2
        na=$((na + 1)); continue
    fi
    if grep -qx 'LINKFAIL' "$a"; then
        echo "armlane: FAIL $name -- does not link on linux-arm64" >&2
        sed 's/^/    /' "$W/arm/out/$name.link" | head -5 >&2
        diffs=$((diffs + 1)); continue
    fi
    if ! grep -qx 'exit=0' "$a"; then crash=$((crash + 1)); fi
    if diff -u "$l" "$a" > "$W/$name.diff"; then
        pass=$((pass + 1))
    else
        echo "armlane: DIFF $name (x86_64 -> arm64)" >&2
        head -30 "$W/$name.diff" >&2
        diffs=$((diffs + 1))
    fi
done < "$W/list"

echo "armlane: $pass identical, $diffs different, $na n/a, $buildfail not built, $crash exited non-zero on arm64 (of $(ls "$RT"/tests/abi/*-parity.bas | wc -l))"
[ "$diffs" = 0 ] && [ "$buildfail" = 0 ]
