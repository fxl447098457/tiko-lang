/* msvccrt.c -- the CRT startup and the few shims ucrtbase.dll does not export.
**
** MSVC-ONLY, and empty everywhere else: the gnu targets get all of this from
** fbc's crt2.o and libmingwex.a, which are on their link line already.
**
** WHY THIS EXISTS.  Before it, a windows-x86_64 link needed Visual Studio on the
** machine doing the compiling -- not the SDK, VC Tools specifically, for
** libcmt.lib, libvcruntime.lib, oldnames.lib and legacy_stdio_definitions.lib.
** Measured 2026-09-06: those four are the only reason clang reached into
** "C:/Program Files/Microsoft Visual Studio". They are also NOT in Microsoft's
** own redistributable set -- VC/Redist/MSVC/<v>/x64 contains runtime DLLs and no
** static libraries at all -- so shipping copies was not obviously permitted.
**
** WHAT WAS ACTUALLY MISSING was small, and that is the point of the file.
** ucrtbase.dll is a Windows system component present on every Windows 10 and
** later, and it exports 2,650 symbols: every mem* and str* function, fileno,
** the whole stdio core, and every startup primitive used below. A link against
** it plus our own import libraries left exactly six names undefined:
**
**     mainCRTStartup   the entry point, which lives in no DLL
**     _fltused         a marker the backend emits a reference to
**     atexit           over _crt_atexit, which IS exported
**     sprintf          inline in the UCRT headers, so not exported
**     time localtime   named _time64 and _localtime64 in the UCRT
**     feraiseexcept    inline in the UCRT's fenv.h (added later; see below)
**
** floor and floorf were on that list too and are not shim work: they were a bug
** in our generated ucrtbase.lib, which marked them as DATA imports.
**
** NOT A TRANSLITERATION OF MSVC's STARTUP.  Every entry point called here is
** exported by ucrtbase.dll and declared below from its documented signature.
** The one thing that had to be read rather than guessed is what sprintf passes
** to __stdio_common_vsprintf, because getting the option word wrong is a silent
** formatting difference rather than a link error. From the SDK's own stdio.h:
** sprintf calls _vsprintf_l, which calls _vsnprintf_l with a count of
** (size_t)-1, which calls __stdio_common_vsprintf with
** _CRT_INTERNAL_LOCAL_PRINTF_OPTIONS | _CRT_INTERNAL_PRINTF_LEGACY_VSPRINTF_NULL_TERMINATION
** and returns -1 for any negative result. _CRT_INTERNAL_LOCAL_PRINTF_OPTIONS is
** (*__local_stdio_printf_options()), a per-translation-unit static that is zero
** unless the unit sets it, so the whole word here is the one legacy flag.
*/

#ifdef TKORT_MSVC

typedef unsigned long long tkort_u64;
typedef unsigned long long tkort_size;
typedef void ( __cdecl *tkort_pvfv )( void );

/* EVERY SHIM OF A UCRT-HEADER INLINE IS WEAK. MSVC compiles those inlines into each
** object that calls them, as COMDAT copies the linker may pick any one of -- so a
** static MSVC library brings its own sprintf. Ours was a strong definition, and a
** strong definition beside a COMDAT one is a duplicate: linking raylib's static
** raylib.lib stopped on 'duplicate symbol: sprintf' (and fprintf, snprintf, sscanf)
** between its rcore.obj and this file. Weak, the library's copy wins where there is
** one and ours is used where there is not -- both measured with lld, including a
** program whose only reference to this archive member is a weak name. */
#define TKORT_UCRT_INLINE __attribute__(( weak ))

/* ---------------------------------------------------------- ucrtbase.dll */

int    __cdecl _configure_narrow_argv( int mode );
int    __cdecl _initialize_narrow_environment( void );
int *  __cdecl __p___argc( void );
char***__cdecl __p___argv( void );
void   __cdecl _initterm( tkort_pvfv *first, tkort_pvfv *last );
void   __cdecl exit( int code );
int    __cdecl _crt_atexit( tkort_pvfv fn );
int    __cdecl __stdio_common_vsprintf( tkort_u64 options, char *buffer,
                                        tkort_size count, char const *format,
                                        void *locale, char *arglist );
/* 'struct _iobuf *' AND NOT 'void *', which is what FILE is on Windows. fprintf is a
** clang BUILTIN, so a declaration that disagrees with the builtin's own signature earns
** -Wbuiltin-requires-header -- a new warning in a build that has none. sprintf above
** needs no such care because its (char*, char const*, ...) already matches. Declared
** opaquely rather than by including <stdio.h>, which is the rule this whole file keeps.
*/
struct _iobuf;
int    __cdecl __stdio_common_vfprintf( tkort_u64 options, struct _iobuf *stream,
                                        char const *format,
                                        void *locale, char *arglist );
float  __cdecl _hypotf( float x, float y );
long long __cdecl _time64( long long *dest );
int       __cdecl _fileno( void *stream );
void *    __cdecl _localtime64( long long const *src );

