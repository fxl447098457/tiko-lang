#!/bin/sh
# implibs.sh -- windows-x86_64's import libraries from COMMITTED .def files, not from fbc.
#
#   build/implibs.sh build  [--defs lib/implib] --out <lib dir>
#   build/implibs.sh export --from <dir of lib*.dll.a> [--to lib/implib] [--only "a b"]
#
# build/mkmsvcimplibs.sh used to regenerate all 843 .lib files at every package run
# from fbc's MinGW lib*.dll.a (a toolchain's lib/win64-fb, a copy of fbc-modern's
# lib/win64), through build/mkmsvcdef.py, and threw the .def files away. Since
# 2026-10-10 the .def files are KEPT, in lib/implib/, and package.sh builds from them:
# the default target's import libraries no longer need fbc's tree to exist.
#
# Why it matters, measured 2026-09-06: without them clang's msvc driver passes
# -libpath for an installed Visual Studio and Windows SDK, so windows-x86_64 linked only
# on a machine with both. Why the format: lld-link reads a GNU import archive, but an
# MSVC short import is a quarter the size (kernel32: 1.5 MB against 365 KB). Why the
# DATA split is the hard part, and how it was got wrong twice: build/mkmsvcdef.py.
#
# export -- ONCE. Runs the same mkmsvcdef.py over the same inputs and KEEPS each
#           <name>.def in --to; copies the GUID/data archives (no exports, R/D
#           symbols -- uuid, dxguid, ...) to --to/static/<name>.lib, their GUID
#           COMDATs turned from SAME_SIZE to ANY (build/comdatany.py: why). Writes
#           --to/EXPORTED.txt with the inputs, the machine, and the counts: the
#           code/data split consults this machine's System32 (mkmsvcdef.py), so the
#           result is a snapshot and is recorded as one. Run it only to pick up a
#           NEW library, and read the .def diff it makes. --only "<name> ..." exports
#           just those libraries and appends a line to EXPORTED.txt instead of
#           rewriting it. --to/ADDED.txt lists exports kept by hand; each export
#           puts them back, so a fresh export reproduces the committed files.
# build  -- EVERY package run. llvm-dlltool per .def, static/*.lib copied through,
#           and each umbrella/<name>/ (below) merged into <name>.lib by llvm-lib.
#           Reads nothing outside --defs. Same command line as mkmsvcimplibs.sh.
#
# AN UMBRELLA LIBRARY spans several DLLs -- ucrt (the api-ms-win-crt-* API sets),
# mincore, windowsapp, runtimeobject (API sets), vfw32 (AVICAP32, AVIFIL32, MSVFW32).
# One .def has one LIBRARY line, so each was once ucrt.def naming 'ucrt.dll', a DLL
# no Windows has: a program linking -lucrt built and then failed to load. Now each is
# umbrella/<name>/<dll>.def, one per DLL. Which DLL an export belongs to is what the
# MinGW archive records: every import member references its group's _head_<g>, and
# the group's tail member defines __<g>_iname and holds the DLL's name. An API set is
# no file in System32; the loader maps it to a host (api-ms-win-crt-* -> ucrtbase.dll),
# so export asks the loader (LoadLibraryEx, no DllMain run), reads the code/data split
# from the host, and leaves out a DLL the loader cannot find.
#
# lib/implib/ is derived from mingw-w64's import libraries: ZPL 2.1, with parts in
# the public domain -- lib/implib/COPYING.MinGW-w64-runtime.txt, which ships with them.

set -e

MODE=${1:-}; [ $# -gt 0 ] && shift
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TREE="$ROOT"; FROM=""; TO="$ROOT/lib/implib"; DEFS="$ROOT/lib/implib"; OUTD=""; ONLY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --tree) shift; TREE="$1" ;;
        --only) shift; ONLY="$1" ;;
        --from) shift; FROM="$1" ;;
        --to)   shift; TO="$1" ;;
        --defs) shift; DEFS="$1" ;;
        --out)  shift; OUTD="$1" ;;
        *) echo "implibs: unknown argument '$1'" >&2; exit 2 ;;
    esac
    shift
