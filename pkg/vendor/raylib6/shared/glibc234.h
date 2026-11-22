/* glibc234.h -- forced into every raylib source file by build.sh ('-include'), so the shared
 * library it builds runs on glibc 2.34 or later whatever glibc the build host has.
 *
 * glibc gave these libm functions a new symbol version after 2.34 -- hypot and hypotf at 2.35,
 * fmod and fmodf at 2.38 (the old wrappers' SVID error handling dropped) -- and a library linked
 * on a newer host imports the new version, which an older glibc does not have. Each reference
 * is bound to the x86-64 base version instead, GLIBC_2.2.5, which every glibc still exports;
 * the results are the same for any argument, only errno handling under the long-gone
 * _LIB_VERSION differs. Measured on Ubuntu 22.04 (glibc 2.35): without this the library
 * imports hypot@GLIBC_2.35 and hypotf@GLIBC_2.35; raylib's own release build, made on a newer
 * glibc, also fmod@GLIBC_2.38 and fmodf@GLIBC_2.38. build.sh fails if any version newer than
 * 2.34 is still imported, so a new one is added here, not shipped. */
#if defined(__linux__) && defined(__x86_64__)
__asm__( ".symver hypot,hypot@GLIBC_2.2.5" );
__asm__( ".symver hypotf,hypotf@GLIBC_2.2.5" );
__asm__( ".symver fmod,fmod@GLIBC_2.2.5" );
__asm__( ".symver fmodf,fmodf@GLIBC_2.2.5" );
#elif defined(__linux__) && defined(__aarch64__)
/* aarch64's base version is GLIBC_2.17, the first glibc for the architecture
 * (docs/tiko-linux-arm64 L4); the same four functions, bound there. */
__asm__( ".symver hypot,hypot@GLIBC_2.17" );
__asm__( ".symver hypotf,hypotf@GLIBC_2.17" );
__asm__( ".symver fmod,fmod@GLIBC_2.17" );
__asm__( ".symver fmodf,fmodf@GLIBC_2.17" );
#endif
