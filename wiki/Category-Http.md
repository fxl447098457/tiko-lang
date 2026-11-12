[Home](Home) › [All Categories](Categories) › **HTTP and TLS**

# HTTP and TLS: Web Requests and Encrypted Connections

Two modules work together here. `std/http` is an HTTP/1.1 client: it fetches `http` and `https` URLs, follows redirects and reuses connections. `std/tls` is the encryption underneath it, and it can be used on its own to talk TLS over any connected stream.

```freebasic
#import "std/http"

dim r as http.HttpResultResponse = http.Fetch( "https://example.com/" )
if r.IsOk( ) then
    print r.Value( ).StatusCode                                  ' 200
    print r.Value( ).Header.Get( "content-type" ).ValueOr( "" )
    print left( r.Value( ).Text( ), 60 )
else
    print r.Failure( ).Message( )
end if
```

Every call that can fail returns a `Result`. **A status such as 404 is not a failure**: the request worked and the server answered, so check `StatusCode` (or `IsSuccess( )`). A failure is an `HttpError`: the server could not be reached, the certificate was refused, the reply was malformed, a timeout ran out.

## A Client

`http.Fetch` and `http.Post` make one request with the default settings. For more than one request, or to change a setting, make a `Client`. It keeps finished connections open and reuses them for the next request to the same host.

```freebasic
#import "std/http"

dim c as http.Client
c.TimeoutMs = 5000
c.UserAgent = "my-tool/1.0"
c.DefaultHeader.Add( "Accept-Language", "en" )

dim r as http.HttpResultResponse = c.Fetch( "https://example.com/" )
if r.IsOk( ) then print r.Value( ).StatusCode, r.Value( ).Body.Count( ); " bytes"
r = c.Post( "https://example.com/form", "application/x-www-form-urlencoded", "name=tiko&kind=language" )
if r.IsOk( ) then print r.Value( ).StatusCode
```

| Setting | Default | Meaning |
|---|---|---|
| `TimeoutMs` | `30000` | the connect, and each read or write; not the whole exchange. `0` waits for ever |
| `MaxRedirects` | `10` | redirects followed; `0` returns the `3xx` response itself |
| `MaxBodyBytes` | 64 MiB | the largest body `Send` will read into memory |
| `KeepAlive` | `TRUE` | reuse connections; `FALSE` sends `Connection: close` |
| `MaxIdle` | `8` | idle connections kept for reuse |
| `UserAgent` | `"tiko-http/0.1"` | sent unless a request has its own; `""` sends none |
| `DefaultHeader` | empty | headers added to every request that does not have them |
| `TlsOptions` | system roots | the `tls.TlsConfig` for `https` |

`CloseIdle( )` closes the kept connections; `IdleCount( )` says how many there are.

## Requests

A `Request` is a value: `Method`, `Url`, `Header` and `Body`. `Client.Send` sends it and reads the whole reply.

```freebasic
#import "std/http"

dim c as http.Client
dim req as http.Request = http.Request( "PUT", "https://example.com/api/items/7" )
req.Header.Add( "X-Request-Id", "42" )
req.SetBody( "{""name"":""tiko""}", "application/json" )
req.SetBasicAuth( "user", "secret" )
dim r as http.HttpResultResponse = c.Send( req )
if r.IsOk( ) then print r.Value( ).StatusCode, r.Value( ).Reason
```

| Call | Does |
|---|---|
| `Request( method, url )` | a request; the method is sent as given |
| `SetBody( text, contentType )` | the body as UTF-8, and its `Content-Type` |
| `SetBodyBytes( bytes, contentType )` | the body as bytes |
| `SetBasicAuth( user, password )` | an `Authorization: Basic` header; a URL like `https://user:pw@host/` does the same |

The client adds `Host`, `Content-Length`, `User-Agent` and `Accept: */*` itself. A header name that is not a valid token, or a value holding a line break, is refused with `HTTP_INVALID_ARGUMENT` before anything is sent.