done
say( )  { echo "implibs: $*"; }
fail( ) { echo "implibs: FAILED -- $*" >&2; exit 1; }
LLVM=${LLVM_BIN:-"C:/Program Files/LLVM/bin"}
[ -x "$LLVM/llvm-dlltool.exe" ] || [ -x "$LLVM/llvm-dlltool" ] || fail "no llvm-dlltool in $LLVM (set LLVM_BIN)"
DLLTOOL="$LLVM/llvm-dlltool"; [ -x "$DLLTOOL.exe" ] && DLLTOOL="$DLLTOOL.exe"
NM="$LLVM/llvm-nm";           [ -x "$NM.exe" ] && NM="$NM.exe"
STRINGS="$LLVM/llvm-strings"; [ -x "$STRINGS.exe" ] && STRINGS="$STRINGS.exe"
AR="$LLVM/llvm-ar";           [ -x "$AR.exe" ] && AR="$AR.exe"
LIBTOOL="$LLVM/llvm-lib";     [ -x "$LIBTOOL.exe" ] && LIBTOOL="$LIBTOOL.exe"
# A path glued to an option ('-out:<path>') is not converted by MSYS for a native tool.
winpath( ) { cygpath -m "$1" 2>/dev/null || echo "$1"; }
DLLRE='^[A-Za-z0-9_.-]+\.(dll|drv|exe|cpl|ocx|sys|acm)$'

# The hand-kept exports of one .def (ADDED.txt: '<path under --to> <export>'), merged
# into its code exports in mkmsvcdef.py's order.
add_hand( ) {  # $1 .def, $2 its path under --to
    [ -f "$TO/ADDED.txt" ] || return 0
    adds=$(awk -v p="$2" '$1 == p { print "  " $2 }' "$TO/ADDED.txt")
    [ -n "$adds" ] || return 0
    {
        sed -n '1,2p' "$1"
        { sed '1,2d' "$1" | grep -v '  DATA$' || true; echo "$adds"; } | LC_ALL=C sort -u
        sed '1,2d' "$1" | grep '  DATA$' || true
    } > "$1.tmp" && mv "$1.tmp" "$1"
}

# Where the loader finds a DLL: its file in System32, or an API set's host. Prints the
# host's file name, or nothing. DONT_RESOLVE_DLL_REFERENCES: no DllMain runs.
loader_host( ) {
    python -c '
import ctypes, os, sys
from ctypes import wintypes
k = ctypes.WinDLL("kernel32", use_last_error=True)
k.LoadLibraryExW.restype = wintypes.HMODULE
k.LoadLibraryExW.argtypes = [wintypes.LPCWSTR, wintypes.HANDLE, wintypes.DWORD]
k.GetModuleFileNameW.argtypes = [wintypes.HMODULE, wintypes.LPWSTR, wintypes.DWORD]
h = k.LoadLibraryExW(sys.argv[1], None, 0x800 | 0x1)  # SEARCH_SYSTEM32 | DONT_RESOLVE
if h:
    b = ctypes.create_unicode_buffer(1024)
    if k.GetModuleFileNameW(h, b, 1024) and os.path.dirname(b.value).lower() == os.path.join(os.environ["SystemRoot"], "System32").lower():
        print(os.path.basename(b.value))
' "$1"
}

