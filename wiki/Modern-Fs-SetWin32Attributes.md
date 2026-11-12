[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **SetWin32Attributes**

# SetWin32Attributes

Replaces a file's whole Windows attribute word; fails as unsupported on Linux and macOS.

## Syntax

```freebasic
SetWin32Attributes( p, attrs )
```

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "hello" )

'' Windows only, and it sets the WHOLE word -- read the current value
'' and modify it, rather than assigning a bare constant, or every other
'' attribute is cleared
dim cur as FsResultULong = GetWin32Attributes( p )

if cur.IsOk( ) then
    const FILE_ATTRIBUTE_HIDDEN = &h2
    print SetWin32Attributes( p, cur.Value( ) or FILE_ATTRIBUTE_HIDDEN ).IsOk( )
    print Stat( p ).Value( ).IsHidden( )  '' true
    SetWin32Attributes( p, cur.Value( ) )
end if

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Links And Permissions
