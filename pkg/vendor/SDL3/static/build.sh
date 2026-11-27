#!/bin/bash
# Build vendor/SDL3's STATIC libraries -- SDL3, SDL3_ttf (with FreeType and HarfBuzz folded into
# its archive) and SDL3_image (stb backend) -- for '#import "vendor/SDL3" link static' and its
# satellites; on Windows also the DLLs 'link dynamic' uses -- SDL3.dll, SDL3_ttf.dll (FreeType
# and HarfBuzz linked in) and SDL3_image.dll -- from the same sources, because upstream's prebuilt
# SDL3_ttf.dll carries FreeType 2.13.2 and no SDL_image release has the LBM fix (../fetch.toml,
# THE SOURCES). Run by build/vendorfetch.sh ('script' entries in ../fetch.toml), which downloads
# and verifies the pinned sources and passes them as TIKO_VENDOR_INPUTS, in this order:
#
#   SDL3  SDL3_ttf  SDL3_image  freetype  harfbuzz
#
# SDL publishes no static library, so each host builds its own, with CMake and Ninja:
#   windows  clang/clang++ for x86_64-pc-windows-msvc, the static C runtime (/MT) -- a program
#            linking these needs Visual Studio's libvcruntime.lib and oldnames.lib, as any
#            static C++ on that target does
#   linux    gcc/g++, position-independent; X11, Wayland, GL and audio stay dlopen'd by SDL
#   macos    Apple clang, arm64, macOS 13.0
#   android  from Windows (vendorfetch.sh --target android-x86_64|android-arm64): the NDK's own
#            clang through its CMake toolchain file, API 29, libc++ static, position-independent
#            (the archives go into a program's libmain.so). Also classes.dex: SDL's Java glue
#            (android-project's org.libsdl.app) and org.tiko.app.TikoActivity (android/ here),
#            compiled once against the SDK's newest android.jar, so an app build never runs javac
#            (docs/tiko-android A4, D-A4-6)
# Output: bin/<host>/{SDL3,SDL3_ttf,SDL3_image}_<host>_<arch>.a beside this script, and on Windows
# bin/windows/{SDL3,SDL3_ttf,SDL3_image}.dll -- /MT too, so they need no Visual C++
# redistributable. The build trees live under TIKO_VENDOR_CACHE. Incremental: a stamp of the
# inputs and this script.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
HOST=${TIKO_VENDOR_HOST:?run me through build/vendorfetch.sh}
CACHE=${TIKO_VENDOR_CACHE:?run me through build/vendorfetch.sh}
set -- $TIKO_VENDOR_INPUTS
[ $# -eq 5 ] || { echo "SDL3 static: expected 5 inputs, got $#" >&2; exit 1; }
SRC_SDL=$1; SRC_TTF=$2; SRC_IMG=$3; SRC_FT=$4; SRC_HB=$5

case $HOST in
    windows) ARCH=x86_64 ;;
    linux)   ARCH=${TIKO_VENDOR_ARCH:-x86_64} ;;   # arm64 on linux-arm64 (docs/tiko-linux-arm64 L4)
    macos)   ARCH=arm64 ;;
    android) ARCH=${TIKO_VENDOR_ARCH:-x86_64} ;;
    *) echo "SDL3 static: unknown host '$HOST'" >&2; exit 1 ;;
esac
# THE FLAVOUR, TIKO_VENDOR_FLAVOUR: 'msvc' (the default) builds the MSVC ABI against the
# static C runtime (/MT), which is what needs Visual Studio's libvcruntime.lib and
# oldnames.lib. 'mingw' builds the MinGW ABI with the MinGW-w64 GCC toolchain and its own
# C runtime (msvcrt.dll) and needs no Visual Studio at all. The two archives are named
# apart -- ..._<flavour>.a -- because they are different programs: the MSVC one carries
# /DEFAULTLIB:libcmt.lib and the UCRT's internal __stdio_common_* entry points, neither of
# which the MinGW C runtime has.
FLAVOUR=${TIKO_VENDOR_FLAVOUR:-msvc}
if [ "$HOST" = windows ] && [ "$FLAVOUR" = mingw ]; then
    ARCH=${TIKO_VENDOR_ARCH:-x86_64}
    FLAVOUR_TAG=_mingw
