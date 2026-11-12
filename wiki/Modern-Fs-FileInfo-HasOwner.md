[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **FileInfo.HasOwner**

# FileInfo.HasOwner

Returns true if OwnerUid and OwnerGid are filled in: on Linux and macOS, not on Windows.

## Syntax

```freebasic
FileInfo.HasOwner( )
```

## Notes

- TRUE on POSIX, where OwnerUid and OwnerGid hold the file's user and group ids. FALSE on Windows, whose owners are security identifiers this library does not model.

## Examples

```freebasic
#import "std/fs"
#import "std/chrono"
using fs

dim as ustring dir_ = CreateTempDir( "tkdoc" ).Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "x" )
dim as FileInfo fi = Stat( p ).Value( )
#ifdef __FB_WIN32__
print fi.HasOwner( )    '' false
#else
print fi.HasOwner( )    '' true
#endif

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)
**Category:** [Filesystem](Category-Filesystem)
**Documented under:** Metadata
