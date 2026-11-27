@echo off
rem build.bat -- build tiko-lang with the stage0 compiler: a tiko seed.
rem
rem   build\build.bat [Debug^|Release^|RelWithDebInfo^|MinSizeRel] [--test-runner] [--no-dll] [--oracle]
rem   build\build.bat [Release^|MinSizeRel] --dll
rem   build\build.bat Release --lib
rem
rem A compiler build also builds the editor's bin\parser.dll and copies it beside tkEdit
rem (%TIKO_EDITOR_DIR%, default tkedit\bin in this tree). '--no-dll' skips both.
rem
rem The Linux peer is build/build.sh and is kept line-for-line analogous.
rem Configuration flags live here and nowhere else (docs/plan/02 section 3).

setlocal enabledelayedexpansion

set "ROOT=%~dp0.."
set "LIBHOSTARCH=x86_64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" set "LIBHOSTARCH=x86"
set "CFG=%~1"
if "%CFG%"=="" set "CFG=Debug"
if "%CFG%"=="--test-runner" set "CFG=Debug"
if "%CFG%"=="--no-dll" set "CFG=Debug"
if "%CFG%"=="--oracle" set "CFG=Debug"
rem '--dll' anywhere: build the editor's parser.dll INSTEAD of the compiler (below).
set "DLL=0"
set "SCANLIB=0"
set "NODLL=0"
set "TESTRUNNER=0"
set "ORACLE=0"
for %%a in (%*) do (
    if /i "%%~a"=="--dll" set "DLL=1"
    if /i "%%~a"=="--lib" set "SCANLIB=1"
    if /i "%%~a"=="--no-dll" set "NODLL=1"
    if /i "%%~a"=="--oracle" set "ORACLE=1"
    if /i "%%~a"=="--test-runner" set "TESTRUNNER=1"
)
if "%CFG%"=="--dll" set "CFG=Release"
if "%CFG%"=="--lib" set "CFG=Release"
rem fbc cannot build this tree any more: its source imports the std modules (2026-10-10).
rem '--oracle' and MinSizeRel were fbc builds of the compiler -- see build.sh.
if "%ORACLE%"=="1" goto :nooracle
if /i "%CFG%"=="MinSizeRel" goto :nooracle
goto :oracleok
:nooracle
echo build: --oracle and MinSizeRel built the compiler with fbc, which cannot build it since 1>&2
echo build: its source imports the std modules (2026-10-10); seed-3's V5 was the last 1>&2
exit /b 2
:oracleok

rem THE SEED IS STAGE0: TIKO_SEED, else defaultseed.bat's pick; '--oracle' builds with the fbc
rem TIKO_ORACLE_FBC names instead -- see the peer note in build.sh, which also says why that is
rem a flag, why the seed's flags are its own and why TKO_STAGE0, fbc's old name, is ignored.
if not "%TKO_STAGE0%"=="" echo build: TKO_STAGE0 is retired and ignored -- the seed is stage0; an fbc for the oracle is TIKO_ORACLE_FBC 1>&2
set "SEEDED=0"
set "STAGE0="
if "%ORACLE%"=="1" if "%TIKO_ORACLE_FBC%"=="" (
    echo build: --oracle builds with the fbc TIKO_ORACLE_FBC names, and it names none 1>&2
    exit /b 3
)
if "%ORACLE%"=="1" set "STAGE0=%TIKO_ORACLE_FBC%"
if "%ORACLE%"=="1" goto stage0set
if not "%TIKO_SEED%"=="" goto seedset
call "%ROOT%\build\defaultseed.bat" "%ROOT%"
if not defined DEFAULT_SEED (
    echo build: no seed compiler. Fetch the pinned one ^(seed/fetch-seed.sh^), package a 1>&2
    echo build: toolchain ^(build/package.sh^), or set TIKO_SEED to a tiko 1>&2
    exit /b 3
)
set "TIKO_SEED=%DEFAULT_SEED%"
:seedset
set "SEEDED=1"
set "STAGE0=%TIKO_SEED%"
:stage0set