# umbrella <archive> <name> -- one .def per DLL into $TO/umbrella/<name>/. Prints
# "<dlls> <code> <data> <unfound dlls>".
umbrella( ) {
    u_tmp=$(mktemp -d); u_dir="$TO/umbrella/$2"
    rm -rf "$u_dir"; mkdir -p "$u_dir"
    u_ar=$(winpath "$1")
    ( cd "$u_tmp" && "$AR" x "$u_ar" ) || fail "llvm-ar x $1"
    # MEMBER NAMES REPEAT: two groups can draw the same prefix (mincore: 58 names, among
    # them the whole dozh* group of api-ms-win-core-file-l1-2-1 and of authz), and 'x'
    # leaves only the last. Each instance of a repeated name is extracted on its own
    # ('xN <k>') as <k>-<name>, and the map below names it the same way.
    "$AR" t "$u_ar" | tr -d '\r' | sort | uniq -c | awk '$1 > 1 { print $2, $1 }' > "$u_tmp/dups.txt"
    while read -r u_m u_c; do
        u_k=1
        while [ "$u_k" -le "$u_c" ]; do
            mkdir "$u_tmp/n"
            ( cd "$u_tmp/n" && "$AR" xN "$u_k" "$u_ar" "$u_m" ) || fail "llvm-ar xN $u_k $u_m"
            mv "$u_tmp/n/$u_m" "$u_tmp/$u_k-$u_m"; rmdir "$u_tmp/n"
            u_k=$((u_k + 1))
        done
    done < "$u_tmp/dups.txt"
    # S <group> <member>: an import member of the group; T <group> <member>: its tail.
    "$NM" --no-demangle "$1" | tr -d '\r' | awk '
        FILENAME == ARGV[1]             { dup[$1] = 1; next }   # (NR == FNR fails on an empty file)
        /^[^ ]+:$/                      { m = substr($0, 1, length($0) - 1)
                                          if (m in dup) m = (++seen[m]) "-" m
                                          next }
        $1 == "U" && $2 ~ /^_head_/     { g[m] = substr($2, 7) }
        $2 == "I" && $3 ~ /^__imp_/     { imp[m] = 1 }
        $2 == "I" && $3 ~ /^__.+_iname$/ { t = substr($3, 3); print "T", substr(t, 1, length(t) - 6), m }
        END { for (k in g) if (k in imp) print "S", g[k], k }' "$u_tmp/dups.txt" - > "$u_tmp/map.txt"
    u_n=0; u_code=0; u_data=0; u_lost=0; : > "$u_tmp/seen.txt"
    # ONE NAME, TWO DLLS: mincore's ncrypt exports 55 of bcrypt's functions (forwarded),
    # and oleaut32, rpcrt4 and winhttp share a few. The MinGW archive answers with the
    # group that comes FIRST in it -- its symbol table points there, so that is what a
    # MinGW link of -lmincore imports -- and so does this: groups are taken in archive
    # order and a later .def drops a name an earlier one kept. Both DLLs export it.
    for u_g in $(awk '$1 == "T" && !seen[$2]++ { print $2 }' "$u_tmp/map.txt"); do
        u_tail=$(awk -v g="$u_g" '$1 == "T" && $2 == g { print $3; exit }' "$u_tmp/map.txt")
        u_dll=$("$STRINGS" -a "$u_tmp/$u_tail" | tr -d '\r' | grep -i -E "$DLLRE" | head -1)
        [ -n "$u_dll" ] || fail "$2: no DLL name in $u_tail"
        u_host=$(loader_host "$u_dll" | tr -d '\r')
        if [ -z "$u_host" ]; then
            echo "implibs: $2: $u_dll -- the loader finds no such DLL; left out" >&2
            u_lost=$((u_lost + 1)); continue
        fi
        # A real DLL keeps System32's spelling; an API set (host differs) its own name.
        if [ -f "$SYS32/$u_dll" ]; then u_dll=$(basename "$(find "$SYS32" -maxdepth 1 -iname "$u_dll" | head -1)"); fi
        awk -v g="$u_g" '$1 == "S" && $2 == g { print $3 }' "$u_tmp/map.txt" | sort > "$u_tmp/$u_g.rsp"
        ( cd "$u_tmp" && "$AR" rc "$u_g.a" "@$u_g.rsp" ) || fail "llvm-ar rc $u_g"
        u_def="$u_dir/${u_dll%.*}.def"
        [ ! -f "$u_def" ] || fail "$2: two groups name $u_dll"
        python "$TREE/build/mkmsvcdef.py" "$u_tmp/$u_g.a" "$u_host" "$u_def" > /dev/null \
            || fail "$2: mkmsvcdef.py gave nothing for $u_dll ($u_g)"
        # The split was read from the host; the import names the DLL the archive records.
        awk -v dll="$u_dll" 'FILENAME == ARGV[1] { seen[$1] = 1; next }
            FNR == 1 { print "LIBRARY " dll; next }
            FNR == 2 || !($1 in seen)' "$u_tmp/seen.txt" "$u_def" > "$u_def.tmp" && mv "$u_def.tmp" "$u_def"
        add_hand "$u_def" "umbrella/$2/${u_dll%.*}.def"
        if [ "$(wc -l < "$u_def")" -le 2 ]; then
            echo "implibs: $2: $u_dll -- every export is an earlier DLL's; left out" >&2
            rm -f "$u_def"; continue
        fi
        sed -n '3,$s/^  \([^ ]*\).*/\1/p' "$u_def" >> "$u_tmp/seen.txt"
        u_n=$((u_n + 1))
        u_code=$((u_code + $(sed '1,2d' "$u_def" | grep -c -v '  DATA$' || true)))
        u_data=$((u_data + $(grep -c '  DATA$' "$u_def" || true)))
    done
    rm -rf "$u_tmp"
    echo "$u_n $u_code $u_data $u_lost"
}

