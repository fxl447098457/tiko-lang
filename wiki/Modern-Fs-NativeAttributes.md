[Home](Home) › [Filesystem](Category-Filesystem) › [Filesystem Library](Category-Filesystem) › **FileInfo.NativeAttributes**

# FileInfo.NativeAttributes

Returns the raw attribute word: attributes on Windows, mode bits on Linux and macOS.

## Syntax

```freebasic
FileInfo.NativeAttributes( )
```

## Examples

```freebasic
#import "std/fs"
using fs

dim td as FsResultUStr = CreateTempDir( "fbdoc" )
dim as ustring dir_ = td.Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "hello" )

'' The FileInfo accessor for the same raw word: dwFileAttributes on
'' Windows, st_mode on POSIX. It comes back with the Stat that was
'' already made, so it costs no extra syscall.
dim info as FileInfo = Stat( p ).Value( )

print info.NativeAttributes( ) > 0        '' -1 (true)

'' The bits mean different things on each platform, so anything reading
'' them is platform code. Prefer IsReadOnly, IsHidden, IsFile and the
'' rest wherever they answer the question.

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)  
**Category:** [Filesystem](Category-Filesystem)  
**Documented under:** What Is Not Here
