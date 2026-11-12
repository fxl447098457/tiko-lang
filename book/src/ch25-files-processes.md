# Files, Processes and the Environment

Almost every useful program reads something it did not make and leaves something behind: a
configuration file, a log, a folder of results, an exit code a build script checks. This chapter
is about that boundary — the files a program reads and writes, the directories around them, the
console it talks through, the other programs it starts, and the machines it talks to over the
network.

Files are the **`std/fs` module**: an open `File` and the streams layered on it, a path algebra, a
single `Stat` call for every fact about a file, directory walks with `for each`, whole-file reads
and writes, and the directories a program keeps its own files in. Configuration files in TOML and
INI are **`std/config`**; addresses, sockets and URLs are **`std/net`**. Every operation that can fail
returns a `Result` (Chapter 18) rather than raising a runtime error, so a missing file is a value
the program looks at, not a crash.

```tiko
#import "std/fs"
```

## Files and streams

### Text files

A `File` is opened in place and **closes itself** when it goes out of scope. A `TextWriter`
writes text to it, and `ReadLines` reads a file back a line at a time with `for each`:

```tiko
{{#include ../examples/ch25/textfile.tiko}}
```

```text
{{#include ../examples/ch25/textfile.out}}
```

`Create` makes the file, or empties one that is there; `OpenAppend` keeps what is there and writes
at the end; `OpenRead` opens for reading only. The `scope` blocks are where each `File` ends: its
destructor closes the handle, and the `TextWriter` declared after it is destroyed first, so nothing
is left unwritten. A `File` cannot be copied — pass it `byref`.

`WriteLine` ends each line the way the platform does: carriage return and line feed on Windows,
line feed alone on Linux and macOS. Set the writer's `NewLine` to `chr( 10 )` for files that must be the
same bytes everywhere. `ReadLines` accepts either ending, removes it, and yields one
`Result( of ustring, FsError )` per line — `ln.Value( )` is the text. It holds one line in memory at
a time, whatever the size of the file, and leaving the loop early closes the file.

Text is UTF-8 unless you say otherwise, and a `TextReader` and `ReadLines` also honour a byte-order
mark at the start of a file, for UTF-8 and UTF-16 text written by other programs.

### Text in other encodings

Not every file is UTF-8. Windows tools save UTF-16, and older programs save in a **code page** such
as Windows-1252, one byte per character, in which the same letters are different bytes. Every text
call in std/fs takes an encoding as an extra, last argument:

```tiko
{{#include ../examples/ch25/encodings.tiko}}
```

```text
{{#include ../examples/ch25/encodings.out}}
```

An encoding is a `TextEncoding`. `Utf8( )` is the default; `Utf16LE( )` and `Utf16BE( )` write a
byte-order mark unless passed `false`; `CodePage( n )` is a Windows code page by number, and
`Ansi( )` the one the machine is set to, on Windows only; `BinaryMode( )` reads byte n as character
n, so any file reads and writes back unchanged. `ReadAllText`, `ReadAllLines`, `WriteAllText`,
`AppendAllText`, `WriteAtomic`, `ReadLines`, `TextReader` and `TextWriter` all take one, and so do
`Stream.WriteText` and `MemoryStream.ToText` for bytes in memory.

A read with an encoding **believes it**: a byte-order mark that matches is skipped, and any other
bytes are text. Bytes that are not valid in the encoding become U+FFFD, or fail under `TEXT_STRICT`.
When the encoding is not known, pass a `TextDetect` instead, as the listing does: a byte-order mark
decides, else UTF-8 if the bytes are valid UTF-8, else the fallback it names, and `found` says which
was used. A file that starts with a UTF-32 mark is refused with `FS_UNSUPPORTED`, never misread.

A write is **strict by default**. A character the encoding cannot hold fails with
`FS_INVALID_DATA` before the file is opened, so the file keeps what it had. Pass `TEXT_REPLACE` to
write a `?` in its place instead; the write then succeeds and its value is `false`, meaning "written,
but not exactly". `AppendAllText` with an encoding refuses to add UTF-16 to a file that starts with
a UTF-8 mark, or the other way round.

### Opening a file

Every open returns a `Result( of boolean, FsError )`, and the error says why:

```tiko
{{#include ../examples/ch25/openfile.tiko}}
```

```text
{{#include ../examples/ch25/openfile.out}}
```

| Method | Opens for | An existing file is | A missing file |
|---|---|---|---|
| `OpenRead( p )` | reading | read | fails, `FS_NOT_FOUND` |
| `Create( p )` | writing | **emptied** | created |
| `CreateNew( p )` | writing | refused, `FS_ALREADY_EXISTS` | created |
| `OpenAppend( p )` | writing at the end | kept | created |
| `Open( p, options )` | what `OpenOptions` says | as the options say | as the options say |

An `OpenOptions` names what the program needs: `Read`, `Write`, `Append`, `Truncate`, `Create` and
`CreateNew`. A combination that makes no sense — `Append` with `Truncate`, `CreateNew` without
`Write` — is refused before anything is opened. An operation the `File` was not opened for fails
too: writing to a file opened for reading is a failure, not a silent nothing.

Other programs may still read, write, rename and delete a file you have open; on Windows the
`ShareRead`, `ShareWrite` and `ShareDelete` options narrow that. A handle is **not** passed to the
programs this one starts unless `Inheritable` is set.

### Fields in a line

The simplest file format a program can save and read again is one record per line with its fields
separated by commas:

```tiko
{{#include ../examples/ch25/fields.tiko}}
```

```text
{{#include ../examples/ch25/fields.out}}
```

A field that contains a comma is written inside double quotes, and `strings.SplitCsvRow` splits a
line into its fields with the quotes removed, so `hopper, grace` survives the round trip. `valint`
and `val` turn the text fields back into numbers. For anything that other programs must read,
prefer a format both sides agree on.

### Records at a position