if not exist "%STAGE0%" (
    echo build: stage0 compiler not found at %STAGE0% 1>&2
    echo build: TIKO_SEED must name a tiko, TIKO_ORACLE_FBC an fbc 1>&2
    exit /b 3
)
rem The output flag: fbc's is -x, tiko's -o.
set "OUTOPT=-x"
if "%SEEDED%"=="1" set "OUTOPT=-o"
rem The tree's own headers, inc\: a seed's only default directory, fbc's first -i -- see
rem build.sh, which says why an inherited TIKO_INCLUDE is overridden.
set "INCOPT="
if exist "%ROOT%\inc\" (
    if "%SEEDED%"=="1" ( set "TIKO_INCLUDE=%ROOT%\inc" ) else ( set "INCOPT=-i inc" )
)
rem ...and its own packages, pkg\: the compiler imports std/containers and std/fs, the
rem tree's and not the seed's copy -- see build.sh.
set "TIKO_PKG=%ROOT%\pkg"
rem ...and the same again under the seed's old TKO_* names, which a seed built before the
rem 2026-11-06 rename reads instead (build/defaultseed.sh, seed_env, says the rest).
for %%v in (INCLUDE LIBPATH PKG MODCACHE PATH CLANG AR LIBCLANG SDKROOT JOBS) do set "TKO_%%v=!TIKO_%%v!"

if /i "%CFG%"=="Debug"          set "FLAGS=-g -exx -w all"
if /i "%CFG%"=="RelWithDebInfo" set "FLAGS=-g -w all"
rem Release and MinSizeRel as build.sh has them -- its comments say why: -O 2 because
rem fbc's default is -O 0, and size through the gcc backend because '-O s' is ignored.
if /i "%CFG%"=="Release"        set "FLAGS=-O 2 -w all"
if /i "%CFG%"=="MinSizeRel"     set "FLAGS=-gen gcc -Wc -Os -w all"
if "%FLAGS%"=="" (
    echo build: unknown configuration '%CFG%' 1>&2
    exit /b 2
)
rem ...and a seed's, in its own spelling -- see build.sh. MinSizeRel is fbc's gcc backend
rem and nothing else, so a seed refuses it.
if "%SEEDED%"=="1" (
    if /i "%CFG%"=="Debug"          set "FLAGS=-g -exx"
    if /i "%CFG%"=="RelWithDebInfo" set "FLAGS=-g"
    if /i "%CFG%"=="Release"        set "FLAGS=-O2"
    if /i "%CFG%"=="MinSizeRel" (
        echo build: MinSizeRel is fbc's gcc backend ^(-gen gcc^), which a tiko seed has not got; 1>&2
        echo build: it is built only by an fbc ^('--oracle', TIKO_ORACLE_FBC^), and never shipped 1>&2
        exit /b 2
    )
)

rem The first entry of sources.txt is the main module; -m makes that explicit so the
rem runtime initialises the command line before any module constructor runs.
set "SOURCES="
set "MAINMOD="
for /f "usebackq delims=" %%f in ("%ROOT%\build\sources.txt") do (
    set "LINE=%%f"
    if not "!LINE!"=="" if not "!LINE:~0,1!"=="#" (
        set "SOURCES=!SOURCES! %%f"
        if "!MAINMOD!"=="" for %%n in ("%%f") do set "MAINMOD=%%~nn"
    )
)

if not exist "%ROOT%\bin" mkdir "%ROOT%\bin"
if not exist "%ROOT%\build\obj\%CFG%" mkdir "%ROOT%\build\obj\%CFG%"

rem THE EDITOR'S SCANNER AS A STATIC ARCHIVE -- the Windows peer of build.sh's --lib.
if "%SCANLIB%"=="1" (
    call :buildlib
    if errorlevel 1 exit /b 1
    echo build: ok
    exit /b 0
)

rem THE EDITOR'S DLL -- see the peer note in build.sh. The main module is left out, and
rem NEVER -exx: a failed runtime check ends the process, and in a DLL that is the editor.
if "%DLL%"=="1" (
    call :builddll
    if errorlevel 1 exit /b 1
    echo build: ok
    exit /b 0
)
goto :compiler