else
    FLAVOUR_TAG=
fi
OUT=$HERE/bin/$HOST
# Android's two architectures are built on ONE host, so each gets its own directory and stamp.
[ "$HOST" = android ] && OUT=$HERE/bin/android-$ARCH
OUTS="$OUT/SDL3_${HOST}_$ARCH$FLAVOUR_TAG.a $OUT/SDL3_ttf_${HOST}_$ARCH$FLAVOUR_TAG.a $OUT/SDL3_image_${HOST}_$ARCH$FLAVOUR_TAG.a"
[ "$HOST" = windows ] && [ "$FLAVOUR" = msvc ] && OUTS="$OUTS $OUT/SDL3.dll $OUT/SDL3_ttf.dll $OUT/SDL3_image.dll"
[ "$HOST" = windows ] && [ "$FLAVOUR" = mingw ] && \
    OUTS="$OUTS $OUT/SDL3_${HOST}_${ARCH}_mingw.dll $OUT/SDL3_ttf_${HOST}_${ARCH}_mingw.dll $OUT/SDL3_image_${HOST}_${ARCH}_mingw.dll"
[ "$HOST" = android ] && OUTS="$OUTS $OUT/classes.dex"
JAVA_TIKO=$HERE/android/org/tiko/app/TikoActivity.java

# macOS has no sha256sum; its shasum is the same digest.
digest() { if command -v sha256sum >/dev/null; then sha256sum; else shasum -a 256; fi; }
STAMP=$( { for f in "$@"; do basename "$f"; done; cat "$0"; [ "$HOST" = android ] && cat "$JAVA_TIKO"; echo "$HOST"; [ "$HOST" = windows ] && echo "$FLAVOUR"; [ "$HOST" = windows ] && [ "$FLAVOUR" = mingw ] && echo "$TIKO_MINGW_ROOT"; [ "$ARCH" = x86_64 ] || echo "$ARCH"; } | digest | cut -c1-16 )
fresh=1
for o in $OUTS; do [ -f "$o" ] || fresh=0; done
[ "$fresh" = 1 ] && [ "$(cat "$OUT/.stamp" 2>/dev/null)" = "$STAMP" ] && exit 0
# A FINISHED BUILD IN THE CACHE is copied, not redone: a fresh tree (a test copy, a package
# worktree) finds the archives the last identical build left there.
W=$CACHE/sdl3-static-$HOST
[ "$HOST" = linux ] && [ "$ARCH" != x86_64 ] && W=$CACHE/sdl3-static-$HOST-$ARCH
[ "$HOST" = windows ] && [ "$FLAVOUR" = mingw ] && W=$W-mingw
[ "$HOST" = android ] && W=$CACHE/sdl3-static-android-$ARCH
if [ "$(cat "$W/done/.stamp" 2>/dev/null)" = "$STAMP" ]; then
    mkdir -p "$OUT"
    for o in $OUTS; do cp -f "$W/done/$(basename "$o")" "$o" || exit 1; done
    echo "$STAMP" > "$OUT/.stamp"
    exit 0
fi

command -v cmake >/dev/null || { echo "SDL3 static: cmake is not on PATH" >&2; exit 1; }
command -v ninja >/dev/null || { echo "SDL3 static: ninja is not on PATH" >&2; exit 1; }