## Responses

| Field or call | Gives |
|---|---|
| `StatusCode`, `Reason`, `Proto` | `200`, `"OK"`, `"HTTP/1.1"` |
| `Url` | the URL that answered, after any redirects |
| `Header` | the response headers |
| `Body` | the body bytes, an `Array( of ubyte )` |
| `Text( )` | the body as UTF-8 text; bytes that are not UTF-8 become U+FFFD |
| `IsSuccess( )` | `TRUE` for 200 to 299 |

`Headers` is an ordered list of name and value pairs. Names compare without regard to case, and a name may appear more than once: `Get( name )` gives the first value as an `Optional`, `GetAll( name )` all of them; `Add`, `SetValue`, `Remove`, `Has`, `Count`, `NameAt( i )` and `ValueAt( i )` do the rest.

## Reading A Body As It Arrives

`Send` keeps the whole body in memory. `Open` hands it over as a stream instead, to read at your own pace — a large download straight to a file, for example. A `ResponseStream` is a [stream](Category-File-Streams), so everything a stream can do works on it.

```freebasic
#import "std/http"
#import "std/fs"

dim c as http.Client
dim body as http.ResponseStream
dim r as http.HttpResultBool = c.Open( http.Request( "GET", "https://example.com/" ), body )
if r.IsOk( ) then
    print body.StatusCode, body.ContentLength( )        ' -1 when the server did not say
    dim buf( 0 to 4095 ) as ubyte
    dim total as longint = 0
    do
        dim got as fs.FsResultI64 = body.Read( @buf( 0 ), 4096 )
        if got.IsOk( ) = false orelse got.Value( ) = 0 then exit do
        total += got.Value( )
    loop
    print total; " bytes"
    body.Close( )
end if
```

Read the body to its end and `Close` the stream, and the connection goes back to the client for the next request. A stream closed early closes its connection. A `ResponseStream` must not outlive the `Client` that opened it.

## Redirects

A `301`, `302`, `303`, `307` or `308` with a `Location` is followed, up to `MaxRedirects` times; more than that is `HTTP_TOO_MANY_REDIRECTS`. A `303`, or a `301` or `302` answering a `POST`, becomes a `GET` without a body; `307` and `308` repeat the same method and body. The `Authorization` header is dropped when the redirect leads to another host.

## TLS On Its Own

`std/tls` encrypts any connected stream. `ConnectHost` opens a TCP connection and shakes hands as a client; `Connect` shakes hands over a stream you already have; `Accept` shakes hands as a server. After that a `TlsStream` reads and writes like any other stream.

```freebasic
#import "std/tls"
#import "std/containers"
using containers

dim cfg as tls.TlsConfig
dim s as tls.TlsStream
dim r as tls.TlsResultBool = s.ConnectHost( "example.com", 443, cfg, 5000 )
if r.IsOk( ) then
    print s.Protocol( )                                      ' TLSv1.3
    s.WriteUtf8( !"HEAD / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n" )
    dim reply as Array( of ubyte )
    s.ReadToEnd( reply )
    print reply.Count( ); " bytes"
    s.Close( )
else
    print r.Failure( ).Message( )
end if
```

A `TlsConfig` is a value:

| Field or call | Meaning |
|---|---|
| `MinVersion` | `TLS_VERSION_1_2` (the default) or `TLS_VERSION_1_3` |
| `AddRootPem( pem )`, `AddRootFile( path )` | trust these root certificates as well as the system's |
| `InsecureSkipVerify` | check neither the chain nor the name — for tests only |
| `SetIdentityPem( certPem, keyPem )`, `SetIdentityFiles( certPath, keyPath )` | a server's certificate chain (leaf first) and its PKCS#8 private key, for `Accept` |

**Checking the server.** A client checks that the certificate chain ends at a trusted root, that every certificate is in date, and that the certificate names the host it was given — a DNS name, or an IP address for `127.0.0.1` or `[::1]`. Revocation is not checked.

