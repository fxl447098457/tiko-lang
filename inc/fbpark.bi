'' fbpark.bi -- the park/unpark layer.
''
'' Specified by C:\dev\docs\goroutines\RFC-0001-park.md.
''
'' A parker is a per-thread blocking primitive that can wake ONE specific
'' waiter, WITH a timeout.  CondWait can do neither, which is why this exists:
'' it has no timed form, and a condition variable's waiters live inside the
'' condition variable, so the only wakes available are "one, of the runtime's
'' choosing" and "all".
''
'' This is an IMPLEMENTATION LAYER for Channel( of T ), the scheduler and
'' SELECT.  It is not part of the language surface, nothing here becomes a
'' keyword, and it is not in the language reference.  It lives in namespace FB
'' rather than at global scope so that a program does not acquire a global
'' 'Park'.
''
'' THE CONTRACT, in full -- every clause is load-bearing:
''
''   * The permit is STICKY.  An Unpark that arrives before the matching Park
''     is remembered, and that Park returns immediately having consumed it.
''     Without this, every wait in the system has a lost-wakeup race.
''   * The permit is BINARY, not counted.  Two Unparks with no intervening
''     Park leave one permit.
''   * Spurious wakeups are permitted.  Every caller waits in a loop on its own
''     predicate.
''   * ParkTimed returns FALSE if and only if the deadline expired without a
''     permit.  A caller that gets FALSE must still re-check its predicate.
''   * Timing is monotonic: a timed park is not affected by a system clock
''     change.
''   * Unpark on a parker whose thread has exited is safe.
''   * One parker, one thread.  Not reentrant, not shareable.
''
'' A parker is a kernel object.  Create one per THREAD and cache it for the
'' thread's life -- never one per wait, which would put a kernel object
'' create/destroy on every channel operation.
''
'' ParkerCreate returns NULL on the targets that have no threading (dos, js,
'' xbox).  Callers must check: a NULL parker that silently "worked" would turn
'' an unsupported platform into a channel that never delivers.

#pragma once

namespace FB

'' EXTERN "C" IS REQUIRED, not decoration.  Inside a namespace, ALIAS sets the
'' base identifier but FreeBASIC still applies namespace mangling on top of it,
'' so these resolved to 'FB::fb_Park' and failed to link against the C runtime.
'' fbthread.bi does not need this only because it declares at global scope.
'' FBCALL is __stdcall on 32-bit Windows and nothing everywhere else, so the
'' runtime exports _fb_Foo@N there and fb_Foo elsewhere.  An EXTERN "C" block
'' forces cdecl and fails to link on win32 ONLY -- and ALIAS does not rescue it,
'' because inside a NAMESPACE fbc mangles past the alias.  So match the
'' convention rather than fight it.
''
'' Found by rebuilding the win32 toolchain, not by any win64 test: win64 has one
'' calling convention and cannot tell the two apart.
#ifdef __FB_WIN32__
	#ifdef __FB_64BIT__
		extern "rtlib"
	#else
		extern "Windows"
	#endif
#else
	extern "C"
#endif

'' The calling thread's parker, created on first use and destroyed when the
'' thread exits.  This is what callers should use -- a parker is a kernel
'' object, and creating one per wait would put a create/destroy on the hot path
'' of every rendezvous channel operation.  Safe because a thread is in at most
'' one channel wait at a time.
declare function ParkerSelf    alias "fb_ParkerSelf"    ( ) as any ptr

declare function ParkerCreate  alias "fb_ParkerCreate"  ( ) as any ptr
declare sub      ParkerDestroy alias "fb_ParkerDestroy" ( byval parker as any ptr )
declare sub      Park          alias "fb_Park"          ( byval parker as any ptr )
declare function ParkTimed     alias "fb_ParkTimed"     ( byval parker as any ptr, byval ms as ulong ) as long
declare sub      Unpark        alias "fb_Unpark"        ( byval parker as any ptr )

'' Logical processor count, at least 1.  Wrong inside a container with a CPU
'' quota, and it is what every other language's runtime uses.
declare function CpuCount      alias "fb_CpuCount"      ( ) as long

end extern

end namespace
