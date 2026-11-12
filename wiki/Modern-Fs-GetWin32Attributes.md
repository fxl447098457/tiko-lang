[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **GetWin32Attributes**

# GetWin32Attributes

Returns a file's raw Windows attribute flags; fails as unsupported on Linux and macOS.

## Syntax

```freebasic
GetWin32Attributes( p )
```

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "hello" )

'' The raw dwFileAttributes word. WINDOWS ONLY -- elsewhere it fails
'' rather than inventing a value.
dim r as FsResultULong = GetWin32Attributes( p )

print r.IsOk( )              '' true on Windows
if r.IsOk( ) then print r.Value( ) > 0    '' -1 (true)

'' Code that reads this is platform code by definition. IsReadOnly and
'' IsHidden are the portable questions.

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Links And Permissions