rm -rf "$W"; mkdir -p "$W/src" "$OUT"
LOG=$W/build.log
# Xcode/ is left out: a commit archive (SDL_image's) carries framework symlinks MSYS tar cannot
# make, and CMake never reads it.
for f in "$@"; do tar -xf "$f" -C "$W/src" --exclude='*/Xcode'; done
dir_of() { find "$W/src" -maxdepth 1 -type d -name "$1" | head -1; }
# SDL_image comes from a commit's archive (SDL_image-<sha>), not a release's (SDL3_image-<ver>).
SRCDIR_IMG=$(dir_of 'SDL3_image-*'); [ -n "$SRCDIR_IMG" ] || SRCDIR_IMG=$(dir_of 'SDL_image-*')
if [ "$HOST" = windows ] && [ "$FLAVOUR" = mingw ]; then
    # Name the shared target itself, so SDL3_ttf/image's import tables and the
    # installed CMake target all refer to the architecture-qualified DLL.
    sed -i "s/OUTPUT_NAME \"SDL3\"/OUTPUT_NAME \"SDL3_${HOST}_${ARCH}_mingw\"/g" \
        "$(dir_of 'SDL3-*')/CMakeLists.txt"
    sed -i 's/set(harfbuzz_link_libraries Threads::Threads)/set(harfbuzz_link_libraries "-Wl,-Bstatic" winpthread "-Wl,-Bdynamic")/' \
        "$(dir_of 'SDL3_ttf-*')/CMakeLists.txt"
    hb_static=$(cygpath -m "$W/inst/lib/libharfbuzz.a")
    sed -i "s|set(harfbuzz_link_libraries harfbuzz::harfbuzz)|set(harfbuzz_link_libraries \"$hb_static\" \"-Wl,-Bstatic\" winpthread \"-Wl,-Bdynamic\")|" \
        "$(dir_of 'SDL3_ttf-*')/CMakeLists.txt"
fi

C=(-G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF
   -DCMAKE_INSTALL_PREFIX="$W/inst" -DCMAKE_PREFIX_PATH="$W/inst" -DCMAKE_INSTALL_LIBDIR=lib
   -DCMAKE_POLICY_VERSION_MINIMUM=3.5)
case $HOST in
windows)
    if [ "$FLAVOUR" = mingw ]; then
        # THE MinGW TOOLCHAIN: the MinGW-w64 GCC, which CMake drives natively (no
        # toolchain file, no cross-compiling). TIKO_MINGW_ROOT is the tree that decides
        # the width as well as the runtime: mingw64 or mingw32.
        MG=${TIKO_MINGW_ROOT:?SDL3 static: the MinGW tree is TIKO_MINGW_ROOT}
        C+=(-DCMAKE_C_COMPILER="$MG/bin/gcc.exe" -DCMAKE_CXX_COMPILER="$MG/bin/g++.exe"
            -DCMAKE_RC_COMPILER="$MG/bin/windres.exe"
            -DCMAKE_C_FLAGS="-I$(cygpath -m "$W/inst/include/harfbuzz")"
            -DCMAKE_SHARED_LINKER_FLAGS="-static-libstdc++ -static-libgcc -Wl,-Bstatic -lwinpthread -Wl,-Bdynamic"
            -DCMAKE_CXX_STANDARD_LIBRARIES="-static-libstdc++ -static-libgcc -Wl,-Bstatic -lwinpthread -Wl,-Bdynamic")
    else
    CL=$(cygpath -m "${TIKO_CLANG:-C:/Program Files/LLVM/bin/clang.exe}")
    C+=(-DCMAKE_C_COMPILER="$CL" -DCMAKE_CXX_COMPILER="$(dirname "$CL")/clang++.exe"
        -DCMAKE_RC_COMPILER="$(dirname "$CL")/llvm-rc.exe"
        -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded -DCMAKE_POLICY_DEFAULT_CMP0091=NEW)
    fi ;;
    # The RC compiler named, or CMake finds one on the PATH only -- and an LLVM install that leaves
    # its bin off the PATH (LLVM 23's did) fails every configure: "No CMAKE_RC_COMPILER".
    # CMP0091 NEW, or a project with an old cmake_minimum_required (HarfBuzz) ignores the runtime
    # library and builds /MD -- which lld-link then refuses beside /MT objects (failifmismatch).
linux)
    C+=(-DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_POSITION_INDEPENDENT_CODE=ON) ;;
macos)
    C+=(-DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++
        -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 -DCMAKE_OSX_ARCHITECTURES=arm64
        -DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF) ;;
android)
    NDK=${TIKO_ANDROID_NDK:?run me through build/vendorfetch.sh --target android-...}
    case $ARCH in x86_64) ABI=x86_64 ;; arm64) ABI=arm64-v8a ;; *) echo "SDL3 static: android arch '$ARCH'" >&2; exit 1 ;; esac
    C+=(-DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" -DANDROID_ABI=$ABI
        -DANDROID_PLATFORM=android-29 -DANDROID_STL=c++_static -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        # The toolchain file confines find_package to the sysroot (FIND_ROOT_PATH_MODE ONLY), so
        # the satellites could not see FreeType and SDL3 under W/inst: it is a root too.
        -DCMAKE_FIND_ROOT_PATH="$(cygpath -m "$W/inst")") ;;
