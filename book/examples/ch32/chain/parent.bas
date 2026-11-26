'' CHAIN runs another program, waits for it, and returns its exit code.
#ifdef TIKO_OS_WINDOWS
    const CHILD = "child.exe"
#else
    const CHILD = "./child"
#endif

print "parent: chaining"
dim as long rc = chain( CHILD )
print "parent: back; the child's exit code was"; rc
print "a missing program gives"; chain( "no-such-program" )
