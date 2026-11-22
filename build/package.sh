#!/bin/sh
# package.sh -- assemble a distributable tiko toolchain under toolchains/.
#
#   build/package.sh [options]
#
#   build/package.sh                        Release, the current host, everything
#   build/package.sh --config Debug         a debug toolchain, for chasing a bug
#   build/package.sh --no-build             package what is already built
#   build/package.sh --no-inc               skip the ~100 MB header copy
#   build/package.sh --clean                empty the output directory first
#   build/package.sh --verify               compile and RUN a program per target
#   build/package.sh --third-party-inc DIR  third-party bindings (default: the seed's inc/)
#   build/package.sh --out DIR              somewhere other than toolchains/
#   build/package.sh --no-tkedit            leave the editor out (see "the editor")
#
# The output is toolchains/tiko-windows or toolchains/tiko-linux: what an end user
# unpacks, as opposed to bin/tiko, which is what build/build.sh produces for
# developing the compiler. Beside it, toolchains/tkedit-<host>: the editor, ready to
# run, which a release archive puts beside the compiler in tiko-lang/ (build/release.sh).
#
# ---------------------------------------------------------------- what it is NOT
#
# THIS DOES NOT PRODUCE A SELF-CONTAINED TOOLCHAIN, and the manifest it writes says
# so. One thing stays external, and one is optional:
#
#   clang    src/codegen/toolchain.tiko runs clang for BOTH steps -- the .ll to .o
#            compile and the link. It is found at C:\Program Files\LLVM\bin, or
#            wherever TIKO_CLANG points. Bundling LLVM is a gigabyte and a separate
#            decision, so a packaged toolchain depends on an installed one.
#
#   win64    -target win64, the MinGW ABI, is NOT PACKAGED (the author's order,
#            2026-10-10; decision Q2): no lib/win64, no MinGW runtime. The compiler
#            still accepts the target -- build tiko-rt for it (lib/rt/build/build.sh
#            Release win64) and link with a MinGW-w64 on PATH. windows-x86_64, the
#            default, and linux-x86_64 need nothing of the kind.
#
# Neither is a packaging bug. Both are written into MANIFEST.txt so that a
# toolchain cannot be passed on with them invisible.
#
# ------------------------------------------------------------------- NO fbc
#
# Since 2026-10-10 nothing here reads fbc or fbc-modern. The compiler is built by the
# pinned seed (seed/seed.lock), the runtime and the graphics library by that compiler,
# the headers are the tree's inc/, the import libraries lib/implib/, and FreeBASIC's
# notices licences/. The third-party bindings come from the seed's inc/ -- tiko's own
# last release -- until the author decides where they live.
#
# --------------------------------------------------------------- cross-packaging
#
# A host packages ITSELF. build/build.sh compiles the compiler for the machine it
# runs on, so tiko-linux comes from running this under Linux or WSL and
# tiko-windows from running it on Windows. There is no --host flag: it would only
# ever produce a tree with a foreign binary in it.

set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)

CFG=Release
DO_BUILD=1
DO_INC=1
DO_CLEAN=0
DO_VERIFY=0
DO_TKEDIT=1
T0=$(date +%s)
TPINC=${TIKO_THIRDPARTY_INC:-}
OUT=

die( ) { echo "package: $*" >&2; exit 1; }
note( ) { echo "package: [$(( $(date +%s) - T0 ))s] $*"; }
# THE MANIFEST IS WRITTEN WITH printf, NOT echo. dash -- Linux's /bin/sh -- expands
# backslash escapes in echo's arguments, so the Windows clang path came out as
# 'C:\Program Files\LLVMin': its '\b' was a backspace. Git Bash's sh does not, which
# is why the Windows manifest never showed it.
say( ) { printf '%s\n' "$*"; }

# LIBTINFO WITHOUT ITS SYMBOL VERSIONS (2026-11-04). tiko's runtime links libtinfo, and linked
# here -- Ubuntu, whose libtinfo versions every symbol -- an executable requires
# NCURSES6_TINFO_5.0.19991023 of it. Fedora's and Arch's libtinfo carry no versions, so glibc
# printed 'libtinfo.so.6: no version information available (required by .../tiko)' on every
# start there. build/elfunversion.py drops that requirement; the unversioned references bind to
# the default version where libtinfo is versioned, so nothing changes on Debian or Ubuntu.
unversion_tinfo( ) {
    command -v python3 >/dev/null 2>&1 || return 1
    python3 "$ROOT/build/elfunversion.py" "$1" libtinfo.so.6 >/dev/null
}

usage( ) {
    sed -n '2,53p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

while [ $# -gt 0 ]; do
    case $1 in
        --config)    CFG=$2;      shift 2 ;;
        --mingw-lib) die "--mingw-lib is gone: -target win64 is not packaged since 2026-10-10" ;;
        --third-party-inc) TPINC=$2; shift 2 ;;
        --out)       OUT=$2;      shift 2 ;;
        --no-build)  DO_BUILD=0;  shift ;;
        --no-inc)    DO_INC=0;    shift ;;
        --clean)     DO_CLEAN=1;  shift ;;
        --verify)    DO_VERIFY=1; shift ;;
        --no-tkedit) DO_TKEDIT=0; shift ;;
        # Both retired 2026-10-10, refused by name rather than as 'unknown'.
        --fbc-tree)  die "--fbc-tree is gone: nothing reads fbc now (--third-party-inc for bindings)" ;;
        --implibs)   die "--implibs is gone: the import libraries are built from lib/implib/ on every run" ;;
        -h|--help)   usage ;;
        *)           die "unknown option '$1' (try --help)" ;;
    esac
done

case $CFG in
    Debug|Release|RelWithDebInfo|MinSizeRel) ;;
    *) die "unknown configuration '$CFG' (Debug|Release|RelWithDebInfo|MinSizeRel)" ;;
esac

# ------------------------------------------------------------------- the host
#
# The target list is the host's rather than a choice.
#
# WIN32 IS GONE, and it took packaging with it. D14 made x86-64 the only
# architecture -- -m32 is now an error and TargetFromName knows no "win32" -- so
# lib/rt/build/common.sh dropped it from RT_TARGETS, and the guard below then
# died with "no runtime for win32" on every single run. Nothing could be
# packaged on Windows at all, which is also why no libtkogfx ever reached a
# toolchain: the script never got as far as copying one.
#
# WINDOWS-X86_64 IS THE DEFAULT and is listed first. It is the only target lib/gfx
# builds, so it is the only one where a SCREEN program links; and it is the ONE
# target that needs nothing behind it. That is measured, 2026-09-06: a program
# built for windows-x86_64 against lib/windows-x86_64 alone -- no fbc directory, none to
# have -- linked and ran. tiko-rt's MSVC archive carries no MinGW imports
# (build/abidelta.sh, and gatemsvc.sh at 3,922,073 assertions). win64 needed fbc's
# libfb behind it until decision 0015 (D15); now it needs only fbc's CRT behind it.
#
# win64, the MinGW ABI, is not packaged -- see 'what it is NOT' above.

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        HOST=windows; EXT=".exe"; BINSUB=""
        TARGETS="windows-x86_64"
        # The compiler's own default on this host -- HostTarget( ), src/types/type.tiko.
        DEFTARGET=windows-x86_64
        CLANG_DEFAULT='C:\Program Files\LLVM\bin\clang.exe'
        ;;
    Linux)
        HOST=linux; EXT=""; BINSUB="bin/"
        TARGETS="linux-x86_64"
        DEFTARGET=linux-x86_64
        # The compiler's own default on Linux -- see src/codegen/toolchain.tiko.
        CLANG_DEFAULT=/usr/bin/clang
        # aarch64 IS ITS OWN PACKAGE, tiko-linux-arm64 (docs/tiko-linux-arm64 L5): the same
        # Linux recipe, its own target, toolchain directory and [linux-arm64.<n>] vendor tables.
        if [ "$(uname -m)" = aarch64 ]; then
            HOST=linux-arm64; TARGETS="linux-arm64"; DEFTARGET=linux-arm64
        fi
        ;;
    Darwin)
        # Apple Silicon (docs/tiko-macos D1): the compiler under bin/, as on Linux.
        HOST=macos; EXT=""; BINSUB="bin/"
        TARGETS="macos-arm64"
        DEFTARGET=macos-arm64
        # Homebrew's LLVM (docs/tiko-macos D6) -- see src/codegen/toolchain.tiko.
        CLANG_DEFAULT=/opt/homebrew/opt/llvm/bin/clang
        ;;
    *)  die "unsupported host '$(uname -s)' -- this packages Windows, Linux or macOS" ;;
esac
# THE OS AND ARCHITECTURE beside HOST, the package's name: linux-arm64 is a Linux host for
# every OS question below (libtinfo, the X11 display, the MANIFEST's graphics), arm64 for names.
case $HOST in
    linux-arm64) HOSTOS=linux; HOSTARCH=arm64 ;;
    macos)       HOSTOS=macos; HOSTARCH=arm64 ;;
    *)           HOSTOS=$HOST; HOSTARCH=x86_64 ;;
esac

