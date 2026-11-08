'' smoke: #cinclude against the mingw headers -- the C-interop path -- beside a
'' USER-WRITTEN extern "rtlib" declare with the RUNTIME'S OWN signature: fb_GetEnviron
'' takes the FBSTRING descriptor (it reads varname->data and releases the temp), which
'' a zstring-ptr spelling hands it garbage and segfaults -- measured. The prelude's
'' own environ declare is the same signature; this exercises the user-written half.
'' expect: cbrt(27) = 3
'' expect: env ok:-1
#cinclude once "math.h"
extern "rtlib"
	declare function fb_GetEnviron( byref n as const string ) as string
end extern
print "cbrt(27) ="; cbrt( 27.0 )
print "env ok:"; len( fb_GetEnviron( "PATH" ) ) > 0
