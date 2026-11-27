#!/bin/sh
# vendorfetch.sh -- the vendor packages' binaries (tiko-vendor RFC-0002 V9, V11).
#
#   sh build/vendorfetch.sh                    into the tree's own pkg/vendor/*/lib
#   sh build/vendorfetch.sh --out DIR          into DIR/vendor/*/lib (package.sh: $OUT/pkg)
#   sh build/vendorfetch.sh --module sqlite3   one module only
#   sh build/vendorfetch.sh --target android-x86_64|android-arm64
#                                              on Windows: the [android.<n>] (x86_64) or
#                                              [android-arm64.<n>] entries, cross-built with the
#                                              NDK (docs/tiko-android A2, A3)
#
# A vendor package commits its translated headers and a fetch.toml; its binaries are never
# committed. This reads each pkg/vendor/<module>/fetch.toml and, for THIS host's [<os>.<n>]
# entries -- [linux-arm64.<n>] on an aarch64 Linux host (docs/tiko-linux-arm64 D-L4-1), never
# linux's, whose 'copy' entries can be x86-64 binaries -- downloads the pinned archive, checks its SHA-256, and either copies a file out of
# it ('copy': where upstream publishes the binary) or compiles C sources with clang into a
# static archive and/or a shared library ('cbuild': where it does not). A host makes its own
# binaries, as package.sh makes its own toolchain. A 'copy' whose url is a single file, not an
# archive, copies that file. 'script' runs a build script committed in the package
# (tkControls' scintk, SDL3's static libraries, raylib6's Linux .so) and copies what it made; its
# optional 'inputs' -- 'url sha256 url sha256 ...' -- are fetched and verified first, like any
# download, and handed to the script as TIKO_VENDOR_INPUTS (the local paths, in order), with
# TIKO_VENDOR_HOST (windows, linux, macos: the OS, also on linux-arm64; android under --target,
# with TIKO_ANDROID_NDK and TIKO_ANDROID_SDK), TIKO_VENDOR_ARCH (x86_64, arm64) and
# TIKO_VENDOR_CACHE. A 'cbuild' entry's optional
# 'patches' -- files committed in the package, relative to it, applied in order with 'patch -p1'
# inside 'dir' before compiling -- carry upstream fixes no release has yet. Its optional
# 'copies' -- 'from:to' pairs, both relative to 'dir' -- are copied after the patches: the
# files a library ships under one name for builds without its own build system to rename
# (PCRE2's config.h.generic, pcre2.h.generic, pcre2_chartables.c.dist).
#
#   TIKO_VENDOR_CACHE    where downloads are kept (default build/.vendorfetch); one already
#                       there with the right SHA-256 is not downloaded again
#   TIKO_VENDOR_MIRROR   a base URL tried first, by file name -- the tiko-lang release assets
#                       the archives are mirrored as; upstream is the fallback
#   TIKO_CLANG, TIKO_AR   the compiler and archiver ('cbuild'); default the LLVM install on
#                       Windows, clang / llvm-ar (else ar) on Linux and macOS
#   CXX                 the C++ compiler a 'script' entry's script uses; default clang++
#                       beside TIKO_CLANG on Windows, the script's own choice elsewhere
#
# An entry whose outputs are newer than its fetch.toml is skipped, so a rerun does nothing.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/pkg"
ONLY=
XTARGET=
SYSROOTOPT=
die( ) { echo "vendorfetch: $*" >&2; exit 1; }
note( ) { echo "vendorfetch: $*"; }
while [ $# -gt 0 ]; do
    case $1 in
        --out)    OUT=$2;  shift 2 ;;
        --module) ONLY=$2; shift 2 ;;
        --target) XTARGET=$2; shift 2 ;;
        -h|--help) sed -n '2,34p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown option '$1'" ;;
    esac