# WHICH TARGETS HAVE A GRAPHICS LIBRARY. windows-x86_64, where tiko emits the
# Microsoft ABI and there is no MSVC libfbgfx anywhere to fall back on; and
# linux-x86_64 since the X11 driver landed (docs/graphics RFC-0012 L2), which loads
# libX11 at run time, so the package gains no X11 dependency; and macos-arm64 since
# its Cocoa driver (RFC-0012 M1), which reaches AppKit through the Objective-C
# runtime and needs fbrt0's tko_darwin_entry -- built by this same package.
# Kept as a list rather than a test so that the day another appears, this is the
# line that changes.
GFX_TARGETS="windows-x86_64 linux-x86_64 macos-arm64 linux-arm64"

gfx_has_target( ) {
    for __g in $GFX_TARGETS; do [ "$1" = "$__g" ] && return 0; done
    return 1
}

[ -n "$OUT" ] || OUT="$ROOT/toolchains/tiko-$HOST"

MINGW_STATE="not applicable on this host"
[ "$HOST" = "windows" ] && MINGW_STATE="-target win64 (MinGW) is not packaged"

# THE THIRD-PARTY BINDINGS' SOURCE: the one given, else the seed's inc/ -- the pinned
# seed's (seed/cache) or, failing that, a locally packaged toolchain's, the same search
# build/build.sh makes for its compiler. tiko-lang's own inc/ goes over them below.
if [ -z "$TPINC" ]; then
    . "$ROOT/build/defaultseed.sh"
    if [ "$HOST" = "windows" ]; then _sw=1; else _sw=0; fi
    if _seed=$( default_seed "$ROOT" "$_sw" ); then
        _sd=$( dirname "$_seed" ); [ "$HOST" = "windows" ] || _sd=$( dirname "$_sd" )
        [ -d "$_sd/inc" ] && TPINC="$_sd/inc"
    fi
fi

note "host $HOST, configuration $CFG, targets $TARGETS"
note "output $OUT"

# ------------------------------------------------------------------- the parts
#
# Everything is built BEFORE anything is copied, so a build failure leaves the
# previous toolchain intact rather than half-replaced.

if [ "$DO_BUILD" = "1" ]; then
    # THE COMPILER FIRST, THEN THE REST WITH IT. The runtime is built by tiko since
    # 2026-10-10 -- by THIS compiler, bin/tiko, not by the seed that built it: a seed
    # may predate a fix the runtime's own source needs (seed-1 does: R1-R3). So the
    # compiler builds alone, and the runtimes and the graphics library then build
    # concurrently, each into its own obj/<target>/<config> tree.
    mkdir -p "$ROOT/lib/rt/obj" "$ROOT/lib/gfx/obj"
    note "building the compiler [$CFG]"
    # --no-dll: no editor DLL -- tkedit links its scanner in (build.sh --lib, below).
    if ! sh "$ROOT/build/build.sh" "$CFG" --no-dll >"$ROOT/lib/rt/obj/package-tiko.log" 2>&1; then
        tail -20 "$ROOT/lib/rt/obj/package-tiko.log" >&2
        die "the compiler build failed -- lib/rt/obj/package-tiko.log"
    fi
    note "compiler built"
    TKORT_TIKO="$ROOT/bin/tiko$EXT"; export TKORT_TIKO
    _pids_rt=""
    for t in $TARGETS; do
        note "building the runtime [$CFG $t]"
        sh "$ROOT/lib/rt/build/build.sh" "$CFG" "$t" >"$ROOT/lib/rt/obj/package-$t.log" 2>&1 &
        _pids_rt="$_pids_rt $t:$!"
    done
    # The graphics library too -- see the note below on why its failure is not fatal.
    _pids_gfx=""
    for t in $TARGETS; do
        gfx_has_target "$t" || continue
        note "building the graphics library [$CFG $t]"
        sh "$ROOT/lib/gfx/build/build.sh" "$CFG" "$t" >"$ROOT/lib/gfx/obj/package-$t.log" 2>&1 &
        _pids_gfx="$_pids_gfx $t:$!"
    done
    for _tp in $_pids_rt; do
        if ! wait "${_tp#*:}"; then
            tail -20 "$ROOT/lib/rt/obj/package-${_tp%%:*}.log" >&2
            die "the runtime build failed for ${_tp%%:*} -- lib/rt/obj/package-${_tp%%:*}.log"
        fi
        note "runtime built [${_tp%%:*}]"
    done

    # THE GRAPHICS LIBRARY IS BUILT, NOT SCAVENGED. It used to be neither: the
    # copy below looked for an archive nobody here had built, so whether a
    # toolchain shipped graphics came down to whether someone had happened to
    # run lib/gfx/build/build.sh by hand first, and to which configuration.
    #
    # A FAILURE HERE IS NOTED, NOT FATAL, and that is deliberate: aborting the whole
    # package because the graphics library could not build would take the compiler
    # and runtime down with it. The manifest records the reason instead, so the
    # absence is never silent.
    # obj/ IS GITIGNORED, so a fresh clone or worktree has none -- the mkdir above makes
    # it, or the redirect failed before build.sh ran, reporting a build failure that never
    # happened and packaging whatever stale archive was lying about.
    for _tp in $_pids_gfx; do
        _gl="$ROOT/lib/gfx/obj/package-${_tp%%:*}.log"
        if wait "${_tp#*:}"; then
            note "graphics library built [${_tp%%:*}]"
        else
            GFX_FAIL=$( grep -m1 -iE 'error|die|no ' "$_gl" | cut -c1-120 )
            [ -n "$GFX_FAIL" ] || GFX_FAIL="see lib/gfx/obj/package-${_tp%%:*}.log"
            note "WARNING: graphics build failed for ${_tp%%:*} -- $GFX_FAIL"
        fi
    done
else
    note "--no-build: packaging what is already built"
    # WHAT bin/ HOLDS IS WHAT build.sh LAST STAMPED, and a newer timestamp cannot tell a
    # Debug binary from a Release one -- '--no-build' would have shipped a Debug exe in a
    # toolchain whose MANIFEST says Release.
    _stamp=$( cat "$ROOT/build/obj/.build-stamp" 2>/dev/null )
    [ -n "$_stamp" ] || die "--no-build: bin/ carries no build stamp -- run build/build.sh $CFG"
    [ "${_stamp%%|*}" = "$CFG" ] || die "--no-build: bin/ holds a ${_stamp%%|*} build, not $CFG -- run build/build.sh $CFG"
fi

TIKO="$ROOT/bin/tiko$EXT"
[ -f "$TIKO" ] || die "no compiler at $TIKO -- run build/build.sh $CFG"

for t in $TARGETS; do
    [ -f "$ROOT/lib/rt/lib/$t/libfb.a" ] || \
        die "no runtime for $t -- run lib/rt/build/build.sh $CFG $t"
done

# ----------------------------------------------------------------- the assembly

if [ "$DO_CLEAN" = "1" ] && [ -d "$OUT" ]; then
    note "cleaning $OUT"
    # Everything: the per-host toolchain directories hold build products only, and no
    # README is kept or written there.
    find "$OUT" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
fi

mkdir -p "$OUT"
[ -z "$BINSUB" ] || mkdir -p "$OUT/$BINSUB"

# THE EXAMPLES: the tree's examples/, shipped whole as pkg/ is (the author's order, 2026-10-16,
# replacing 2026-10-10's "no examples/ in a toolchain"). A toolchain's examples/ is this copy
# and nothing else -- whatever was there before, such as the 2,098 fbx examples once placed in
# toolchains/tiko-windows by hand, is removed first -- and a program built inside the tree's
# copy leaves nothing behind in the package: no binary, no library beside it, and no Linux
# executable, which is the one file there without an extension.
rm -rf "$OUT/examples"
# Only what the tree TRACKS, when it is a git checkout: a working tree also holds ignored build
# products and helper folders -- examples/tkControls/linux-lib's Linux .so symlinks among them,
# which Git Bash cannot recreate, so a whole-tree cp died there (set -e) and left examples/ half
# copied. A clean worktree and the main tree now package the same examples/.
if ( cd "$ROOT" && git rev-parse --is-inside-work-tree >/dev/null 2>&1 ); then
    mkdir -p "$OUT/examples"
    ( cd "$ROOT" && git -c core.quotePath=false ls-files -z -- examples | tar --null -T - -cf - ) | ( cd "$OUT" && tar -xf - ) \
        || die "copying the tracked examples/ failed"
else
    cp -r "$ROOT/examples" "$OUT/examples"
fi
find "$OUT/examples" -type f \( -name '*.exe' -o -name '*.dll' -o -name '*.so' -o -name '*.o' \
    -o -name '*.pdb' -o -name '*.a' -o ! -name '*.*' \) -delete
# ...but a DLL the tree TRACKS is part of an example, not a build product: the WebView2 examples
# do not start without WebView2Loader.dll beside them, and nothing builds it. Put those back.
( cd "$ROOT" && git -c core.quotePath=false ls-files -- 'examples/*.dll' 2>/dev/null ) |
while IFS= read -r f; do
    mkdir -p "$OUT/$( dirname "$f" )"
    cp "$ROOT/$f" "$OUT/$f"
done
[ -f "$OUT/examples/SDL3/renderer/01-clear/clear.tiko" ] || die "packaged examples/ has no SDL3/"
note "examples -> examples/ ($( ls "$OUT/examples" | tr '\n' ' '))"

