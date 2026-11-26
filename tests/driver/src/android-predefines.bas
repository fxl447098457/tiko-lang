#ifdef __FB_ANDROID__
    #print ANDROID
#endif
#ifdef __FB_UNIX__
    #print UNIX
#endif
#ifdef __FB_X86__
    #print X86
#endif
#ifdef __FB_64BIT__
    #print HAS64
#endif
#ifdef TIKO_OS_ANDROID
    #print OS_ANDROID
#endif
#ifdef TIKO_ARCH_X86_64
    #print ARCH_X86_64
#endif
#print __FB_ASM__
#ifdef __FB_LINUX__
    #print LINUXDEF
#endif
#ifdef TIKO_OS_LINUX
    #print OSLINUX
#endif
#ifdef __FB_PCOS__
    #print PCOS
#endif
#ifdef __FB_WIN32__
    #print WIN
#endif
