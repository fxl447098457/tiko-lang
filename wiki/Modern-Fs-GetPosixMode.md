[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **GetPosixMode**

# GetPosixMode

Returns a file's permission bits on Linux and macOS; fails as unsupported on Windows.

## Syntax

```freebasic
GetPosixMode( p )
```

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "hello" )

'' THE POSIX PERMISSION BITS, AND POSIX ONLY. Off that platform it
'' returns FS_UNSUPPORTED rather than inventing a value -- so this is
'' one to branch on ONCE AT STARTUP, not to treat as a transient
'' failure.
dim r as FsResultULong = GetPosixMode( p )

print r.IsOk( )              '' FALSE on Windows

if r.IsOk( ) then
    print r.Value( ) > 0
else
    print r.Failure( ).Code( ) = FS_UNSUPPORTED      '' -1 (true) on Windows
end if

'' Calling Value( ) on that failed Result RAISES -- IsOk is not
'' optional here. IsReadOnly is the portable question.

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Links And Permissions
