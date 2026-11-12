[Home](Home) › [All Categories](Categories) › [Filesystem](Category-Filesystem) › **File Streams**

# File Streams

```freebasic
#import "std/fs"
using fs

dim as ustring dir_ = CreateTempDir( "tkdoc" ).Value( )
dim as ustring p = PathJoin( dir_, "log.txt" )

WriteAllText( p, "first" & chr( 10 ) )         ' a whole file in one call
AppendAllText( p, "second" & chr( 10 ) )

dim as File f
if( f.OpenAppend( p ).IsOk( ) ) then           ' an open file is a Stream
    dim as TextWriter tw = TextWriter( f )
    tw.NewLine = chr( 10 )
    tw.WriteLine( "third" )
    f.Close( )
end if

for each ln in ReadLines( p )                  ' one line at a time, never the whole file
    if( ln.IsOk( ) ) then print ln.Value( )
next

dim as MemoryStream m                          ' a Stream over memory
m.WriteUtf8( "in memory" )
print m.ToUtf8Text( )

RemoveDirAll( dir_ )
```

## Why It Exists

This page is the half of std/fs that reads and writes what is inside a file. Paths, file information, directories, copying, links and volumes are on [Filesystem](Category-Filesystem).

**Whole files in one line.** ReadAllText, ReadAllLines and ReadAllBytes read a file; WriteAllText and WriteAllBytes write one; WriteAtomic replaces it so that a reader sees the old file or the new one, never a half-written one.

**An open file that closes itself.** File opens in place, closes in its destructor, and reads, writes, seeks, locks and syncs through one handle.

**One stream type for everything.** File, MemoryStream and your own types share the Stream base, so Copy, the buffered wrappers and the text readers work on any of them.

**Text that reads the same everywhere.** TextReader, ReadLines and ReadAllText honour the same byte-order marks, default to UTF-8 and split lines the same way, so a file read whole and the same file read a line at a time agree.

## Using It

Everything here is in the same module as the rest of the library:

```freebasic
#import "std/fs"
using fs
```

