'' fbclaim.bi -- the process-wide claim lock
''
'' RFC-0002 section 5.1.  Held only across a test-and-set of one boolean on a
'' channel wait record, so that a waiter registered on N channels -- which is
'' what a SELECT is -- wakes exactly once.
''
'' It is process-wide and lives in the runtime because it must be: a
'' 'dim shared' in a .bi included by two modules gives two mutexes, and there is
'' no lock available to guard a lazy first-use initialisation from FreeBASIC.
''
'' LOCK ORDER: channel lock(s) first, then this, never the reverse.  It is a
'' leaf and must stay one.

#pragma once

namespace FB

'' EXTERN "C" is required: inside a namespace, ALIAS sets the base identifier
'' but FreeBASIC still applies namespace mangling on top of it.
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
declare sub ClaimLock   alias "fb_ClaimLock"  ( )
declare sub ClaimUnlock alias "fb_ClaimUnlock"( )
end extern

end namespace