esac

step() {     # step <name> <source dir> <cmake args...>
    local n=$1 s=$2; shift 2
    echo "== $n" >> "$LOG"
    if ! { cmake -S "$s" -B "$W/b-$n" "${C[@]}" "$@" && cmake --build "$W/b-$n" && cmake --install "$W/b-$n"; } >> "$LOG" 2>&1; then
        echo "SDL3 static: $n failed ($LOG)" >&2; tail -20 "$LOG" >&2; exit 1
    fi
}

# X11 screensaver and XTest need development packages a build host may lack; neither is used.
SDLX=(); [ "$HOST" = linux ] && SDLX=(-DSDL_X11_XSCRNSAVER=OFF -DSDL_X11_XTEST=OFF)
# SDL3.jar is SDL's own packaging of the Java glue; classes.dex below replaces it.
[ "$HOST" = android ] && SDLX=(-DSDL_ANDROID_JAR=OFF)
step sdl "$(dir_of 'SDL3-*')" -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_TEST_LIBRARY=OFF -DSDL_EXAMPLES=OFF "${SDLX[@]}"
step ft "$(dir_of 'freetype-*')" -DFT_DISABLE_ZLIB=ON -DFT_DISABLE_BZIP2=ON -DFT_DISABLE_PNG=ON \
     -DFT_DISABLE_BROTLI=ON -DFT_DISABLE_HARFBUZZ=ON
HBTHREAD=()
[ "$HOST" = windows ] && [ "$FLAVOUR" = msvc ] && HBTHREAD=(-DCMAKE_DISABLE_FIND_PACKAGE_Threads=ON)
step hb "$(dir_of 'harfbuzz-*')" -DHB_HAVE_FREETYPE=ON -DHB_HAVE_GLIB=OFF -DHB_HAVE_ICU=OFF \
     -DHB_HAVE_CORETEXT=OFF -DHB_BUILD_SUBSET=OFF -DHB_BUILD_UTILS=OFF -DHB_BUILD_TESTS=OFF "${HBTHREAD[@]}"
TTFX=(-DSDLTTF_VENDORED=OFF -DSDLTTF_HARFBUZZ=ON -DSDLTTF_PLUTOSVG=OFF -DSDLTTF_SAMPLES=OFF)
IMGX=(-DSDLIMAGE_VENDORED=OFF -DSDLIMAGE_BACKEND_STB=ON -DSDLIMAGE_BACKEND_IMAGEIO=OFF
      -DSDLIMAGE_BACKEND_WIC=OFF -DSDLIMAGE_AVIF=OFF -DSDLIMAGE_JXL=OFF -DSDLIMAGE_TIF=OFF
      -DSDLIMAGE_WEBP=OFF -DSDLIMAGE_SAMPLES=OFF -DSDLIMAGE_TESTS=OFF)
step ttf "$(dir_of 'SDL3_ttf-*')" "${TTFX[@]}"
step img "$SRCDIR_IMG" "${IMGX[@]}"

# WINDOWS' DLLS: an SDL build of their own, shared only, so the static archive above never holds
# dllexport objects; and an install prefix of their own (W/dll), because a shared SDL3_ttf's
# import library has the static one's name. They link the static FreeType and HarfBuzz in W/inst.
if [ "$HOST" = windows ]; then
    WM=$(cygpath -m "$W")
    D=(-DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX="$WM/dll" -DCMAKE_PREFIX_PATH="$WM/dll;$WM/inst")
    step sdl-dll "$(dir_of 'SDL3-*')" "${D[@]}" -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TEST_LIBRARY=OFF \
         -DSDL_EXAMPLES=OFF
    step ttf-dll "$(dir_of 'SDL3_ttf-*')" "${D[@]}" "${TTFX[@]}"
    step img-dll "$SRCDIR_IMG" "${D[@]}" "${IMGX[@]}"
fi