done
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        # THE FLAVOUR, TIKO_VENDOR_FLAVOUR: 'msvc' (the default) builds the vendor packages
        # with the MSVC ABI and the static C runtime, which needs Visual Studio's
        # libvcruntime.lib and oldnames.lib; 'mingw' builds them with the MinGW-w64
        # toolchain and its own C runtime, and needs no Visual Studio at all. The two are
        # different programs -- the MSVC archives carry /DEFAULTLIB:libcmt.lib and the
        # UCRT's internal __stdio_common_* entry points -- so each has its own tables
        # ([windows.N] and [windows-mingw.N]) and its own file names.
        FLAVOUR=${TIKO_VENDOR_FLAVOUR:-msvc}
        VOS=windows
        TABLES=windows
        # NO CALLING-CONVENTION FLAG: the MinGW C convention is cdecl, which is what
        # clang's MinGW target already uses, and the one library that wants otherwise
        # says so in its own header (cJSON's CJSON_PUBLIC is __stdcall on Windows) --
        # so the archive is decorated ('_cJSON_Delete@4') and the binding names the
        # convention to match.
        if [ "$FLAVOUR" = mingw ]; then
            TABLES=windows-mingw
            VARCH=${TIKO_VENDOR_ARCH:-x86_64}
            case "$VARCH" in
                x86)   TABLES=windows-mingw-x86; TRIPLE=i686-w64-mingw32 ;;
                *)     TRIPLE=x86_64-w64-mingw32 ;;
            esac
            # THE SYSROOT IS NAMED, because clang does not find the i686 one by itself:
            # a clang.cfg beside it pins the 64-bit root, and the 64-bit root has no i686
            # headers ('stdio.h' file not found, measured).
            [ -n "${TIKO_MINGW_ROOT:-}" ] && SYSROOTOPT="--sysroot=$TIKO_MINGW_ROOT"
        else
            TRIPLE=x86_64-pc-windows-msvc; VARCH=x86_64
        fi
        HOST=windows
        CLANG=${TIKO_CLANG:-"C:/Program Files/LLVM/bin/clang.exe"}
        AR=${TIKO_AR:-"$(dirname "$CLANG")/llvm-ar.exe"}
        [ -n "$CXX" ] || CXX="$(dirname "$CLANG")/clang++.exe"; export CXX ;;
    Linux)
        HOST=linux; TRIPLE=x86_64-pc-linux-gnu; VOS=linux; VARCH=x86_64
        if [ "$(uname -m)" = aarch64 ]; then
            HOST=linux-arm64; TRIPLE=aarch64-unknown-linux-gnu; VARCH=arm64
        fi
        CLANG=${TIKO_CLANG:-${CLANG:-clang}}
        AR=${TIKO_AR:-$(command -v llvm-ar || command -v ar)} ;;
    Darwin)
        # The SDK is clang's own business here: Apple's clang (and Homebrew's) find it.
        HOST=macos; TRIPLE=arm64-apple-macosx13.0; VOS=macos; VARCH=arm64
        CLANG=${TIKO_CLANG:-${CLANG:-clang}}
        AR=${TIKO_AR:-$(command -v llvm-ar || command -v ar)} ;;
    *) die "unsupported host '$(uname -s)'" ;;
