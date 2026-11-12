[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **SetHidden**

# SetHidden

Sets or clears a file's hidden flag on Windows; fails as unsupported on Linux and macOS.

## Syntax

```freebasic
SetHidden( p, v )
```

## Notes

- Portable in name only. On Windows it sets or clears FILE_ATTRIBUTE_HIDDEN. On Linux and macOS a hidden file is one whose name starts with a dot, and rather than rename the file behind your back it fails with FS_UNSUPPORTED.

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "hello" )

print SetHidden( p, true ).IsOk( )         '' true
print Stat( p ).Value( ).IsHidden( )       '' true

'' PORTABLE IN NAME ONLY. On Windows it sets an attribute. On Linux and macOS
'' hidden means a leading dot in the name, and renaming the file is a
'' different operation, so there the call fails with FS_UNSUPPORTED
'' and the file is left alone.
SetHidden( p, false )

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Links And Permissions
