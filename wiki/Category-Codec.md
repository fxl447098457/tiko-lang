[Home](Home) › [All Categories](Categories) › **Codec**

# Codec: Base64, Hex, Percent-Encoding, Text Encodings And Binary Data

The `std/codec` module turns bytes into text and back. Base64, base32 and hex put binary data into text formats, percent-encoding is for URLs, and text encodings (UTF-8, UTF-16, Windows code pages) convert text to and from bytes. It also reads and writes fixed-width numbers and variable-length integers in a byte buffer.

```freebasic
#import "std/codec"

print codec.Base64Encode( "hello" )                   ' aGVsbG8=
print codec.HexEncode( "hi" )                         ' 6869
print codec.PercentEncode( "a b&c" )                  ' a%20b%26c
print codec.Base64DecodeText( "aGVsbG8=" ).Value( )   ' hello
```

**Bytes** are a `containers.Array( of ubyte )`, as in [std/fs](Category-Filesystem). **Text** is `ustring`; where text becomes bytes, it is UTF-8 unless a [text encoding](#text-encodings) says otherwise. A `string` argument is taken as raw bytes.

## Base64, Base32 And Hex

```freebasic
#import "std/codec"
#import "std/containers"

dim raw as containers.Array( of ubyte )
raw.Push( &hFB ) : raw.Push( &hFF )

print codec.Base64Encode( raw )                         ' +/8=
print codec.Base64Encode( raw, codec.B64_URL )          ' -_8=
print codec.Base64Encode( raw, codec.B64_URL, false )   ' -_8
print codec.Base32Encode( "hi" )                        ' NBUQ====
print codec.HexEncode( raw, true )                      ' FBFF

dim back as containers.Array( of ubyte )
var r = codec.Base64Decode( "+/8=", back )
if r.IsOk( ) then print r.Value( ); " bytes"            ' 2 bytes
```

Each family has three procedures: `…Encode` (bytes, `ustring` or `string` in, text out), `…Decode` (text in, bytes into an array, returning the byte count) and `…DecodeText` (text in, `ustring` out — the decoded bytes must be UTF-8).

| Alphabet | Value |
|---|---|
| `B64_STANDARD` | `A-Z a-z 0-9 + /` |
| `B64_URL` | `A-Z a-z 0-9 - _`, safe in URLs and file names |
| `B32_STANDARD` | `A-Z 2-7` |
| `B32_HEX` | `0-9 A-V`, which sorts like the bytes it encodes |

## Strict Decoding

Decoding accepts exactly what an encoder writes, so every byte sequence has one accepted encoding:

- only the alphabet's characters — a base32 decoder does not accept lower case;
- `=` padding exactly where it belongs, and required;
- no whitespace;
- no stray low bits in the last character (`Zh==` is refused, `Zg==` is not).

Two options relax that, and can be combined with `or`:

| Option | Accepts |
|---|---|
| `DECODE_IGNORE_WHITESPACE` | spaces, tabs and line breaks anywhere (MIME base64) |
| `DECODE_ALLOW_MISSING_PAD` | base64 or base32 with the `=` left off, as in JSON Web Tokens |

A failure is an `EncodingError` with a `Code( )`, the 1-based `Position( )` of the first bad character, and a `Message( )`:

```freebasic
#import "std/codec"
#import "std/containers"

dim b as containers.Array( of ubyte )
var r = codec.Base64Decode( "Zm9v!", b )
print r.Failure( ).Message( )        ' Base64Decode: invalid character at 5
```

| Code | Meaning |
|---|---|
| `ENC_INVALID_CHAR` | a character outside the alphabet |
| `ENC_INVALID_LENGTH` | a length no encoder produces |
| `ENC_INVALID_PADDING` | `=` missing, misplaced or excessive |
| `ENC_TRAILING_BITS` | the last character has non-zero unused bits |
| `ENC_INVALID_UTF8` | `…DecodeText` decoded bytes that are not UTF-8 |
| `ENC_TRUNCATED`, `ENC_OVERFLOW` | a varint ends early, or is wider than 64 bits |
| `ENC_UNMAPPABLE` | `EncodeText` met a character the encoding cannot hold |
| `ENC_INVALID_BYTES` | a strict `DecodeText` met bytes the code page does not define |
| `ENC_UNSUPPORTED` | an encoding or code page this platform cannot convert |

## Percent-Encoding

```freebasic
#import "std/codec"

print codec.PercentEncode( "a b/c?d" )                        ' a%20b%2Fc%3Fd
print codec.PercentEncode( "a b/c", codec.PCT_PATH )          ' a%20b/c
print codec.PercentEncode( "q=a b&x", codec.PCT_QUERY )       ' q%3Da+b%26x
print codec.PercentDecode( "a+b%26c", codec.PCT_QUERY ).Value( )   ' a b&c
```

| Mode | Keeps | For |
|---|---|---|
| `PCT_COMPONENT` | `A-Z a-z 0-9 - . _ ~` | one value inside a URL |
| `PCT_PATH` | also `/ : @ ! $ & ' ( ) * + , ; =` | a path with its separators |
| `PCT_QUERY` | `A-Z a-z 0-9 - . _ ~`; space becomes `+` | HTML form data |

Every other byte of the UTF-8 text becomes `%XX` in upper-case hex. Decoding accepts either case, turns `+` into a space only in `PCT_QUERY` mode, and passes characters that were never escaped through unchanged.

## Text Encodings

`EncodeText` and `DecodeText` convert between text and bytes in a named encoding, and `DetectEncoding` works out which encoding some bytes are in. [std/fs](Category-Filesystem) uses the same encodings for files.

```freebasic
#import "std/codec"
#import "std/containers"

dim b as containers.Array( of ubyte )
codec.EncodeText( "café", codec.Utf16LE( ), b )            ' FF FE 63 00 61 00 66 00 E9 00
print codec.DecodeText( b, codec.Utf16LE( ) ).Value( )     ' café

var r = codec.EncodeText( "snow " & wchr( &h2603 ), codec.CodePage( 1252 ), b )
print r.Failure( ).Message( )     ' EncodeText: character not representable in the encoding

var lossy = codec.EncodeText( "snow " & wchr( &h2603 ), codec.CodePage( 1252 ), b, false )
print lossy.Value( ), b.Count( )  ' false  6   (the snowman became ?)
```

An encoding is a `TextEncoding` value, made by one of these functions:

| Function | Encoding | `Name( )` |
|---|---|---|
| `Utf8( bom = false )` | UTF-8 | `utf-8` |
| `Utf16LE( bom = true )` | UTF-16, little-endian | `utf-16le` |
| `Utf16BE( bom = true )` | UTF-16, big-endian | `utf-16be` |
| `Ansi( )` | the system's ANSI code page, looked up at each call (1252 in western Europe and the Americas) | `ansi` |
| `CodePage( n )` | a Windows code page by number; `CodePage( 65001 )` is `Utf8( )` | `windows-1252`, `iso-8859-1`, `ibm437`, `shift_jis`, … or `cp<n>` |
| `BinaryMode( )` | byte *n* is character U+00*nn*, and back | `binary` |

`TextEncoding` has three fields: `Kind` (`TEXT_UTF8`, `TEXT_UTF16LE`, `TEXT_UTF16BE`, `TEXT_CODEPAGE` or `TEXT_BINARY`), `CodePage`, and `Bom`. A default-constructed `TextEncoding` is UTF-8 without a BOM.

### Decoding

`DecodeText( bytes, enc [, strict] )`, or `DecodeText( ptr, count, enc [, strict] )`, returns the text.

- **The encoding you name is the one used.** A byte-order mark that matches it is skipped: `EF BB BF` for UTF-8, `FF FE` for UTF-16LE, `FE FF` for UTF-16BE. Any other leading bytes are text. A code page and `BinaryMode( )` skip nothing, so reading a file that starts with a UTF-8 BOM as `CodePage( 1252 )` gives the three characters `ï»¿`.
- UTF-16 drops an odd last byte and keeps an unpaired surrogate.
- Bytes the encoding does not define become U+FFFD. For a code page they become whatever character Windows gives them. With `strict = true` they fail instead, with `ENC_INVALID_UTF8` or `ENC_INVALID_BYTES`.

### Encoding

`EncodeText( text, enc, bytes [, strict] )` replaces the array's contents. The BOM is written when `enc.Bom` is true, for UTF-8 and UTF-16 only.

- **Strict is the default.** A character the encoding cannot hold fails the call with `ENC_UNMAPPABLE` at its position, and leaves the array empty.
- With `strict = false` each such character becomes `?`, and the result's value is `false`, meaning "written, but not exactly". A `true` value means every character was written as it was.
- Characters are never replaced by lookalikes: `∞` does not become `8`, and `ā` does not become `a`.
- UTF-16 holds every character, so it writes an unpaired surrogate as it is. UTF-8 writes one as U+FFFD and returns `false`.

### Code Pages

On Windows, every code page the system has installed is available. On Linux and macOS, a fixed set is built in: 1250–1258, 28591 (ISO-8859-1), 28605 (ISO-8859-15), 437 and 850. They decode and encode exactly as Windows does. On Linux, `Ansi( )` and every other code page fail with `ENC_UNSUPPORTED`.

These code pages fail with `ENC_UNSUPPORTED` on every platform:

- the stateful ones: ISO-2022 (50220–50229), HZ (52936) and UTF-7 (65000);
- the ones that cannot be written without lookalike replacement: 42 and 57002–57011;
- UTF-16 and UTF-32 named by number (1200, 1201, 12000, 12001), which have their own encodings.

`CodePageTable( cp, units, invalid )` returns a built-in table: the 256 characters that bytes 0–255 decode to, and which bytes a strict decode refuses.

### Detection

```freebasic
#import "std/codec"
#import "std/containers"

dim b as containers.Array( of ubyte )
b.Push( &h63 ) : b.Push( &h61 ) : b.Push( &h66 ) : b.Push( &hE9 )   ' "café" in Windows-1252

dim opts as codec.TextDetect = codec.TextDetect( codec.CodePage( 1252 ) )
var found = codec.DetectEncoding( b, opts )
print found.Value( ).Name( )                                ' windows-1252
print codec.DecodeText( b, found.Value( ) ).Value( )       ' café
```

`DetectEncoding` checks for each of these in turn and returns the first it finds:

1. A BOM. The result is that encoding, with `Bom` set to true.
2. If `Utf16NoBom` is set: UTF-16 without a BOM.
3. Valid UTF-8. Empty input counts as UTF-8.
4. Otherwise, the `Fallback` encoding.

A UTF-32 BOM fails with `ENC_UNSUPPORTED`.

| `TextDetect` field | Default | Meaning |
|---|---|---|
| `Fallback` | `Utf8( )` | used when there is no BOM and the bytes are not valid UTF-8 — `Ansi( )` for files from Windows programs, `BinaryMode( )` to keep every byte |
| `Utf16NoBom` | `false` | guess UTF-16 without a BOM: at least two units, nine in ten of them a zero byte beside a non-zero one, the zero always on the same side. Text with no zero bytes never passes. |
| `PrefixBytes` | 65536 | how much a stream looks at before its first line, and the sample the UTF-16 guess uses |

With the defaults, detection agrees with the rules std/fs reads files by when no encoding is named. `DetectEncoding( ptr, count, opts, complete )` takes `complete = false` when the bytes are only the beginning of the data. Then UTF-8 that stops partway through a character still counts as UTF-8.

## Numbers In A Byte Buffer

```freebasic
#import "std/codec"
#import "std/containers"

dim b as containers.Array( of ubyte )
codec.AppendU32LE( b, &h11223344 )      ' 44 33 22 11
codec.AppendU16BE( b, 513 )             ' 02 01
print hex( codec.GetU32LE( b, 0 ) )     ' 11223344
print codec.GetU16BE( b, 4 )            ' 513
```

`Get<T><E>( b, offset )`, `Put<T><E>( b, offset, value )` and `Append<T><E>( b, value )`, for `T` = `U16 U32 U64 I16 I32 I64 F32 F64` and `E` = `LE` (little-endian) or `BE` (big-endian). Offsets count bytes from 0. A `Get` past the end is runtime error 6; a `Put` past the end grows the array, filling any gap with zeros. Floats move as their IEEE 754 bit pattern.

## Variable-Length Integers

```freebasic
#import "std/codec"
#import "std/containers"

dim b as containers.Array( of ubyte )
codec.AppendUVarint( b, 300 )           ' AC 02
codec.AppendVarint( b, -2 )             ' 03

dim at as long = 0
print codec.ReadUVarint( b, at ).Value( ), at      ' 300  2
print codec.ReadVarint( b, at ).Value( ), at       ' -2  3
```

LEB128: seven bits per byte, low group first, the high bit set on every byte but the last — the format protobuf, DWARF and WebAssembly use. `AppendVarint` zig-zags first (0, -1, 1, -2 … become 0, 1, 2, 3 …), so small negative numbers stay short. `Read…` advances its offset past the value, and leaves it alone on failure.

## See Also

[UUID](Category-UUID) · [Array](Category-Array) · [Filesystem](Category-Filesystem) · [String Library](Category-String-Library)