esac
# A CROSS TARGET: Android, from Windows. Its C sources need Bionic's headers, so clang gets the
# NDK's sysroot (the NDK found as the compiler finds it: TIKO_ANDROID_NDK, ANDROID_NDK_HOME,
# ANDROID_NDK_ROOT, then the highest <sdk>/ndk/<version>), and the archive is static.
case "$XTARGET" in
    "") ;;
    android-x86_64|android-arm64)
        [ "$HOST" = windows ] || die "--target $XTARGET runs from Windows"
        # The cross target selects its own tables, even if the host defaults named a Windows
        # flavour above; the NDK sysroot replaces any MinGW one.
        TABLES=
        _sdk=${ANDROID_HOME:-${LOCALAPPDATA:-}/Android/Sdk}
        _ndk=${TIKO_ANDROID_NDK:-${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-$(ls -d "$_sdk"/ndk/* 2>/dev/null | sort -V | tail -1)}}}
        _sr=$_ndk/toolchains/llvm/prebuilt/windows-x86_64/sysroot
        [ -f "$_sr/usr/include/stdio.h" ] || die "no Android NDK sysroot at '$_sr' (set ANDROID_NDK_HOME)"
        command -v cygpath > /dev/null 2>&1 && _sr=$(cygpath -m "$_sr")
        if [ "$XTARGET" = android-arm64 ]; then
            HOST=android-arm64; TRIPLE=aarch64-linux-android29; VARCH=arm64
        else
            HOST=android; TRIPLE=x86_64-linux-android29; VARCH=x86_64
        fi
        # A 'script' entry (SDL3's CMake build, A4) gets the OS as android and the NDK and SDK
        # themselves: CMake takes the NDK's toolchain file, and SDL's Java is compiled against
        # the SDK's android.jar.
        VOS=android
        TIKO_ANDROID_NDK=$(cygpath -m "$_ndk" 2>/dev/null || printf '%s' "$_ndk")
        TIKO_ANDROID_SDK=$(cygpath -m "$_sdk" 2>/dev/null || printf '%s' "$_sdk")
        export TIKO_ANDROID_NDK TIKO_ANDROID_SDK
        SYSROOTOPT="--sysroot=$_sr" ;;
    *) die "--target: android-x86_64 and android-arm64 are the cross targets" ;;
esac
CACHE=${TIKO_VENDOR_CACHE:-$ROOT/build/.vendorfetch}
mkdir -p "$CACHE"

# fetch.toml as 'table<TAB>key<TAB>value' lines: the subset this file's header describes --
# comments, [table] headers, key = "string".
toml( ) {
    awk '
        /^[ \t]*(#|$)/ { next }
        /^[ \t]*\[/ { t = $0; gsub( /^[ \t]*\[|\][ \t]*$/, "", t ); next }
        {
            k = $0; sub( /[ \t]*=.*/, "", k ); gsub( /^[ \t]+/, "", k )
            v = $0; sub( /^[^=]*=[ \t]*"/, "", v ); sub( /"[ \t]*(#.*)?$/, "", v )
            printf "%s\t%s\t%s\n", t, k, v
        }' "$1" | tr -d '\r'
}

# macOS has no sha256sum; its shasum is the same digest.
if command -v sha256sum >/dev/null 2>&1; then
    sha_of( ) { sha256sum "$1" | cut -d' ' -f1; }
else
    sha_of( ) { shasum -a 256 "$1" | cut -d' ' -f1; }
fi

# is_archive <url>: true for what unpack opens.
is_archive( ) { case "$1" in *.zip|*.tar.gz|*.tgz) return 0 ;; *) return 1 ;; esac; }

# fetch <url> <sha256>: the archive, in the cache, verified; its path printed. A single file is
# kept under its SHA-256's first 12 digits as well as its name: two packages' LICENSE files
# must not take each other's place.
fetch( ) {
    _f="$CACHE/${1##*/}"
    is_archive "$1" || _f="$CACHE/$(printf '%.12s' "$2")-${1##*/}"
    if [ ! -f "$_f" ] || [ "$(sha_of "$_f")" != "$2" ]; then
        rm -f "$_f"
        if [ -n "$TIKO_VENDOR_MIRROR" ]; then
            curl -fsSL -o "$_f" "${TIKO_VENDOR_MIRROR%/}/${1##*/}" || rm -f "$_f"
        fi
        [ -f "$_f" ] || curl -fsSL -o "$_f" "$1" || die "cannot download $1"
    fi
    [ "$(sha_of "$_f")" = "$2" ] || { rm -f "$_f"; die "${1##*/}: SHA-256 is not $2"; }
    printf '%s\n' "$_f"
}

# unpack <archive>: into a fresh directory, printed.
unpack( ) {
    _x="$CACHE/x/$(basename "$1")"
    rm -rf "$_x"; mkdir -p "$_x"
    case "$1" in
        *.zip) unzip -q "$1" -d "$_x" ;;
        *)     tar -xzf "$1" -C "$_x" ;;
    esac
    printf '%s\n' "$_x"
}