/* THE INITIALISER RANGE.  tkort_msvc_init_ is allocated into .CRT$XCY
** (msvcinit.c) and the linker sorts the .CRT$XC* fragments together, so
** bracketing them with XCA and XCZ and handing the pair to _initterm is what
** actually calls it. Without this the runtime starts in the "C" locale and
** UCASE leaves accented characters alone -- the failure msvcinit.c records.
**
** The XI range is C-style initialisers. Nothing here uses it today; it is
** bracketed anyway because the cost is two empty pointers and the failure mode
** if something starts using it is silent. */
#pragma section( ".CRT$XIA", read )
#pragma section( ".CRT$XIZ", read )
#pragma section( ".CRT$XCA", read )
#pragma section( ".CRT$XCZ", read )
__declspec(allocate(".CRT$XIA")) tkort_pvfv tkort_xi_a[] = { 0 };
__declspec(allocate(".CRT$XIZ")) tkort_pvfv tkort_xi_z[] = { 0 };
__declspec(allocate(".CRT$XCA")) tkort_pvfv tkort_xc_a[] = { 0 };
__declspec(allocate(".CRT$XCZ")) tkort_pvfv tkort_xc_z[] = { 0 };

/* THE TERMINATOR RANGE, and it was missing outright.
**
** LLVM lowers '@llvm.global_dtors' on a Windows-MSVC target into .CRT$XTX --
** the same mechanism .CRT$XC* is for initialisers -- and nothing here bracketed
** or ran it, so a module destructor was EMITTED CORRECTLY AND NEVER CALLED.
**
** Measured on tests/vendor/fbc-tests/scopes/dtor_eol_eof1.bas: fbc emits
** 'void CHECK( void ) __attribute__(( destructor ));' and the program prints
** '1  1'; the tiko build printed nothing at all and exited 0. It compiled, it
** linked, and it was silent -- which is why only build/runscan.sh could see it.
**
** The real MSVC CRT walks this range inside exit(); we reach the UCRT's exit,
** which knows nothing about our fragments, so msvccrtexe.c registers a handler
** that walks it. */
#pragma section( ".CRT$XTA", read )
#pragma section( ".CRT$XTZ", read )
__declspec(allocate(".CRT$XTA")) tkort_pvfv tkort_xt_a[] = { 0 };
__declspec(allocate(".CRT$XTZ")) tkort_pvfv tkort_xt_z[] = { 0 };

/* THE WALK ORDER IS fbc's ON WINDOWS, which the plain _initterm walk was not.
**
** Measured with fbc-modern's default backend, which links through mingw: numbered
** constructors ('sub f( ) constructor 101') run first, lowest number first; then the
** unnumbered ones in REVERSE -- last module linked first, and within a module last
** written first -- and a numbered group runs reversed the same way. Destructors run
** the other way round: the unnumbered forwards, then the numbered, highest number
** first, each group forwards. mingw gets all of it by walking .ctors backwards and
** .dtors forwards over gcc's layout: the unnumbered, then .ctors.NNNNN sorted, where
** NNNNN is 65535 minus the number.
**
** codegen/llvmstructors.tiko lays the .CRT$X fragments out the same way -- unnumbered
** in .CRT$XCU / .CRT$XTX, numbered after them in .CRT$XCV / .CRT$XTY plus 65535 minus
** the number -- so the same two walks give the same order, module order included.
** tiko ran every fragment forwards, so fbc's own concurrency/sched.bas -- whose first
** test relies on a later one having started the goroutine pool -- failed here alone.
**
** The runtime's own start-up is at .CRT$XCY, the LAST fragment, so the backwards walk
** runs it first (msvcinit.c). Nulls -- the brackets, and any padding the linker puts
** between fragments -- are skipped, as _initterm skips them. */
static void tkort_walk_back( tkort_pvfv *first, tkort_pvfv *last )
{
    while( last > first ) {
        --last;
        if( *last ) (*last)( );
    }
}

/* Called by both entry points. */
void tkort_run_initialisers( void )
{
    _initterm( tkort_xi_a, tkort_xi_z );
    tkort_walk_back( tkort_xc_a, tkort_xc_z );
}

void __cdecl tkort_run_terminators( void )
{
    _initterm( tkort_xt_a, tkort_xt_z );
}

/* THE STACK PROBE.  The backend emits 'call __chkstk' in the prologue of any
** function whose frame exceeds a page, and on this target nothing defines it:
** it lives in Visual Studio's libcmt, and clang's own clang_rt.builtins does
** NOT carry it (checked). tiko-rt's io_printusg.o is the first module to need
** one -- fb_PrintUsingWstr and fb_PrintUsingUStr both have large frames.
**
** THE CONTRACT, which is the whole of it: RAX holds the byte count, the routine
** touches one byte on every page between the current RSP and RSP-RAX so the
** guard page is hit in order, and it returns with RAX and every other register
** unchanged. It does NOT move RSP -- the caller's next instruction is
** 'sub rsp, rax'. Written in assembly because that register discipline cannot
** be expressed in C.
**
** Guard pages must be touched IN DESCENDING ORDER, one per page. Skipping one
** and writing past it is how a stack overflow becomes a silent memory
** corruption instead of an exception. */__asm__(
    ".globl __chkstk\n"
    "__chkstk:\n"
    "    push %rcx\n"
    "    push %rax\n"
    "    cmp  $0x1000, %rax\n"
    "    lea  24(%rsp), %rcx\n"
    "    jb   2f\n"
    "1:\n"
    "    sub  $0x1000, %rcx\n"
    "    test %rcx, (%rcx)\n"
    "    sub  $0x1000, %rax\n"
    "    cmp  $0x1000, %rax\n"
    "    ja   1b\n"
    "2:\n"
    "    sub  %rax, %rcx\n"
    "    test %rcx, (%rcx)\n"
    "    pop  %rax\n"
    "    pop  %rcx\n"
    "    ret\n"
);