Every call that can fail returns a Result carrying an [FsError](Category-Filesystem#errors) -- the codes, the messages and the result aliases are described there. A File, a Stream and a wrapper report through the same codes; FS_CLOSED, FS_UNEXPECTED_EOF, FS_NOT_SEEKABLE and FS_INVALID_DATA are the ones you meet mostly here.

## Whole Files

```text
ReadAllText( p [, maxBytes ] )         FsResultUStr
ReadAllBytes( p, buf [, maxBytes ] )   FsResultI64 -- fills Array( of uint8 )
ReadAllLines( p, lines )               FsResultLong -- fills Array( of ustring )
WriteAllText( p, s )                   FsResultBool
WriteAllBytes( p, buf )                FsResultBool
AppendAllText( p, s )                  FsResultBool
AppendAllBytes( p, buf )               FsResultBool
WriteAtomic( p, s )                    FsResultBool -- see below
WriteAtomic( p, bytes )                Array( of ubyte ), written as given
```

Each text call also takes a text encoding: see [Choosing An Encoding](#choosing-an-encoding).

### Text Encoding

With no encoding named, five rules:

1. **A BOM is honoured and consumed** -- UTF-8, UTF-16LE and UTF-16BE. It is not part of the returned text.
2. **No BOM means UTF-8.** Not the ANSI codepage, not the console codepage, on any platform -- a codepage default would make the same file read differently on two machines.
3. **Invalid input is replaced, not rejected.** ReadAllText on a binary file succeeds and returns mojibake. If you need to know, read bytes.
4. **WriteAllText writes UTF-8 with no BOM.** Name `Utf8( true )` if you need one.
5. **ReadAllLines splits on `\n` and strips a preceding `\r`**, so CRLF, LF and a mixed file give the same lines. A final newline does not produce a trailing empty line; an empty file gives zero lines. A lone `\r` is not a terminator -- classic Mac endings are not supported.

A file that starts with a UTF-32 byte-order mark (FF FE 00 00 or 00 00 FE FF) is refused with FS_UNSUPPORTED by every call that chooses the encoding itself -- ReadAllText, ReadAllLines, ReadLines and a TextReader -- rather than read as UTF-16 or UTF-8. A call given an encoding believes it.

Reading a directory is FS_IS_A_DIRECTORY on every platform. A file too large to allocate is FS_NO_SPACE, not a truncation.

### Choosing An Encoding

The rules above apply when you name no encoding. To read or write another encoding, add a `TextEncoding`, the same one [std/codec](Category-Codec#text-encodings) uses:

```freebasic
#import "std/fs"
using fs

dim as ustring dir_ = CreateTempDir( "fbdoc" ).Value( )
dim as ustring p = PathJoin( dir_, "notes.txt" )

WriteAllText( p, "café", Utf16LE( ) )              ' FF FE 63 00 61 00 66 00 E9 00
print ReadAllText( p, Utf16LE( ) ).Value( )         ' café

dim r as FsResultBool = WriteAllText( p, "snow " & wchr( &h2603 ), CodePage( 1252 ) )
print r.IsOk( )                  ' false: 1252 has no snowman, so nothing was written
r = WriteAllText( p, "snow " & wchr( &h2603 ), CodePage( 1252 ), TEXT_REPLACE )
print r.IsOk( ), r.Value( )      ' true  false: written, but the snowman became ?

RemoveDirAll( dir_ )
```

```text
ReadAllText( p, enc [, mode ] )            mode TEXT_REPLACE by default
ReadAllLines( p, lines, enc [, mode ] )
WriteAllText( p, s, enc [, mode ] )        mode TEXT_STRICT by default
AppendAllText( p, s, enc [, mode ] )
WriteAtomic( p, s, enc [, mode ] )
Stream.WriteText( s, enc [, mode ] )       the bytes WriteAllText would write
MemoryStream.ToText( enc [, mode ] )       the text ReadAllText would read
```

The encodings are `Utf8( [bom] )`, `Utf16LE( [bom] )`, `Utf16BE( [bom] )`, `Ansi( )`, `CodePage( n )` and `BinaryMode( )`. `fs.TextEncoding` is `codec.TextEncoding` under another name. A program with both `using fs` and `using codec` has to qualify these names.

- **The encoding you name is the one used.** A BOM that matches it is skipped. Any other leading bytes are text, so reading a file that starts with a UTF-8 BOM as `Ansi( )` gives you the three BOM characters. UTF-16 drops an odd last byte.
- **Writes are strict by default.** If a character cannot be written in the encoding, the call fails with FS_INVALID_DATA and the file is not touched. With TEXT_REPLACE each such character becomes `?`, the write succeeds, and the result's value is `false`. A value of `true` means every character was written exactly. Characters are never replaced by lookalikes.
- **BOMs.** `Utf16LE( )` and `Utf16BE( )` write one unless you pass `false`. `Utf8( )` writes one only as `Utf8( true )`. A code page and `BinaryMode( )` never do.
- **AppendAllText checks the BOM.** If the file starts with a BOM for a different UTF encoding, the call fails with FS_INVALID_DATA and the file is not changed. A new or empty file gets the encoding's BOM. A file that already has text never gets a second one.
- **`BinaryMode( )`** reads each byte as the character with the same number, U+0000 to U+00FF. The text writes back to exactly the same bytes, so any file round-trips.
- **`Ansi( )`** is the system's ANSI code page, and exists only on Windows. On Linux and macOS, use `CodePage( 1252 )` or another built-in code page.
- A call with no encoding behaves as before. `WriteAllText( p, s, Utf8( ) )` writes exactly the bytes `WriteAllText( p, s )` does.

### WriteAtomic

What it actually guarantees, because the word is routinely oversold:

| Guarantee | |
| --- | --- |
| a reader sees the old file or the new one, never a partial | **yes** |
| survives a crash mid-call | **yes** |
| the new contents survive power loss once it returns Ok | **yes** |

It writes a temporary in the same directory as the target -- not the system temp directory, which is often on another volume and would destroy the atomicity -- named from the platform CSPRNG and created exclusively. It flushes the temporary to the disk, renames it over the target write-through, and on POSIX syncs the directory too. The temporary takes the target's permission bits on POSIX, so a 0600 file stays 0600. It never touches RND, so a seeded program's random sequence is unchanged. The temporary is removed on every failure path.

The durability costs a synchronous flush or two per call. That is the price of the name: a replace that can leave an empty file after a power cut protects nothing.

## Files

```text
File                      an open file: a Stream over a handle it owns
  .Open( p, opts ) .OpenRead( p ) .Create( p ) .CreateNew( p ) .OpenAppend( p )
  .OpenTemp( [ dir ] [, prefix ] )     created exclusively, Read + Write, never auto-deleted
  .Close( )               FsResultBool -- reports the close's own error
  .ReadAt( pos, buf, n ) / .WriteAt( pos, buf, n )   positional; the position does not move
  .Size( ) .SetSize( n ) .Sync( ) .SyncData( ) .Stat( )
  .Lock( [ exclusive ] ) .TryLock( [ exclusive ] ) .Unlock( )
  .IsOpen( ) .Path( ) .NativeHandle( )
OpenOptions               Read Write Append Truncate Create CreateNew
                          ShareRead ShareWrite ShareDelete Inheritable NoFollow PosixMode
OpenOptionsRead( ) / OpenOptionsWrite( ) / OpenOptionsAppend( )
```

**A File is opened in place and closes itself.** Declare it, call one of the Open methods, and its destructor closes the handle when it goes out of scope. It cannot be copied -- pass it byref -- and every operation on a closed File fails with FS_CLOSED.

**It is unbuffered.** Every Read and Write is one system call, so wrap many small ones in a buffer, or build the output in a MemoryStream and write it once.

**Sharing is permissive by default**, on Windows as on Linux and macOS: a file you have open can still be read, written, renamed and deleted by other programs. ShareRead, ShareWrite and ShareDelete narrow that on Windows. **Handles are not inherited** by child processes unless Inheritable is set.

**Positional IO does not move the position.** ReadAt and WriteAt work at an offset and leave Position( ) where it was, on every platform, and may be called from several threads on one File. WriteAt is refused on an Append File.

**Locks are whole-file and belong to the handle.** Lock waits, TryLock fails with FS_WOULD_BLOCK, and closing the File releases its lock. They use the same mechanism as FileLock, so the two exclude each other.

## Records

```text
RecordFile( of T )        a file of fixed-size records of T, numbered from 1
  .Open( p [, recordLen ] ) / .Open( p, opts [, recordLen ] )   read + write + create by default
  .GetRecord( n, r )      FsResultBool -- false, r untouched, if record n is not all there
  .PutRecord( n, r )      FsResultBool -- past the end grows the file
  .Append( r )            FsResultI64 -- the new record's number
  .Count( )               FsResultI64 -- whole records only
  .Close( ) .IsOpen( ) .RecordLength( )
  for each r in rf        each an FsResult of T
ReadRecord( of T )( f, n, r ) / WriteRecord( of T )( f, n, r ) / RecordCount( of T )( f )
                          the same, on a File you opened yourself
```

**Records are numbered from 1**, and record n is the bytes at ( n - 1 ) times the record length, which is sizeof( T ) unless Open is given a longer one for a file whose records are padded. This is the model of [Random](Random) files, with the failures returned as values.

**A record that is not there is not an error.** Reading past the end, or a short last record, gives a value of false and leaves the record as it was; Count( ) does not count a short record. Writing past the end grows the file, and the records in the gap read as zeros. Append can never leave a gap.

**T must be plain data**: numbers, zstring * n and wstring * n, and types made of those. A ustring, string, pointer or dynamic array is written as the address it holds, which means nothing when the file is read back, and nothing checks this for you. The bytes are T's bytes in memory, padding included; `field = 1` removes the padding, and [std/codec](Category-Codec)'s Get and Put helpers lay out a format that must read the same on another machine.

**It owns its File.** A RecordFile closes itself when it goes out of scope; do not copy one, pass it byref. There are no record locks: File.Lock locks the whole file.

## Streams

```text
Stream                    the byte-stream base type
  .Read( buf, n )         FsResultI64 -- may be short; Ok( 0 ) is the end
  .Write( buf, n )        FsResultI64 -- may be short, never 0
  .Seek( offset [, origin ] )   FsResultI64 -- the new absolute position
  .Flush( )               FsResultBool
  .ReadExact( buf, n )    FsResultBool -- FS_UNEXPECTED_EOF if the data ends first
  .ReadToEnd( buf )       FsResultI64 -- APPENDS to an Array( of ubyte )
  .WriteAll( buf, n ) / .WriteBytes( buf ) / .WriteUtf8( s )
  .WriteText( s, enc [, mode ] )   FsResultBool -- false if written lossily
  .Position( )            FsResultI64
  .CanRead( ) .CanWrite( ) .CanSeek( )
MemoryStream              a growable byte buffer; a value
  .Length( ) .ToBytes( buf ) .ToUtf8Text( ) .ToText( enc [, mode ] ) .Clear( )
Copy( src, dst [, bufSize ] )   FsResultI64 -- src's position to its end
```

**One base type, with capability queries.** A tiko type has one base, so a stream that both reads and writes cannot extend a Reader and a Writer. Stream carries every operation and says which ones work. The operations it cannot do fail with FS_UNSUPPORTED.

**Your own stream overrides the operations it supports.** Read, Write, Seek and Flush are virtual and return a Result; override the ones your stream can do, and CanRead, CanWrite and CanSeek to match. An override keeps the contract itself, the argument rule included. [Stream](Modern-Fs-Stream) has a complete example.

**Short reads and writes are normal.** Read may return fewer bytes than asked; only Ok( 0 ) means the end. Write may write fewer than asked. ReadExact, WriteAll and Copy are the loops that make that invisible.

**MemoryStream.ToUtf8Text decodes exactly as ReadAllText does** -- the same byte-order marks, the same UTF-8 default, the same U+FFFD for invalid input -- so text built in memory and text read from a file compare equal.

### Buffered And Text

```text
BufferedReader( inner [, capacity ] )   a Stream: .ReadByte .ReadUntil .ReadLine (bytes) .Peek
BufferedWriter( inner [, capacity ] )   a Stream: small writes passed on in large pieces
TextReader( inner [, mode ] )           .ReadLine( line ) .ReadToEnd( s ) .Encoding( ) .Detected( )
TextReader( inner, enc [, mode ] )      in a named TextEncoding
TextReader( inner, opts [, mode ] )     detecting the encoding: a TextDetect
TextWriter( inner [, writeBom ] )       .Write( s ) .WriteLine( [ s ] ) .NewLine .Flush( )
TextWriter( inner, enc [, mode ] )      in a named TextEncoding; TEXT_STRICT by default
ReadLines( p [, mode ] )                for each line -- one FsResultUStr per line, lazily
ReadLines( p, enc [, mode ] )           in a named TextEncoding
TextErrorMode                           TEXT_REPLACE (U+FFFD) or TEXT_STRICT (FS_INVALID_DATA)
```

**A wrapper does not own what it wraps.** Each keeps a pointer to the stream it was given, which must outlive it, and none can be copied.

**Lines are ReadAllLines' lines**, in every reader: a line ends at LF, one CR before it is dropped, a CR anywhere else is text, the last line needs no LF, and a final LF is not followed by an empty line.

**Text is ReadAllText's text.** TextReader honours the same byte-order marks, defaults to UTF-8 the same way and replaces invalid input the same way, so a file read whole and the same file read through a TextReader agree. TextWriter writes UTF-8, with NewLine platform-native by default.

**With an encoding, the same holds encoding by encoding.** `TextReader( s, enc )` reads as `ReadAllText( p, enc )` does, and `ReadLines( p, enc )` gives `ReadAllLines( p, lines, enc )`'s lines. Code pages and `BinaryMode( )` are cut into lines at the LF byte; no code page uses that byte inside a character. `TextReader( s, opts )` detects as `ReadAllText( p, found, opts )` does, but it judges only the first `opts.PrefixBytes` bytes (64 KiB) before its first line. A file whose first invalid UTF-8 comes after that point is read as UTF-8 by the stream, and in the fallback by the whole-file call. `Detected( )` says what the reader is using.

**A TextWriter with an encoding encodes each Write in full before writing any of it.** Under TEXT_STRICT, the default, a Write that holds a character the encoding cannot represent fails with FS_INVALID_DATA and writes nothing, not even the BOM. A Write that succeeds returns `true` when every character was written exactly, and `false` when TEXT_REPLACE turned one into `?`.

```freebasic
#import "std/fs"
using fs

dim as ustring dir_ = CreateTempDir( "fbdoc" ).Value( )
dim as ustring p = PathJoin( dir_, "log.txt" )

scope
    dim as File f
    f.Create( p )
    dim as TextWriter w = TextWriter( f, Utf16LE( ) )   ' FF FE, then UTF-16LE
    w.WriteLine( "first" )
    w.WriteLine( "caf" & wchr( &hE9 ) )
end scope

for each ln in ReadLines( p, Utf16LE( ) )
    print ln.Value( )                                   ' first, café
next

' Detection: a BOM, else UTF-8, else the fallback -- here Windows-1252
dim as File g
g.OpenRead( p )
dim as TextReader r = TextReader( g, TextDetect( CodePage( 1252 ) ) )
dim as ustring s
r.ReadLine( s )
print s, r.Encoding( ), r.Detected( ).Bom             ' first  utf-16le  true
g.Close( )

RemoveDirAll( dir_ )
```


**ReadLines never holds the file in memory**, yields its failures as elements, and closes the file when the loop is left early.

## Implementation

The tiko side, in pkg/std/fs/:

| File | Holds |
| --- | --- |
| fsops.tiko | ReadAllText, WriteAllText and the rest of the whole-file calls, WriteAtomic |
| fsstream.tiko | Stream, MemoryStream, Copy |
| fsfile.tiko | OpenOptions and File |
| fstext.tiko | BufferedReader, BufferedWriter, TextReader, TextWriter, ReadLines, the whole-file size limits, AppendAllBytes |

The byte-order-mark and encoding rules are in tiko-rt's lib/rt/src/fs/text.tiko, shared by every reader on this page.

## Tests

Run tests in tests/codegen/:

| Test | Covers |
| --- | --- |
| fs-p2 | the Stream contract, a stream defined outside the library, Copy, and MemoryStream decoding as ReadAllText does |
| fs-p3 | File: the option rules, every disposition, append, positional IO, SetSize, Stat, locks, inheritance, NoFollow, OpenTemp |
| fs-file-nocopy | a File cannot be copied or assigned |
| fs-p4 | buffered and text layers through a one-byte-at-a-time stream, line for line against ReadAllLines, ReadLines closing on exit for, the size limits |

The whole-file encoding rules and WriteAtomic's guarantees are tested with the rest of the library; see [Filesystem](Category-Filesystem#tests).

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Files and folders](Functions-Files) lists them beside the rest of the area.

### Read or write a whole file

| Function | What it does | From |
|---|---|---|
| [ReadAllText](Modern-Fs-ReadAllText) | Reads a whole file as UTF-8 text into a string, or fails if it cannot be read. | `std/fs` |
| [ReadAllLines](Modern-Fs-ReadAllLines) | Reads a file's lines into an Array, without their line endings; returns the count. | `std/fs` |
| [ReadAllBytes](Modern-Fs-ReadAllBytes) | Reads a whole file into an Array of bytes; returns the number read. | `std/fs` |
| [WriteAllText](Modern-Fs-WriteAllText) | Writes a string to a file as UTF-8, creating the file or replacing it. | `std/fs` |
| [WriteAllBytes](Modern-Fs-WriteAllBytes) | Writes an Array of bytes to a file, creating the file or replacing it. | `std/fs` |
| [AppendAllText](Modern-Fs-AppendAllText) | Adds text to the end of a file, creating the file if it is not there. | `std/fs` |
| [AppendAllBytes](Modern-Fs-AppendAllBytes) | Adds an Array of bytes to the end of a file, creating the file if it is not there. | `std/fs` |
| [WriteAtomic](Modern-Fs-WriteAtomic) | Replaces a file so a reader sees the old or the new contents, never a half-written file. | `std/fs` |

### File numbers: open and close files

| Function | What it does | From |
|---|---|---|
| [Random](Random) | Opens a file with Open for reading and writing fixed-size records, 128 bytes by default. | built-in |

### Read and write text a line at a time

| Function | What it does | From |
|---|---|---|
| [ReadLines](Modern-Fs-ReadLines) | Reads a file a line at a time in a for each loop, never holding the whole file in memory. | `std/fs` |
| [TextReader](Modern-Fs-TextReader) | Holds a reader that decodes lines and text from any Stream, in UTF-8 or UTF-16. | `std/fs` |
| [TextReader.ReadLine](Modern-Fs-TextReader-ReadLine) | Reads the next decoded line into a string; returns false at the end. | `std/fs` |
| [TextReader.ReadToEnd](Modern-Fs-TextReader-ReadToEnd) | Appends all the remaining decoded text to a string. | `std/fs` |
| [TextReader.Encoding](Modern-Fs-TextReader-Encoding) | Returns the encoding found at the start: utf-8, utf-16le or utf-16be. | `std/fs` |
| [TextErrorMode](Modern-Fs-TextErrorMode) | Holds what a TextReader does with invalid UTF-8: replace it or fail. | `std/fs` |
| [TextWriter](Modern-Fs-TextWriter) | Holds a writer that sends text to any Stream as UTF-8, with an optional BOM. | `std/fs` |
| [TextWriter.WriteLine](Modern-Fs-TextWriter-WriteLine) | Writes a string followed by the writer's NewLine. | `std/fs` |

### File: open a file and work in place

| Function | What it does | From |
|---|---|---|
| [File](Modern-Fs-File) | Holds an open file: a Stream over a handle it owns and closes when it goes out of scope. | `std/fs` |
| [File.Open](Modern-Fs-File-Open) | Opens a file the way an OpenOptions says: read, write, append, create and more. | `std/fs` |
| [File.OpenRead](Modern-Fs-File-OpenRead) | Opens an existing file for reading only. | `std/fs` |
| [File.Create](Modern-Fs-File-Create) | Opens a file for writing, creating it or emptying it first. | `std/fs` |
| [File.CreateNew](Modern-Fs-File-CreateNew) | Creates a new file for writing; fails if one is already there. | `std/fs` |
| [File.OpenAppend](Modern-Fs-File-OpenAppend) | Opens a file so every write goes to its end, creating it if needed. | `std/fs` |
| [File.OpenTemp](Modern-Fs-File-OpenTemp) | Creates and opens a new, randomly named file in a folder or the temporary folder. | `std/fs` |
| [File.Close](Modern-Fs-File-Close) | Closes the file and reports any error the close itself raised. | `std/fs` |
| [File.IsOpen](Modern-Fs-File-IsOpen) | Returns true if the File has a file open. | `std/fs` |
| [File.Path](Modern-Fs-File-Path) | Returns the path the file was opened with. | `std/fs` |
| [File.ReadAt](Modern-Fs-File-ReadAt) | Reads up to n bytes at an offset without moving the position. | `std/fs` |
| [File.WriteAt](Modern-Fs-File-WriteAt) | Writes bytes at an offset without moving the position; refused in append mode. | `std/fs` |
| [File.Size](Modern-Fs-File-Size) | Returns the open file's current size in bytes. | `std/fs` |
| [File.SetSize](Modern-Fs-File-SetSize) | Truncates the file to a size, or extends it with zero bytes. | `std/fs` |
| [File.Sync](Modern-Fs-File-Sync) | Forces the file's data and metadata onto the disk, so a write survives a power cut. | `std/fs` |
| [File.SyncData](Modern-Fs-File-SyncData) | Forces the file's data onto the disk; can be cheaper than Sync on Linux. | `std/fs` |
| [File.Stat](Modern-Fs-File-Stat) | Returns the open file's FileInfo, read from the handle even if the file was renamed. | `std/fs` |
| [File.Lock](Modern-Fs-File-Lock) | Locks the whole file, waiting until it is free: exclusive by default, or shared. | `std/fs` |
| [File.TryLock](Modern-Fs-File-TryLock) | Locks the whole file if it is free, or fails at once if another holder has it. | `std/fs` |
| [File.Unlock](Modern-Fs-File-Unlock) | Releases this handle's lock; succeeds when none is held. | `std/fs` |
| [File.Id](Modern-Fs-File-Id) | Returns the FileId of the open file, still right after a rename. | `std/fs` |
| [File.NativeHandle](Modern-Fs-File-NativeHandle) | Returns the operating-system handle or descriptor, or -1 when closed. | `std/fs` |
| [OpenOptions](Modern-Fs-OpenOptions) | Holds the flags that say how File.Open opens a file: read, write, create, share and more. | `std/fs` |
| [OpenOptionsRead](Modern-Fs-OpenOptionsRead) | Returns the OpenOptions for reading a file that must already exist. | `std/fs` |
| [OpenOptionsWrite](Modern-Fs-OpenOptionsWrite) | Returns the OpenOptions for writing a new file or an existing one emptied. | `std/fs` |
| [OpenOptionsAppend](Modern-Fs-OpenOptionsAppend) | Returns the OpenOptions for adding to the end of a file, creating it if needed. | `std/fs` |

### Streams: read and write bytes

| Function | What it does | From |
|---|---|---|
| [Stream](Modern-Fs-Stream) | Holds the base type of every byte stream, with read, write, seek and flush. | `std/fs` |
| [Stream.Read](Modern-Fs-Stream-Read) | Reads up to n bytes and returns how many; 0 means the end of the data. | `std/fs` |
| [Stream.ReadExact](Modern-Fs-Stream-ReadExact) | Reads exactly n bytes, or fails if the data ends first. | `std/fs` |
| [Stream.ReadToEnd](Modern-Fs-Stream-ReadToEnd) | Appends every remaining byte to an Array; returns how many. | `std/fs` |
| [Stream.Write](Modern-Fs-Stream-Write) | Writes up to n bytes and returns how many it wrote, which may be fewer. | `std/fs` |
| [Stream.WriteAll](Modern-Fs-Stream-WriteAll) | Writes all n bytes, calling Write as often as it takes. | `std/fs` |
| [Stream.WriteBytes](Modern-Fs-Stream-WriteBytes) | Writes every byte of an Array. | `std/fs` |
| [Stream.WriteUtf8](Modern-Fs-Stream-WriteUtf8) | Writes a string as UTF-8, with no BOM. | `std/fs` |
| [Stream.Seek](Modern-Fs-Stream-Seek) | Moves the position from the start, the current place or the end; returns the new position. | `std/fs` |
| [Stream.Position](Modern-Fs-Stream-Position) | Returns the current position, or fails on a stream that cannot seek. | `std/fs` |
| [Stream.Flush](Modern-Fs-Stream-Flush) | Passes any buffered bytes on to where they are going. | `std/fs` |
| [Stream.CanRead](Modern-Fs-Stream-CanRead) | Returns true if Read can succeed on this stream. | `std/fs` |
| [Stream.CanWrite](Modern-Fs-Stream-CanWrite) | Returns true if Write can succeed on this stream. | `std/fs` |
| [Stream.CanSeek](Modern-Fs-Stream-CanSeek) | Returns true if Seek can succeed on this stream. | `std/fs` |
| [SeekOrigin](Modern-Fs-SeekOrigin) | Holds where Stream.Seek measures from: the start, the current position or the end. | `std/fs` |
| [Copy](Modern-Fs-Copy) | Copies a stream from its position to its end into another; returns the byte count. | `std/fs` |
| [MemoryStream](Modern-Fs-MemoryStream) | Holds a growable byte buffer in memory that reads, writes and seeks like a file. | `std/fs` |
| [MemoryStream.Length](Modern-Fs-MemoryStream-Length) | Returns the number of bytes held, whatever the position. | `std/fs` |
| [MemoryStream.Clear](Modern-Fs-MemoryStream-Clear) | Empties the stream; its length and position become 0. | `std/fs` |
| [MemoryStream.ToBytes](Modern-Fs-MemoryStream-ToBytes) | Copies every byte held into an Array; returns the count. | `std/fs` |
| [MemoryStream.ToUtf8Text](Modern-Fs-MemoryStream-ToUtf8Text) | Returns the bytes held decoded as text, the same way ReadAllText decodes a file. | `std/fs` |
| [BufferedReader](Modern-Fs-BufferedReader) | Holds a Stream that reads another in large pieces, so many small reads stay fast. | `std/fs` |
| [BufferedReader.ReadByte](Modern-Fs-BufferedReader-ReadByte) | Reads the next byte; returns false at the end. | `std/fs` |
| [BufferedReader.ReadLine](Modern-Fs-BufferedReader-ReadLine) | Reads the next line as raw bytes in a string, not decoded; returns false at the end. | `std/fs` |
| [BufferedReader.ReadUntil](Modern-Fs-BufferedReader-ReadUntil) | Appends bytes up to and including a delimiter to an Array; returns the count. | `std/fs` |
| [BufferedReader.Peek](Modern-Fs-BufferedReader-Peek) | Copies up to n upcoming bytes into an Array without consuming them. | `std/fs` |
| [BufferedWriter](Modern-Fs-BufferedWriter) | Holds a Stream that gathers small writes and passes them on in large pieces. | `std/fs` |

<!-- finder:end -->

---

[Home](Home) · [Filesystem](Category-Filesystem) · [Keyword Index](Keyword-Index)
