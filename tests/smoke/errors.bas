'' smoke: Result, defer -- the error path without exceptions.
'' expect: 10/2 = 5
'' expect: error caught:true
'' expect: in sub
'' expect: cleanup 2 (reversed)
'' expect: cleanup 1
#import "std/outcome"
function SafeDiv( byval a as double, byval b as double ) as outcome.Result( of double, ustring )
	if b = 0 then return outcome.Fail( of double, ustring )( "division by zero" )
	return outcome.Ok( of double, ustring )( a / b )
end function
dim r = SafeDiv( 10, 2 )
print "10/2 ="; r.Value( )
dim bad = SafeDiv( 1, 0 )
print "error caught:"; bad.IsOk( ) = false
sub Cleanup( )
	defer print "cleanup 2 (reversed)"
	defer print "cleanup 1"
	print "in sub"
end sub
Cleanup( )