/* THE /GS COOKIE PAIR.  LLVM's prebuilt clang_rt.builtins-x86_64.lib -- linked for
** int128's '\', MOD and float conversions (toolchain.tiko, rtBuiltinsLib) -- is
** compiled with /GS, so __divti3, __modti3, __floatuntidf & co. reference
** __security_cookie and __security_check_cookie, which live in Visual Studio's
** libcmt like __chkstk above. Measured 2026-11-19, LLVM 23.1.5: the link failed on
** exactly those two. The value is MSVC's own default (it is never re-seeded here:
** nothing calls __security_init_cookie), and a mismatch fails fast, as MSVC's does.
**
** The check is ASSEMBLY for __chkstk's reason: it is called in an EPILOGUE, after the
** result is already in RAX or XMM0, and must touch nothing but the flags.
**
** BOTH ARE WEAK, for sprintf's reason above: a static library built by MSVC brings
** Visual Studio's own pair. raylib.lib's objects are compiled with /GS, reference
** __GSHandlerCheck, and their /DEFAULTLIB:MSVCRT names VC's static MSVCRT.lib, whose
** gshandler.obj pulls in gs_cookie.obj for __security_cookie_complement -- and that object
** defines __security_cookie too. Strong here, every link of such a library stopped on
** 'duplicate symbol: __security_cookie' between libfb.a(msvccrt.o) and
** MSVCRT.lib(gs_cookie.obj): the book's Chapter 30 raylib and SDL3 listings, measured
** 2026-11-20 with lld-link /verbose. Weak, VC's definition wins where it is linked and
** ours is used where it is not; either way the program has ONE cookie, and every /GS
** check -- ours, VC's, the library's -- compares against it.
**
** The check is a NAKED weak function rather than a '.globl' label in top-level asm:
** LLVM's COFF assembler keeps a '.weak' label in inline asm strong (measured), while
** 'weak, naked' gives a weak external over exactly these four instructions. */
__attribute__(( weak )) unsigned long long __security_cookie = 0x00002B992DDFA232ull;

__attribute__(( weak, naked )) void __cdecl __security_check_cookie( void )
{
    __asm__(
        "    cmp  __security_cookie(%rip), %rcx\n"
        "    jne  1f\n"
        "    ret\n"
        "1:\n"
        "    ud2\n"
    );
}

/* THE FLOATING-POINT MARKER.  The backend emits a reference to _fltused from
** any module that touches a float, and the CRT is expected to define it. Its
** value is never read; only its presence is. */
int _fltused = 0x9875;

/* A DLL'S atexit IS ITS OWN.  _crt_atexit registers with the UCRT's table, which
** belongs to the PROCESS: a DLL that put fb_hRtExit there (msvcinit.c does) and was
** then unloaded left the process calling into freed code at exit -- 0xC0000005 after
** every correct line of output, measured with build/apitest.sh's harness, which
** FreeLibrary's tikoParser.dll before it returns.  MSVC's own CRT gives each DLL its
** own table and runs it at DLL_PROCESS_DETACH; msvccrtdll.c does the same, and sets
** this hook before any initialiser of the DLL runs.  An executable never links that
** entry point, so the hook stays NULL there and nothing changes for it. */
int ( __cdecl *tkort_dll_atexit )( tkort_pvfv fn ) = 0;

int __cdecl atexit( tkort_pvfv fn )
{
    if( tkort_dll_atexit ) return tkort_dll_atexit( fn );
    return _crt_atexit( fn );
}

TKORT_UCRT_INLINE int __cdecl sprintf( char *buffer, char const *format, ... )
{
    int result;
    char *arglist;
    __builtin_va_start( arglist, format );
    /* 1 is _CRT_INTERNAL_PRINTF_LEGACY_VSPRINTF_NULL_TERMINATION. */
    result = __stdio_common_vsprintf( 1ull, buffer, (tkort_size)-1,
                                      format, 0, arglist );
    __builtin_va_end( arglist );
    return result < 0 ? -1 : result;
}

