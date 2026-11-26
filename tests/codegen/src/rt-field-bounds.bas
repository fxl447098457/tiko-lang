'' See rt-field-bounds-run.test. The field is 3002 wide; the lines come back 2048.
dim as string f = "\" & space( 3000 ) & "\"
dim as string s = string( 4000, "x" )
dim as string ln

open "rt-field-bounds.tmp" for output as #1
print #1, using f; s
print #1, using f; "ab"
close #1

open "rt-field-bounds.tmp" for input as #1
line input #1, ln
print "long " & len( ln )
line input #1, ln
print "short " & len( ln )
close #1
kill "rt-field-bounds.tmp"

'' 300 characters before the colon: not "COMn", so the name is a device path, copied as it is.
open com string( 300, "A" ) & ":9600" as #2
print "com " & err