note "compiler -> ${BINSUB}tiko$EXT"
cp -f "$TIKO" "$OUT/${BINSUB}tiko$EXT"
[ "$HOSTOS" != "linux" ] || unversion_tinfo "$OUT/${BINSUB}tiko" || \
    die "could not drop libtinfo's symbol versions from ${BINSUB}tiko (python3 and build/elfunversion.py)"

# The headers. The compiler finds these itself: AppendDefaultIncludeDir looks at
# <exe-dir>/inc and then <exe-dir>/../inc, which is exactly why the Windows binary
# sits at the root and the Linux one under bin/ -- both resolve to ./inc.
#
# TWO LAYERS, assembled in a scratch directory and then swapped in, because the
# first layer's source may be this very directory (a seed found as
# toolchains/tiko-<host>, which is where this writes):
#
#   1. the third-party bindings -- SDL, GTK, AfxNova and the rest tiko-lang does not
#      carry -- from --third-party-inc, else the seed's inc/. NOT fbc's: since
#      2026-10-10 they come from tiko's own last release.
#   2. tiko-lang's OWN HEADERS over them (phase H): crt/, win/, windows.bi and the rest
#      of FreeBASIC's set are the tree's inc/, the one copy (fb/ and containers.bi are the
#      std modules in pkg/ since 2026-10-10, and inc-exclude.txt keeps the seed's out) --
#      inc/PROVENANCE.md says where each came from.
#
# AN EMPTY inc/ IS REFUSED. tiko-linux once shipped one -- copied from fbc-modern-linux's
# empty inc/ rather than its include/freebasic -- and --verify still said PASS, because
# its program then included no bundled header. It does now.
if [ "$DO_INC" = "1" ]; then
    _newinc="$OUT/.inc.new"
    rm -rf "$_newinc"; mkdir -p "$_newinc"
    if [ -n "$TPINC" ] && [ -d "$TPINC" ]; then
        note "headers -> inc/  third-party bindings from $TPINC"
        cp -r "$TPINC/." "$_newinc/"
        INC_STATE="inc/ at this commit, over the third-party bindings in $TPINC"
    else
        note "WARNING: no third-party bindings -- no --third-party-inc and no seed inc/"
        INC_STATE="inc/ at this commit ONLY -- no third-party bindings (no --third-party-inc, no seed)"
    fi
    # fbx IS NOT SHIPPED (ADR 0017 §20): its successor is the package pkg/sys (sys/win). Kept, it
    # would also be a package named fbx that a '-i <inc>' root offers '#import "fbx/..."'.
    rm -rf "$_newinc/fbx"
    note "headers -> inc/  tiko-lang's own over them: $(find "$ROOT/inc" -name '*.bi' | wc -l | tr -d ' ') files from inc/"
    cp -r "$ROOT/inc/." "$_newinc/"
    rm -f "$_newinc/.import-manifest.tsv"
    # THE EXCLUSIONS (build/inc-exclude.txt): top-level entries the toolchain does not ship --
    # third-party bindings tiko does not carry, by the author's list. A header that IS shipped
    # but includes an excluded one would fail at its first '#include' in a user's build, so
    # that is refused here rather than discovered there.
    # One entry per line, a path below inc/; a second word 'unreachable' exempts it from the
    # include check below (inc-exclude.txt says when that is true).
    _exf=$( grep -v '^[[:space:]]*#' "$ROOT/build/inc-exclude.txt" | tr -d '\r' | grep -v '^[[:space:]]*$' )
    _excl=$( printf '%s\n' "$_exf" | awk '{ print $1 }' )
    _chk=$( printf '%s\n' "$_exf" | awk '$2 != "unreachable" { print $1 }' )
    _nex=0
    for _e in $_excl; do
        if [ -e "$_newinc/$_e" ]; then rm -rf "$_newinc/$_e"; _nex=$(( _nex + 1 )); fi
    done
    _pat=$( printf '%s\n' $_chk | sed 's/[.]/\\./g' | paste -sd'|' - )
    _dang=$( grep -rIliE "^[[:space:]]*#[[:space:]]*include([[:space:]]+once)?[[:space:]]+\"($_pat)(\"|/)" "$_newinc" 2>/dev/null | head -5 | sed "s#^$_newinc/##" | tr '\n' ' ' )
    [ -z "$_dang" ] || { rm -rf "$_newinc"; die "shipped headers include excluded ones (build/inc-exclude.txt): $_dang"; }
    note "headers -> inc/  $_nex entries left out (build/inc-exclude.txt)"
    INC_STATE="$INC_STATE; $_nex entries left out by build/inc-exclude.txt"
    [ -n "$( ls -A "$_newinc" 2>/dev/null )" ] || { rm -rf "$_newinc"; die "packaged inc/ is EMPTY -- the compiler would find no headers at all"; }
    # include/ was fbc-modern-linux's header tree, copied whole beside inc/. The compiler
    # never looked in it (<exe-dir>/inc, <exe-dir>/../inc); it goes.
    rm -rf "$OUT/include"
    # EMPTIED, NOT REMOVED. The directory itself is sometimes held open -- a shell whose cwd
    # is inside it, an editor, a junction -- and 'rm -rf inc' then deleted every header and
    # failed on the directory, leaving the toolchain with NONE (2026-09-23, 09-24, 10-10).
    # Its contents can always go, so they do, and the new set moves in entry by entry.
    mkdir -p "$OUT/inc"
    find "$OUT/inc" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    for _e in "$_newinc"/* "$_newinc"/.[!.]*; do
        [ -e "$_e" ] && mv "$_e" "$OUT/inc/"
    done
    rmdir "$_newinc"
else
    note "--no-inc: headers not packaged"
    INC_STATE="not packaged (--no-inc)"
fi

# THE PACKAGE TREE (ADR 0017; RFC-0007 §5): pkg/, beside inc/, which '#import "std/..."'
# finds as <exe-dir>/pkg or <exe-dir>/../pkg -- the two layouts the binaries sit in. The
# copy is ASSERTED: a pkg/ that silently failed to ship would look like a user's typo in
# an import path.
rm -rf "$OUT/pkg"
cp -r "$ROOT/pkg" "$OUT/pkg"
[ -f "$OUT/pkg/std/tiko.toml" ] || die "packaged pkg/ has no std/tiko.toml -- '#import \"std/...\"' would find nothing"
[ -f "$OUT/pkg/std/strings/string.tiko" ] || die "packaged pkg/ has no std/strings"
[ -f "$OUT/pkg/sys/win/gui/CWindow.tiko" ] || die "packaged pkg/ has no sys/win/gui"
[ -f "$OUT/pkg/sys/posix/posix.ti" ] || die "packaged pkg/ has no sys/posix -- the std modules' POSIX code includes it"
note "packages -> pkg/ ($( ls "$OUT/pkg" | tr '\n' ' '))"

# THE VENDOR PACKAGES (tiko-vendor RFC-0002 V9, V11): their translated headers came with
# pkg/; their binaries are never copied from the tree -- vendorfetch.sh downloads or builds
# this host's, pinned and SHA-256-checked, straight into the output -- and fetch.toml is
# that script's alone. Each module must end with binaries and its library's licence --
# binaries only where its fetch.toml has entries for this host: vendor/SDL3 (and its image,
# ttf and mixer) has none on Linux, where SDL publishes no binaries; it links the system's.
rm -rf "$OUT"/pkg/vendor/*/lib
rm -f "$OUT"/pkg/vendor/*/fetch.toml
rm -rf "$OUT"/pkg/vendor/*/patches     # fetch.toml's too: vendorfetch.sh reads both from the tree
# vendor/tkControls also fetches fonts/, and builds scintk (tkCodeEdit/scintk) in place: the
# tree's build output is not shipped, only its source and what vendorfetch.sh copies to lib/.
rm -rf "$OUT/pkg/vendor/tkControls/fonts" "$OUT/pkg/vendor/tkControls/tkCodeEdit/scintk/bin" \
       "$OUT/pkg/vendor/tkControls/tkCodeEdit/scintk/out" "$OUT/pkg/vendor/SDL3/static/bin" \
       "$OUT/pkg/vendor/raylib6/shared/bin"
sh "$ROOT/build/vendorfetch.sh" --out "$OUT/pkg" || die "vendorfetch.sh failed: the vendor packages have no binaries"
for _vm in "$OUT"/pkg/vendor/*/; do
    _vft="$ROOT/pkg/vendor/$( basename "$_vm" )/fetch.toml"
    if grep -q "^\[$HOST\." "$_vft" 2>/dev/null; then
        [ -n "$( ls "$_vm/lib" 2>/dev/null )" ] || die "packaged $_vm has no lib/ -- '#import \"vendor/...\"' would not link"
    else
        note "packaged $_vm has no $HOST binaries: its fetch.toml has no [$HOST.<n>] entry"
    fi
    [ -f "$_vm/LICENSE" ] || die "packaged $_vm has no LICENSE"
done
note "vendor packages -> pkg/vendor ($( cd "$OUT/pkg/vendor" && ls -d */ | tr -d '/' | tr '\n' ' '))"