/* fprintf IS INLINE IN THE UCRT HEADERS TOO, exactly as sprintf is, so it is not
** exported either. It was not on the list of six above because that list is what
** tiko-rt ITSELF leaves undefined, and tiko-rt never calls fprintf -- but a PROGRAM
** may, and fbc's own fbcunit does, from REPORT_CLOSE and its console reporter. On the
** default Windows target that program could not be linked at all.
**
** READ, NOT GUESSED, for the same reason sprintf's option word was -- getting it wrong
** is a silent formatting difference rather than a link error. From the SDK's stdio.h:
** fprintf calls _vfprintf_l, which calls __stdio_common_vfprintf with
** _CRT_INTERNAL_LOCAL_PRINTF_OPTIONS and returns the result UNCHANGED.
**
** THE OPTION WORD IS ZERO HERE, and that is the one place it differs from sprintf.
** sprintf's chain goes through _vsnprintf_l, which ORs in
** _CRT_INTERNAL_PRINTF_LEGACY_VSPRINTF_NULL_TERMINATION; fprintf's chain adds nothing,
** and _CRT_INTERNAL_LOCAL_PRINTF_OPTIONS is (*__local_stdio_printf_options()), a
** per-translation-unit static that is zero unless the unit sets it. Nor is there a
** negative-result clamp: sprintf returns -1 for any negative, fprintf returns what it
** was given.
*/
/* THE WARNING IS ABOUT THE HEADER, NOT THE SIGNATURE, so matching FILE* does not quiet
** it: -Wbuiltin-requires-header fires because <stdio.h> is not included, and not
** including it is this file's whole method -- every entry point here is declared from
** the documented signature so that the shim depends on no SDK headers at all. sprintf
** above escapes only because its builtin needs no type from that header.
**
** Scoped to the definition rather than the file: another builtin declared later should
** still be told about.
*/
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-requires-header"
TKORT_UCRT_INLINE int __cdecl fprintf( struct _iobuf *stream, char const *format, ... )
{
    int result;
    char *arglist;
    __builtin_va_start( arglist, format );
    result = __stdio_common_vfprintf( 0ull, stream, format, 0, arglist );
    __builtin_va_end( arglist );
    return result;
}
#pragma clang diagnostic pop

/* snprintf AND vsprintf ARE THE SAME FAMILY as sprintf -- inline in the UCRT headers,
** so not exported -- and fbc's own suite reaches both: crt/varargs.bas calls vsprintf
** directly, and nine modules of the finance tests call snprintf.
**
** READ FROM THE SDK, and the two option words are NOT the same, which is the whole
** reason to read rather than copy sprintf:
**
**   snprintf -> vsnprintf     -> __stdio_common_vsprintf( STANDARD_SNPRINTF_BEHAVIOR,
**                                    buffer, count, format, NULL, args )
**   vsprintf -> _vsnprintf_l  -> __stdio_common_vsprintf( LEGACY_VSPRINTF_NULL_TERMINATION,
**                                    buffer, (size_t)-1, format, NULL, args )
**
** from corecrt_stdio_config.h: LEGACY_VSPRINTF_NULL_TERMINATION is (1ULL << 0) and
** STANDARD_SNPRINTF_BEHAVIOR is (1ULL << 1). Getting these the wrong way round is a
** silent behavioural difference in truncation and termination, not a link error.
**
** BOTH CLAMP a negative result to -1, which sprintf above does too.
*/
TKORT_UCRT_INLINE int __cdecl snprintf( char *buffer, tkort_size count, char const *format, ... )
{
    int result;
    char *arglist;
    __builtin_va_start( arglist, format );
    /* 2 is _CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR. */
    result = __stdio_common_vsprintf( 2ull, buffer, count, format, 0, arglist );
    __builtin_va_end( arglist );
    return result < 0 ? -1 : result;
}

TKORT_UCRT_INLINE int __cdecl vsprintf( char *buffer, char const *format, char *arglist )
{
    int result;
    /* 1 is _CRT_INTERNAL_PRINTF_LEGACY_VSPRINTF_NULL_TERMINATION, as sprintf uses. */
    result = __stdio_common_vsprintf( 1ull, buffer, (tkort_size)-1,
                                      format, 0, arglist );
    return result < 0 ? -1 : result;
}

/* printf ITSELF, AND THE REST OF THE FAMILY, were still missing. All are inline in the
** UCRT headers, as sprintf is, so a program calling them could not be linked on the
** default Windows target: 'printf' through crt.bi was "undefined symbol: printf", and
** so were vprintf, vfprintf, vsnprintf, scanf, fscanf and sscanf -- measured by
** linking one program that calls each. fbc-modern's default target is MinGW's, which
** exports every one.
**
** READ FROM THE SDK (10.0.26100.0, ucrt/stdio.h and corecrt_stdio_config.h), as the
** shims above were:
**
**   printf   -> _vfprintf_l( stdout, ... )  -> __stdio_common_vfprintf( OPTS, ... )
**   vprintf, vfprintf                       -> the same, unchanged result
**   vsnprintf                               -> __stdio_common_vsprintf( OPTS |
**                                   STANDARD_SNPRINTF_BEHAVIOR, ... ), clamped to -1
**   scanf    -> _vfscanf_l( stdin, ... )    -> __stdio_common_vfscanf( SOPTS, ... )
**   fscanf, vfscanf, vscanf                 -> the same
**   sscanf   -> _vsscanf_l                  -> __stdio_common_vsscanf( SOPTS, buffer,
**                                              (size_t)-1, ... )
**
** OPTS and SOPTS are *__local_stdio_printf_options() and *__local_stdio_scanf_options():
** zero-initialised statics a unit only changes deliberately, so both words are 0 here,
** as fprintf's is. stdin and stdout are __acrt_iob_func( 0 ) and ( 1 ), exported. */
struct _iobuf * __cdecl __acrt_iob_func( unsigned index );
int __cdecl __stdio_common_vfscanf( tkort_u64 options, struct _iobuf *stream,
                                    char const *format, void *locale, char *arglist );
