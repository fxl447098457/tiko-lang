[Home](Home) › [All Categories](Categories) › **Net**

# Net: Addresses, Sockets and URLs

The `std/net` module parses and prints IP addresses, looks up host names, talks TCP and UDP, and takes URLs apart and puts them back together.

```freebasic
#import "std/net"

dim u as net.NetResultUrl = net.ParseUrl( "https://example.com:8443/docs/a%20b?q=tiko&page=2#top" )
if u.IsOk( ) then
    print u.Value( ).Host, u.Value( ).Port, u.Value( ).Path
    print u.Value( ).Query( ).Get( "q" ).ValueOr( "" )
end if
```

Every call that can fail returns a `Result`; a socket call's failure is a `NetError`. Reading and writing a `TcpStream` reports an `fs.FsError` instead, because a `TcpStream` is a [stream](Category-File-Streams) like a file.

## IP Addresses

An `IpAddress` is a value — copy it, keep it, compare it with `Equals`. It is IPv4 or IPv6; an IPv6 address may carry a zone, the interface after `%` in `fe80::1%eth0`.

```freebasic
#import "std/net"

dim a as net.IpAddress = net.ParseIp( "2001:0db8:0:0:0:0:0:1" ).Value( )
print a.ToString( )                         ' 2001:db8::1
print a.IsV6( ), a.IsGlobalUnicast( )
print net.ParseIp( "010.1.1.1" ).IsOk( )    ' false: a leading zero is refused
print net.Ipv4( 192, 168, 1, 20 ).IsPrivate( )
```

| Call | Gives |
|---|---|
| `ParseIp( text )` | an `IpAddress`, or `NET_INVALID_ADDRESS`; dotted IPv4, any IPv6 form, `::ffff:1.2.3.4`, a zone after `%` |
| `Ipv4( a, b, c, d )` | an IPv4 address from its four numbers |
| `IpFromBytes( bytes )` | an address from 4 or 16 bytes |
| `Loopback( v6 )` | `127.0.0.1`, or `::1` with `TRUE` |
| `AnyAddress( v6 )` | `0.0.0.0`, or `::` — "every address of this machine" for `Bind` |
| `ToString( )` | IPv6 in its shortest form: lower case, the longest run of zeros as `::` |
| `IsV4( )`, `IsV6( )`, `Bytes( )`, `Zone( )`, `WithZone( z )` | the parts |
| `IsLoopback( )`, `IsPrivate( )`, `IsLinkLocal( )`, `IsMulticast( )`, `IsUnspecified( )`, `IsGlobalUnicast( )` | what kind of address it is |
| `IsV4Mapped( )`, `Unmap( )` | an IPv4 address written as IPv6 (`::ffff:1.2.3.4`), and back |
| `Equals( other )` | the same address and zone |

**Parsing is strict.** An IPv4 part with a leading zero (`010.1.1.1`) is refused rather than read as decimal or octal, so two programs can never disagree about which address a string means.

A `SocketAddress` is an address and a port: `SocketAddress( ip, port )`, the fields `Ip` and `Port`, `ToString( )` (`1.2.3.4:80`, `[::1]:80`) and `ParseSocketAddress( text )`, which requires the port and the brackets around IPv6.

## Looking Up Host Names

```freebasic
#import "std/net"

dim r as net.NetResultAddrs = net.Resolve( "localhost", 8080 )
if r.IsOk( ) then
    for each a in r.Value( )
        print a.ToString( )
    next
end if
```

`Resolve( host, port, family )` asks the system's resolver and gives every address, each with `port`; `family` is `AF_ANY` (the default), `AF_IPV4` or `AF_IPV6`. An IP address given as text comes back as itself, with no lookup. A name with no address is `NET_HOST_NOT_FOUND`; a resolver that cannot answer now is `NET_TEMPORARY_FAILURE`.

## TCP Connections

A `TcpStream` is one connection. `Connect` it to a `SocketAddress`, or `ConnectHost` to a name and port, then read and write it as any stream: `Read`, `Write`, `WriteAll`, `WriteUtf8`, `ReadExact`, `ReadToEnd`.

```freebasic
#import "std/net"

dim c as net.TcpStream
dim r as net.NetResultBool = c.ConnectHost( "localhost", 7, 3000 )
if r.IsOk( ) then
    c.SetReadTimeout( 5000 )
    c.WriteUtf8( "hello" )
    dim as string buf = space( 5 )
    if c.ReadExact( cptr( ubyte ptr, strptr( buf ) ), 5 ).IsOk( ) then print buf
else
    print r.Failure( ).Message( )   ' e.g. Connect '[::1]:7': connection refused
end if
```

