[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **FileInfo.NativeAttributes**

# FileInfo.NativeAttributes

Returns the raw attribute word: attributes on Windows, mode bits on Linux and macOS.

## Syntax

```freebasic
FileInfo.NativeAttributes( )
```

## Notes

- dwFileAttributes / st_mode

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "hello" )

'' The raw platform word: dwFileAttributes on Windows, st_mode on
'' POSIX.
dim info as FileInfo = Stat( p ).Value( )

print info.NativeAttributes( ) > 0       '' -1 (true)

'' CODE USING IT IS PLATFORM CODE, by definition -- the bits mean
'' different things on each side. Prefer IsReadOnly, IsHidden and the
'' rest wherever they cover the question.

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** Metadata