int __cdecl __stdio_common_vsscanf( tkort_u64 options, char const *buffer,
                                    tkort_size count, char const *format,
                                    void *locale, char *arglist );

/* Builtins every one, declared without <stdio.h> -- see fprintf above. */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-requires-header"
TKORT_UCRT_INLINE int __cdecl vfprintf( struct _iobuf *stream, char const *format, char *arglist )
{
    return __stdio_common_vfprintf( 0ull, stream, format, 0, arglist );
}

TKORT_UCRT_INLINE int __cdecl vprintf( char const *format, char *arglist )
{
    return __stdio_common_vfprintf( 0ull, __acrt_iob_func( 1 ), format, 0, arglist );
}

TKORT_UCRT_INLINE int __cdecl printf( char const *format, ... )
{
    int result;
    char *arglist;
    __builtin_va_start( arglist, format );
    result = __stdio_common_vfprintf( 0ull, __acrt_iob_func( 1 ), format, 0, arglist );
    __builtin_va_end( arglist );
    return result;
}

TKORT_UCRT_INLINE int __cdecl vsnprintf( char *buffer, tkort_size count, char const *format, char *arglist )
{
    /* 2 is _CRT_INTERNAL_PRINTF_STANDARD_SNPRINTF_BEHAVIOR, as snprintf uses. */
    int result = __stdio_common_vsprintf( 2ull, buffer, count, format, 0, arglist );
    return result < 0 ? -1 : result;
}

TKORT_UCRT_INLINE int __cdecl vfscanf( struct _iobuf *stream, char const *format, char *arglist )
{
    return __stdio_common_vfscanf( 0ull, stream, format, 0, arglist );
}

TKORT_UCRT_INLINE int __cdecl vscanf( char const *format, char *arglist )
{
    return __stdio_common_vfscanf( 0ull, __acrt_iob_func( 0 ), format, 0, arglist );
}

TKORT_UCRT_INLINE int __cdecl vsscanf( char const *buffer, char const *format, char *arglist )
{
    return __stdio_common_vsscanf( 0ull, buffer, (tkort_size)-1, format, 0, arglist );
}

TKORT_UCRT_INLINE int __cdecl fscanf( struct _iobuf *stream, char const *format, ... )
{
    int result;
    char *arglist;
    __builtin_va_start( arglist, format );
    result = __stdio_common_vfscanf( 0ull, stream, format, 0, arglist );
    __builtin_va_end( arglist );
    return result;
}

TKORT_UCRT_INLINE int __cdecl scanf( char const *format, ... )
{
    int result;
    char *arglist;
    __builtin_va_start( arglist, format );
    result = __stdio_common_vfscanf( 0ull, __acrt_iob_func( 0 ), format, 0, arglist );
    __builtin_va_end( arglist );
    return result;
}

TKORT_UCRT_INLINE int __cdecl sscanf( char const *buffer, char const *format, ... )
{
    int result;
    char *arglist;
    __builtin_va_start( arglist, format );
    result = __stdio_common_vsscanf( 0ull, buffer, (tkort_size)-1, format, 0, arglist );
    __builtin_va_end( arglist );
    return result;
}
#pragma clang diagnostic pop

/* hypotf IS NOT SHIM WORK OF THE SAME KIND: ucrtbase.dll DOES have it, under the name
** _hypotf, exactly as time and localtime are _time64 and _localtime64 up above. Checked
** against the DLL's own export table rather than assumed -- the header already records
** floor and floorf looking like this and being a bug in our generated import library
** instead, so which of the two it is has to be established each time.
**
** fb/core.bas reaches it through FB.HPOW10.
*/
TKORT_UCRT_INLINE float __cdecl hypotf( float x, float y )
{
    return _hypotf( x, y );
}

/* fileno IS NOT AN EXPORT, whatever fbc's import library says. ucrtbase.dll
** exports _fileno only, and libucrtbase.dll.a lists 'fileno' -- a name the DLL
** does not have. Harmless in fbc's tree, where nothing references it; here it
** produced a binary the loader silently refused to start. A graphics program
** built without error and exited 127 while the same program without graphics
** ran, because only the graphics path reaches fileno.
**
** build/mkmsvcdef.py now drops export names the DLL does not actually have, so
** the bogus import cannot be generated again. This defines the name properly. */
int __cdecl fileno( void *stream )
{
    return _fileno( stream );
}