# The libraries: lib/<target>/, ours alone -- tiko-rt, its startup object on a gnu
# target, libtkogfx where there is one. No target has a second, -fb, directory since
# 2026-10-10: linux-x86_64's held nothing the driver names, and win64's MinGW runtime
# went with the win64 target.
# STALE TARGET DIRECTORIES ARE REMOVED FIRST, and this is not housekeeping.
# Packaging into an existing tree only ever replaced the directories it was about
# to write, so lib/win32 and lib/win32-fb from an older run would sit there
# afterwards -- 60 MB of libraries for a target that no longer exists, counted in
# the manifest's file total, and looking exactly like something meant to be used.
# A stale archive does not announce itself; it links, and answers plausibly.
#
# Only lib/ is swept, and only entries that do not belong to a current target,
# so this cannot touch inc/, licences/ or the compiler.
if [ -d "$OUT/lib" ]; then
    for d in "$OUT"/lib/*; do
        [ -d "$d" ] || continue
        _keep=0
        for t in $TARGETS; do
            case ${d##*/} in "$t") _keep=1 ;; esac
        done
        # No -fb directory for any target now: linux-x86_64-fb held fbc's fbrt0.o and
        # libraries the driver never names (tiko-rt has its own fbrt0, R8), and win64 --
        # whose MinGW runtime win64-fb was -- is not packaged. Both are swept here.
        if [ "$_keep" = "0" ]; then
            note "removing stale lib/${d##*/} -- not a target of this toolchain"
            rm -rf "$d"
        fi
    done
fi

GFX_STATE=""

for t in $TARGETS; do
    note "runtime -> lib/$t/  (tiko-rt)"
    rm -rf "$OUT/lib/$t"
    mkdir -p "$OUT/lib/$t"
    cp -f "$ROOT/lib/rt/lib/$t/libfb.a"   "$OUT/lib/$t/"
    cp -f "$ROOT/lib/rt/lib/$t/libfbmt.a" "$OUT/lib/$t/"
    # THE PIC PAIR, where the runtime builds one (linux-x86_64): what a Linux '-dll'
    # links, as fbc's own '-lfbpic' does. lib/rt/build/build.sh says why.
    for _pic in libfbpic.a libfbmtpic.a; do
        [ -f "$ROOT/lib/rt/lib/$t/$_pic" ] && cp -f "$ROOT/lib/rt/lib/$t/$_pic" "$OUT/lib/$t/"
    done
    # THE STARTUP OBJECT, tiko-rt's own since 2026-10-09 (lib/rt/src/c/fbrt0.c), for a
    # gnu target. It goes beside the runtime so the driver's first-match search finds
    # it before lib/<target>-fb/; that copy of fbc's is deleted below all the same.
    for _rt0 in fbrt0.o fbrt0pic.o; do
        [ -f "$ROOT/lib/rt/lib/$t/$_rt0" ] && cp -f "$ROOT/lib/rt/lib/$t/$_rt0" "$OUT/lib/$t/"
    done
    case $t in
        windows-x86_64) ;;
        *) [ -f "$OUT/lib/$t/fbrt0.o" ] || \
               die "no fbrt0.o for $t -- lib/rt/build/build.sh builds it beside libfb.a" ;;
    esac

    # THE GRAPHICS LIBRARY GOES BESIDE THE RUNTIME, in lib/<target>/ and not a
    # directory of its own, because that is where the compiler looks: since
    # 2026-09-06 it appends <exe-dir>/lib/<target> to its own library search, and
    # LinkExe names each search path's libtkogfx.a the same way it names libfb.a.
    # A separate lib/gfx/ in the package would need a -p nobody would know to pass.
    #
    # THE CONFIGURATION IS CHECKED, not assumed. lib/gfx writes .config beside the
    # archive precisely so a Release toolchain cannot quietly ship a Debug library:
    # a stale archive does not error, it links and yields a plausible wrong answer.
    _gfx="$ROOT/lib/gfx/lib/$t/libtkogfx.a"
    if [ -f "$_gfx" ]; then
        _gcfg=$( cat "$ROOT/lib/gfx/lib/$t/.config" 2>/dev/null || echo unknown )
        cp -f "$_gfx" "$OUT/lib/$t/"
        if [ "$_gcfg" = "$CFG" ]; then
            note "graphics -> lib/$t/libtkogfx.a  ($_gcfg)"
            GFX_STATE="$GFX_STATE
  $t  packaged, $_gcfg"
        else
            note "WARNING: graphics archive for $t is $_gcfg, not $CFG -- packaged anyway"
            GFX_STATE="$GFX_STATE
  $t  packaged, but built $_gcfg where this toolchain is $CFG"
        fi
    elif gfx_has_target "$t"; then
        note "WARNING: no graphics archive for $t -- the build above did not produce one"
        GFX_STATE="$GFX_STATE
  $t  MISSING -- lib/gfx builds for this target and produced nothing"
    else
        note "graphics: none for $t -- lib/gfx builds $GFX_TARGETS only"
        GFX_STATE="$GFX_STATE
  $t  none -- lib/gfx builds $GFX_TARGETS only"
    fi

done

# THE MSVC IMPORT LIBRARIES, built from the tree: lib/implib/*.def, one llvm-dlltool
# run each, and lib/implib/static/*.lib copied through (build/implibs.sh). The MSVC
# linker looks for <name>.lib; nothing else here supplies one.
#
# WITHOUT THESE THE DEFAULT TARGET DEPENDS ON VISUAL STUDIO. Measured 2026-09-06:
# clang's msvc driver passes -libpath for VS 2022 Community and Windows SDK
# 10.0.26100 out of its own knowledge of the machine, so windows-x86_64 linked here and
# would not link on a machine without them. A toolchain whose default target needs
# an unrelated install is not one that can be handed to anyone.
#
# NOT FROM fbc ANY MORE (phase L, 2026-10-10). They were generated at every run from
# fbc's MinGW lib*.dll.a, and the .def files that made were thrown away; those are
# what lib/implib/ commits, and all 843 libraries came out byte for byte the same.
#
# NOT FATAL, on the same reasoning as the graphics build above: this needs
# llvm-dlltool, and losing the compiler and runtime because the import libraries
# could not be built would be the wrong trade. The manifest records what happened.
IMPLIB_STATE="not applicable on this host"
if [ "$HOST" = "windows" ]; then
    note "msvc import libraries -> lib/windows-x86_64/  (from lib/implib/)"
    if IMPLIB_OUT=$( sh "$ROOT/build/implibs.sh" build --out "$OUT/lib/windows-x86_64" 2>&1 ); then
        IMPLIB_STATE=$( echo "$IMPLIB_OUT" | sed -n 's/^implibs: //p' | tail -1 | sed 's/ -> .*//' )
        note "$IMPLIB_STATE"
    else
        IMPLIB_STATE="FAILED -- $( echo "$IMPLIB_OUT" | tail -1 )"
        note "WARNING: msvc import libraries not built -- $IMPLIB_STATE"
    fi
fi

# ------------------------------------------------------------------- fbcunit
#
# THE UNIT-TEST LIBRARY SHIPS, header and archive, so a user's test suite needs
# nothing that is not in the toolchain: '#include "fbcunit.bi"' is found in inc/,
# and its '#inclib "fbcunit"' in lib/<target>/, beside the runtime, where the
# compiler already looks. fbcunit is fbc's own -- tests/vendor/fbc-tests/fbcunit,
# vendored unmodified -- so it is BUILT HERE with the compiler just packaged,
# per target, rather than copied: fbc's archives are MinGW and the default target
# is the Microsoft ABI. libfbcunit.a on every target, the MSVC one included --
# LinkExe resolves lib<name>.a in a search path before it asks lld-link for
# <name>.lib.
#
# LGPL-2.1-or-later WITH A STATIC-LINKING EXCEPTION, so the archive carries an
# obligation: its source ships beside it, under src/fbcunit, with its notices.
#
# NOT FATAL, as the graphics library is not: a user without fbcunit has lost the
# test library, not the compiler. The manifest records each target either way.
FBCU="$ROOT/tests/vendor/fbc-tests/fbcunit"
FBCU_AR=${TIKO_AR:-$( command -v llvm-ar 2>/dev/null || echo "/c/Program Files/LLVM/bin/llvm-ar.exe" )}
# On macOS Homebrew's LLVM is deliberately not on PATH (docs/tiko-macos D6): its llvm-ar is named.
# An 'if', not a '{ ...; }' inside the '$( )' above: macOS's /bin/sh (bash 3.2) cannot parse that.
if [ -z "${TIKO_AR:-}" ] && [ "$HOST" = "macos" ] && ! command -v llvm-ar > /dev/null 2>&1; then
    FBCU_AR=/opt/homebrew/opt/llvm/bin/llvm-ar
