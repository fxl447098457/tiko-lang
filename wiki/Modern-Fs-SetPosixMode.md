[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **SetPosixMode**

# SetPosixMode

Sets a file's permission bits on Linux and macOS; fails as unsupported on Windows.

## Syntax

```freebasic
SetPosixMode( p, mode )
```

## Notes

- FS_UNSUPPORTED on Windows

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "hello" )

'' POSIX ONLY, like GetPosixMode: on Windows every call fails with
'' FS_UNSUPPORTED, including the ones that look harmless.
dim r as FsResultBool = SetPosixMode( p, &o644 )

print r.IsOk( )              '' FALSE on Windows
if r.IsOk( ) = false then
    print r.Failure( ).Code( ) = FS_UNSUPPORTED      '' -1 (true)
end if

'' Use SetReadOnly for the portable question -- it is the read-only
'' attribute on Windows and the owner write bit on POSIX, which is the
'' same operation on each platform's own model
print SetReadOnly( p, true ).IsOk( )      '' true, on both
SetReadOnly( p, false )

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Links And Permissions