/* THE WIDE MEMORY FAMILY IS INLINE IN THE UCRT HEADERS, exactly as sprintf is, so none
** of it is exported: checked against our ucrt.lib, ucrtbase.lib and msvcrt.lib with
** llvm-nm, where wmemmove, wmemcpy, wmemset, wmemcmp and wmemchr all come back absent
** while memmove, memcpy, memset and memcmp are present. crt/wchar.bi declares them
** as ordinary functions and AfxNova's DWSTRING calls wmemmove from ResizeBuffer and
** AppendBuffer, so PsCalendar's link stopped on 'undefined symbol: wmemmove'.
**
** wchar_t IS 16 BITS on this target, and the counts are in CHARACTERS, not bytes.
** Declared with the compiler's own __WCHAR_TYPE__ and __SIZE_TYPE__ so the definitions
** match clang's builtin signatures exactly; the header warning is silenced for the
** same reason fprintf's is. tiko-rt itself never calls these -- see ustr/prim.tiko. */
typedef __WCHAR_TYPE__ tkort_wchar;
void * __cdecl memmove( void *dst, void const *src, __SIZE_TYPE__ n );
void * __cdecl memcpy( void *dst, void const *src, __SIZE_TYPE__ n );
int    __cdecl memcmp( void const *a, void const *b, __SIZE_TYPE__ n );

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-requires-header"
TKORT_UCRT_INLINE tkort_wchar * __cdecl wmemmove( tkort_wchar *dst, tkort_wchar const *src, __SIZE_TYPE__ n )
{
    return (tkort_wchar *)memmove( dst, src, n * sizeof( tkort_wchar ) );
}

TKORT_UCRT_INLINE tkort_wchar * __cdecl wmemcpy( tkort_wchar *dst, tkort_wchar const *src, __SIZE_TYPE__ n )
{
    return (tkort_wchar *)memcpy( dst, src, n * sizeof( tkort_wchar ) );
}

TKORT_UCRT_INLINE tkort_wchar * __cdecl wmemset( tkort_wchar *dst, tkort_wchar c, __SIZE_TYPE__ n )
{
    __SIZE_TYPE__ i;
    for( i = 0; i < n; i++ ) dst[i] = c;
    return dst;
}

/* ORDERED BY CODE UNIT VALUE, not by memcmp's byte order: a little-endian byte
** compare would rank 0x0100 below 0x00FF. */
TKORT_UCRT_INLINE int __cdecl wmemcmp( tkort_wchar const *a, tkort_wchar const *b, __SIZE_TYPE__ n )
{
    __SIZE_TYPE__ i;
    for( i = 0; i < n; i++ ) {
        if( a[i] != b[i] ) return a[i] < b[i] ? -1 : 1;
    }
    return 0;
}

TKORT_UCRT_INLINE tkort_wchar * __cdecl wmemchr( tkort_wchar const *s, tkort_wchar c, __SIZE_TYPE__ n )
{
    __SIZE_TYPE__ i;
    for( i = 0; i < n; i++ ) {
        if( s[i] == c ) return (tkort_wchar *)( s + i );
    }
    return 0;
}
#pragma clang diagnostic pop

/* time_t IS 64-BIT on x64, so these are renames rather than conversions. */
TKORT_UCRT_INLINE long long __cdecl time( long long *dest )
{
    return _time64( dest );
}

TKORT_UCRT_INLINE void * __cdecl localtime( long long const *src )
{
    return _localtime64( src );
}

/* feraiseexcept IS INLINE IN THE UCRT'S fenv.h, like sprintf, so it is not exported:
** ucrtbase.dll's own export table has feclearexcept, fegetenv, fegetexceptflag,
** fegetround, feholdexcept, fesetenv, fesetexceptflag, fesetround and fetestexcept, and
** not this one -- checked against the DLL, not the import library. fb/fenv.bi's
** RaiseFpException calls it, so math/fenv linked under fbc (libmingwex has it) and not
** here.
**
** EXACTLY THE FLAGS ASKED FOR, through the exported fesetexceptflag. Raising them by
** arithmetic, as the UCRT's inline version does, is measurably not what fbc's program
** gets: an overflowing multiply sets INEXACT with OVERFLOW, and so does an underflow,
** where libmingwex's feraiseexcept sets the one bit it was given -- raising OVERFLOW
** under fbc tests true for OVERFLOW alone. The bits are the UCRT's own _SW_* codes;
** fb/fenv.bi detects that family at startup and translates to it.
**
** fexcept_t CARRIES EACH FLAG TWICE, and that is measured, not read: fegetexceptflag
** after '1 / 0' stores &h08000008 -- the _SW_ bit for the x87 status word in the low
** byte and again at bit 24 for MXCSR. Handed the bare &h08, fesetexceptflag returns 1
** and sets nothing; handed both halves it sets exactly that flag, all five tested. */
int __cdecl fesetexceptflag( unsigned long const *flagp, int excepts );

TKORT_UCRT_INLINE int __cdecl feraiseexcept( int excepts )
{
    unsigned long e = (unsigned long)( excepts & 0x1f );
    unsigned long flags = e | ( e << 24 );
    return fesetexceptflag( &flags, excepts & 0x1f );
}

