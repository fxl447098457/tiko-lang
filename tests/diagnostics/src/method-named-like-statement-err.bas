'' Statement keywords and same-named methods, the programs fbc refuses. Each used to stop
'' the build with an internal error (TKO0993 or TKO0994), not with a diagnostic.
type Filer
    as integer v
    declare sub Close( )
    declare sub Print( )
    declare sub Doit( )
    declare sub Other( )
end type

sub Filer.Close( )
end sub
sub Filer.Print( )
end sub

'' fbc settles on the method first: 'Close #1' here is its error 3, not the file statement.
sub Filer.Doit( )
    Close #1
    Print "x"
end sub

'' No Close method in reach, so 'Close( )' is the statement, and it has no argument for '( )'.
type NoFile
    as integer v
    declare sub Doit( )
end type
sub NoFile.Doit( )
    Close( )
end sub

sub Foo( )
end sub

'' A statement call passing too many arguments.
Foo "x"

'' '( )' holds no expression anywhere.
print ( )
dim as integer x = 1 + ( )
