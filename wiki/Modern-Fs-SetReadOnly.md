[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **SetReadOnly**

# SetReadOnly

Sets or clears a file's read-only flag, or its write bits on Linux and macOS.

## Syntax

```freebasic
SetReadOnly( p, v )
```

## Notes

- portable

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "hello" )

print SetReadOnly( p, true ).IsOk( )      '' true
print Stat( p ).Value( ).IsReadOnly( )    '' true

'' PORTABLE: the read-only attribute on Windows, the owner write bit on
'' POSIX -- each platform's own model, not a translation
print SetReadOnly( p, false ).IsOk( )     '' true

'' Clear it before deleting: a read-only file cannot be removed

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Links And Permissions