/* THE INTERLOCKED INTRINSICS THE WINDOWS HEADERS DECLARE AS FUNCTIONS.
**
** fbc-modern's win/intrin.bi declares '_InterlockedExchangeAdd' and its 64-bit twin as
** ordinary externs, and builds '_InterlockedAdd' on top of them in FB. On MinGW those
** names are real symbols in libmingwex; under the MSVC ABI they are COMPILER
** intrinsics, expanded inline by the C frontend and present in no library at all -- so
** an FB program that reaches one gets 'lld-link: error: undefined symbol:
** _InterlockedExchangeAdd', which is 24 of the corpus link failures build/linkscan.sh
** reports, every file that uses fb/comptr.bi.
**
** __atomic_fetch_add WITH SEQ_CST, which is what the Windows contract says: the
** Interlocked family is a full barrier in both directions, and __ATOMIC_SEQ_CST is the
** only ordering that promises that. The return value is the OLD value, which is what
** both the intrinsic and the FB declaration expect.
**
** Named without the leading underscore in the generated call is NOT a possibility: the
** header declares the underscored spelling and that is the symbol the linker asks for.
*/
/* THE NAME IS AN ASM LABEL, not the C identifier. clang REFUSES a definition of a name
** it knows as a builtin -- "definition of builtin function
** '_InterlockedExchangeAdd'" -- and there is no per-function way to turn that off. So
** the function is called something else in C and CARRIES the intrinsic's symbol name
** into the object, which is the only thing the linker looks at. */
long __cdecl tkort_interlocked_xadd32( long volatile *Addend, long Value )
    __asm__( "_InterlockedExchangeAdd" );
long __cdecl tkort_interlocked_xadd32( long volatile *Addend, long Value )
{
    return __atomic_fetch_add( Addend, Value, __ATOMIC_SEQ_CST );
}

long long __cdecl tkort_interlocked_xadd64( long long volatile *Addend,
                                            long long Value )
    __asm__( "_InterlockedExchangeAdd64" );
long long __cdecl tkort_interlocked_xadd64( long long volatile *Addend,
                                            long long Value )
{
    return __atomic_fetch_add( Addend, Value, __ATOMIC_SEQ_CST );
}

/* ...AND THE REST OF THE FAMILY, 2026-09-14. The two above were added for fb/comptr.bi;
** tracks reaches '_InterlockedExchange' and '_InterlockedIncrement' through winbase.bi's
** InterlockedExchange and InterlockedIncrement macros, and its link failed the same way.
**
** THE SET IS MEASURED, not recalled: every _Interlocked* name that mingw-w64's
** libkernel32.dll.a DEFINES (llvm-nm over fbc-modern's lib/win64), which is exactly the
** set a program fbc links is able to call. Two of that list are NOT here: _InterlockedAdd
** and _InterlockedAdd64, which intrin.bi builds in FB over ExchangeAdd. The SList
** functions are real kernel32.dll exports and need nothing.
**
** WHAT EACH RETURNS DIFFERS BY NAME, per the Windows contract: Increment and Decrement
** give the NEW value; Exchange, CompareExchange and And/Or/Xor give the OLD one; the bit
** tests give the tested bit's OLD state as 0 or 1. */
/* THE GCC-STYLE __sync_* BUILTINS, not the __atomic_* family the two above use. This
** clang has no __atomic_exchange of that shape and no __atomic_compare_exchange_strong
** at all -- measured, both failed to compile -- while every __sync_* operation below is
** a single lock-prefixed instruction: a full barrier, which is the Interlocked contract.
** And their results already ARE the contract's: lock_test_and_set and
** val_compare_and_swap return the value BEFORE, *_and_fetch the value AFTER. */
#define TKORT_IL( ret_, cname_, sym_, params_ ) \
    ret_ __cdecl cname_ params_ __asm__( sym_ ); \
    ret_ __cdecl cname_ params_

TKORT_IL( long, tkort_il_xchg32, "_InterlockedExchange", ( long volatile *Target, long Value ) )
    { return __sync_lock_test_and_set( Target, Value ); }
TKORT_IL( long long, tkort_il_xchg64, "_InterlockedExchange64",
          ( long long volatile *Target, long long Value ) )
    { return __sync_lock_test_and_set( Target, Value ); }
TKORT_IL( void *, tkort_il_xchgp, "_InterlockedExchangePointer",
          ( void * volatile *Target, void *Value ) )
    { return __sync_lock_test_and_set( Target, Value ); }

TKORT_IL( short, tkort_il_inc16, "_InterlockedIncrement16", ( short volatile *Addend ) )
    { return __sync_add_and_fetch( Addend, 1 ); }
TKORT_IL( long, tkort_il_inc32, "_InterlockedIncrement", ( long volatile *Addend ) )
    { return __sync_add_and_fetch( Addend, 1 ); }
TKORT_IL( long long, tkort_il_inc64, "_InterlockedIncrement64", ( long long volatile *Addend ) )
    { return __sync_add_and_fetch( Addend, 1 ); }
TKORT_IL( short, tkort_il_dec16, "_InterlockedDecrement16", ( short volatile *Addend ) )
    { return __sync_sub_and_fetch( Addend, 1 ); }
TKORT_IL( long, tkort_il_dec32, "_InterlockedDecrement", ( long volatile *Addend ) )
    { return __sync_sub_and_fetch( Addend, 1 ); }