A file of fixed-size records can be read and written **by number**, without touching the records
around the one you want. A `RecordFile( of T )` is such a file, of records of the type `T`:

```tiko
{{#include ../examples/ch25/records.tiko}}
```

```text
{{#include ../examples/ch25/records.out}}
```

`Open` opens the file for reading and writing and creates it if it is missing; `Open( p, options )`
takes `OpenOptions` instead. Records are numbered from 1, and record `n` begins
`( n - 1 ) * sizeof( Item )` bytes into the file. `Append` writes after the last record and returns
the new record's number, `GetRecord` and `PutRecord` read and write record `n`, `Count( )` is the
number of whole records, and `for each r in stock` walks them, one `Result` per record. Reading a
record that is not all there — past the end, or a short last record — is not a failure: the value
is `false` and the record is left untouched. Writing past the end grows the file, and the records
in between read as zeros.

Every field must have a fixed size for this to work, which is why `label` is a `string * 8` rather
than a `ustring`: a variable-length string is a pointer, and a pointer written to a file means
nothing when it is read back. Nothing checks this for you. The bytes are the record's bytes in
memory, padding included; `field = 1` removes the padding.

Underneath are `File.ReadAt( position, buffer, count )` and `WriteAt`, which read and write bytes
at any byte position without moving the file's position, and may be called from several threads on
one `File`. Use them for a file that mixes records with other data, and `ReadRecord( of T )`,
`WriteRecord( of T )` and `RecordCount( of T )` for records in a `File` you have opened yourself.

### Binary formats

A record of fixed-size fields is one kind of binary file. Most binary formats — images, archives,
network messages — are laid out byte by byte instead, with each number in a stated width and
**byte order**:

```tiko
{{#include ../examples/ch25/binformat.tiko}}
```

```text
{{#include ../examples/ch25/binformat.out}}
```

`codec.AppendU32BE` appends a 32-bit number **big-endian**, most significant byte first — the order
a person reads, and the one network protocols use. `AppendU16LE` writes **little-endian**, the
order x86 processors keep in memory and most file formats on Windows use. The format decides; the
code must match it field by field, which is why every name carries its width and order: `Get`,
`Put` and `Append`, for `U16` to `U64`, `I16` to `I64`, `F32` and `F64`, each `LE` or `BE`. A `Get`
past the end of the buffer is a run-time error, the same as indexing an array past its end.

The values are **varints**: each byte carries seven bits and a flag saying whether another byte
follows, so 5 takes one byte and a million three. `AppendVarint` first folds the sign in, so that
-2 stays as short as 2. `ReadUVarint( buf, at )` and `ReadVarint` read one value at `at` and move
`at` past it, which is what lets the loop walk the list without knowing where each value ends.

The buffer is a `containers.Array( of ubyte )`, so `fs.WriteAllBytes` and `fs.ReadAllBytes` move it
to and from a file whole, and `MemoryStream` and `File.Write` take its bytes as they are.

### Streams

A `File` is a **`Stream`**: something that bytes can be read from, written to, or both. A
`MemoryStream` is another — a growable buffer in memory — and everything that works on one works on
the other:

```tiko
{{#include ../examples/ch25/streams.tiko}}
```

```text
{{#include ../examples/ch25/streams.out}}
```

`fs.Copy( source, destination )` copies from the source's current position to its end, which is why
the listing seeks the `MemoryStream` back to 0 first. A `TextReader` reads lines from any stream,
here the `File`; `ReadLine` returns `false` when there are no more.

| Type | Is |
|---|---|
| `File` | a file on disk; **unbuffered**: each `Read` and `Write` is one call to the system |
| `MemoryStream` | bytes in memory; `Length( )`, `ToUtf8Text( )` |
| `BufferedReader`, `BufferedWriter` | a buffer over another stream, so many small reads or writes become a few large ones |
| `TextReader`, `TextWriter` | text over another stream: `ReadLine`, `WriteLine` |

A wrapper keeps a pointer to the stream it was given, so that stream must outlive it — declare the
stream first. `Read` may return fewer bytes than asked, and `Ok( 0 )` means the end; `ReadExact`,
`WriteAll` and `Copy` are the loops that make short reads and writes invisible.

A stream of your own extends `fs.Stream` and overrides the operations it supports:

```tiko
{{#include ../examples/ch25/counting.tiko}}
```

```text
{{#include ../examples/ch25/counting.out}}
```

`Read`, `Write`, `Seek` and `Flush` are virtual and return a `Result`. `Counter` overrides `Write`
and says so with `CanWrite`; the operations it does not override fail with `FS_UNSUPPORTED`, and
`CanRead( )` answers `false`. Anything written for a `Stream` — `TextWriter`, `Copy`, a buffer —
now works with it.

## Paths, metadata and directories

### Paths

Paths are strings, and `std/fs` has the functions to take them apart and build them without
touching the disk:

```tiko
{{#include ../examples/ch25/paths.tiko}}
```

On Windows:

```text
{{#include ../examples/ch25/paths.windows-x86_64.out}}
```

On Linux and macOS:

```text
{{#include ../examples/ch25/paths.out}}
```

| Function | Gives |
|---|---|
| `PathJoin( a, b, … )` | the parts joined with the platform's separator |
| `PathParent( p )`, `PathFileName( p )` | everything before the last separator; the last part |
| `PathStem( p )`, `PathExtension( p )` | the file name without, and only, its last extension |
| `PathNormalize( p )` | `.` and `..` resolved, separators made uniform |
| `PathChangeExtension( p, ext )` | `p` with a different extension |
| `PathIsAbsolute( p )`, `PathStartsWith( p, prefix )` | tests |
| `PathRelativeTo( p, base )` | `p` written relative to `base` |