fi
FBCU_STATE=""
for t in $TARGETS; do
    _fo="$OUT/.fbcunit.$t"
    rm -rf "$_fo"; mkdir -p "$_fo"
    _fok=1
    for _fs in "$FBCU"/src/*.bas; do
        _fn=$( basename "$_fs" .bas )
        "$OUT/${BINSUB}tiko$EXT" -target "$t" -c "$_fs" -i "$FBCU/inc" -i "$FBCU/src" \
            -o "$_fo/$_fn.o" >>"$_fo/log" 2>&1 || true
        # THE OBJECT IS THE TEST, not the exit code -- see verify_target below.
        [ -f "$_fo/$_fn.o" ] || _fok=0
    done
    rm -f "$OUT/lib/$t/libfbcunit.a"
    if [ "$_fok" = "1" ] && "$FBCU_AR" rcs "$OUT/lib/$t/libfbcunit.a" "$_fo"/*.o; then
        note "fbcunit -> lib/$t/libfbcunit.a"
        FBCU_STATE="$FBCU_STATE
  $t  packaged"
    else
        _fwhy=$( grep -m1 -iE 'error' "$_fo/log" | cut -c1-120 )
        [ -n "$_fwhy" ] || _fwhy="archive not written ($FBCU_AR)"
        note "WARNING: fbcunit not built for $t -- $_fwhy"
        FBCU_STATE="$FBCU_STATE
  $t  FAILED -- $_fwhy"
    fi
    rm -rf "$_fo"
done
if [ -d "$OUT/inc" ]; then
    cp -f "$FBCU/inc/fbcunit.bi" "$OUT/inc/fbcunit.bi"
else
    note "WARNING: no inc/ -- fbcunit.bi not packaged"
    FBCU_STATE="$FBCU_STATE
  header NOT packaged -- no inc/"
fi
rm -rf "$OUT/src/fbcunit"
mkdir -p "$OUT/src/fbcunit"
cp -r "$FBCU/src" "$FBCU/inc" "$OUT/src/fbcunit/"
cp -f "$FBCU/readme.txt" "$FBCU/license.txt" "$FBCU/lgpl-2.1.txt" "$OUT/src/fbcunit/"

# ----------------------------------------------------------------- the notices
#
# lib/rt is LGPL-2.1-or-later and a derivative of libfb; lib/gfx is
# LGPL-2.1-or-later with the static-linking exception and a derivative of gfxlib2;
# inc/ carries FreeBASIC's headers. docs/plan/11 records that as permitted and
# carrying obligations rather than prohibitions -- so the notices ship with the
# toolchain instead of being something to remember at release time.
mkdir -p "$OUT/licences"
cp -f "$ROOT/LICENSE"              "$OUT/licences/LICENSE-tiko"
cp -f "$ROOT/COPYING"              "$OUT/licences/COPYING-tiko"
cp -f "$ROOT/COPYING.LGPL-2.1"     "$OUT/licences/COPYING.LGPL-2.1-tiko"
cp -f "$ROOT/lib/gfx/LICENSE"      "$OUT/licences/LICENSE-libtkogfx"
cp -f "$ROOT/lib/rt/LICENSE"       "$OUT/licences/LICENSE-tiko-rt"
cp -f "$ROOT/pkg/LICENSE"          "$OUT/licences/LICENSE-pkg"
cp -f "$ROOT/lib/rt/PROVENANCE.md" "$OUT/licences/PROVENANCE-tiko-rt.md"
cp -f "$FBCU/license.txt"         "$OUT/licences/LICENSE-fbcunit"
cp -f "$FBCU/lgpl-2.1.txt"        "$OUT/licences/COPYING.LGPL-2.1-fbcunit"
# FreeBASIC's own notices, FROM THE TREE (licences/), not from an fbc install: which
# licence covers which part, and the two licence texts -- the same files as tiko's
# own COPYING and COPYING.LGPL-2.1, so they are not committed twice. cp -f under
# set -e: a missing one stops the package rather than shipping without it.
cp -f "$ROOT/licences/LICENSE.freebasic" "$OUT/licences/LICENSE.freebasic"
cp -f "$ROOT/COPYING"                    "$OUT/licences/COPYING.GPL-2.0.freebasic"
cp -f "$ROOT/COPYING.LGPL-2.1"           "$OUT/licences/COPYING.LGPL-2.1.freebasic"
# mingw-w64's, for the import libraries built from lib/implib/.
if [ "$HOST" = "windows" ]; then
    cp -f "$ROOT/lib/implib/COPYING.MinGW-w64-runtime.txt" "$OUT/licences/COPYING.MinGW-w64-runtime.txt"
fi

# --------------------------------------------------------------- verification
#
# A toolchain that assembles is not a toolchain that works, and the difference is
# invisible: every file is present, every size is plausible, and the first thing
# that fails is a user's link. So --verify compiles and RUNS a program with the
# tree as packaged, per target, and the result goes into the manifest as a
# measurement rather than a claim.
#
# Run from $OUT passing nothing but -target -- the invocation the manifest tells a
# user to use -- so what is verified is the documented one and not some other.

VERIFY_LINES=""

verify_target( ) {
    _t=$1
    _tmp="$OUT/.verify.$_t"
    rm -rf "$_tmp"; mkdir -p "$_tmp"
    # A BUNDLED HEADER IS PART OF THE TEST. 'print "ok"' alone needs no inc/ at all,
    # so a toolchain whose headers were unreachable -- tiko-linux, whose inc/ was
    # copied from fbc-modern-linux's EMPTY inc/ rather than its include/freebasic --
    # passed this, and the first '#include "containers.bi"' a user wrote was TKO0301.
    # crt.bi since 2026-10-10, when containers.bi became std/containers (checked below).
    printf '#include once "crt.bi"
print "ok"
' > "$_tmp/hello.tiko"

    ( cd "$OUT" && "./${BINSUB}tiko$EXT" -target "$_t"             ".verify.$_t/hello.tiko" -o ".verify.$_t/hello$EXT" ) >"$_tmp/log" 2>&1 || true

    # THE EXIT CODE IS NOT THE TEST. Measured 2026-09-04: tiko returns 0 when the
    # link fails and writes no executable, so trusting it reported a win32 link
    # failure as 'built but did not run'. The artifact existing is the test.
    if [ -f "$_tmp/hello$EXT" ]; then
        if [ "$( "$_tmp/hello$EXT" 2>/dev/null )" = "ok" ]; then
            VERIFY_LINES="$VERIFY_LINES
  $_t  PASS -- compiled, linked and ran"
        else
            VERIFY_LINES="$VERIFY_LINES
  $_t  FAIL -- built, but the program did not run correctly"
        fi
    else
        # The first linker line is the useful one; the rest are the same fact
        # repeated once per undefined symbol.
        _why=$( grep -m1 -iE 'error|undefined' "$_tmp/log" | cut -c1-160 )
        [ -n "$_why" ] || _why="see the build log"
        VERIFY_LINES="$VERIFY_LINES
  $_t  FAIL -- $_why"
    fi
    rm -rf "$_tmp"
}

# FBCUNIT IS VERIFIED THE SAME WAY: a program that includes the shipped header,
# resolves its #inclib out of lib/<target>/ and RUNS. An archive that is present
# but was built for the wrong ABI links nothing, and only a link says so.
verify_fbcunit( ) {
    _t=$1
    _tmp="$OUT/.verifycu.$_t"
    rm -rf "$_tmp"; mkdir -p "$_tmp"
    printf '#include once "fbcunit.bi"
CU_ASSERT( 1 + 1 = 2 )
if fbcu.dblIsInf( 1.0 ) = false then print "ok"
' > "$_tmp/cu.tiko"
    ( cd "$OUT" && "./${BINSUB}tiko$EXT" -target "$_t" ".verifycu.$_t/cu.tiko" -o ".verifycu.$_t/cu$EXT" ) >"$_tmp/log" 2>&1 || true
    if [ -f "$_tmp/cu$EXT" ] && [ "$( "$_tmp/cu$EXT" 2>/dev/null )" = "ok" ]; then
        VERIFY_LINES="$VERIFY_LINES
  $_t  fbcunit PASS -- compiled, linked and ran"
    else
        _why=$( grep -m1 -iE 'error|undefined' "$_tmp/log" | cut -c1-160 )
        [ -n "$_why" ] || _why="built, but did not print ok"
        VERIFY_LINES="$VERIFY_LINES
  $_t  fbcunit FAIL -- $_why"
    fi
    rm -rf "$_tmp"
}

# THE GRAPHICS LIBRARY IS VERIFIED THE SAME WAY, where one is shipped: a SCREEN
# program built from the package, linked against the shipped libtkogfx.a and RUN.
# GFX_NULL -- the null driver, a framebuffer and no window -- so it needs no display
# on any host, and still takes every path a windowed program's link does: the
# archive's entry points, its calls into libfb (the GNU ld order the ELF link group
# exists for), the runtime's console hooks. The pixel is read back through POINT.
verify_gfx( ) {
    _t=$1
    _tmp="$OUT/.verifygfx.$_t"
    rm -rf "$_tmp"; mkdir -p "$_tmp"
    printf 'screenres 64, 48, 32, , -1
pset ( 3, 4 ), &hFF8040
dim as long c = point( 3, 4 )
screen 0
print hex( c and &hFFFFFF )
' > "$_tmp/gfx.tiko"
    ( cd "$OUT" && "./${BINSUB}tiko$EXT" -target "$_t" ".verifygfx.$_t/gfx.tiko" -o ".verifygfx.$_t/gfx$EXT" ) >"$_tmp/log" 2>&1 || true
    if [ -f "$_tmp/gfx$EXT" ] && [ "$( "$_tmp/gfx$EXT" 2>/dev/null )" = "FF8040" ]; then
        VERIFY_LINES="$VERIFY_LINES
  $_t  graphics PASS -- a GFX_NULL screen compiled, linked and ran"
    else
        _why=$( grep -m1 -iE 'error|undefined' "$_tmp/log" | cut -c1-160 )
        [ -n "$_why" ] || _why="built, but did not read its pixel back"
        VERIFY_LINES="$VERIFY_LINES
  $_t  graphics FAIL -- $_why"
    fi
    rm -rf "$_tmp"
}

# THE STANDARD PACKAGE IS VERIFIED THE SAME WAY: programs importing every std facade
# (RFC-0009 §7), found in the packaged pkg/ and nowhere else, their headers in the packaged
# inc/, built with their modules and RUN. Each facade prints one value on a line of its
# own: a wrong value fails that facade's line, and a header that renamed or dropped a name
# its facade exports fails the build, every line carrying the error that names it -- HERE,
# and not in a user's build. std/tasks gets a program of its own: its
# headers refuse to compile without -mt. The module cache goes to the scratch directory,
# which is removed.
STD_CHECKS='strings|print strings.Replace( "k-o", "-", "" )|ko
fs|print fs.PathExtension( "a.txt" )|.txt
containers|dim as containers.Array( of long ) a : a.Push( 7 ) : print str( a[0] )|7
chrono|print str( chrono.LocalDate( 2026, 9, 28 ).Day )|28
outcome|print str( outcome.Some( of long )( 5 ).Value( ) )|5
numeric|print str( numeric.GCD( 12ull, 18ull ) )|6
money|print money.DecimalFromInt( 12 ).ToString( )|12
logs|print logs.LevelName( logs.LOG_WARN )|WARN
tui|print str( tui.TuiStringWidth( "abc" ) )|3
memory|dim as memory.SharedPtr( of long ) sp = memory.MakeSharedFrom( of long )( 9 ) : print str( *sp )|9'
STD_TASKS='tasks|dim as tasks.WaitGroup wg : wg.Add( 1 ) : wg.Done( ) : print str( wg.Count( ) )|0'

# verify_std_run <target> <tag> <checks> <extra tiko flags>
verify_std_run( ) {
    _t=$1; _tag=$2; _checks=$3; _flags=$4
    _tmp="$OUT/.verifystd.$_t.$_tag"
    rm -rf "$_tmp"; mkdir -p "$_tmp"
    : > "$_tmp/std.tiko"
    echo "$_checks" | while IFS='|' read -r _m _code _want; do
        printf '#import "std/%s"\n' "$_m" >> "$_tmp/std.tiko"
    done
    echo "$_checks" | while IFS='|' read -r _m _code _want; do
        printf '%s\n' "$_code" >> "$_tmp/std.tiko"
    done
    ( cd "$OUT" && TIKO_MODCACHE=".verifystd.$_t.$_tag/cache" "./${BINSUB}tiko$EXT" $_flags -target "$_t" \
        ".verifystd.$_t.$_tag/std.tiko" -o ".verifystd.$_t.$_tag/std$EXT" ) >"$_tmp/log" 2>&1 || true
    _why=""
    if [ -f "$_tmp/std$EXT" ]; then
        "$_tmp/std$EXT" 2>/dev/null | tr -d '\r' > "$_tmp/out" || true
    else
        _why=$( grep -m1 -iE 'error|undefined' "$_tmp/log" | cut -c1-160 )
        [ -n "$_why" ] || _why="not built"
    fi
    _i=0
    _lines=$( echo "$_checks" | while IFS='|' read -r _m _code _want; do
        _i=$(( _i + 1 ))
        if [ -n "$_why" ]; then
            echo "  $_t  std/$_m FAIL -- $_why"
        elif [ "$( sed -n "${_i}p" "$_tmp/out" )" = "$_want" ]; then
            echo "  $_t  std/$_m PASS -- imported, compiled, linked and ran"
        else
            echo "  $_t  std/$_m FAIL -- printed '$( sed -n "${_i}p" "$_tmp/out" )', not '$_want'"
        fi
    done )
    VERIFY_LINES="$VERIFY_LINES
$_lines"
    rm -rf "$_tmp"
}

verify_std( ) {
    verify_std_run "$1" all "$STD_CHECKS" ""
    verify_std_run "$1" tasks "$STD_TASKS" "-mt"
}

# SYS/WIN, shipped by every toolchain, usable for Windows alone. On a Windows target all seven
# modules are imported from the packaged pkg/sys -- gui builds the largest, and imports win and
# gdiplus; richedit imports com and gui -- and a string helper, a GDI+ colour, a CWindow, a
# DVARIANT and a RichEdit type used. On any other target the import must stop at the guard every
# module's header opens with: TKO0309, the #error line, and a failing exit.
verify_syswin( ) {
    _t=$1
    _tmp="$OUT/.verifysyswin.$_t"
    rm -rf "$_tmp"; mkdir -p "$_tmp"
    case "$_t" in
    win*)
        printf '#import "sys/win"
#import "sys/win/com"
#import "sys/win/gdiplus"
#import "sys/win/gui"
#import "sys/win/richedit"
#import "sys/win/direct2d"
#import "sys/win/webview2"
dim as gui.CWindow w
dim as com.DVARIANT v
dim as richedit.CTextRange2 ptr r
print win.UpperCase( "tiko" ); " "; hex( gdiplus.GDIP_ARGB( &hFF, 1, 2, 3 ) )
' > "$_tmp/syswin.tiko"
        ( cd "$OUT" && TIKO_MODCACHE=".verifysyswin.$_t/cache" "./${BINSUB}tiko$EXT" -target "$_t" \
            ".verifysyswin.$_t/syswin.tiko" -o ".verifysyswin.$_t/syswin$EXT" ) >"$_tmp/log" 2>&1 || true
        if [ -f "$_tmp/syswin$EXT" ] && [ "$( "$_tmp/syswin$EXT" 2>/dev/null | tr -d '' )" = "TIKO FF010203" ]; then
            VERIFY_LINES="$VERIFY_LINES
  $_t  sys/win PASS -- all seven modules imported, compiled, linked and ran"
        else
            _why=$( grep -m1 -iE 'error|undefined' "$_tmp/log" | cut -c1-160 )
            [ -n "$_why" ] || _why="built, but did not print 'TIKO FF010203'"
            VERIFY_LINES="$VERIFY_LINES
  $_t  sys/win FAIL -- $_why"
        fi
        ;;
    *)
        printf '#import "sys/win"\nprint 1\n' > "$_tmp/guard.tiko"
        _rc=0
        ( cd "$OUT" && TIKO_MODCACHE=".verifysyswin.$_t/cache" "./${BINSUB}tiko$EXT" -target "$_t" -c \
            ".verifysyswin.$_t/guard.tiko" -o ".verifysyswin.$_t/guard.o" ) >"$_tmp/log" 2>&1 || _rc=$?
        if [ "$_rc" -ne 0 ] && grep -q 'error TKO0309: #error: "sys/win is Windows-only' "$_tmp/log"; then
            VERIFY_LINES="$VERIFY_LINES
  $_t  sys/win PASS -- shipped, and its import stops at the Windows-only guard"
        else
            _why=$( grep -m1 -iE 'error' "$_tmp/log" | cut -c1-160 )
            [ -n "$_why" ] || _why="the import compiled (exit $_rc): the guard did not fire"
            VERIFY_LINES="$VERIFY_LINES
  $_t  sys/win FAIL -- $_why"
        fi
        ;;
    esac
    rm -rf "$_tmp"
}

# THE VENDOR PACKAGES, the RFC's own program (tiko-vendor RFC-0002 §1): vendor/sqlite3
# imported 'link static' and 'link dynamic', from the packaged pkg/ alone, built and RUN --
# the dynamic one from beside the DLL / .so the compiler copied there (V13).
verify_vendor( ) {
    _t=$1
    for _mode in static dynamic; do
        _tmp="$OUT/.verifyvendor.$_t.$_mode"
        rm -rf "$_tmp"; mkdir -p "$_tmp"
        printf '#import "vendor/sqlite3" link %s
dim as sqlite3 ptr db
if sqlite3_open( ":memory:", @db ) <> SQLITE_OK then print "open failed"
dim as sqlite3_stmt ptr st
sqlite3_prepare_v2( db, "select ? || %s", -1, @st, 0 )
sqlite3_bind_text( st, 1, "sqlite", -1, SQLITE_TRANSIENT )
if sqlite3_step( st ) = SQLITE_ROW then print *cast( zstring ptr, sqlite3_column_text( st, 0 ) )
sqlite3_finalize( st )
sqlite3_close( db )
' "$_mode" "'ok'" > "$_tmp/v.tiko"
        ( cd "$OUT" && TIKO_MODCACHE=".verifyvendor.$_t.$_mode/cache" "./${BINSUB}tiko$EXT" -target "$_t" \
            ".verifyvendor.$_t.$_mode/v.tiko" -o ".verifyvendor.$_t.$_mode/v$EXT" ) >"$_tmp/log" 2>&1 || true
        if [ -f "$_tmp/v$EXT" ] && [ "$( "$_tmp/v$EXT" 2>/dev/null | tr -d '\r' )" = "sqliteok" ]; then
            VERIFY_LINES="$VERIFY_LINES
  $_t  vendor/sqlite3 link $_mode PASS -- imported, compiled, linked and ran"
        else
            _why=$( grep -m1 -iE 'error|undefined|cannot' "$_tmp/log" | cut -c1-160 )
            [ -n "$_why" ] || _why="built, but did not print 'sqliteok'"
            VERIFY_LINES="$VERIFY_LINES
  $_t  vendor/sqlite3 link $_mode FAIL -- $_why"
        fi
        rm -rf "$_tmp"
    done
}

if [ "$DO_VERIFY" = "1" ]; then
    for t in $TARGETS; do
        note "verifying $t: compile, link and run"
        verify_target "$t"
        verify_fbcunit "$t"
        gfx_has_target "$t" && verify_gfx "$t"
        verify_std "$t"
        verify_syswin "$t"
        verify_vendor "$t"
    done
else
    VERIFY_LINES="
  not run -- pass --verify to compile and run a program per target"
fi

# ---------------------------------------------------------------- the editor
#
# TKEDIT SHIPS WITH THE TOOLCHAIN (the author's orders, 2026-10-27 and 2026-10-29): a release
# archive unpacks to ONE folder, tiko-lang/, with tkedit in its root (tkedit.exe next to
# tiko.exe, tkedit or tkEdit.app in the root above bin/tiko), and tkedit finds the compiler in its
# own folder or its bin/ (tkedit/src/core/build: SiblingCompiler). Here every host packages into one
# toolchains/, so the editor is staged apart, as tkedit-<host>; build/release.sh puts it in.
#
# ONE FILE (docs/tkEdit/SINGLE-FILE.md): tkedit links in SDL, SDL_ttf, SDL_image, scintk and its
# scanner, and carries its fonts, themes, catalogs, keyword lists and licences inside itself
# ('tkedit --export-resources DIR' writes them out, '--licences' prints the notices). So the folder
# holds tkedit.exe / tkedit alone, and on macOS tkEdit.app: Contents/MacOS/tkedit, Info.plist and
# Resources/tkEdit.icns (the .icns made from icons/tkedit.png with sips + iconutil), signed ad hoc
# (SINGLE-FILE SF3, SF5).
#
# BUILT BY THE TOOLCHAIN JUST PACKAGED, so this is one more check that it works. A failure
# is recorded as FAIL rather than ending the run: the toolchain itself is good, and
# build/release.sh refuses a MANIFEST with a FAIL in it.

TKEDIT_STATE="not packaged (--no-tkedit)"
if [ "$DO_TKEDIT" = "1" ]; then
    TKD="$(dirname "$OUT")/tkedit-$HOST"
    TKSRC="$ROOT/tkedit"
    _tklog="$ROOT/lib/rt/obj/package-tkedit.log"
    mkdir -p "$ROOT/lib/rt/obj"; : > "$_tklog"
    _tkfail=""
    # the editor's scanner, LINKED INTO tkedit (docs/tkEdit/SINGLE-FILE.md S4): build.sh --lib builds
    # bin/parser_<os>_<arch>.a with THE COMPILER JUST PACKAGED -- the one that builds tkedit below, so
    # each std module is one copy at tkedit's link (bin/ keeps the tree's compiler untouched)
    note "building tikoParser for tkedit"
    if ! TIKO_SEED="$OUT/${BINSUB}tiko$EXT" sh "$ROOT/build/build.sh" Release --lib >>"$_tklog" 2>&1; then
        _tkfail="tikoParser did not build"
    fi
    case $HOST in
        macos) _tkp="$ROOT/bin/parser_macos_arm64.a" ;;
        *)     _tkp="$ROOT/bin/parser_${HOSTOS}_${HOSTARCH}.a" ;;
    esac
    [ -n "$_tkfail" ] || [ -f "$_tkp" ] || _tkfail="no $_tkp after the build"
    if [ -z "$_tkfail" ]; then
        note "building tkedit with the packaged compiler"
        rm -rf "$TKSRC/src/app/out/release"
        if ! ( cd "$TKSRC/src/app" && TIKO_MODCACHE="$TKSRC/out/modcache-package" \
                 "$OUT/${BINSUB}tiko$EXT" build --profile release ) >>"$_tklog" 2>&1; then
            _tkfail="the build failed -- lib/rt/obj/package-tkedit.log"
        fi
    fi
    _tkrel="$TKSRC/src/app/out/release"
    [ -n "$_tkfail" ] || [ -f "$_tkrel/tkedit$EXT" ] || _tkfail="no $_tkrel/tkedit$EXT"
    if [ -z "$_tkfail" ]; then
        rm -rf "$TKD"; mkdir -p "$TKD"
        if [ "$HOST" = "macos" ]; then
            _app="$TKD/tkEdit.app/Contents"
            mkdir -p "$_app/MacOS" "$_app/Resources"
            cp -f "$_tkrel/tkedit" "$_app/MacOS/tkedit"
            _tkver=$( sed -n 's/^version *= *"\(.*\)"/\1/p' "$TKSRC/src/app/tiko.toml" | head -1 )
            cat > "$_app/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>                 <string>tkEdit</string>
    <key>CFBundleDisplayName</key>          <string>tkEdit</string>
    <key>CFBundleIdentifier</key>           <string>com.planetsquires.tkedit</string>
    <key>CFBundleExecutable</key>           <string>tkedit</string>
    <key>CFBundleIconFile</key>             <string>tkEdit</string>
    <key>CFBundlePackageType</key>          <string>APPL</string>
    <key>CFBundleShortVersionString</key>   <string>${_tkver:-0.1.0}</string>
    <key>CFBundleVersion</key>              <string>${_tkver:-0.1.0}</string>
    <key>LSMinimumSystemVersion</key>       <string>13.0</string>
    <key>NSHighResolutionCapable</key>      <true/>
</dict>
</plist>
PLIST
            # the Finder and Dock icon: icons/tkedit.png at each size an .icns holds, up to its own
            _iset="$ROOT/lib/rt/obj/tkEdit.iconset"
            rm -rf "$_iset" && mkdir -p "$_iset"
            for _sz in 16 32 64 128 256; do
                sips -z $_sz $_sz "$TKSRC/icons/tkedit.png" --out "$_iset/icon_${_sz}x${_sz}.png" >/dev/null 2>&1
            done
            cp -f "$_iset/icon_32x32.png" "$_iset/icon_16x16@2x.png"
            cp -f "$_iset/icon_64x64.png" "$_iset/icon_32x32@2x.png"
            cp -f "$_iset/icon_256x256.png" "$_iset/icon_128x128@2x.png"
            rm -f "$_iset/icon_64x64.png"
            iconutil -c icns "$_iset" -o "$_app/Resources/tkEdit.icns" >>"$_tklog" 2>&1 \
                || _tkfail="iconutil could not make tkEdit.icns"
            # SIGNED AD HOC (SINGLE-FILE SF5): arm64 runs nothing unsigned; no Developer ID yet
            codesign --force --deep -s - "$TKD/tkEdit.app" >>"$_tklog" 2>&1 || _tkfail="codesign failed"
            codesign --verify --deep --strict "$TKD/tkEdit.app" >>"$_tklog" 2>&1 || _tkfail="codesign --verify failed"
            _tkexe="$_app/MacOS/tkedit"
        else
            cp -f "$_tkrel/tkedit$EXT" "$TKD/"
            [ "$HOSTOS" != "linux" ] || unversion_tinfo "$TKD/tkedit" || \
                _tkfail="could not drop libtinfo's symbol versions from tkedit"
            _tkexe="$TKD/tkedit$EXT"
        fi
        note "tkedit -> $TKD"
        TKEDIT_STATE="../tkedit-$HOST, built by this compiler (the archive puts it beside the compiler)"
        # --verify: its self-test, compiling with this toolchain. It writes scratch files under
        # <its folder>/out/, removed after. On Linux it needs a display (WSLg has one); macOS's
        # is the logged-in desktop (over ssh too), and macOS has no timeout(1): perl's alarm.
        if [ "$DO_VERIFY" = "1" ]; then
            if [ "$HOSTOS" != "linux" ] || [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
                note "verifying tkedit: its self-test"
                if [ "$HOST" = "macos" ]; then
                    _tkres=$( cd "$TKD" && TKEDIT_TIKO="$OUT/${BINSUB}tiko$EXT" \
                              perl -e 'alarm 600; exec @ARGV' "$_tkexe" --selftest 2>&1 | grep ' selftest: ' | tail -1 )
                else
                    _tkres=$( cd "$TKD" && env -u LD_LIBRARY_PATH TKEDIT_TIKO="$OUT/${BINSUB}tiko$EXT" SDL_VIDEO_DRIVER=${SDL_VIDEO_DRIVER:-} \
                              timeout 600 "$_tkexe" --selftest 2>&1 | grep ' selftest: ' | tail -1 )
                fi
                rm -rf "$TKD/out"
                # NOTHING MAY WRITE INSIDE THE BUNDLE: one added file and the signature fails
                if [ "$HOST" = "macos" ] && ! codesign --verify --deep --strict "$TKD/tkEdit.app" >>"$_tklog" 2>&1; then
                    _tkres="the self-test wrote inside tkEdit.app: codesign --verify fails"
                fi
                if echo "$_tkres" | grep -q ' 0 failed'; then
                    TKEDIT_STATE="$TKEDIT_STATE; self-test: ${_tkres#*selftest: }"
                    VERIFY_LINES="$VERIFY_LINES
  tkedit  self-test ok -- ${_tkres#*selftest: }"
                else
                    _tkfail="self-test: ${_tkres:-no summary line}"
                fi
            else
                TKEDIT_STATE="$TKEDIT_STATE; self-test not run (no display)"
            fi
        fi
    fi
    if [ -n "$_tkfail" ]; then
        note "WARNING: tkedit FAIL -- $_tkfail"
        TKEDIT_STATE="FAIL -- $_tkfail"
        VERIFY_LINES="$VERIFY_LINES
  tkedit  FAIL -- $_tkfail"
    fi
fi

# ---------------------------------------------------------------- the manifest
#
# A packaged toolchain is a pile of copied binaries with nothing in it that says
# WHICH ones. A stale archive does not error -- it links, and yields a plausible
# wrong answer. So every part records where it came from and at what commit, and
# a dirty tree is marked as such.

# UNDER WSL a worktree made by Windows git records its gitdir as 'C:/...', which
# Linux git cannot open -- the Linux toolchain was stamped 'commit unknown'. Windows
# git, reachable through WSL interop, answers for the same tree.
git_in_root( ) {
    if ( cd "$ROOT" && git rev-parse --git-dir >/dev/null 2>&1 ); then
        ( cd "$ROOT" && git "$@" )
    elif command -v git.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
        git.exe -C "$( wslpath -w "$ROOT" )" "$@" | tr -d '\r'
    else
        return 1
    fi
}
REV=$( git_in_root rev-parse --short HEAD 2>/dev/null || echo unknown )
[ -n "$REV" ] || REV=unknown
if [ -n "$( git_in_root status --porcelain 2>/dev/null | head -1 )" ]; then
    REV="$REV+dirty"
fi

# The seed the lock pins -- what build/build.sh builds the compiler with unless TIKO_SEED
# or TIKO_ORACLE_FBC says otherwise, in which case that is recorded instead.
SEED_STATE=$( awk -v h="$HOST" '$1 == h { print $2 " (" $3 ", sha256 " $4 ")" }' "$ROOT/seed/seed.lock" 2>/dev/null )
[ -n "$SEED_STATE" ] || SEED_STATE="none pinned for $HOST"
[ -n "${TIKO_SEED:-}" ] && SEED_STATE="TIKO_SEED=$TIKO_SEED (the lock pins $SEED_STATE)"
[ -z "${TIKO_SEED:-}" ] && [ -n "${TIKO_ORACLE_FBC:-}" ] && SEED_STATE="TIKO_ORACLE_FBC=$TIKO_ORACLE_FBC -- NOT a release build (the lock pins $SEED_STATE)"

# tr: BSD wc and du pad their numbers (macOS), GNU's do not.
NFILES=$( cd "$OUT" && find . -type f ! -name MANIFEST.txt | wc -l | tr -d ' ' )
SIZE=$( du -sh "$OUT" | cut -f1 | tr -d ' ' )

{
    say "tiko toolchain -- $HOST"
    say
    say "packaged       $(date -u '+%Y-%m-%d %H:%M:%SZ')"
    say "from           $ROOT"
    say "commit         $REV"
    say "configuration  $CFG"
    say "targets        $TARGETS"
    say "seed           $SEED_STATE"
    say "headers        $INC_STATE"
    say "MinGW runtime  $MINGW_STATE"
    say "contents       $NFILES files, $SIZE"
    say
    say "-- what is NOT in here -------------------------------------------------"
    say "clang       REQUIRED, not bundled. The compiler runs it for both the"
    say "            .ll -> .o step and the link. Install LLVM, and point at it"
    say "            by setting TIKO_CLANG if it is not at the default"
    say "            $CLANG_DEFAULT."
    if [ "$HOST" = "macos" ]; then
        say "            On macOS: 'brew install llvm'. Homebrew's clang is not put on"
        say "            PATH, and tiko does not need it there."
        say "Xcode's Command Line Tools REQUIRED ('xcode-select --install'): the"
        say "            macOS SDK and Apple's linker, ld64, which every link uses."
        say "Optional, from Homebrew: openssl@3 for std/tls and std/http, and sdl3"
        say "            (sdl3_image, sdl3_ttf, sdl3_mixer) for vendor/SDL3 -- and for tkedit,"
        say "            which links Homebrew's sdl3, sdl3_ttf and sdl3_image and ships none."
        say "A DOWNLOADED ARCHIVE is quarantined by macOS, and its unsigned programs are"
        say "            then refused: 'xattr -dr com.apple.quarantine tiko-macos tkedit'."
    fi
    if [ "$HOST" = "linux-arm64" ]; then
        say "            On aarch64 Linux (Ubuntu 22.04+, Debian 12+, Raspberry Pi OS"
        say "            bookworm): clang 18 or newer -- Ubuntu 24.04's 'apt install clang';"
        say "            on older systems apt.llvm.org's clang-NN and TIKO_CLANG=/usr/bin/clang-NN."
        say "            lld is used when present ('apt install lld'), else the system linker."
        say "            Everything here needs glibc 2.35 or newer (built on Ubuntu 22.04)."
    fi
    say
    say "-- libraries, per target -----------------------------------------------"
    say "lib/<target>/     tiko-rt: libfb.a and libfbmt.a, plus libtkogfx.a"
    say "                  where there is one -- the compiler looks for all"
    say "                  three in the same directory."
    if [ "$HOST" = "windows" ]; then
        say "-target win64 (the MinGW ABI) is not packaged: no lib/win64. The"
        say "                  compiler accepts it; its runtime is built from"
        say "                  lib/rt in tiko-lang, and it links with a MinGW-w64"
        say "                  on PATH."
        say
        say "lib/windows-x86_64/*.lib   MSVC-format import libraries for the Windows"
        say "                  DLLs, built from tiko-lang's lib/implib/*.def by"
        say "                  build/implibs.sh -- the MSVC linker looks for"
        say "                  <name>.lib and would otherwise fall back on an"
        say "                  installed Visual Studio."
        say
        say "import libraries: $IMPLIB_STATE"
    else
        say "Nothing behind lib/<target>/: the C runtime and libc are the system's."
    fi
    say
    say "graphics:$GFX_STATE"
    say
    say "fbcunit (the unit-test library; source in src/fbcunit):$FBCU_STATE"
    say
    say "tkedit         $TKEDIT_STATE"
    say
    say "-- verification --------------------------------------------------------"
    say "Each target below was checked by compiling AND RUNNING a program with"
    say "this tree, using exactly the invocation shown under 'linking'."
    say "$VERIFY_LINES"
    say
    say "-- linking -------------------------------------------------------------"
    say "Nothing has to be passed. tiko appends inc/ to the include search and"
    say "lib/<target>/ to the library search on its own, both relative to the"
    say "executable."
    say
    say "  tiko yourprogram.tiko                 the default, $DEFTARGET"
    for t in $TARGETS; do
        say "  tiko -target $t yourprogram.tiko"
    done
    say
    if [ "$HOST" = "windows" ]; then
        say "GRAPHICS IS windows-x86_64 ONLY. libtkogfx is built for the Microsoft ABI"
        say "and there is no MinGW build of it, so a SCREEN or PSET program links"
        say "on the default target and nowhere else. That is why it is the default."
    elif [ "$HOST" = "macos" ]; then
        say "GRAPHICS IS COCOA, REACHED AT RUN TIME. A program that uses graphics runs"
        say "its main( ) on a thread of its own and AppKit keeps the main one; one that"
        say "never opens a window never touches AppKit. GFX_NULL, or FBGFX=null, draws"
        say "with no window at all."
    elif [ "$HOSTOS" = "linux" ]; then
        say "GRAPHICS USES X11, LOADED WHEN A WINDOW OPENS. libtkogfx dlopens libX11"
        say "(and libXext, libXrandr if present), so a SCREEN program links with no X11"
        say "library and needs an X display only to open its window. GFX_NULL, or"
        say "FBGFX=null, draws with no display at all."
    else
        say "NO GRAPHICS ON THIS HOST. libtkogfx ships for windows-x86_64,"
        say "linux-x86_64 and macos-arm64 only, so a SCREEN or PSET program does not link here:"
        say "fb_Gfx* are undefined."
    fi
    say
    say "A -p of your own is searched BEFORE both, so it can override either."
    say "TIKO_LIBPATH replaces them instead, as TIKO_INCLUDE replaces inc/."
    say
    say "-- licences ------------------------------------------------------------"
    say "licences/ holds tiko's own notices -- the compiler under GPL-2.0+, pkg/"
    say "under GPL-2.0+ with a linking exception, and"
    say "tiko-rt and libtkogfx under LGPL-2.1+ with the static-linking"
    say "exception -- with tiko-rt's provenance, FreeBASIC's own, and on Windows"
    say "mingw-w64's for the import libraries. This tree"
    say "redistributes binaries built from LGPL sources; distributing it"
    say "carries the source-offer obligation."
} > "$OUT/MANIFEST.txt"

note "manifest -> MANIFEST.txt"
# --verify GATES. It recorded FAIL lines in the manifest and then said "ok".
if [ "$DO_VERIFY" = "1" ] && echo "$VERIFY_LINES" | grep -q ' FAIL'; then
    echo "$VERIFY_LINES" | grep ' FAIL' >&2
    note "FAILED -- --verify found a target that does not build and run ($NFILES files, $SIZE)"
    exit 1
fi
note "ok -- $NFILES files, $SIZE"