| Call | Does |
|---|---|
| `Connect( addr, timeoutMs )` | connects; with a timeout of 0 or more, gives up with `NET_TIMED_OUT` after that many milliseconds |
| `ConnectHost( host, port, timeoutMs )` | resolves the name and tries each address, IPv6 and IPv4 in turn, until one connects; the timeout covers them all |
| `SetReadTimeout( ms )`, `SetWriteTimeout( ms )` | a read or write that waits longer fails with `fs.FS_TIMED_OUT`; 0 means wait for ever. Can be set before `Connect` |
| `SetNoDelay( on )` | sends small writes at once instead of gathering them |
| `SetKeepAlive( on )` | probes an idle connection so a dead peer is noticed |
| `Shutdown( how )` | `SHUTDOWN_WRITE` tells the peer there is no more data — its reads then end; `SHUTDOWN_READ`, `SHUTDOWN_BOTH` |
| `LocalAddress( )`, `PeerAddress( )` | this end's and the other end's `SocketAddress` |
| `Close( )`, `IsOpen( )` | closing twice is harmless; the destructor closes too |

A read that returns 0 bytes means the peer finished sending. A peer that resets the connection makes reads and writes fail with `fs.FS_CONNECTION_RESET`.

## TCP Servers

A `TcpListener` waits for connections. `Bind` it to an address and port, then `Accept` each connection into a `TcpStream`.

```freebasic
#import "std/net"

dim l as net.TcpListener
if l.Bind( net.SocketAddress( net.Loopback( ), 0 ) ).IsOk( ) then
    print "listening on "; l.LocalAddress( ).Value( ).ToString( )
    dim conn as net.TcpStream
    dim r as net.NetResultBool = l.Accept( conn, 100 )
    if r.IsOk( ) = false then print r.Failure( ).Message( )   ' Accept: timed out
end if
```

| Call | Does |
|---|---|
| `Bind( addr, backlog, dualStack )` | binds and starts listening. Port 0 picks a free port — read it back with `LocalAddress( )`. Bound to `AnyAddress( TRUE )` (`::`), a listener with `dualStack` (the default) also takes IPv4 connections |
| `Accept( conn, timeoutMs )` | waits for the next connection and opens `conn` on it; `NET_TIMED_OUT` when the timeout ends first |
| `LocalAddress( )`, `Close( )`, `IsOpen( )` | |

A port another listener holds is `NET_ADDRESS_IN_USE`. On Windows a bound port cannot be taken over by another program; on Linux and macOS a restarted server can bind its port again at once, even while old connections are still closing.

## UDP

A `UdpSocket` sends and receives datagrams — single messages that arrive whole or not at all.

```freebasic
#import "std/net"

dim a as net.UdpSocket, b as net.UdpSocket
a.Bind( net.SocketAddress( net.Loopback( ), 0 ) )
b.Bind( net.SocketAddress( net.Loopback( ), 0 ) )
dim as string msg = "ping"
a.SendTo( cptr( ubyte ptr, strptr( msg ) ), len( msg ), b.LocalAddress( ).Value( ) )

dim as string buf = space( 100 )
dim from as net.SocketAddress
b.SetReadTimeout( 1000 )
dim r as net.NetResultI64 = b.ReceiveFrom( cptr( ubyte ptr, strptr( buf ) ), 100, from )
if r.IsOk( ) then print left( buf, r.Value( ) ); " from "; from.ToString( )
```

| Call | Does |
|---|---|
| `Bind( addr )` | receives on that address and port |
| `SendTo( p, n, dst )` | sends `n` bytes as one datagram; an unbound socket is opened for `dst`'s kind of address |
| `ReceiveFrom( p, n, src )` | waits for one datagram and says who sent it. One longer than `n` fills the buffer and fails with `NET_MESSAGE_TOO_LONG` — the rest is lost |
| `Connect( addr )`, `Send( p, n )`, `Receive( p, n )` | fixes the other end, after which only its datagrams arrive |
| `SetReadTimeout( ms )` | a receive that waits longer fails with `NET_TIMED_OUT` |
| `SetBroadcast( on )`, `JoinMulticast( group )` | broadcast sends; receiving a multicast group |
| `LocalAddress( )`, `Close( )`, `IsOpen( )` | |

An IPv6 socket bound to `::` talks to IPv4 addresses too; they appear as `::ffff:a.b.c.d`.

## URLs

`ParseUrl( text )` takes a URL apart following RFC 3986. A `Url` is a value with public fields:

| Field | Holds |
|---|---|
| `Scheme` | `https` — always lower case |
| `User`, `Password` | from `user:pass@`, decoded |
| `Host` | `example.com`; an IPv6 address without its brackets, with its zone (`fe80::1%eth0`) |
| `Port` | the number, or -1 when the URL has none |
| `Path` | decoded: `/a b` for `/a%20b` |
| `RawQuery` | the query as written, without the `?` |
| `Fragment` | decoded, without the `#` |

