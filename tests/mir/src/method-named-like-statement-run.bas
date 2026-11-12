'' Methods named like statement keywords. In a member body fbc looks the name up before it
'' tries the statement: its own method and an inherited one are both a plain call.
type Base1
    as integer v
    declare sub Close( )
    declare sub Get( )
    declare sub Put( byval n as integer )
    declare sub Name( )
    declare sub Line( byval n as integer )
    declare sub Swap( )
    declare sub Print( )
    declare sub Input( )
    declare function Open( ) as long
    declare function Seek( ) as long
end type

sub Base1.Close( )
    this.v += 1
end sub
sub Base1.Get( )
    this.v += 10
end sub
sub Base1.Put( byval n as integer )
    this.v += n
end sub
sub Base1.Name( )
    this.v += 1000
end sub
sub Base1.Line( byval n as integer )
    this.v += n
end sub
sub Base1.Swap( )
    this.v += 100000
end sub
sub Base1.Print( )
    this.v += 1000000
end sub
sub Base1.Input( )
    this.v += 10000000
end sub
function Base1.Open( ) as long
    return 7
end function
function Base1.Seek( ) as long
    return 8
end function

type Derived extends Base1
    declare sub Doit( )
    declare sub Own( )
    declare function Own2( ) as long
end type

'' Inherited, each in the shape that used to stop the build or be refused.
sub Derived.Doit( )
    Close( )
    Get( )
    Put( 100 )
    Name( )
    Line( 2 )
    Swap( )
    Print( )
    Input( )
end sub

'' The same names on the type itself, a sibling method calling them.
type Self1
    as integer v
    declare sub Close( )
    declare sub Get( )
    declare sub Name( )
    declare function Close2( ) as long
    declare sub Doit( )
end type
sub Self1.Close( )
    this.v += 1
end sub
sub Self1.Get( )
    this.v += 10
end sub
sub Self1.Name( )
    this.v += 100
end sub
function Self1.Close2( ) as long
    return 3
end function
sub Self1.Doit( )
    Close( )
    Close
    Get( )
    Name
end sub

'' A method's value in expression position: it is the method's, not fb_FileCloseAll's.
type Value1
    as integer v
    declare function Close( ) as long
    declare sub Doit( )
end type
function Value1.Close( ) as long
    this.v = 5
    return 42
end function
sub Value1.Doit( )
    dim as long r = Close( )
    print r; this.v
end sub

'' 'color( )' with empty parentheses is 'color', and a statement beside a method of another
'' type keeps its meaning: nothing here has a 'color' or 'print' method named on it.
type Plain1
    as integer v
    declare sub Doit( )
end type
sub Plain1.Doit( )
    Color( )
    print "plain"
end sub

dim as Derived d
d.Doit( )
print d.v
dim as Self1 s
s.Doit( )
print s.v
dim as Value1 w
w.Doit( )
dim as Plain1 pl
pl.Doit( )