:buildlib
    if "%ORACLE%"=="1" (
        echo build: --lib builds the scanner with a tiko seed, not the fbc oracle 1>&2
        exit /b 1
    )
    set "LIBSRC="
    for %%f in (!SOURCES!) do if /i not "%%~nf"=="!MAINMOD!" set "LIBSRC=!LIBSRC! %%f"
    set "LIBFLAGS=!FLAGS:-exx=! -mt"
    set "LIBARCH=%LIBHOSTARCH%"
    set "LIBTARGET="
    set "LIBTAG="
    if /i "%LIBHOSTARCH%"=="x86" (
        set "LIBARCH=x86"
        set "LIBTARGET=-target win32"
        set "LIBTAG=_mingw"
    ) else if /i "%TIKO_BUILD_FLAVOUR%"=="mingw" (
        set "LIBTARGET=-target win64"
        set "LIBTAG=_mingw"
    )
    if /i "%TIKO_BUILD_FLAVOUR%"=="mingw" goto :libmingw
    goto :librun
:libmingw
    if /i "%TIKO_MINGW_TARGET:~0,4%"=="i686" (
        set "LIBARCH=x86"
        set "LIBTARGET=-target win32"
    )
:librun
    set "LIBOUT=bin\parser_windows_!LIBARCH!!LIBTAG!.a"
    echo build: !LIBOUT! [%CFG%] with %STAGE0%
    if exist "%ROOT%\!LIBOUT!" del /f /q "%ROOT%\!LIBOUT!"
    pushd "%ROOT%"
    "%STAGE0%" -lib !LIBSRC! src\api\tikoparser.tiko -i src !INCOPT! !LIBFLAGS! !LIBTARGET! -o "!LIBOUT!"
    if errorlevel 1 ( popd & exit /b 1 )
    popd
    if not exist "%ROOT%\!LIBOUT!" ( echo build: no !LIBOUT! 1>&2 & exit /b 1 )
    exit /b 0

:builddll
    set "LIBSRC="
    for %%f in (!SOURCES!) do if /i not "%%~nf"=="!MAINMOD!" set "LIBSRC=!LIBSRC! %%f"
    set "DLLFLAGS=!FLAGS:-exx=!"
    echo build: parser.dll [%CFG%] with %STAGE0%
    pushd "%ROOT%"
    "%STAGE0%" -dll !LIBSRC! src\api\tikoparser.tiko -i src !INCOPT! !DLLFLAGS! !OUTOPT! "bin\parser.dll"
    if errorlevel 1 ( popd & exit /b 1 )
    popd
    rem Beside the editor's exe (tkEdit's tkedit\bin, or TIKO_EDITOR_DIR), which loads it from
    rem there. A failed copy (a running editor holds the DLL open) warns and does not fail the
    rem build -- see build.sh.
    set "EDITOR=%TIKO_EDITOR_DIR%"
    if "!EDITOR!"=="" set "EDITOR=%ROOT%\tkedit\bin"
    if not exist "!EDITOR!\" (
        echo build: no editor at !EDITOR! -- parser.dll stays in bin\ ^(set TIKO_EDITOR_DIR^)
        exit /b 0
    )
    copy /y "%ROOT%\bin\parser.dll" "!EDITOR!\parser.dll" >nul 2>&1
    if errorlevel 1 (
        echo build: WARNING: could not copy parser.dll to !EDITOR! -- is the editor running? 1>&2
    ) else (
        echo build: parser.dll -^> !EDITOR!
    )
    exit /b 0

:compiler
echo build: tiko-lang [%CFG%] with %STAGE0%
pushd "%ROOT%"
"%STAGE0%" !SOURCES! -m !MAINMOD! -i src %INCOPT% %FLAGS% %OUTOPT% "bin\tiko.exe"
if errorlevel 1 ( popd & exit /b 1 )

if "%TESTRUNNER%"=="1" goto :buildrunner
goto :done

:buildrunner
echo build: tiko-test [%CFG%]
"%STAGE0%" tools\tiko-test\tikotest.tiko -i src %INCOPT% %FLAGS% -mt %OUTOPT% "bin\tiko-test.exe"
if errorlevel 1 ( popd & exit /b 1 )

:done
rem What bin\ now holds -- see the peer note in build.sh.
if not exist "%ROOT%\build\obj" mkdir "%ROOT%\build\obj"
<nul set /p "=%CFG%|%STAGE0%">"%ROOT%\build\obj\.build-stamp"
popd
if not "%NODLL%"=="1" (
    call :builddll
    if errorlevel 1 exit /b 1
)
echo build: ok
exit /b 0
