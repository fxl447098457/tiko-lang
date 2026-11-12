[Home](Home) › [Filesystem](Category-Filesystem) › [File Streams](Category-File-Streams) › **Stream.WriteText**

# Stream.WriteText

Writes a string in a text encoding, the bytes WriteAllText would write.

## Syntax

```freebasic
Stream.WriteText( s, enc [, mode ] )      '' FsResultBool
```

## Notes

- Writes s encoded in enc, BOM included when enc asks for one, so a stream receives exactly the bytes WriteAllText( p, s, enc ) writes to a file.
- Text written in pieces wants the BOM once: pass the BOM-less form after the first piece, such as Utf16LE( false ), or use a TextWriter, which does that itself.
- Strict by default: a character enc cannot hold fails with FS_INVALID_DATA and nothing is written. With TEXT_REPLACE it becomes ?, the write succeeds, and Value( ) is false.
- An encoding the platform does not support, such as Ansi( ) on Linux and macOS, fails with FS_UNSUPPORTED.
- See [Choosing An Encoding](Category-File-Streams#choosing-an-encoding).

## Examples

```freebasic
#import "std/fs"
using fs

dim as MemoryStream m
m.WriteText( "caf" & wchr( &hE9 ), Utf16LE( ) )
print m.Length( )    '' 10: the BOM, then four two-byte characters
```

---

**Library:** [Filesystem Library](Category-Filesystem)
**Category:** [File Streams](Category-File-Streams)
**Documented under:** Streams