**Closing.** `Close` sends the TLS close message and, after `ConnectHost`, closes the connection too. The peer closing — with or without that message — reads as the end of the stream.

**On each system.** Windows uses its own TLS (SChannel), on Windows 10 1809 or later; a server's private key is put into the user's key store for the life of the connection and deleted afterwards. Linux uses OpenSSL 3, loaded when the first handshake starts: a program that never uses TLS does not need it, and without `libssl.so.3` every handshake fails with `TLS_UNAVAILABLE`. macOS uses OpenSSL 3 the same way, from Homebrew's `openssl@3`.

## Blocking And Threads

Every call blocks until it finishes or its timeout runs out, as [Net](Category-Net)'s do. A `Client` and a `TlsStream` belong to one thread at a time; give each thread its own. OpenSSL's handshake needs more stack than a thread's minimum, so give a thread that uses TLS a stack of a megabyte or so (`threadcreate( @proc, arg, 1024 * 1024 )`).

## Errors

`HttpError` has `Code( )`, `OsCode( )`, `Operation( )`, `Subject( )` (the URL), `Detail( )` (the lower layer's message) and `Message( )`. When the code is `HTTP_TLS_FAILED`, `TlsCode( )` says why.

| `HttpErrorCode` | Meaning |
|---|---|
| `HTTP_INVALID_URL`, `HTTP_UNSUPPORTED_SCHEME` | not a URL with a host, or not `http`/`https` |
| `HTTP_CONNECT_FAILED` | the host was not found or refused the connection |
| `HTTP_TLS_FAILED` | the handshake or the certificate check failed |
| `HTTP_TIMED_OUT` | a connect, read or write took longer than `TimeoutMs` |
| `HTTP_IO` | sending or receiving failed |
| `HTTP_BAD_RESPONSE` | a malformed status line, header or chunk, or a body cut short |
| `HTTP_TOO_MANY_REDIRECTS`, `HTTP_HEADERS_TOO_LARGE`, `HTTP_BODY_TOO_LARGE` | a limit was passed |
| `HTTP_INVALID_ARGUMENT` | a bad method, header name or header value |
| `HTTP_CLOSED` | a `ResponseStream` that is not open |

| `TlsErrorCode` | Meaning |
|---|---|
| `TLS_CERT_UNTRUSTED` | the chain does not end at a trusted root |
| `TLS_CERT_EXPIRED` | a certificate is out of date, or not yet valid |
| `TLS_CERT_NAME_MISMATCH` | the certificate is for another host |
| `TLS_CERT_INVALID` | any other certificate problem |
| `TLS_HANDSHAKE_FAILED` | no version or cipher in common, or the peer sent an alert |
| `TLS_CONNECT_FAILED`, `TLS_TRANSPORT`, `TLS_TIMED_OUT` | the connection failed, broke, or timed out during the handshake |
| `TLS_UNAVAILABLE` | no TLS library on this machine |
| `TLS_BAD_PEM`, `TLS_BAD_KEY`, `TLS_NO_IDENTITY` | the config's certificates or key could not be used, or a server has none |
| `TLS_CLOSED`, `TLS_ALREADY_OPEN`, `TLS_INVALID_ARGUMENT` | the stream's state, or an empty host name |

Reading a `ResponseStream` or a `TlsStream` reports `fs.FsError` codes: `FS_UNEXPECTED_EOF` for a body shorter than it said, `FS_INVALID_DATA` for a bad chunk or a record that does not decrypt, and the connection's own `FS_TIMED_OUT` or `FS_CONNECTION_RESET`.

**Not here yet:** proxies, cookies, compressed bodies (no `Accept-Encoding` is sent, so servers send plain bodies), HTTP/2, and an HTTP server.

## See Also

- [Net](Category-Net) — the TCP connections and URLs underneath
- [Filesystem Library](Category-Filesystem) — streams, which a `ResponseStream` and a `TlsStream` are
- [Codec](Category-Codec) — base64 and percent-encoding on their own