```freebasic
#import "std/net"

dim base_ as net.Url = net.ParseUrl( "http://example.com/docs/guide/intro.html" ).Value( )
print base_.Resolve( "../api/net.html#url" ).Value( ).ToString( )
' http://example.com/docs/api/net.html#url

dim u as net.Url
u.Scheme = "https"
u.Host = "example.com"
u.Path = "/files/report 2026.pdf"
u.RawQuery = "v=2"
print u.ToString( )      ' https://example.com/files/report%202026.pdf?v=2
```

| Call | Does |
|---|---|
| `ParseUrl( text )` | a `Url`, or `NET_INVALID_URL` for a bad `%` escape, a bad port, a space in the host, a control character |
| `ToString( )` | the URL again, each part escaped as little as it needs; a parsed URL prints as it was written |
| `Resolve( reference )`, `ResolveUrl( url )` | a link relative to this URL — `../x`, `?q=1`, `//host/p` — made absolute, `.` and `..` removed |
| `Query( )` | `RawQuery` as `QueryValues`; a pair with a bad escape is left out |
| `EscapedPath( )` | the path as it appears in the URL |
| `HostPort( )` | `example.com:8443`, `[::1]:80` |
| `IsAbsolute( )` | it has a scheme |

Changing a field and calling `ToString( )` escapes the new value, so text can be put into a `Url` as it is.

## Query Strings

`QueryValues` is the `name=value&name=value` part of a URL: an ordered list of pairs in which one name may appear more than once.

```freebasic
#import "std/net"

dim q as net.QueryValues = net.ParseQuery( "tag=a&tag=b&q=tiko+lang" ).Value( )
print q.Get( "q" ).ValueOr( "" )        ' tiko lang
print q.GetAll( "tag" ).Count( )        ' 2
q.SetValue( "page", "3" )
q.Remove( "tag" )
print q.Encode( )                       ' q=tiko+lang&page=3
```

| Call | Does |
|---|---|
| `ParseQuery( text )` | splits on `&` and each pair at its first `=`, decodes `%XX` and `+`; a bad escape is `NET_INVALID_URL`. A `;` is part of a value, not a separator |
| `Get( name )` | the first value, as an `Optional` |
| `GetAll( name )`, `Has( name )` | every value; whether there is one |
| `Add( name, value )` | appends a pair |
| `SetValue( name, value )` | the first pair of that name takes the value, the others go |
| `Remove( name )` | removes every pair of that name |
| `Count( )`, `KeyAt( i )`, `ValueAt( i )` | the pairs in order, from 0 |
| `Encode( )` | the query text, in order; spaces become `+` |

## Blocking And Threads

Every socket call waits until it is done or its timeout ends. A goroutine inside one holds its worker thread while it waits, so a server that handles each connection in a goroutine should either limit how many it serves at once to the number of workers, or give every connection timeouts. Sockets cannot be copied, and one socket must not be used from two threads at once; different sockets on different threads are fine. Child processes do not inherit sockets.

On Windows, after a read has timed out the system no longer promises what state the connection is in — close it rather than read again.

## Errors

A `NetError` has `Code( )`, `OsCode( )` (the system's own number, or 0), `Operation( )`, `Subject( )` (the address, host or text concerned) and `Message( )`, for example `Connect '127.0.0.1:9': connection refused (os error 10061)`.

| Code | Means |
|---|---|
| `NET_HOST_NOT_FOUND`, `NET_TEMPORARY_FAILURE` | the name has no address; the resolver could not answer now |
| `NET_CONNECTION_REFUSED`, `NET_CONNECTION_RESET` | nothing listens there; the peer reset the connection |
| `NET_TIMED_OUT` | a timeout ran out |
| `NET_ADDRESS_IN_USE`, `NET_ADDRESS_NOT_AVAILABLE` | `Bind`: the port is taken; the address is not this machine's |
| `NET_NETWORK_UNREACHABLE`, `NET_HOST_UNREACHABLE` | no route |
| `NET_ACCESS_DENIED` | a port or a send the system does not allow |
| `NET_MESSAGE_TOO_LONG` | a datagram longer than the buffer, or than UDP carries |
| `NET_NOT_CONNECTED`, `NET_CLOSED`, `NET_ALREADY_OPEN` | the socket is not connected, not open, or already open |
| `NET_INVALID_ADDRESS`, `NET_INVALID_URL`, `NET_INVALID_ARGUMENT` | text that is not an address or a URL; a negative size or a null buffer |
| `NET_UNKNOWN` | anything else; `OsCode( )` says what |

Stream reads and writes on a `TcpStream` report `fs.FsError` codes: `FS_TIMED_OUT`, `FS_CONNECTION_RESET`, `FS_BROKEN_PIPE`, `FS_CLOSED`.

## See Also

- [Filesystem Library](Category-Filesystem) — streams, which a `TcpStream` is
- [Codec](Category-Codec) — `PercentEncode` and `PercentDecode` on their own
- [Goroutines and Channels](Category-Goroutines-and-Channels) — serving several connections at once
- [Process](Category-Process) — talking to another program through pipes instead
