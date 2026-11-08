'' smoke: freefile and environ -- the prelude's FBCALL declares against the archive.
'' expect: freefile ok:-1
'' expect: environ ok:-1
dim as long fh = freefile
dim as string v = environ( "PATH" )
print "freefile ok:"; fh >= 0
print "environ ok:"; len( v ) > 0