# One entry: the table's keys, then what its kind makes.
entry( ) {
    _mod=$1; _mdir=$2; _toml=$3; _tab=$4
    _get( ) { toml "$_toml" | awk -F'\t' -v t="$_tab" -v k="$1" '$1 == t && $2 == k { print $3; exit }'; }
    _kind=$(_get kind); _url=$(_get url); _sha=$(_get sha256)
    if [ "$_kind" = script ]; then
        # THE SCRIPT IS RUN EVERY TIME: it is incremental itself, and the freshness test below
        # sees only fetch.toml, not the sources the script compiles.
        _scr="$ROOT/pkg/vendor/$_mod/$(_get script)"; _from="$ROOT/pkg/vendor/$_mod/$(_get from)"; _to=$(_get to)
        [ -f "$_scr" ] && [ -n "$_to" ] || die "$_mod [$_tab]: 'script' needs script, from and to"
        TIKO_VENDOR_INPUTS=
        set -- $(_get inputs)
        while [ $# -ge 2 ]; do
            TIKO_VENDOR_INPUTS="$TIKO_VENDOR_INPUTS $(fetch "$1" "$2")"
            shift 2
        done
        [ $# -eq 0 ] || die "$_mod [$_tab]: 'inputs' must be url sha256 pairs"
        export TIKO_VENDOR_INPUTS TIKO_VENDOR_HOST=$VOS TIKO_VENDOR_ARCH=$VARCH TIKO_VENDOR_CACHE=$CACHE
        export TIKO_VENDOR_FLAVOUR=${FLAVOUR:-msvc}
        bash "$_scr" >/dev/null || die "$_mod [$_tab]: $(_get script) failed"
        [ -f "$_from" ] || die "$_mod [$_tab]: $(_get script) made no $(_get from)"
        mkdir -p "$(dirname "$_mdir/$_to")"
        cp -f "$_from" "$_mdir/$_to"
        note "$_mod [$_tab]: $_to"
        return
    fi
    [ -n "$_url" ] && [ -n "$_sha" ] || die "$_mod [$_tab]: needs url and sha256"
    _outs=
    case $_kind in
        copy)   _outs=$(_get to) ;;
        cbuild) _outs="$(_get static) $(_get shared)" ;;
        *) die "$_mod [$_tab]: kind is 'copy', 'cbuild' or 'script', not '$_kind'" ;;
    esac
    # A PATCH IS AN INPUT TOO: one newer than an output rebuilds it, as fetch.toml does.
    _pats=
    for _p in $(_get patches); do
        [ "$_kind" = cbuild ] || die "$_mod [$_tab]: 'patches' is for 'cbuild' entries"
        [ -f "$ROOT/pkg/vendor/$_mod/$_p" ] || die "$_mod [$_tab]: patch '$_p' is not in the package"
        _pats="$_pats $ROOT/pkg/vendor/$_mod/$_p"
    done
    _fresh=1
    for _o in $_outs; do
        if [ ! -f "$_mdir/$_o" ] || [ "$_toml" -nt "$_mdir/$_o" ]; then _fresh=0; fi
        for _p in $_pats; do [ "$_p" -nt "$_mdir/$_o" ] && _fresh=0; done
    done
    if [ "$_fresh" = 1 ]; then note "$_mod [$_tab]: up to date"; return; fi
    _dl=$(fetch "$_url" "$_sha")
    if [ "$_kind" = copy ] && ! is_archive "$_url"; then
        _to=$(_get to)
        mkdir -p "$(dirname "$_mdir/$_to")"
        cp -f "$_dl" "$_mdir/$_to"
        note "$_mod [$_tab]: $_to"
        return
    fi
    _x=$(unpack "$_dl")
    case $_kind in
    copy)
        _from=$(_get from); _to=$(_get to)
        # with a folder in it, a path's end; else a name anywhere (GNU find warns that -name
        # never matches a pattern with a '/')
        case $_from in
        */*) _src=$(find "$_x" -path "*/$_from" | head -1) ;;
        *)   _src=$(find "$_x" -name "$_from" | head -1) ;;
        esac
        [ -n "$_src" ] && [ -f "$_src" ] || die "$_mod [$_tab]: '$_from' is not in ${_url##*/}"
        mkdir -p "$(dirname "$_mdir/$_to")"
        cp -f "$_src" "$_mdir/$_to"
        note "$_mod [$_tab]: $_to"
        ;;
    cbuild)
        _dir="$_x/$(_get dir)"; _objs=
        for _p in $_pats; do
            patch -p1 -s -t -d "$_dir" -i "$_p" || die "$_mod: patch $(basename "$_p") does not apply"
            note "$_mod [$_tab]: patched with $(basename "$_p")"
        done
        for _c in $(_get copies); do
            case $_c in *:*) ;; *) die "$_mod [$_tab]: a 'copies' entry is 'from:to', not '$_c'" ;; esac
            [ -f "$_dir/${_c%%:*}" ] || die "$_mod [$_tab]: '${_c%%:*}' is not in ${_url##*/}"
            cp -f "$_dir/${_c%%:*}" "$_dir/${_c#*:}"
        done
        for _s in $(_get sources); do
            _o="$_x/$(basename "$_s" .c).o"
            # shellcheck disable=SC2046
            "$CLANG" --target=$TRIPLE $SYSROOTOPT $(_get cflags) -c "$_dir/$_s" -o "$_o" || die "$_mod: clang failed on $_s"
            _objs="$_objs $_o"
        done
        _st=$(_get static); _sh=$(_get shared)
        if [ -n "$_st" ]; then
            mkdir -p "$(dirname "$_mdir/$_st")"; rm -f "$_mdir/$_st"
            # shellcheck disable=SC2086
            "$AR" rcs "$_mdir/$_st" $_objs || die "$_mod: archiving $_st failed"
            note "$_mod [$_tab]: $_st"
        fi
        if [ -n "$_sh" ]; then
            mkdir -p "$(dirname "$_mdir/$_sh")"
            if [ "$HOST" = windows ]; then
                # A DLL, with lld. Its import library and .exp stay in the unpack directory:
                # beside the DLL, '#foreignlib ... dynamic' would find the .lib first. The
                # sources must dllexport what the DLL exports -- their cflags say how.
                # -implib:, not /implib: -- MSYS would rewrite a leading slash as a path.
                _imp="$(cygpath -m "$_x" 2>/dev/null || printf '%s' "$_x")/$(basename "$_sh" .dll).lib"
                _implibopt=-Wl,-implib:
                _sharedrt=
                case "$TRIPLE" in
                    *-windows-msvc) ;;
                    *) _implibopt=-Wl,--out-implib,
                       case "$TRIPLE" in i686-*) _mgcc=i686-w64-mingw32-gcc.exe ;; *) _mgcc=x86_64-w64-mingw32-gcc.exe ;; esac
                       _libgcc=$("$TIKO_MINGW_ROOT/bin/$_mgcc" -print-libgcc-file-name)
                       # i686 clang can otherwise bind the division helpers through
                       # libgcc_s's import DLL; link the real libgcc objects instead.
                       _divobjs=
                       for _member in _divdi3.o _udivdi3.o _moddi3.o _umoddi3.o; do
                           if "$AR" t "$_libgcc" | tr -d '\r' | grep -qx "$_member"; then
                               ( cd "$_x" && "$AR" x "$_libgcc" "$_member" )
                               _divobjs="$_divobjs $_x/$_member"
                           fi
                       done
                       _sharedrt="$_divobjs -static-libstdc++ -Wl,-Bstatic -lgcc -lgcc_eh -lwinpthread -Wl,-Bdynamic" ;;
                esac
                # shellcheck disable=SC2086
                "$CLANG" --target=$TRIPLE $SYSROOTOPT -shared -fuse-ld=lld -o "$_mdir/$_sh" \
                    "$_implibopt$_imp" \
                    $_objs $(_get libs) $_sharedrt || die "$_mod: linking $_sh failed"
            elif [ "$HOST" = macos ]; then
                # THE INSTALL NAME IS @rpath/<its own name>, the soname's counterpart: a program
                # records it, and finds the copy beside it through its '@loader_path' run path.
                # shellcheck disable=SC2086
                "$CLANG" --target=$TRIPLE -dynamiclib -Wl,-install_name,"@rpath/$(basename "$_sh")" \
                    -o "$_mdir/$_sh" $_objs $(_get libs) || die "$_mod: linking $_sh failed"
            else
                # THE SONAME IS THE FILE'S OWN NAME: a program records it as NEEDED, and the
                # copy tiko puts beside the program (RFC-0002 V13) is found by it through $ORIGIN.
                # shellcheck disable=SC2086
                "$CLANG" --target=$TRIPLE -shared -Wl,-soname,"$(basename "$_sh")" -o "$_mdir/$_sh" \
                    $_objs $(_get libs) || die "$_mod: linking $_sh failed"
            fi
            note "$_mod [$_tab]: $_sh"
        fi
        ;;
    esac
}

_n=0
for _ft in "$ROOT"/pkg/vendor/*/fetch.toml; do
    [ -f "$_ft" ] || continue
    _mod=$(basename "$(dirname "$_ft")")
    [ -z "$ONLY" ] || [ "$ONLY" = "$_mod" ] || continue
    _mdir="$OUT/vendor/$_mod"
    mkdir -p "$_mdir"
    for _tab in $(toml "$_ft" | cut -f1 | grep "^${TABLES:-$HOST}\." | sort -u); do
        entry "$_mod" "$_mdir" "$_ft" "$_tab"
        _n=$(( _n + 1 ))
    done
done
note "$_n entries for $HOST -> $OUT/vendor"