case "$MODE" in
export)
    [ -n "$TREE" ] && [ -n "$FROM" ] && [ -n "$TO" ] || fail "export needs --from"
    [ -f "$TREE/build/mkmsvcdef.py" ] || fail "no build/mkmsvcdef.py in $TREE"
    [ -d "$FROM" ] || fail "no directory $FROM"
    mkdir -p "$TO/static"
    export LLVM_BIN="$LLVM"
    SYS32=$(cygpath -u "${SYSTEMROOT:-C:\\Windows}")/System32
    made=0; stat=0; empty=0; codes=0; datas=0; umb=0; umbdlls=0; lost=0
    for f in "$FROM"/*.dll.a; do
        [ -f "$f" ] || continue
        name=$(basename "$f" .dll.a); name=${name#lib}
        [ -n "$name" ] || continue
        if [ -n "$ONLY" ]; then
            case " $ONLY " in *" $name "*) ;; *) continue ;; esac
        fi
        # Several tails, several DLLs: an umbrella library (top of this file).
        if [ "$("$NM" --no-demangle "$f" 2>/dev/null | grep -c -E ' I __.+_iname$')" -gt 1 ]; then
            counts=$(umbrella "$f" "$name") || exit 1
            rm -f "$TO/$name.def"
            umb=$((umb + 1))
            umbdlls=$((umbdlls + $(echo "$counts" | cut -d' ' -f1)))
            codes=$((codes + $(echo "$counts" | cut -d' ' -f2)))
            datas=$((datas + $(echo "$counts" | cut -d' ' -f3)))
            lost=$((lost + $(echo "$counts" | cut -d' ' -f4)))
            say "$name: umbrella over $(echo "$counts" | cut -d' ' -f1) DLLs -> umbrella/$name/"
            continue
        fi
        # THE DLL IS WHAT System32 HAS, not always <name>.dll. Taking <name>.dll for
        # every library gave ten .def files a DLL Windows does not have (fixed
        # 2026-11-15): winspool is winspool.drv, d3dcompiler D3DCompiler_47.dll,
        # resutil resutils.dll. The name the MinGW library records is the fallback,
        # NOT the authority -- for twelve it is the DLL's internal export name, absent
        # from System32 (storprop.dll records PROPPAGE.DLL). So: <name>.dll if System32
        # has it, else the recorded name if System32 has that, else <name>.dll. A
        # library recording several DLLs is an umbrella, handled above.
        dll="$name.dll"
        # (A file test, not grep over a listing: on Git Bash 'printf | grep -q' over
        # System32's 4900 names died of SIGPIPE.) find -iname gives System32's spelling.
        if [ ! -f "$SYS32/$dll" ]; then
            rec=$("$STRINGS" -a "$f" | grep -i -E "$DLLRE" | sort -u)
            if [ -n "$rec" ] && [ "$(echo "$rec" | wc -l)" -eq 1 ] && [ -f "$SYS32/$rec" ]; then
                dll=$(basename "$(find "$SYS32" -maxdepth 1 -iname "$rec" | head -1)")
            fi
        fi
        if counts=$(python "$TREE/build/mkmsvcdef.py" "$f" "$dll" "$TO/$name.def" 2>/dev/null); then
            add_hand "$TO/$name.def" "$name.def"
            made=$((made + 1))
            codes=$((codes + $(echo "$counts" | cut -d' ' -f1)))
            datas=$((datas + $(echo "$counts" | cut -d' ' -f2)))
        else
            rm -f "$TO/$name.def"
            if "$NM" "$f" 2>/dev/null | grep -qE '^[0-9a-f]+ [RrDd] '; then
                cp "$f" "$TO/static/$name.lib"; stat=$((stat + 1))
                python "$TREE/build/comdatany.py" "$TO/static/$name.lib" > /dev/null \
                    || fail "comdatany.py could not patch static/$name.lib"
            else
                empty=$((empty + 1))
            fi
        fi
    done
    win=$(cmd.exe //c ver 2>/dev/null | tr -d '\r' | grep -i version | sed 's/.*\[Version \(.*\)\].*/\1/')
    if [ -n "$ONLY" ]; then
        # A partial export amends the record; the full one above it still describes the rest.
        {
            echo
            echo "reexport $(date -u +%Y-%m-%d): $ONLY, from $FROM on Windows ${win:-unknown}"
            echo "          ($made single-DLL .def, $umb umbrella over $umbdlls DLLs, $lost DLLs left out)"
        } >> "$TO/EXPORTED.txt"
        say "--only: $made single-DLL .def, $umb umbrella over $umbdlls DLLs, $stat static, $empty empty, $lost DLLs left out"
        exit 0
    fi
    {
        echo "exported  $(date -u +%Y-%m-%dT%H:%M:%SZ) on $(uname -n 2>/dev/null || echo unknown)"
        echo "from      $FROM"
        echo "tool      $TREE/build/mkmsvcdef.py ($(git -C "$TREE" rev-parse --short=12 HEAD 2>/dev/null || echo '?'))"
        echo "windows   $(cmd.exe //c ver 2>/dev/null | tr -d '\r' | grep -i version || echo unknown)"
        echo "defs      $made single-DLL + $umb umbrella over $umbdlls DLLs ($codes code exports, $datas data exports)"
        echo "left out  $lost DLLs of umbrella libraries the loader does not find"
        echo "static    $stat GUID/data archives copied through, COMDATs SAME_SIZE -> ANY (comdatany.py)"
        echo "empty     $empty import archives with no exports, skipped"
        echo
        echo "The code/data split consulted this machine's System32 DLLs (mkmsvcdef.py)."
        echo "Re-export only to pick up a NEW library; review the .def diff by hand."
    } > "$TO/EXPORTED.txt"
    cat "$TO/EXPORTED.txt"
    ;;
