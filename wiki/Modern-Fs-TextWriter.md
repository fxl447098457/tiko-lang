[Home](Home) › [Filesystem](Category-Filesystem) › [File Streams](Category-File-Streams) › **TextWriter**

# TextWriter

Holds a writer that sends text to any Stream as UTF-8, with an optional BOM.

## Syntax

```freebasic
type TextWriter
    declare constructor( byref inner as Stream, byval writeBom as boolean = FALSE )
    declare constructor( byref inner as Stream, byval enc as TextEncoding, byval mode as TextErrorMode = TEXT_STRICT )
    as ustring NewLine        '' chr( 13, 10 ) on Windows, chr( 10 ) on Linux and macOS
    Write( s ) / WriteLine( [ s ] ) / Flush( )
end type
```

## Notes

- A wrapper does not own what it wraps: it keeps a pointer to the stream it was given, which must outlive it. It cannot be copied.
- UTF-8. With writeBom the byte-order mark is written once, before the first text. A lone surrogate is written as U+FFFD.
- With an encoding: its byte-order mark, if it has one, before the first text. Each Write is encoded in full before any of it is written. Under TEXT_STRICT, the default, a Write holding a character the encoding cannot represent fails with FS_INVALID_DATA and writes nothing. Under TEXT_REPLACE that character becomes ?, and the call returns false instead of true. See [Choosing An Encoding](Category-File-Streams#choosing-an-encoding).
- NewLine is platform-native by default. Set it to chr( 10 ) for a file that must be identical on every platform. Only WriteLine uses it; Write writes its text exactly as given.
- It buffers nothing itself: wrap a BufferedWriter for many small writes.

## Examples

```freebasic
#import "std/fs"
using fs

dim as MemoryStream m
dim as TextWriter tw = TextWriter( m )
tw.NewLine = chr( 10 )
tw.WriteLine( "first" )
tw.Write( "second" )
print m.Length( )    '' 12
```

---

**Library:** [Filesystem Library](Category-Filesystem)
**Category:** [File Streams](Category-File-Streams)
**Documented under:** Streams
