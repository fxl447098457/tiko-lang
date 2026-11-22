#!/bin/bash
# release.sh -- archive, hash, smoke-test and (only when asked) publish a toolchain release.
#
#   bash build/release.sh --notes <notes.md> [--sha <commit>] [--prev <dir>]
#                         [--editor <dir>] [--no-tkedit] [--lsp <dir>] [--no-lsp] [--no-mac] [--no-arm64]
#                         [--publish [--latest]]
#
# THE RECIPE THAT LIVED IN MEMORY NOTES (review BLD-06, 2026-10-24), as one script. It does
# not package: run build/package.sh --verify for each host first (Windows here, Linux under
# WSL, on the Mac in ~/dev/tiko-lang or TIKO_MAC_ROOT, and in the Mac's arm64 VM at
# TIKO_ARM_ROOT), at the SAME commit. Then this:
#
#   1. refuses unless every toolchain's MANIFEST.txt names the commit (default HEAD);
#   EVERY ARCHIVE HOLDS ONE FOLDER, tiko-lang/, on every OS (author 2026-10-29), with the one-file
#   tkedit in its root: tiko-lang/tkedit.exe next to tiko.exe; tiko-lang/tkedit above bin/tiko; on
#   macOS tiko-lang/tkEdit.app. The archive names are unchanged. (--no-tkedit: the
#   compiler alone.)
#   THE LANGUAGE SERVER RIDES ALONG (author 2026-10-30): tiko-lang/tiko-lsp.exe next to tiko.exe,
#   tiko-lang/bin/tiko-lsp next to bin/tiko -- so a tiko on the PATH puts tiko-lsp there too --
#   and its licence as licences/LICENSE-tiko-lsp. It is taken from tiko-lsp's OWN release
#   archives, the binaries that passed that repository's gates (its release/build-*.sh):
#   --lsp <dir> holds tiko-lsp-windows-x86_64.zip and tiko-lsp-linux-x86_64.tar.gz (default
#   ../tiko-lsp/dist); the Mac's is ~/dev/tiko-lsp/dist/tiko-lsp-macos-arm64.tar.gz there.
#   --no-lsp leaves it out.
#   2. zips toolchains/tiko-windows, staged as tiko-lang, with C:/Windows/System32/tar.exe (bsdtar) -- Git Bash's
#      bare tar.exe is GNU tar, whose '-a -cf x.zip' writes an uncompressed TAR named .zip --
#      and checks the result is a zip;
#   3. tars toolchains/tiko-linux under WSL from a copy in ~/tkrel-<sha>, 644 for files and
#      755 for bin/tiko and tkedit, owner 0 (tarring from /mnt/c gives every file 777);
#   3b. tars toolchains/tiko-macos ON THE MAC (docs/tiko-macos M9), over ssh to TIKO_MAC_HOST
#      (default 'mac', options in TIKO_MAC_SSH_OPTS): bsdtar, owner 0, no extended attributes
#      or AppleDouble files, 644/755 as above; copied back here. It unpacks to tiko-lang/, as the
#      others do, tkEdit.app in its bin/. --no-mac leaves it out;
#   3c. tars toolchains/tiko-linux-arm64 IN THE LIMA VM tk22 on the Mac (docs/tiko-linux-arm64 L5),
#      the Linux lane's recipe on the VM's own disk, copied back through the Mac's ~/tkm.
#      --no-arm64 leaves it out;
#   4. writes SHA256SUMS and appends the hashes to a copy of the notes;
#   5. smoke-tests each archive extracted into an empty directory with no TIKO_* variable:
#      hello.tiko compiled and run, tiko-lang/ the archive's only folder, and tkedit in its
#      root -- on macOS a tkEdit.app whose signature verifies (one file: docs/tkEdit/SINGLE-FILE.md);
#      and tiko-lsp beside the compiler, answering --version;
#   6. with --prev <dir> holding the previous release's two archives, prints the files each
#      archive gained and lost, below the top folder (so an older tiko-windows/ compares as tiko-lang/);
#   7. with --editor <dir>, mirrors tiko-windows into <dir> (the editor's toolchain copy);
#   8. with --publish, and only then, 'gh release create toolchain-<short> --target <full sha>'
#      -- a short sha is HTTP 422 -- with the archives. --latest marks it Latest.
#
# Everything lands in build/.release/<short>/. Nothing is published without --publish.
set -o pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 2
NOTES="" SHA="" PREV="" EDITOR="" PUBLISH=0 LATEST=0 TKEDIT=1 MAC=1 ARM=1 LSP=1 LSPDIR=
while [ $# -gt 0 ]; do
    case "$1" in
        --notes)   shift; NOTES=$1 ;;
        --sha)     shift; SHA=$1 ;;
        --prev)    shift; PREV=$1 ;;
        --editor)  shift; EDITOR=$1 ;;
        --publish) PUBLISH=1 ;;
        --latest)  LATEST=1 ;;
        --no-tkedit) TKEDIT=0 ;;
        --no-mac)  MAC=0 ;;
        --no-arm64) ARM=0 ;;
        --lsp)     shift; LSPDIR=$1 ;;
        --no-lsp)  LSP=0 ;;
        -h|--help) sed -n '2,42p' "$0"; exit 0 ;;
        *) echo "release: unknown argument '$1'" >&2; exit 2 ;;
    esac
    shift