build)
    [ -n "$DEFS" ] && [ -n "$OUTD" ] || fail "build needs --defs and --out"
    [ -d "$DEFS" ] || fail "no directory $DEFS"
    mkdir -p "$OUTD"
    OUTD=$(cd "$OUTD" && pwd)   # absolute: llvm-lib runs from a temporary folder
    made=0; failed=0
    for d in "$DEFS"/*.def; do
        [ -f "$d" ] || continue
        name=$(basename "$d" .def)
        if "$DLLTOOL" -m i386:x86-64 -d "$d" -l "$OUTD/$name.lib" 2>/dev/null; then made=$((made + 1))
        else failed=$((failed + 1)); echo "implibs: FAILED $name" >&2; fi
    done
    # An umbrella: one llvm-dlltool library per DLL, merged by llvm-lib into <name>.lib.
    numb=0
    for u in "$DEFS"/umbrella/*/; do
        [ -d "$u" ] || continue
        name=$(basename "$u"); parts=$(mktemp -d); ok=1
        for d in "$u"*.def; do
            [ -f "$d" ] || continue
            "$DLLTOOL" -m i386:x86-64 -d "$d" -l "$parts/$(basename "$d" .def).lib" 2>/dev/null || { ok=0; break; }
        done
        [ "$ok" = "1" ] && ( cd "$parts" && "$LIBTOOL" -machine:x64 "-out:$(winpath "$OUTD/$name.lib")" *.lib ) \
            && numb=$((numb + 1)) || { failed=$((failed + 1)); echo "implibs: FAILED umbrella $name" >&2; }
        rm -rf "$parts"
    done
    nstat=0
    for s in "$DEFS"/static/*.lib; do [ -f "$s" ] && cp "$s" "$OUTD/" && nstat=$((nstat + 1)); done
    say "$made import libraries from .def, $numb umbrella, $nstat static archives copied, $failed failed -> $OUTD"
    [ "$failed" = "0" ] || exit 1
    ;;
*)
    sed -n '/^set -e/q; 2,$p' "$0"; exit 2 ;;
esac