TKORT_IL( long long, tkort_il_dec64, "_InterlockedDecrement64", ( long long volatile *Addend ) )
    { return __sync_sub_and_fetch( Addend, 1 ); }

/* ARGUMENT ORDER DIFFERS: the Windows call is ( destination, new, comparand ) and the
** builtin is ( destination, comparand, new ). */
TKORT_IL( short, tkort_il_cmpxchg16, "_InterlockedCompareExchange16",
          ( short volatile *Destination, short ExChange, short Comperand ) )
    { return __sync_val_compare_and_swap( Destination, Comperand, ExChange ); }
TKORT_IL( long, tkort_il_cmpxchg32, "_InterlockedCompareExchange",
          ( long volatile *Destination, long ExChange, long Comperand ) )
    { return __sync_val_compare_and_swap( Destination, Comperand, ExChange ); }
TKORT_IL( long long, tkort_il_cmpxchg64, "_InterlockedCompareExchange64",
          ( long long volatile *Destination, long long ExChange, long long Comperand ) )
    { return __sync_val_compare_and_swap( Destination, Comperand, ExChange ); }
TKORT_IL( void *, tkort_il_cmpxchgp, "_InterlockedCompareExchangePointer",
          ( void * volatile *Destination, void *ExChange, void *Comperand ) )
    { return __sync_val_compare_and_swap( Destination, Comperand, ExChange ); }

TKORT_IL( long, tkort_il_and32, "_InterlockedAnd", ( long volatile *Destination, long Value ) )
    { return __sync_fetch_and_and( Destination, Value ); }
TKORT_IL( long long, tkort_il_and64, "_InterlockedAnd64",
          ( long long volatile *Destination, long long Value ) )
    { return __sync_fetch_and_and( Destination, Value ); }
TKORT_IL( long, tkort_il_or32, "_InterlockedOr", ( long volatile *Destination, long Value ) )
    { return __sync_fetch_and_or( Destination, Value ); }
TKORT_IL( long long, tkort_il_or64, "_InterlockedOr64",
          ( long long volatile *Destination, long long Value ) )
    { return __sync_fetch_and_or( Destination, Value ); }
TKORT_IL( long, tkort_il_xor32, "_InterlockedXor", ( long volatile *Destination, long Value ) )
    { return __sync_fetch_and_xor( Destination, Value ); }
TKORT_IL( long long, tkort_il_xor64, "_InterlockedXor64",
          ( long long volatile *Destination, long long Value ) )
    { return __sync_fetch_and_xor( Destination, Value ); }

/* The bit tests. An offset past the width is undefined in the contract; it is masked
** here rather than shifting by more than the width, which would be undefined in C. */
#define TKORT_BIT32( o_ ) ( (long)( 1UL << ( (o_) & 31 ) ) )
#define TKORT_BIT64( o_ ) ( (long long)( 1ULL << ( (o_) & 63 ) ) )
TKORT_IL( unsigned char, tkort_il_bts32, "_interlockedbittestandset",
          ( long volatile *Base, long Offset ) )
    { return (unsigned char)( ( (unsigned long)__sync_fetch_and_or( Base, TKORT_BIT32( Offset ) )
                                >> ( Offset & 31 ) ) & 1 ); }
TKORT_IL( unsigned char, tkort_il_btr32, "_interlockedbittestandreset",
          ( long volatile *Base, long Offset ) )
    { return (unsigned char)( ( (unsigned long)__sync_fetch_and_and( Base, ~TKORT_BIT32( Offset ) )
                                >> ( Offset & 31 ) ) & 1 ); }
TKORT_IL( unsigned char, tkort_il_btc32, "_interlockedbittestandcomplement",
          ( long volatile *Base, long Offset ) )
    { return (unsigned char)( ( (unsigned long)__sync_fetch_and_xor( Base, TKORT_BIT32( Offset ) )
                                >> ( Offset & 31 ) ) & 1 ); }
TKORT_IL( unsigned char, tkort_il_bts64, "_interlockedbittestandset64",
          ( long long volatile *Base, long long Offset ) )
    { return (unsigned char)( ( (unsigned long long)__sync_fetch_and_or( Base, TKORT_BIT64( Offset ) )
                                >> ( Offset & 63 ) ) & 1 ); }
TKORT_IL( unsigned char, tkort_il_btr64, "_interlockedbittestandreset64",
          ( long long volatile *Base, long long Offset ) )
    { return (unsigned char)( ( (unsigned long long)__sync_fetch_and_and( Base, ~TKORT_BIT64( Offset ) )
                                >> ( Offset & 63 ) ) & 1 ); }
TKORT_IL( unsigned char, tkort_il_btc64, "_interlockedbittestandcomplement64",
          ( long long volatile *Base, long long Offset ) )
    { return (unsigned char)( ( (unsigned long long)__sync_fetch_and_xor( Base, TKORT_BIT64( Offset ) )
                                >> ( Offset & 63 ) ) & 1 ); }

#undef TKORT_BIT64
#undef TKORT_BIT32
#undef TKORT_IL

#endif /* TKORT_MSVC */
