[Home](Home) › [Filesystem](Category-Filesystem) › [File Streams](Category-File-Streams) › **File.ReadAt**

# File.ReadAt

Reads up to n bytes at an offset without moving the position.

## Syntax

```freebasic
File.ReadAt( pos, buf, n )
```

## Notes

- Reads up to n bytes at pos without moving the position, on every platform.
- Past the end it reads 0 bytes. pos < 0 is FS_INVALID_ARGUMENT; a pipe is FS_NOT_SEEKABLE.
- Safe to call from several threads on one File.

## Examples

```freebasic
#import "std/fs"
using fs

dim as ustring dir_ = CreateTempDir( "tkdoc" ).Value( )
dim as ustring p = PathJoin( dir_, "f.txt" )
WriteAllText( p, "0123456789" )
dim as File f
f.OpenRead( p )
dim as ubyte b( 0 to 3 )
print f.ReadAt( 6, @b(0), 4 ).Value( ), chr( b(0) )    '' 4 6
print f.Position( ).Value( )    '' 0 -- unmoved
f.Close( )

RemoveDirAll( dir_ )
```

---

**Library:** [Filesystem Library](Category-Filesystem)
**Category:** [File Streams](Category-File-Streams)
**Documented under:** Files
