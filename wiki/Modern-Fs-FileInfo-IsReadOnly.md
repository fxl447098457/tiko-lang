[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **FileInfo.IsReadOnly**

# FileInfo.IsReadOnly

Returns true if unwritable: the read-only flag, or no write bit on Linux and macOS.

## Syntax

```freebasic
FileInfo.IsReadOnly( )
```

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "hello" )

print Stat( p ).Value( ).IsReadOnly( )    '' false

SetReadOnly( p, true )
print Stat( p ).Value( ).IsReadOnly( )   '' true

'' PORTABLE: the read-only attribute on Windows, the owner write bit on
'' POSIX. Clear it again before deleting, or the removal fails.
SetReadOnly( p, false )

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Metadata