The separator is `\` on Windows and `/` on Linux and macOS, and the functions use the platform's own when
they build a path. A name that begins with a dot, `.gitignore`, has no extension: its stem is the
whole name.

````admonish danger title="Pitfall"
**`PathJoin` with an absolute second part throws the first part away.**

```tiko
{{#include ../examples/ch25/pathescape.tiko}}
```

On Windows:

```text
{{#include ../examples/ch25/pathescape.windows-x86_64.out}}
```

On Linux and macOS:

```text
{{#include ../examples/ch25/pathescape.out}}
```

Joining `"uploads"` with a name a user supplied looks like it keeps the file inside `uploads`. It
does not: an absolute name replaces the folder, and the program reads or writes wherever the name
points. Which names count as absolute differs by platform — on Linux and macOS the Windows-style name is a
harmless file called `C:\Windows\win.ini` inside `uploads`; on Windows it escapes. Check
containment after joining, with `PathStartsWith` on the normalized result, before using a path
built from somebody else's input.
````

### Facts about a file: Stat

```tiko
{{#include ../examples/ch25/stat.tiko}}
```

```text
{{#include ../examples/ch25/stat.out}}
```

`fs.Stat( path )` returns a `Result` holding a `FileInfo` — size, kind, times, read-only and hidden
flags — gathered in one call. A path that is not there is a **failure** whose `FsError` says
`FS_NOT_FOUND`, which is a different answer from `FS_ACCESS_DENIED`. `Exists`, `IsFile` and
`IsDir` answer yes or no and fold every failure into `false`: convenient in an `if`, and unable to
tell "absent" from "not allowed to look". Use `Stat` when the difference matters.

Every `std/fs` operation that can fail returns a `Result` in the same way. `Value( )` on a failure
is a runtime error, so test `IsOk( )` first — the habit from Chapter 18.

### Directories: walking, globbing, copying

```tiko
{{#include ../examples/ch25/copytree.tiko}}
```

```text
{{#include ../examples/ch25/copytree.out}}
```

`CreateTempDir` creates a directory with a fresh, unpredictable name and returns its path — the
safe way to get a scratch area. `ReadDir( p )` walks one directory; `WalkDir( p )` walks a whole
tree, a directory before its contents, with `Depth( )` counting from 0 for the root's own
children. Each element is a `Result`, because a walk can fail part-way — a directory it may not
open is reported as a failed element, and the walk carries on. Directory order is whatever the
file system gives, so the listing sorts before printing.

`Glob( pattern, results )` finds the paths that match a pattern: `*` and `?` within one part of a
path, and `**` for any number of directories, including none. `CopyDir` copies a tree and
`RemoveDirAll` deletes one; each returns how many objects it handled. `RemoveDirAll` deletes a
link inside the tree as a link, without following it, and it opens each directory relative to the
one it is already in, so even another program swapping a directory for a link while the delete
runs cannot send it outside the tree. Given a path that is itself a link, it refuses with
`FS_NOT_A_DIRECTORY` and deletes nothing.

### Whole files, written atomically

```tiko
{{#include ../examples/ch25/wholefile.tiko}}
```

```text
{{#include ../examples/ch25/wholefile.out}}
```

`ReadAllText` reads a file into one `ustring`; `ReadAllLines` splits it into an `Array`, removing
either kind of line ending; `WriteAllText` writes one. Text is UTF-8 unless the file
starts with a byte-order mark that says otherwise.

`WriteAtomic` writes the new content to a temporary file **in the same directory** and then
replaces the target with it. A program reading the file at the same moment sees the old contents
or the new, never half of each, and a crash during the write leaves the old file intact. That is
the right way to save a configuration or a document. What it does not promise is survival of a
power failure at that instant, which needs the operating system's cooperation beyond any library.

### Mapped files, locks and temporary files

```tiko
{{#include ../examples/ch25/advanced.tiko}}
```

```text
{{#include ../examples/ch25/advanced.out}}
```

A `MemoryMappedFile` makes a file's bytes appear in memory: `Data( )` is a pointer to them, and a
write through it changes the file. It is the fastest way to read a large file at random, and it is
a raw pointer — invalid after `Close( )`, and a fault if another program shortens the file while it
is mapped.

A `FileLock` keeps other cooperating programs away from a file while it is held. It is **advisory**:
on Linux and macOS it binds only programs that also ask for the lock, and the library promises no more than
that on Windows either. `CreateTempFile` creates a file under a fresh name and returns the path;
nothing deletes it for you.

`std/fs` also has a `FileWatcher`, which reports files created, changed, renamed and deleted under
a directory when the program calls its `Poll` method. Its events depend on the platform and on
timing — a single save can arrive as several events — so treat each batch as a reason to look
again rather than as an exact log.

### Where a program keeps its files

```tiko
{{#include ../examples/ch25/userdirs.tiko}}
```

```text
{{#include ../examples/ch25/userdirs.out}}
```

| Function | Windows | Linux | macOS |
|---|---|---|---|
| `HomeDir( )` | the user's profile folder | `$HOME`, else the user's account entry | `$HOME`, else the user's account entry |
| `ConfigDir( )` | `AppData\Roaming` | `$XDG_CONFIG_HOME`, else `~/.config` | `$XDG_CONFIG_HOME`, else `~/Library/Application Support` |
| `DataDir( )` | `AppData\Local` | `$XDG_DATA_HOME`, else `~/.local/share` | `$XDG_DATA_HOME`, else `~/Library/Application Support` |
| `CacheDir( )` | `AppData\Local` | `$XDG_CACHE_HOME`, else `~/.cache` | `$XDG_CACHE_HOME`, else `~/Library/Caches` |
| `StateDir( )` | `AppData\Local` | `$XDG_STATE_HOME`, else `~/.local/state` | `$XDG_STATE_HOME`, else `~/Library/Application Support` |
| `ExecutablePath( )` | the program's own file | the program's own file | the program's own file |

**Nothing is created and no program name is added.** Each call says where the directory should
be; join your own program's name, and `CreateDirAll` it before writing there. On Linux and macOS an
`XDG_` variable counts only when it holds an absolute path. `ExecutablePath( )` is the full path of the
running program however it was started, which `command( 0 )` is not — the way to find a file
installed beside the program. `ExpandHome` replaces a leading `~` with the home directory and leaves
every other path as it is.

### Checksums and digests

A **digest** is a short, fixed-size value computed from any amount of data: change one byte and it
changes. `std/hash` computes them:

```tiko
{{#include ../examples/ch25/digest.tiko}}
```

```text
{{#include ../examples/ch25/digest.out}}
```

`DigestHex( algorithm, data )` is the one-call form. Every algorithm is also a type that takes its
data in pieces — `UpdateText`, `UpdateBytes`, or `Update( pointer, count )` — and gives the same
answer as the one call, so a file of any size is hashed a block at a time; `DigestFile` does that
for you. `HmacHex` mixes in a key, so only someone holding the key can produce the value: it is how
a server checks that a message came from someone it trusts.

| Algorithms | Use them for |
|---|---|
| `HASH_CRC32`, `HASH_CRC32C`, `HASH_ADLER32` | catching accidental corruption: zip, PNG, network frames |
| `HASH_FNV1A32`, `HASH_FNV1A64`, `HASH_XXHASH64` | fast hashing of keys and large data |
| `HASH_SHA256`, `HASH_SHA224`, `HASH_SHA512`, `HASH_SHA384` | **anything someone might tamper with**: downloads, signatures, content addresses |
| `HASH_MD5`, `HASH_SHA1` | only to match a format or protocol that already uses them |

The first two rows are not security tools: anyone can make two different files with the same CRC
or FNV value on purpose, and MD5 and SHA-1 have the same weakness. To compare two MACs, use
`hash.ConstantTimeEquals`, which takes the same time whatever the first differing byte is.

## Configuration files and CSV

A program that people install needs settings they can edit, and a program that produces data is
often asked for a spreadsheet. `std/config` reads and writes the two configuration formats most
programs meet, **TOML** and **INI**; the CSV writer sits in `std/strings`, beside `SplitCsv`.

### Reading TOML

TOML is a configuration format with real types: strings, integers, floats, booleans, dates and
times, arrays, and tables that nest. `config.ParseToml` turns the text into a tree of
`TomlValue`s, and `config.LoadToml( path )` does the same for a file:

```tiko
{{#include ../examples/ch25/tomlconfig.tiko}}
```

```text
{{#include ../examples/ch25/tomlconfig.out}}
```

**Every lookup answers a value or nothing, never a crash.** `Path( "server.port" )` follows keys
separated by dots, with a number indexing an array (`"users.1.roles.0"`), and returns an
`Optional`; `AsInt( )`, `AsString( )`, `AsBool( )`, `AsFloat( )` return one too, empty when the
value is of another kind. `Setting` folds the two steps into one, so a missing key such as
`server.wait` falls through to the default the program chose. A default-constructed `TomlValue`
has the kind `TOML_NONE`, and every `As…` on it is empty.

| TOML | `Kind( )` | Read with |
|---|---|---|
| `"text"`, `'text'`, `"""…"""` | `TOML_STRING` | `AsString( )` |
| `42`, `0xFF`, `1_000` | `TOML_INT` | `AsInt( )`, a 64-bit `longint` |
| `3.14`, `5e+22`, `inf`, `nan` | `TOML_FLOAT` | `AsFloat( )`, which also reads an integer |
| `true`, `false` | `TOML_BOOL` | `AsBool( )` |
| `2026-10-19T09:30:00Z` | `TOML_OFFSET_DATETIME` | `AsDateTime( )`, a `chrono.DateTime` with an offset |
| `2026-10-19T09:30:00` | `TOML_LOCAL_DATETIME` | `AsDateTime( )`, without one |
| `2026-10-19`, `09:30:00` | `TOML_LOCAL_DATE`, `TOML_LOCAL_TIME` | `AsLocalDate( )`, `AsLocalTime( )` |
| `[ 1, 2 ]`, `[[users]]` | `TOML_ARRAY` | `Count( )` and `[ i ]` |
| `[server]`, `{ x = 1 }` | `TOML_TABLE` | `Get`, `Find`, `Path`, `Keys`, `KeyAt( i )` |

A table keeps its keys **in the order the file wrote them**, so `Keys( )` and `KeyAt( i )` walk
it the way a reader of the file would. `[[users]]` is an *array of tables*: each `[[users]]`
header starts one more table in the `users` array.

### When a document is wrong

`ParseToml` refuses a document that breaks the format's rules, and the `ConfigError` says where:

```tiko
{{#include ../examples/ch25/tomlerrors.tiko}}
```

```text
{{#include ../examples/ch25/tomlerrors.out}}
```

**A key, or a table, is defined once.** The third document is the subtle one: `apple.color`
under `[fruit]` *defines* the table `fruit.apple` through its dotted key, so a later
`[fruit.apple]` header is a second definition. An integer that does not fit in 64 bits is an
error rather than a float that has quietly lost digits. `Code( )` gives the reason as a
`ConfigErrorCode` — `CFG_SYNTAX`, `CFG_DUPLICATE_KEY`, `CFG_TYPE_REDEFINED`,
`CFG_INVALID_ESCAPE`, `CFG_NUMBER_RANGE`, `CFG_INVALID_DATETIME` — and `Line( )` and `Column( )`
the position, so a program can point its user at the line to fix.

### Changing and writing TOML

The tree can be changed and written back:

```tiko
{{#include ../examples/ch25/tomlwrite.tiko}}
```

```text
{{#include ../examples/ch25/tomlwrite.out}}
```

`Find( key )` returns a pointer into the tree, so `server->SetKey` changes the table in place;
`Get( key )` returns a copy. `SetKey` replaces a key's value or adds the key at the end, `Push`
appends to an array, and `RemoveKey` deletes. `FromInt`, `FromString`, `FromBool`, `FromFloat`,
`FromDateTime`, `FromLocalDate`, `FromLocalTime`, `NewTable` and `NewArray` make the values.

`config.ToTomlText( root )` writes the tree out: each table's plain keys first, then its
sub-tables as `[section]` headers, in the order they were added. **The comment is gone.** The
tree holds values, not the text they came from, so a program that rewrites a hand-edited file
loses its comments. Write settings the program owns to a file of their own, and leave the
user's file to the user.

### INI files

INI is older and simpler: sections of `key = value` lines, every value text.

```tiko
{{#include ../examples/ch25/inifile.tiko}}
```

```text
{{#include ../examples/ch25/inifile.out}}
```

**Names ignore case** unless `IniOptions.CaseSensitiveKeys` says otherwise, so
`Get( "database", "host" )` finds `Host` under `[Database]`. `key: value` works as well as
`key = value`. A line beginning with `;` or `#` is a comment, but a `;` later in a line belongs
to the value. Spaces around a value are dropped unless the value is in double quotes, and the
quotes themselves are removed. Keys before the first `[section]` belong to the section `""`.

`SetValue` replaces a value or adds the key, and the section, at the end; `Remove( section, key )`
deletes a key and `Remove( section )` a whole section. `ToText( )` writes the file back, quoting
the value that needed its quotes. A repeated key replaces the first one, which is what most INI
readers do; `IniOptions.Duplicates = config.INI_DUP_ERROR` makes it an error instead.
`config.LoadIni( path )` and `config.SaveIni( ini, path )` read and write the file itself.

### Writing CSV

`strings.JoinCsvRow` turns an `Array( of ustring )` into one line of CSV, and `CsvWriter`
writes rows to any `fs.Stream`:

```tiko
{{#include ../examples/ch25/csvwrite.tiko}}
```

```text
{{#include ../examples/ch25/csvwrite.out}}
```

**A field is quoted only when it has to be**: when it holds the separator, a double quote or a
line break, or starts or ends with a space. A quote inside a field is doubled. That is the
standard CSV form (RFC 4180), and `SplitCsv` reads it back field for field, as the last line
shows. Records end with CR LF, the standard's line ending, unless the third argument is
`false`; the listing uses LF so that its output prints cleanly. `CsvWriter` keeps the first
failure: later rows are not written, and `Finish( )` reports it.

## Coming from the file statements

tiko still compiles the file statements of the BASIC family — `open`, `print #`, `line input #`,
`get #`, `put #`, `kill`, `mkdir` and the rest — so older programs keep working. New code uses
`std/fs`, where a failure is a value rather than a runtime error or a silent nothing:

| Statement | Does | std/fs |
|---|---|---|
| `open … for output` / `append` / `input` | open a text file | `File.Create`, `OpenAppend`, `OpenRead` |
| `print #`, `line input #`, `eof` | write and read lines | `TextWriter.WriteLine`, `ReadLines`, `TextReader.ReadLine` |
| `write #`, `input #` | comma-separated fields | `WriteLine` of the fields, `strings.SplitCsvRow` |
| `open … for random`, `get #`, `put #` | fixed-size records | `RecordFile`: `GetRecord`, `PutRecord`, `Append` |
| `open … encoding "utf-16"` | text in another encoding | an encoding argument: `ReadAllText( p, Utf16LE( ) )` |
| `lof( f )`, `seek` | length, position | `File.Size( )`, `Seek` |
| `mkdir p`, `rmdir p` | create or remove a directory | `CreateDir`, `CreateDirAll`, `RemoveDir`, `RemoveDirAll` |
| `chdir p`, `curdir( )` | change or read the current directory | `SetCurrentDir`, `CurrentDir` |
| `kill p` | delete a file | `RemoveFile` |
| `name old as new` | rename | `MoveFile` (which also crosses drives) |
| `dir( pattern )`, `dir( )` | first match, then next match | `ReadDir`, `Glob` |
| `exepath( )` | the folder the program is in | `PathParent( ExecutablePath( ).Value( ) )` |

`dir( )` keeps one listing per thread, so two listings cannot be interleaved and a goroutine cannot
continue the main program's (Chapter 23). `ReadDir` has neither limit.

## The console as a device

The console is something a program can draw on — but only when there is a console. When the output
is redirected to a file or a pipe, colour and cursor movement become stray control bytes in
someone else's data:

```tiko
{{#include ../examples/ch25/console.tiko}}
```

```text
{{#include ../examples/ch25/console.out}}
```

`IsRedirected( )`, from `#include once "fbio.bi"`, is true when standard output is not a console;
`IsRedirected( true )` asks the same about standard input. The listing's output above is the
redirected branch, because that is how the book's harness runs it. At a console, `cls` clears the
screen, `color` sets the text colour, `locate row, column` moves the cursor, and `width` sets the
console's size in characters.

For keyboard input, `inkey( )` returns the key waiting to be read, or an empty string at once if
there is none — the right call inside a loop that must keep working. `getkey( )` waits for a key
and returns its code. `sleep ms` pauses for that many milliseconds. `open cons` and `open err` open
the console's output and its error stream as file numbers, for code written against `print #`
(Chapter 19 traced to `open err`).

## Processes and the environment

### Arguments and environment variables

```tiko
{{#include ../examples/ch25/envreport.tiko}}
```

Run as `envreport alpha "two words" 3`:

```text
{{#include ../examples/ch25/envreport.out}}
```

`command( n )` is the `n`-th argument, with quotes already removed, and an empty string past the
last one; `command( 0 )` is the program's own path, and `command( )` all the arguments as one
string. `environ( name )` reads an environment variable — an empty string if it is not set — and
`setenviron "NAME=value"` sets one for this process and the programs it starts.

In the main module, `__FB_ARGC__` is the number of arguments counting the program itself, and
`__FB_ARGV__` the C array of them, a `zstring ptr ptr` — the form a C library that parses its own
command line expects. They belong to the main module's top level, as in fbc: inside a procedure
they are `TKO0743: '__fb_argc__' is not declared`, and another module's top level reads 0.

### The std/os module

`command` and `environ` are short to write, but each loses something: `command( n )` cannot show
an empty argument, because an empty string already means "past the last one", and `environ` cannot
tell a variable that is not set from one set to nothing. `std/os` keeps both apart:

```tiko
{{#include ../examples/ch25/osenv.tiko}}
```

Run as `osenv alpha "two words" ""`:

```text
{{#include ../examples/ch25/osenv.out}}
```

`os.Args( )` is every argument in an `Array( of ustring )`, the program's own path first, Unicode
on every system. `os.GetEnv` returns an `Optional`: empty when the variable is not set, holding
`""` when it is set to nothing. `SetEnv` and `UnsetEnv` return a `Result`, and refuse a name that
is empty or contains `=` with an `OsError` rather than passing it to the system. `ExpandEnv`
replaces `$NAME` and `${NAME}` — and on Windows `%NAME%` — with their values. `Environment( )` is
a sorted snapshot of every variable, as an `OrderedMap`.

The module also answers questions about the machine: `OS_NAME` and `ARCH_NAME` (constants),
`OsVersion( )`, `Hostname( )`, `UserName( )`, `ProcessId( )`, `PageSize( )`, `TotalMemory( )`,
`IsTerminal( fd )`, and `CpuCount( )` — the processors this process may use, which inside a
container or under an affinity mask is fewer than the machine has. That is the number to size a
pool of workers by.

**Set the environment before starting threads.** On Linux and macOS, changing a variable while
another thread reads the environment is not safe, whichever function does it.

### Running other programs

```tiko
{{#include ../examples/ch25/pipe.tiko}}
```

```text
{{#include ../examples/ch25/pipe.out}}
```

| Statement | Runs | Returns |
|---|---|---|
| `shell( "command" )` | a command line, through the system shell | its exit code |
| `exec( program, args )` | a program, directly | its exit code |
| `chain( program )` | a program | its exit code |
| `run program` | a program | nothing: the current program ends |
| `open pipe "command" for input as #f` | a command whose output the program reads | — |

`shell` goes through `cmd.exe` on Windows and `/bin/sh` on Linux and macOS, so the command line is in that
shell's language; `exec` starts a program with no shell in between, which is safer when an argument
came from a user. `open pipe … for input` reads what the command prints, a line at a time, as if it
were a file; `for output` sends lines to its input instead.

### Exit codes

```tiko
{{#include ../examples/ch25/exitcode.tiko}}
```

```text
{{#include ../examples/ch25/exitcode.out}}
```

`end n` ends the program with exit status `n`. Zero means success to every shell and build tool;
anything else is a failure whose number the caller can test — `$?` in a Unix shell, `%ERRORLEVEL%`
in `cmd.exe`, or the return of `shell` and `exec` in another tiko program. A program that can fail
should say so through its exit code, not only through what it prints.

`os.ExitWith( n )` from `std/os` is `end n` under a name a procedure can pass around, and `os.Abort( )`
ends the program at once, skipping every destructor and every buffered write.

### Stopping cleanly on Ctrl-C

Ctrl-C normally ends a console program wherever it happens to be — halfway through writing a file,
with a temporary directory left behind. `os.CatchInterrupt( )` turns it into a flag instead:

```tiko
{{#include ../examples/ch25/interrupt.tiko}}
```

Left alone, it prints:

```text
{{#include ../examples/ch25/interrupt.out}}
```

Press Ctrl-C while it runs and the loop ends at the next check, prints `stopped early after` and
exits with 130, the code a shell reports for a program stopped by Ctrl-C. The program decides
where it is safe to stop; nothing of yours runs at the moment the key is pressed.

`os.Interrupted( )` asks without waiting, `os.WaitInterrupt( ms )` waits, and `os.LastInterrupt( )`
says which kind arrived: `INT_CTRL_C`, `INT_BREAK` (Ctrl-Break, Windows), `INT_TERMINATE` (`SIGTERM`
on Linux and macOS; the console window closing, logoff or shutdown on Windows) or `INT_HANGUP` (`SIGHUP`).
**A second Ctrl-C ends the program at once**, with code 130, so a program that is stuck can still
be stopped; `os.CatchInterrupt( false )` turns that off. On Windows a closing console window gives
the program about five seconds before the system ends it regardless.

## Talking over the network

`std/net` holds the three things a program needs to talk to another machine: **addresses** to say
where, **sockets** to carry the bytes — TCP for a connection, UDP for single messages — and
**URLs**, the text form in which addresses usually arrive.

### Addresses

```tiko
{{#include ../examples/ch25/ipaddr.tiko}}
```

```text
{{#include ../examples/ch25/ipaddr.out}}
```

An `IpAddress` is a value, IPv4 or IPv6, that prints in one canonical form whatever way it was
written: IPv6 in lower case with the longest run of zero groups as `::`. **Parsing is strict.**
`010.0.0.1` is refused rather than read — some systems read a leading zero as octal and reach
`8.0.0.1`, others as decimal, and a filter that checks one reading while a connection uses the other
is a security hole. The `Is…` functions classify an address — `IsLoopback`, `IsPrivate`,
`IsLinkLocal`, `IsMulticast`, `IsGlobalUnicast` — and look through an IPv4 address written as IPv6.
A `SocketAddress` adds a port; written as text an IPv6 one needs brackets, `[::1]:8080`, because
the address itself is full of colons.

`net.Resolve( "example.com", 443 )` asks the system's resolver for a name's addresses and returns
them all, each with the port. An address written as text comes back as itself without a lookup.

### A TCP connection

```tiko
{{#include ../examples/ch25/tcpecho.tiko}}
```

```text
{{#include ../examples/ch25/tcpecho.out}}
```

A `TcpListener` is a server: `Bind` to an address and port — port 0 asks the system for a free one,
which `LocalAddress( )` then reports — and `Accept` each connection into a `TcpStream`. A client
`TcpStream` calls `Connect` with a `SocketAddress`, or `ConnectHost( "example.com", 80 )`, which
resolves the name and tries its addresses in turn. Each of them takes a timeout in milliseconds;
without one a call waits as long as the system lets it.

**A `TcpStream` is a stream**, the same `fs.Stream` as a `File`: `WriteUtf8`, `WriteAll`,
`ReadExact`, `ReadToEnd`, a `BufferedReader` or a `TextReader` all work on a connection. A read
returns what has arrived, which may be less than asked for — TCP carries a stream of bytes, not
messages, so `ReadExact` or a line reader is what puts the messages back together. A read of 0
bytes means the other side has finished sending, as `Shutdown( SHUTDOWN_WRITE )` shows. Reads and
writes report `FsError`s like a file's: `FS_TIMED_OUT` after `SetReadTimeout`,
`FS_CONNECTION_RESET` when the peer drops the connection. Everything else — connecting, binding,
accepting — reports a `NetError`, whose code says what happened: `NET_CONNECTION_REFUSED`,
`NET_TIMED_OUT`, `NET_ADDRESS_IN_USE`, `NET_HOST_NOT_FOUND`.

A `UdpSocket` sends single datagrams instead: `Bind`, then `SendTo( p, n, address )` and
`ReceiveFrom( p, n, sender )`. A datagram arrives whole or not at all, and one longer than the
buffer fails with `NET_MESSAGE_TOO_LONG` rather than arriving cut short without a word.

**Every socket call blocks** until it is done or its timeout ends. A goroutine (Chapter 23) in a
socket call holds its worker thread while it waits, so a server that gives each connection a
goroutine should give every connection a timeout, or serve no more connections at once than it has
workers.

### URLs

```tiko
{{#include ../examples/ch25/urls.tiko}}
```

```text
{{#include ../examples/ch25/urls.out}}
```

`ParseUrl` follows RFC 3986. The fields of a `Url` hold the parts **decoded** — `Path` is
`/docs/a b.html`, not `a%20b` — except `RawQuery`, kept as written because only its own parser
knows where its pairs begin and end; `Query( )` parses it into `QueryValues`, an ordered list of
pairs in which a name may repeat. `ToString( )` escapes each part again as it prints it, so a field
can be set to any text. `Resolve` turns a relative link into an absolute one the way a browser does,
removing `.` and `..`. An invalid escape such as a lone `%` is `NET_INVALID_URL` rather than a guess
at what was meant.

### Fetching a web page

```tiko
{{#include ../examples/ch25/httpget.tiko}}
```

```text
{{#include ../examples/ch25/httpget.out}}
```

`std/http` is an HTTP/1.1 client over those sockets, and `std/tls` encrypts the connection when the
URL says `https`. The listing serves itself, on a second thread, so it runs without a network — the
`Serve` routine is all a server needs to say to an HTTP client: a status line, headers, a blank
line and a body of the length the headers announced.

`http.Fetch( url )` makes one request with the defaults. An `http.Client` holds settings —
`TimeoutMs`, `MaxRedirects`, `UserAgent`, `DefaultHeader`, `TlsOptions` — and **keeps connections
open**: both requests above travelled over one connection, which is still kept for the next request
to the same site. `Send` takes a `Request` built by hand, with any method, headers and body;
`Fetch`, `Head` and `Post` are shorthands for it. A `Response` holds `StatusCode`, `Header`, the
`Body` bytes and `Text( )`. For a body too large to hold, `Open` returns a `ResponseStream`, an
`fs.Stream` like a `File` or a `TcpStream`.

**A status is not an error.** A 404 is a request that worked and an answer the program has to look
at, so it comes back as a `Response`. An `HttpError` means there was no answer: `HTTP_CONNECT_FAILED`,
`HTTP_TIMED_OUT`, `HTTP_BAD_RESPONSE`, or `HTTP_TLS_FAILED` when the server's certificate is not
trusted, out of date, or for another name — the error's `TlsCode( )` says which. Redirects are
followed for you, up to ten.

## What it costs

- **A `File` holds an operating-system handle until it is closed or goes out of scope.** Keep it
  in the narrowest `scope` that needs it. Call `Close( )` yourself when you need to know whether
  the close itself succeeded: it returns a `Result`, and a destructor has nowhere to report one.
- **A `File` is unbuffered**: every `Read` and `Write` is a system call. Many small writes belong in
  a `BufferedWriter`, a `TextWriter` over one, or a `MemoryStream` written once.
- **`Stat` is one system call**; `Exists` followed by a size check is two, and the file can change
  between them.
- **`WalkDir` holds one directory open at a time** and cannot exhaust handles, however deep the
  tree. `ReadAllText` and `ReadAllLines` hold the whole file in memory.
- **`WriteAtomic` writes the file twice over** — a temporary and a rename — which is the price of
  never leaving it half-written.
- **A `TomlValue` is a value**: `Get( key )` and copying a table copy the whole subtree under it.
  `Find( key )` and `[ i ]` reach into the tree without a copy. Looking a key up scans its table,
  which is what a configuration file's tables can afford.
- **An `http.Client` keeps up to eight idle connections open** for reuse, each an operating-system
  handle (and, for `https`, a TLS session). `CloseIdle( )` lets them go; so does the client going
  out of scope.
- **A socket holds an operating-system handle and, while a call waits, a thread.** Close
  connections in the narrowest scope that needs them, and give every network read a timeout:
  without one a peer that stops answering stops the program with it.

## Summary

- `#import "std/fs"`. A `File` opens with `OpenRead`, `Create`, `CreateNew`, `OpenAppend` or
  `Open( p, OpenOptions )`, closes itself, and reports every failure as an `FsError`.
- `TextWriter.WriteLine` writes lines; `for each ln in ReadLines( p )` reads them back.
  `strings.SplitCsvRow` splits a line of comma-separated fields.
- Every text call takes an encoding: `Utf8( )`, `Utf16LE( )`, `Utf16BE( )`, `CodePage( n )`,
  `Ansi( )`, `BinaryMode( )`. Reads believe it; `TextDetect` guesses; writes refuse what the
  encoding cannot hold unless given `TEXT_REPLACE`.
- `RecordFile( of T )` reads and writes fixed-size records by number, from 1, with `GetRecord`,
  `PutRecord`, `Append` and `for each`; every field must be fixed-size. `ReadAt` and `WriteAt` are
  the byte-level calls underneath.
- `std/codec` lays out binary formats in a byte `Array`: `Get`/`Put`/`Append` + width + `LE`/`BE`,
  and LEB128 varints with `AppendUVarint`/`ReadUVarint`.
- A `File` is a `Stream`, like `MemoryStream`; buffers, text readers and writers, and `Copy` work on
  any stream, including one you write by extending `fs.Stream`.
- The `Path*` functions; `Stat` for every fact at once; `ReadDir`, `WalkDir`, `Glob`;
  `ReadAllText`/`ReadAllLines`/`WriteAllText`; `WriteAtomic`.
- `ConfigDir`, `DataDir`, `CacheDir`, `StateDir`, `HomeDir` and `ExecutablePath` say where a program
  keeps its files.
- **`PathJoin` with an absolute second part discards the first** — check containment with
  `PathStartsWith` before using a path built from input.
- The file statements (`open`, `print #`, `kill`, `mkdir`, `dir` …) still compile for older
  programs; each has a `std/fs` counterpart that reports failure as a value.
- `IsRedirected( )` decides whether to draw on the console. `inkey` never waits; `getkey` does.
- `command( n )`, `environ`, `setenviron`; `shell`, `exec`, `chain`, `run`, `open pipe`; `end n`
  sets the exit code.
- `std/os`: `Args( )` keeps empty arguments, `GetEnv` tells unset from empty, `SetEnv` /
  `UnsetEnv` / `ExpandEnv`; host facts such as `CpuCount( )`; `CatchInterrupt( )` turns Ctrl-C into
  a flag the program checks with `Interrupted( )`.
- `std/hash`: `DigestHex( alg, data )`, the same in pieces, `DigestFile`, `HmacHex`. CRC and FNV
  catch accidents; only SHA-2 stands up to tampering.
- `std/config`: `ParseToml` / `LoadToml` give a `TomlValue` tree read with `Path` and `As…`, each
  an `Optional`; `ToTomlText` writes it back, without comments. `ParseIni` / `LoadIni` give an
  `IniFile` with `Get`, `SetValue` and `ToText`. Errors are `ConfigError`s with a line and column.
- `strings.JoinCsvRow` and `strings.CsvWriter` write CSV that `SplitCsv` reads back.
- `std/net`: `ParseIp` (strict) and `IpAddress`; `SocketAddress`; `Resolve`. `TcpListener.Bind` and
  `Accept`, `TcpStream.Connect` / `ConnectHost` — a `TcpStream` is an `fs.Stream`. `UdpSocket`
  for datagrams. Every call blocks; give it a timeout. `ParseUrl` gives a `Url` of decoded fields,
  `Resolve` makes links absolute, `QueryValues` reads and writes query strings.
- `std/http`: `http.Fetch`, or an `http.Client` that reuses connections and follows redirects;
  `Send` a `Request`, read a `Response` — a 404 is a response, not an error. `std/tls` encrypts
  `https`, and checks the server's certificate against the system's trusted roots.

## Exercises

1. Walk a directory tree and count its files by extension, printing the counts in a stable order.
   {solution="ex25-01"}
2. Write `Sell( stock, record, n )` for the stock file of `records.tiko`: it reduces the quantity of
   record `record` by `n` and refuses, returning `false`, if there are not enough.
   {solution="ex25-02"}
3. Make `pathescape.tiko` refuse any name that would leave `uploads`, and print which names were
   refused, on every platform.
4. Rewrite `textfile.tiko` with `fs.WriteAllText` and `fs.ReadAllLines`. Which version would you
   want for a file of a few lines, and which for a log of a few gigabytes?
5. Write a program that runs `exitcode.tiko`'s executable with `exec` and prints a different message
   for exit status 0 and for anything else.
6. Print the SHA-256 digest of every file under a directory, sorted by path, in the format
   `sha256sum` uses: the digest, two spaces, the path.
7. Give `interrupt.tiko` a temporary directory that it creates at the start and removes at the end,
   and check that it is removed when you press Ctrl-C too.
8. Write `binformat.tiko`'s buffer to a file with `fs.WriteAllBytes`, read it back with
   `fs.ReadAllBytes`, and check the magic number before reading anything else. What should a
   reader do with a file whose version it does not know?
9. Give `tomlconfig.tiko` a `[server]` key `port = "8080"`, written as a string. What does it
   print, and how would you report the mistake to the user who wrote the file?
10. Read a TOML file of `[[items]]` tables, each with a `name` and a `price`, and write them to a
    CSV file with `CsvWriter`, a header row first.
11. Change `tcpecho.tiko` so that the client sends three lines and the server answers each with its
    length, reading with a `TextReader` on the server's side. What happens if the client sends all
    three before the server reads any?
12. Write `LinkReport( pageUrl, links )`: resolve each link of a page against its URL and print the
    ones that leave the page's host.
13. Make `httpget.tiko`'s server answer `/old` with `302 Found` and a `Location: /notes` header, and
    fetch `/old`. What does `r.Value( ).Url` hold afterwards? Set `c.MaxRedirects = 0` and fetch it
    again.
