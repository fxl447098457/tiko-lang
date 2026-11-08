'' smoke: classes, virtual dispatch, operator overloading -- the t2 shape.
'' expect: animal:(silence)
'' expect: rex: Woof
'' expect: base says:Woof
type Animal extends Object
	name as ustring
	declare virtual function Speak( ) as ustring
end type
function Animal.Speak( ) as ustring
	return "(silence)"
end function
type Dog extends Animal
	declare function Speak( ) as ustring override
end type
function Dog.Speak( ) as ustring
	return "Woof"
end function
dim a as Animal = type( "generic" )
dim d as Dog = type( "rex" )
print "animal:"; a.Speak( )
print d.name; ": "; d.Speak( )
sub SpeakTo( byref a as Animal )
	print "  base says:"; a.Speak( )
end sub
SpeakTo( d )