lib_of() { find "$W/inst/lib" -maxdepth 1 \( -name "$1.lib" -o -name "$1-static.lib" -o -name "lib$1.a" \) | head -1; }
L_SDL=$(lib_of SDL3); L_TTF=$(lib_of SDL3_ttf); L_IMG=$(lib_of SDL3_image)
L_FT=$(lib_of freetype); L_HB=$(lib_of harfbuzz)
for l in "$L_SDL" "$L_TTF" "$L_IMG" "$L_FT" "$L_HB"; do
    [ -n "$l" ] && [ -f "$l" ] || { echo "SDL3 static: a library is missing under $W/inst/lib" >&2; ls "$W/inst/lib" >&2; exit 1; }
done

# ONE ARCHIVE FOR SDL3_ttf, with FreeType and HarfBuzz inside: the module names one file.
TTF=$OUT/SDL3_ttf_${HOST}_$ARCH$FLAVOUR_TAG.a
rm -f "$TTF"
case $HOST in
windows)
    if [ "$FLAVOUR" = mingw ]; then
        # GNU ar does NOT MERGE ARCHIVES: 'ar rcs out.a a.a b.a' stores those two .a files
        # AS MEMBERS of out.a, and the linker never looks inside them -- the result links
        # nothing (measured: every TTF_* symbol undefined). The members are extracted and
        # added one by one, each with its own prefix so two archives' objects cannot
        # collide on a name.
        rm -rf "$W/ttfmerge"; mkdir -p "$W/ttfmerge"; cd "$W/ttfmerge"
        i=0
        for a in "$L_TTF" "$L_FT" "$L_HB"; do
            i=$((i + 1)); d="m$i"; mkdir -p "$d"
            ( cd "$d" && ar x "$a" ) || { echo "SDL3 static: unpacking $a failed" >&2; exit 1; }
            # CMake's Windows-GNU generator names its objects '.obj', not '.o'.
            for o in "$d"/*.o "$d"/*.obj; do
                [ -f "$o" ] && cp -f "$o" "${d}_$(basename "$o")"
            done
        done
        # The file list is BUILT, not globbed on the ar line: a glob that matches
        # nothing reaches ar as the pattern itself, and ar refuses it ('Invalid argument').
        objs=
        for o in m*_*.o m*_*.obj; do
            [ -f "$o" ] && objs="$objs $o"
        done
        [ -n "$objs" ] || { echo "SDL3 static: no objects to merge into $TTF" >&2; exit 1; }
        ar rcs "$TTF" $objs >> "$LOG" 2>&1
        cd "$HERE"
    else
    "$(dirname "$CL")/llvm-lib.exe" -out:"$(cygpath -m "$TTF")" "$(cygpath -m "$L_TTF")" "$(cygpath -m "$L_FT")" "$(cygpath -m "$L_HB")" >> "$LOG" 2>&1
    fi ;;
linux)
    printf 'create %s\naddlib %s\naddlib %s\naddlib %s\nsave\nend\n' "$TTF" "$L_TTF" "$L_FT" "$L_HB" | ar -M >> "$LOG" 2>&1 ;;
macos)
    libtool -static -o "$TTF" "$L_TTF" "$L_FT" "$L_HB" >> "$LOG" 2>&1 ;;
android)
    printf 'create %s
addlib %s
addlib %s
addlib %s
save
end
' "$(cygpath -m "$TTF")" "$(cygpath -m "$L_TTF")"         "$(cygpath -m "$L_FT")" "$(cygpath -m "$L_HB")" | "$NDK/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-ar.exe" -M >> "$LOG" 2>&1 ;;
esac
[ -f "$TTF" ] || { echo "SDL3 static: combining SDL3_ttf failed ($LOG)" >&2; exit 1; }
if [ "$HOST" = windows ] && [ "$FLAVOUR" = msvc ]; then
    for l in "$L_SDL" "$TTF" "$L_IMG"; do
        if grep -aq "MD_DynamicRelease" "$l"; then echo "SDL3 static: $(basename "$l") has /MD objects" >&2; exit 1; fi
    done
fi
cp -f "$L_SDL" "$OUT/SDL3_${HOST}_$ARCH$FLAVOUR_TAG.a"
cp -f "$L_IMG" "$OUT/SDL3_image_${HOST}_$ARCH$FLAVOUR_TAG.a"
# The NDK's toolchain file compiles with -g: 35 MB of DWARF in SDL3_ttf's archive alone, which a
# program's link strips anyway.
if [ "$HOST" = android ]; then
    for a in "$OUT/SDL3_${HOST}_$ARCH.a" "$TTF" "$OUT/SDL3_image_${HOST}_$ARCH.a"; do
        "$NDK/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-strip.exe" --strip-debug "$(cygpath -m "$a")" >> "$LOG" 2>&1 ||
            { echo "SDL3 static: stripping $(basename "$a") failed" >&2; exit 1; }
    done
fi
if [ "$HOST" = windows ]; then
    for d in SDL3 SDL3_ttf SDL3_image; do
        src="$W/dll/bin/$d.dll"
        if [ "$FLAVOUR" = mingw ] && [ "$d" = SDL3 ]; then
            src="$W/dll/bin/SDL3_${HOST}_${ARCH}_mingw.dll"
        fi
        [ -f "$src" ] || { echo "SDL3 static: no $d.dll under $W/dll/bin" >&2; ls "$W/dll/bin" >&2; exit 1; }
        if [ "$FLAVOUR" = mingw ]; then
            cp -f "$src" "$OUT/${d}_${HOST}_${ARCH}_mingw.dll"
        else
            cp -f "$src" "$OUT/$d.dll"
        fi
    done
fi
# SDL'S JAVA, ONCE: javac at Java 8 against the newest android.jar (SDL's own Gradle build uses
# source/target 1.8), then d8 for the minimum API. The JDK: JAVA_HOME, else the one beside the
# SDK (docs/tiko-android README, D4).
if [ "$HOST" = android ]; then
    SDK=${TIKO_ANDROID_SDK:?run me through build/vendorfetch.sh --target android-...}
    JDK=${JAVA_HOME:-$(dirname "$SDK")/jdk-17}
    BT=$(ls -d "$SDK"/build-tools/* 2>/dev/null | sort -V | tail -1)
    AJAR=$(ls -d "$SDK"/platforms/android-*/android.jar 2>/dev/null | sort -V | tail -1)
    [ -x "$JDK/bin/javac.exe" ] || [ -x "$JDK/bin/javac" ] || { echo "SDL3 static: no JDK at '$JDK' (set JAVA_HOME)" >&2; exit 1; }
    [ -n "$BT" ] && [ -n "$AJAR" ] || { echo "SDL3 static: the SDK at '$SDK' needs build-tools and a platform" >&2; exit 1; }
    J=$W/java; rm -rf "$J"; mkdir -p "$J/classes" "$J/dex"
    JSRC=$(dir_of 'SDL3-*')/android-project/app/src/main/java
    find "$JSRC" "$HERE/android" -name '*.java' | while read -r f; do cygpath -m "$f"; done > "$J/sources.txt"
    echo "== java" >> "$LOG"
    # Java's AF_UNIX self-pipe fails on some Windows machines (docs/tiko-android FACTS, Host).
    export JAVA_TOOL_OPTIONS=${JAVA_TOOL_OPTIONS:--Djdk.net.unixdomain.tmpdir=C:/no-such-dir-afunix}
    if ! { "$JDK/bin/javac" -source 8 -target 8 -Xlint:-options -encoding UTF-8                -bootclasspath "$(cygpath -m "$AJAR")" -d "$(cygpath -m "$J/classes")" @"$(cygpath -m "$J/sources.txt")" &&
           JAVA_HOME=$(cygpath -w "$JDK") "$BT/d8.bat" --release --min-api 29 --lib "$(cygpath -m "$AJAR")"                --output "$(cygpath -m "$J/dex")" $(find "$J/classes" -name '*.class' | while read -r f; do cygpath -m "$f"; done); } >> "$LOG" 2>&1; then
        echo "SDL3 static: SDL's Java failed ($LOG)" >&2; tail -20 "$LOG" >&2; exit 1
    fi
    cp -f "$J/dex/classes.dex" "$OUT/classes.dex"
fi
echo "$STAMP" > "$OUT/.stamp"
mkdir -p "$W/done"
for o in $OUTS; do cp -f "$o" "$W/done/"; done
echo "$STAMP" > "$W/done/.stamp"
echo "SDL3 static: $OUT"