done
die( ) { echo "release: FAILED -- $*" >&2; exit 1; }
note( ) { echo "release: $*"; }

[ -n "$NOTES" ] && [ -f "$NOTES" ] || die "--notes <file> is required: write them from the previous release's"
SHA=$(git rev-parse "${SHA:-HEAD}") || die "no such commit"
SHORT=${SHA:0:8}
WIN=toolchains/tiko-windows
LNX=toolchains/tiko-linux
TKWIN=toolchains/tkedit-windows
TKLNX=toolchains/tkedit-linux
OUT=build/.release/$SHORT
mkdir -p "$OUT"
LSPDIR=${LSPDIR:-../tiko-lsp/dist}
# Relative to this tree, as every use below spells it ("$ROOT/$LSPWIN", WSL's /mnt/c path).
case $LSPDIR in /*) LSPDIR=$(realpath --relative-to="$ROOT" "$LSPDIR") ;; esac
LSPWIN=$LSPDIR/tiko-lsp-windows-x86_64.zip
LSPLNX=$LSPDIR/tiko-lsp-linux-x86_64.tar.gz
MACH=${TIKO_MAC_HOST:-mac}
MSSH=${TIKO_MAC_SSH_OPTS:-}
# THE MAC'S TREE, whose toolchains/ holds tiko-macos and tkedit-macos: TIKO_MAC_ROOT, default
# ~/dev/tiko-lang, written into the Mac's scripts as given (a ~ expands there).
MACROOT=${TIKO_MAC_ROOT:-"~/dev/tiko-lang"}
# A REMOTE STEP IS A FILE, run by a login zsh: a non-login ssh shell has no Homebrew on PATH,
# and variables in an inline ssh command expand on the wrong side (build/aapcslane.sh).
on_mac( ) {
    scp -q -o BatchMode=yes $MSSH "$1" "$MACH:tkm/$(basename "$1")" || return 1
    ssh -o BatchMode=yes $MSSH "$MACH" zsh -l "tkm/$(basename "$1")" < /dev/null
}
# THE linux-arm64 LANE runs in the Lima VM on the Mac (docs/tiko-linux-arm64 L5): TIKO_ARM_VM
# (default tk22, Ubuntu 22.04 arm64 -- the glibc 2.35 floor), its packaged tree at TIKO_ARM_ROOT
# (default /home/pc.guest/tiko-lang) and tiko-lsp at TIKO_ARM_LSP (/home/pc.guest/tiko-lsp).
# A step is a bash file run inside the VM, handed the Mac's ~/tkm -- which the VM mounts at the
# same path and writes through -- by a one-line wrapper the Mac's login zsh runs (limactl is
# Homebrew's).
ARMVM=${TIKO_ARM_VM:-tk22}
ARMROOT=${TIKO_ARM_ROOT:-/home/pc.guest/tiko-lang}
ARMLSP=${TIKO_ARM_LSP:-/home/pc.guest/tiko-lsp}
on_vm( ) {
    scp -q -o BatchMode=yes $MSSH "$1" "$MACH:tkm/$(basename "$1")" || return 1
    printf 'limactl shell %s -- bash "$HOME/tkm/%s" "$HOME/tkm"\n' "$ARMVM" "$(basename "$1")" > "$1.mac"
    on_mac "$1.mac"
}

# 1. both hosts packaged at this commit
for t in "$WIN" "$LNX"; do
    [ -f "$t/MANIFEST.txt" ] || die "$t has no MANIFEST.txt -- run build/package.sh --verify for it"
    grep -q "$SHORT" "$t/MANIFEST.txt" || die "$t/MANIFEST.txt does not name $SHORT -- repackage it at this commit"
    grep -q " FAIL" "$t/MANIFEST.txt" && die "$t/MANIFEST.txt records a FAIL -- read its verification section"
done
note "both MANIFESTs name $SHORT"
if [ "$MAC" = "1" ]; then
    cat > "$OUT/mac-check.sh" <<EOF
cd $MACROOT/toolchains/tiko-macos || exit 2
grep -q "$SHORT" MANIFEST.txt || exit 3
grep -q " FAIL" MANIFEST.txt && exit 4
if [ "$TKEDIT" = "1" ]; then
[ -f ../tkedit-macos/tkEdit.app/Contents/MacOS/tkedit ] || exit 5
grep -q "^tkedit  *\.\./tkedit-macos" MANIFEST.txt || exit 6
fi
[ "$LSP" = "1" ] || exit 0
[ -f ~/dev/tiko-lsp/dist/tiko-lsp-macos-arm64.tar.gz ] || exit 7
exit 0
EOF
    on_mac "$OUT/mac-check.sh"; rc=$?
    [ $rc = 0 ] || die "the Mac's toolchains/tiko-macos: none (2), MANIFEST not at $SHORT (3), a FAIL in it (4), no tkedit-macos/tkEdit.app (5), no tkedit line (6; or pass --no-tkedit) or no ~/dev/tiko-lsp/dist/tiko-lsp-macos-arm64.tar.gz (7; build it there with release/build-macos.sh, or pass --no-lsp) -- rc $rc"
    note "the Mac's MANIFEST names $SHORT"
fi
if [ "$ARM" = "1" ]; then
    cat > "$OUT/arm-check.sh" <<EOF
cd $ARMROOT/toolchains/tiko-linux-arm64 || exit 2
grep -q "$SHORT" MANIFEST.txt || exit 3
grep -q " FAIL" MANIFEST.txt && exit 4
if [ "$TKEDIT" = "1" ]; then
[ -f ../tkedit-linux-arm64/tkedit ] || exit 5
grep -q "^tkedit  *\.\./tkedit-linux-arm64" MANIFEST.txt || exit 6
fi
[ "$LSP" = "1" ] || exit 0
[ -f $ARMLSP/dist/tiko-lsp-linux-arm64.tar.gz ] || exit 7
exit 0
EOF
    on_vm "$OUT/arm-check.sh"; rc=$?
    [ $rc = 0 ] || die "$ARMVM's toolchains/tiko-linux-arm64: none (2), MANIFEST not at $SHORT (3), a FAIL in it (4), no tkedit-linux-arm64/tkedit (5), no tkedit line (6; or pass --no-tkedit) or no $ARMLSP/dist/tiko-lsp-linux-arm64.tar.gz (7; build it there with release/build-linux.sh, or pass --no-lsp) -- rc $rc"
    note "$ARMVM's linux-arm64 MANIFEST names $SHORT"
fi
if [ "$TKEDIT" = "1" ]; then
    [ -f "$TKWIN/tkedit.exe" ] || die "no $TKWIN/tkedit.exe -- package.sh packages it (or pass --no-tkedit)"
    [ -f "$TKLNX/tkedit" ] || die "no $TKLNX/tkedit -- package.sh under WSL packages it (or pass --no-tkedit)"
    grep -q "^tkedit  *\.\./tkedit-windows" "$WIN/MANIFEST.txt" || die "$WIN/MANIFEST.txt has no tkedit line: $TKWIN is not from this packaging"
    grep -q "^tkedit  *\.\./tkedit-linux" "$LNX/MANIFEST.txt" || die "$LNX/MANIFEST.txt has no tkedit line: $TKLNX is not from this packaging"
fi
if [ "$LSP" = "1" ]; then
    [ -f "$LSPWIN" ] || die "no $LSPWIN -- build it in tiko-lsp with release/build-windows.sh (or pass --lsp <dir>, or --no-lsp)"
    [ -f "$LSPLNX" ] || die "no $LSPLNX -- build it in tiko-lsp with release/build-linux.sh under WSL (or pass --lsp <dir>, or --no-lsp)"
    note "tiko-lsp from $LSPDIR"
fi

# 2. the Windows zip
ZIP=$OUT/tiko-windows-x86_64-$SHORT.zip
BSDTAR=/c/Windows/System32/tar.exe
[ -x "$BSDTAR" ] || die "no $BSDTAR (bsdtar) -- the GNU tar in Git Bash cannot write a zip"
rm -f "$ZIP"
# EVERY ARCHIVE HOLDS ONE FOLDER, tiko-lang/, whatever the OS (author 2026-10-29), with the one-file
# tkedit beside the compiler: tiko-lang/tkedit.exe next to tiko.exe. System32's bsdtar has no -s to
# rename, so tiko-windows is staged under that name in $OUT and archived from there.
rm -rf "$OUT/stage" && mkdir -p "$OUT/stage" && cp -r "$WIN" "$OUT/stage/tiko-lang" || die "staging tiko-lang"
if [ "$TKEDIT" = "1" ]; then
    cp -f "$TKWIN/tkedit.exe" "$OUT/stage/tiko-lang/" || die "staging tkedit.exe"
fi
if [ "$LSP" = "1" ]; then
    rm -rf "$OUT/lsp-win" && mkdir -p "$OUT/lsp-win" || die "staging tiko-lsp"
    ( cd "$OUT/lsp-win" && "$BSDTAR" -xf "$ROOT/$LSPWIN" ) || die "$LSPWIN does not extract"
    cp -f "$OUT/lsp-win/tiko-lsp.exe" "$OUT/stage/tiko-lang/" || die "staging tiko-lsp.exe"
    cp -f "$OUT/lsp-win/LICENSE" "$OUT/stage/tiko-lang/licences/LICENSE-tiko-lsp" || die "staging tiko-lsp's licence"
    rm -rf "$OUT/lsp-win"
fi
( cd "$OUT/stage" && "$BSDTAR" -a -cf "$ROOT/$ZIP" tiko-lang ) || die "zip failed"
rm -rf "$OUT/stage"
file "$ZIP" | grep -q "Zip archive" || die "$ZIP is not a zip archive"
note "zip $(du -h "$ZIP" | cut -f1)"

# 3. the Linux tar.gz, under WSL
TGZ=$OUT/tiko-linux-x86_64-$SHORT.tar.gz
WSLSH=$OUT/tar-linux.sh
TKDIRS=""
[ "$TKEDIT" = "1" ] && TKDIRS="tkedit"
LSPGZ=""
[ "$LSP" = "1" ] && LSPGZ="/mnt/c${ROOT#/c}/$LSPLNX"
cat > "$WSLSH" <<EOF
set -e
rm -rf ~/tkrel-$SHORT && mkdir -p ~/tkrel-$SHORT
cp -r "/mnt/c${ROOT#/c}/$LNX" ~/tkrel-$SHORT/tiko-lang
[ -z "$TKDIRS" ] || cp -a "/mnt/c${ROOT#/c}/$TKLNX/tkedit" ~/tkrel-$SHORT/tiko-lang/tkedit
if [ -n "$LSPGZ" ]; then
    mkdir -p ~/tkrel-$SHORT/lsp && tar -xzf "$LSPGZ" -C ~/tkrel-$SHORT/lsp
    cp ~/tkrel-$SHORT/lsp/tiko-lsp ~/tkrel-$SHORT/tiko-lang/bin/tiko-lsp
    cp ~/tkrel-$SHORT/lsp/LICENSE ~/tkrel-$SHORT/tiko-lang/licences/LICENSE-tiko-lsp
    rm -rf ~/tkrel-$SHORT/lsp
    # tiko-lsp links libtinfo too: drop its symbol versions, as package.sh does for tiko and tkedit
    python3 "/mnt/c${ROOT#/c}/build/elfunversion.py" ~/tkrel-$SHORT/tiko-lang/bin/tiko-lsp libtinfo.so.6
fi
cd ~/tkrel-$SHORT
find tiko-lang -type f -exec chmod 644 {} +
find tiko-lang -type d -exec chmod 755 {} +
chmod 755 tiko-lang/bin/tiko
[ -z "$TKDIRS" ] || chmod 755 tiko-lang/tkedit
[ -z "$LSPGZ" ] || chmod 755 tiko-lang/bin/tiko-lsp
tar -czf "/mnt/c${ROOT#/c}/$TGZ" --owner=0 --group=0 tiko-lang
EOF
MSYS_NO_PATHCONV=1 wsl.exe -e sh "/mnt/c${ROOT#/c}/$WSLSH" || die "WSL tar failed"
[ -s "$TGZ" ] || die "no $TGZ"
note "tar.gz $(du -h "$TGZ" | cut -f1)"

# 3b. the macOS tar.gz, on the Mac
MTGZ=""
if [ "$MAC" = "1" ]; then
    MTGZ=$OUT/tiko-macos-arm64-$SHORT.tar.gz
    cat > "$OUT/tar-macos.sh" <<EOF
set -e
rm -rf ~/tkrel-$SHORT && mkdir -p ~/tkrel-$SHORT
cp -R $MACROOT/toolchains/tiko-macos ~/tkrel-$SHORT/tiko-lang
[ -z "$TKDIRS" ] || cp -R $MACROOT/toolchains/tkedit-macos/tkEdit.app ~/tkrel-$SHORT/tiko-lang/tkEdit.app
if [ "$LSP" = "1" ]; then
    mkdir -p ~/tkrel-$SHORT/lsp && tar -xzf ~/dev/tiko-lsp/dist/tiko-lsp-macos-arm64.tar.gz -C ~/tkrel-$SHORT/lsp
    cp ~/tkrel-$SHORT/lsp/tiko-lsp ~/tkrel-$SHORT/tiko-lang/bin/tiko-lsp
    cp ~/tkrel-$SHORT/lsp/LICENSE ~/tkrel-$SHORT/tiko-lang/licences/LICENSE-tiko-lsp
    rm -rf ~/tkrel-$SHORT/lsp
fi
cd ~/tkrel-$SHORT
xattr -cr tiko-lang
find tiko-lang -type f -exec chmod 644 {} +
find tiko-lang -type d -exec chmod 755 {} +
chmod 755 tiko-lang/bin/tiko
[ -z "$TKDIRS" ] || chmod 755 tiko-lang/tkEdit.app/Contents/MacOS/tkedit
[ "$LSP" = "1" ] && chmod 755 tiko-lang/bin/tiko-lsp
COPYFILE_DISABLE=1 tar --no-xattrs --no-mac-metadata --uid 0 --gid 0 -czf tiko-macos-arm64-$SHORT.tar.gz tiko-lang
EOF
    on_mac "$OUT/tar-macos.sh" || die "the Mac's tar failed"
    scp -q -o BatchMode=yes $MSSH "$MACH:tkrel-$SHORT/tiko-macos-arm64-$SHORT.tar.gz" "$MTGZ" || die "scp of the macOS archive"
    [ -s "$MTGZ" ] || die "no $MTGZ"
    note "macOS tar.gz $(du -h "$MTGZ" | cut -f1)"
fi

# 3c. the linux-arm64 tar.gz, in the Lima VM -- the Linux lane's recipe, on the VM's own disk
ATGZ=""
if [ "$ARM" = "1" ]; then
    ATGZ=$OUT/tiko-linux-arm64-$SHORT.tar.gz
    cat > "$OUT/tar-arm64.sh" <<EOF
set -e
rm -rf ~/tkrel-$SHORT && mkdir -p ~/tkrel-$SHORT
cp -r $ARMROOT/toolchains/tiko-linux-arm64 ~/tkrel-$SHORT/tiko-lang
[ -z "$TKDIRS" ] || cp -a $ARMROOT/toolchains/tkedit-linux-arm64/tkedit ~/tkrel-$SHORT/tiko-lang/tkedit
if [ "$LSP" = "1" ]; then
    mkdir -p ~/tkrel-$SHORT/lsp && tar -xzf $ARMLSP/dist/tiko-lsp-linux-arm64.tar.gz -C ~/tkrel-$SHORT/lsp
    cp ~/tkrel-$SHORT/lsp/tiko-lsp ~/tkrel-$SHORT/tiko-lang/bin/tiko-lsp
    cp ~/tkrel-$SHORT/lsp/LICENSE ~/tkrel-$SHORT/tiko-lang/licences/LICENSE-tiko-lsp
    rm -rf ~/tkrel-$SHORT/lsp
    python3 $ARMROOT/build/elfunversion.py ~/tkrel-$SHORT/tiko-lang/bin/tiko-lsp libtinfo.so.6
fi
cd ~/tkrel-$SHORT
find tiko-lang -type f -exec chmod 644 {} +
find tiko-lang -type d -exec chmod 755 {} +
chmod 755 tiko-lang/bin/tiko
[ -z "$TKDIRS" ] || chmod 755 tiko-lang/tkedit
[ "$LSP" != "1" ] || chmod 755 tiko-lang/bin/tiko-lsp
tar -czf "\$1/tiko-linux-arm64-$SHORT.tar.gz" --owner=0 --group=0 tiko-lang
EOF
    on_vm "$OUT/tar-arm64.sh" || die "$ARMVM's tar failed"
    scp -q -o BatchMode=yes $MSSH "$MACH:tkm/tiko-linux-arm64-$SHORT.tar.gz" "$ATGZ" || die "scp of the linux-arm64 archive"
    [ -s "$ATGZ" ] || die "no $ATGZ"
    note "linux-arm64 tar.gz $(du -h "$ATGZ" | cut -f1)"
fi

# 4. hashes, and the notes with them
( cd "$OUT" && sha256sum "$(basename "$ZIP")" "$(basename "$TGZ")" ${MTGZ:+"$(basename "$MTGZ")"} \
      ${ATGZ:+"$(basename "$ATGZ")"} > SHA256SUMS ) || die "sha256sum"
{ cat "$NOTES"; echo; echo "### SHA-256"; echo; echo '```text'; cat "$OUT/SHA256SUMS"; echo '```'; } > "$OUT/notes.md"
note "SHA256SUMS and notes.md written"

# 5. smoke tests: an empty directory, no TIKO_*
SMOKE=$OUT/smoke
rm -rf "$SMOKE" && mkdir -p "$SMOKE/win"
printf 'print "hello from tiko"\n' > "$SMOKE/hello.tiko"
( cd "$SMOKE/win" && "$BSDTAR" -xf "$ROOT/$ZIP" ) || die "zip does not extract"
got=$( cd "$SMOKE" && env -u TIKO_INCLUDE -u TIKO_LIBPATH -u TIKO_PKG \
       win/tiko-lang/tiko.exe hello.tiko -o hello.exe && ./hello.exe ) || die "Windows smoke: $got"
[ "$got" = "hello from tiko" ] || die "Windows smoke printed '$got'"
[ "$(ls -A "$SMOKE/win")" = "tiko-lang" ] || die "Windows smoke: the zip holds more than tiko-lang/: $(ls -A "$SMOKE/win" | tr '\n' ' ')"
if [ "$TKEDIT" = "1" ]; then
    [ -f "$SMOKE/win/tiko-lang/tkedit.exe" ] || die "Windows smoke: no tiko-lang/tkedit.exe beside tiko.exe"
fi
if [ "$LSP" = "1" ]; then
    lsp=$("$SMOKE/win/tiko-lang/tiko-lsp.exe" --version 2>&1) || die "Windows smoke: tiko-lsp.exe --version failed: $lsp"
    case "$lsp" in "tiko-lsp "*) note "smoke windows-x86_64: $lsp" ;; *) die "Windows smoke: tiko-lsp --version said '$lsp'" ;; esac
fi
note "smoke windows-x86_64: ok"
# A WSL distro set up from apt.llvm.org may have only clang-NN (Ubuntu 22.04: clang-18), and
# tiko looks for /usr/bin/clang, then clang on PATH -- as a user there would have to, the
# smoke then names one: TIKO_CLANG for the compile alone, said here, never otherwise.
lin_clang=$(MSYS_NO_PATHCONV=1 wsl.exe -e sh -c 'command -v clang > /dev/null || ls /usr/bin/clang-[0-9]* 2> /dev/null | sort -V | tail -1' | tr -d '\r')
[ -z "$lin_clang" ] || note "smoke linux-x86_64: WSL has no bare clang -- the compile is given TIKO_CLANG=$lin_clang"
cat > "$OUT/smoke-linux.sh" <<EOF
set -e
rm -rf ~/tksmoke-$SHORT && mkdir -p ~/tksmoke-$SHORT && cd ~/tksmoke-$SHORT
tar -xzf "/mnt/c${ROOT#/c}/$TGZ"
test "\$(ls -A)" = "tiko-lang"
[ -z "$TKDIRS" ] || test -x tiko-lang/tkedit
[ -z "$LSPGZ" ] || tiko-lang/bin/tiko-lsp --version 2>&1 | grep -q '^tiko-lsp '
printf 'print "hello from tiko"\n' > hello.tiko
env -u TIKO_INCLUDE -u TIKO_LIBPATH -u TIKO_PKG ${lin_clang:+TIKO_CLANG=$lin_clang} tiko-lang/bin/tiko hello.tiko -o hello
./hello
EOF
got=$(MSYS_NO_PATHCONV=1 wsl.exe -e sh "/mnt/c${ROOT#/c}/$OUT/smoke-linux.sh" | tr -d '\r') || die "Linux smoke: $got"
[ "$got" = "hello from tiko" ] || die "Linux smoke printed '$got'"
note "smoke linux-x86_64: ok"
# AS A NEW USER WOULD: a fresh HOME, PATH the system's alone, no TKO_*. The compiler finds
# Homebrew's clang by its own default (docs/tiko-macos D6), not through PATH.
if [ "$MAC" = "1" ]; then
    cat > "$OUT/smoke-macos.sh" <<EOF
set -e
rm -rf ~/tksmoke-$SHORT && mkdir -p ~/tksmoke-$SHORT/home && cd ~/tksmoke-$SHORT
tar -xzf ~/tkrel-$SHORT/tiko-macos-arm64-$SHORT.tar.gz
test "\$(ls -A | grep -v '^home\$')" = "tiko-lang"
[ -z "$TKDIRS" ] || { test -x tiko-lang/tkEdit.app/Contents/MacOS/tkedit && codesign --verify --deep --strict tiko-lang/tkEdit.app; }
[ "$LSP" != "1" ] || { codesign --verify --strict tiko-lang/bin/tiko-lsp && tiko-lang/bin/tiko-lsp --version 2>&1 | grep -q '^tiko-lsp '; }
echo 'print "hello from tiko"' > hello.tiko
env -i HOME=\$PWD/home PATH=/usr/bin:/bin tiko-lang/bin/tiko hello.tiko -o hello
./hello
EOF
    got=$(on_mac "$OUT/smoke-macos.sh") || die "macOS smoke: $got"
    [ "$got" = "hello from tiko" ] || die "macOS smoke printed '$got'"
    note "smoke macos-arm64: ok"
fi
# linux-arm64 AS A NEW USER WOULD, in the VM: a fresh HOME, the system's PATH, no TKO_*. Ubuntu
# 22.04 there has apt.llvm.org's clang-NN and no bare clang, so the compile is given TIKO_CLANG,
# as the WSL smoke is -- said here, never otherwise.
if [ "$ARM" = "1" ]; then
    cat > "$OUT/smoke-arm64.sh" <<EOF
set -e
rm -rf ~/tksmoke-$SHORT && mkdir -p ~/tksmoke-$SHORT/home && cd ~/tksmoke-$SHORT
tar -xzf "\$1/tiko-linux-arm64-$SHORT.tar.gz"
test "\$(ls -A | grep -v '^home\$')" = "tiko-lang"
[ -z "$TKDIRS" ] || test -x tiko-lang/tkedit
[ "$LSP" != "1" ] || tiko-lang/bin/tiko-lsp --version 2>&1 | grep -q '^tiko-lsp '
echo 'print "hello from tiko"' > hello.tiko
cc=""; command -v clang > /dev/null || cc=\$(ls /usr/bin/clang-[0-9]* 2> /dev/null | sort -V | tail -1)
env -i HOME=\$PWD/home PATH=/usr/bin:/bin \${cc:+TIKO_CLANG=\$cc} tiko-lang/bin/tiko hello.tiko -o hello
./hello
EOF
    got=$(on_vm "$OUT/smoke-arm64.sh") || die "linux-arm64 smoke: $got"
    [ "$got" = "hello from tiko" ] || die "linux-arm64 smoke printed '$got'"
    note "smoke linux-arm64: ok"
fi

# 6. what changed against the previous release
if [ -n "$PREV" ]; then
    # ARCHIVE BY ARCHIVE, paired by host: with four, 'the first *.tar.gz' was linux-arm64's in
    # one folder and linux-x86_64's in the other.
    for a in windows-x86_64.zip linux-x86_64.tar.gz macos-arm64.tar.gz linux-arm64.tar.gz; do
        h=${a%%.*}; kind=${a#*.}
        n=$(ls "$OUT"/tiko-$h-*."$kind" 2>/dev/null | head -1)
        [ -n "$n" ] || continue
        p=$(ls "$PREV"/tiko-$h-*."$kind" 2>/dev/null | head -1)
        [ -n "$p" ] || { note "$h: no previous archive in $PREV -- new"; continue; }
        "$BSDTAR" -tf "$p" | sed 's|^[^/]*/||' | sort > "$OUT/prev.$h.txt"
        "$BSDTAR" -tf "$n" | sed 's|^[^/]*/||' | sort > "$OUT/new.$h.txt"
        note "$h: +$(comm -13 "$OUT/prev.$h.txt" "$OUT/new.$h.txt" | wc -l) files, -$(comm -23 "$OUT/prev.$h.txt" "$OUT/new.$h.txt" | wc -l) files (lists in $OUT)"
    done
fi

# 7. the editor's copy
if [ -n "$EDITOR" ]; then
    MSYS_NO_PATHCONV=1 robocopy "$(cygpath -w "$ROOT/$WIN")" "$(cygpath -w "$EDITOR")" /MIR /NFL /NDL /NJH /NJS /NP > /dev/null
    [ $? -lt 8 ] || die "robocopy into $EDITOR failed"
    note "editor toolchain mirrored into $EDITOR"
fi

# 8. publish -- only when asked
if [ "$PUBLISH" = "1" ]; then
    command -v gh > /dev/null 2>&1 || die "no gh"
    flags=""; [ "$LATEST" = "1" ] && flags="--latest"
    gh release create "toolchain-$SHORT" --target "$SHA" --title "toolchain-$SHORT" \
        --notes-file "$OUT/notes.md" $flags "$ZIP" "$TGZ" ${MTGZ:+"$MTGZ"} ${ATGZ:+"$ATGZ"} || die "gh release create"
    note "published toolchain-$SHORT"
else
    note "not published (pass --publish); everything is in $OUT"
fi
