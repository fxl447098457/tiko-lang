[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **FileInfo.IsHidden**

# FileInfo.IsHidden

Returns true if hidden: the hidden flag on Windows, a leading dot on Linux and macOS.

## Syntax

```freebasic
FileInfo.IsHidden( )
```

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "hello" )

print Stat( p ).Value( ).IsHidden( )      '' false

SetHidden( p, true )
print Stat( p ).Value( ).IsHidden( )     '' true

'' PORTABLE IN NAME ONLY: the hidden attribute on Windows, a leading dot
'' on POSIX -- and on POSIX that means SetHidden RENAMES the file
SetHidden( p, false )

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Metadata
