'' TIKO_OS_* / TIKO_ARCH_* agree with the legacy __FB_WIN32__ / __FB_LINUX__ /
'' __FB_DARWIN__, are "1" so '#if' works as well as '#ifdef', and each target has exactly
'' one OS and one architecture.
#ifdef __FB_WIN32__
    #ifndef TIKO_OS_WINDOWS
        #error "TIKO_OS_WINDOWS not defined on Windows"
    #endif
    #if defined( TIKO_OS_LINUX ) orelse defined( TIKO_OS_MACOS ) orelse defined( TIKO_OS_ANDROID )
        #error "another TIKO_OS_* defined on Windows"
    #endif
#endif
#ifdef __FB_LINUX__
    #ifndef TIKO_OS_LINUX
        #error "TIKO_OS_LINUX not defined on Linux"
    #endif
    #if defined( TIKO_OS_WINDOWS ) orelse defined( TIKO_OS_MACOS ) orelse defined( TIKO_OS_ANDROID )
        #error "another TIKO_OS_* defined on Linux"
    #endif
#endif
#ifdef __FB_DARWIN__
    #ifndef TIKO_OS_MACOS
        #error "TIKO_OS_MACOS not defined on Darwin"
    #endif
    #if defined( TIKO_OS_WINDOWS ) orelse defined( TIKO_OS_LINUX ) orelse defined( TIKO_OS_ANDROID )
        #error "another TIKO_OS_* defined on Darwin"
    #endif
#endif
#ifdef __FB_ANDROID__
    #ifndef TIKO_OS_ANDROID
        #error "TIKO_OS_ANDROID not defined on Android"
    #endif
    #if defined( TIKO_OS_WINDOWS ) orelse defined( TIKO_OS_LINUX ) orelse defined( TIKO_OS_MACOS )
        #error "another TIKO_OS_* defined on Android"
    #endif
    #ifdef __FB_LINUX__
        #error "__FB_LINUX__ defined on Android -- fbc does not"
    #endif
#endif
#if defined( TIKO_ARCH_X86_64 ) = defined( TIKO_ARCH_ARM64 )
    #error "not exactly one TIKO_ARCH_* defined"
#endif
#ifdef TIKO_ARCH_X86_64
    #if TIKO_ARCH_X86_64 <> 1
        #error "TIKO_ARCH_X86_64 is not 1"
    #endif
    #ifndef __FB_X86__
        #error "TIKO_ARCH_X86_64 without __FB_X86__"
    #endif
    #print arch=x86_64
#endif
#ifdef TIKO_ARCH_ARM64
    #if TIKO_ARCH_ARM64 <> 1
        #error "TIKO_ARCH_ARM64 is not 1"
    #endif
    #if defined( __FB_X86__ ) orelse defined( __FB_ASM__ ) orelse (defined( __FB_ARM__ ) = 0)
        #error "TIKO_ARCH_ARM64 with the x86 defines, or without __FB_ARM__"
    #endif
    #print arch=arm64
#endif
#if defined( TIKO_OS_WINDOWS )
    #if TIKO_OS_WINDOWS <> 1
        #error "TIKO_OS_WINDOWS is not 1"
    #endif
    #print os=windows
#elseif defined( TIKO_OS_LINUX )
    #if TIKO_OS_LINUX <> 1
        #error "TIKO_OS_LINUX is not 1"
    #endif
    #print os=linux
#elseif defined( TIKO_OS_MACOS )
    #if TIKO_OS_MACOS <> 1
        #error "TIKO_OS_MACOS is not 1"
    #endif
    #print os=macos
#elseif defined( TIKO_OS_ANDROID )
    #if TIKO_OS_ANDROID <> 1
        #error "TIKO_OS_ANDROID is not 1"
    #endif
    #print os=android
#else
    #error "no TIKO_OS_* defined"
#endif
print 1
