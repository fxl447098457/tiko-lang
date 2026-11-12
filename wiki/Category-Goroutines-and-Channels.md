[Home](Home) › [All Categories](Categories) › **Goroutines and Channels**

# Goroutines and Channels

Most programs do one thing at a time: each line finishes before the next one starts. **Concurrency** is a program doing several things at once -- scanning a folder while it keeps its window responsive, or splitting a big job across all the cores of a CPU. Goroutines and channels are tiko's way of writing that.

A **goroutine** is a procedure that runs *alongside* the rest of your program. You start one with the `spawn` statement, and your program carries straight on without waiting for it to finish.

A **channel** is how goroutines pass values to one another. One side sends a value in; the other side receives it, in the same order. A channel can hold a few values while the receiver catches up, and a receiver that finds it empty simply waits for the next one.

Think of a busy kitchen. The cooks are goroutines: each works on its own dish at the same time as the others. The pass -- the counter where finished plates are set down for the waiters -- is a channel: a cook puts a plate on it, a waiter takes it off, and nobody has to stand around talking to arrange it. Because everything travels through the pass, two cooks never fight over the same plate.

That last point is the reason to use channels. Threads that share variables need careful locking to avoid corrupting each other's data. Goroutines that hand values through channels, and keep everything else to themselves, mostly do not.

> 📘 **Also in this category:** [Goroutines Tutorial](Modern-Goroutines-Tutorial) -- a step-by-step introduction.

```freebasic
#import "std/tasks"
using tasks

sub Produce( byval jobs as SendChan( of int32 ), byval n as int32 )
    for i as int32 = 1 to n
        jobs.Send( i * i )
    next
    jobs.Close( )
end sub

dim jobs as Channel( of int32 ) = Channel( of int32 )( 16 )

spawn Produce( jobs, 100 )

for each v in jobs               ' ends when the producer closes and drains
    print v
next
```

**Requires `-mt`.** std/tasks refuses to compile without it (TKO0309, its `#error`) rather than link a single-threaded runtime and misbehave.

## Why It Exists

std/tasks gives concurrent code a shape that the compiler and the types can check:

- **`spawn`** starts a goroutine and copies its arguments at that moment, so each one works on its own values.
- **Typed channels** carry values between goroutines -- including a goroutine's result back to whoever is waiting for it.
- **`select channel`** waits on several channels at once, with an optional timeout.
- **WaitGroup** waits for a whole fan-out of goroutines to finish.
- **Context** asks goroutines to stop, and composes with `select`.
- **SendChan and RecvChan** say in a procedure's signature which end of a channel it may use.

Getting one value back from a goroutine takes a channel and four lines:

```freebasic
dim done as Channel( of int32 ) = Channel( of int32 )( 1 )
spawn Worker( done )
dim as int32 answer
done.Receive( answer )
```

The channel is typed, so a second worker returning a STRING is a second channel, not a second shared global.

## The Shape, In One Table

| Construct | What it does |
| --- | --- |
| `spawn Worker( a, b )` | run Worker concurrently; a and b are **copied** here |
| `Channel( of T )` | a typed queue: rendezvous or buffered, with close |
| `select channel` | wait on several channels at once |
| `WaitGroup` | wait for a fan-out to finish |
| `Context` | ask a goroutine to stop; composes with select |
| `SendChan` / `RecvChan` | one-way views, so a signature says which end |

| std/tasks file | What it brings |
| --- | --- |
| channel.tiko | Channel, SendChan, RecvChan |
| scheduler.tiko | `tasks.Spawn`, GoroutineCount, WorkerCount |
| select.tiko | the `select channel` runtime |
| sync.tiko | WaitGroup, Context |

## What A Goroutine Is -- Read This Once

A goroutine is a work item on a thread pool. It is **not** Go's goroutine, and the difference is not a matter of effort.

Go's goroutines are stackful coroutines multiplexed onto OS threads, starting at a 2 KB growable stack, and millions of them are routine. That works because the Go runtime owns every blocking operation in the language. tiko programs call Win32 and libc directly, so a fibre that called Sleep or ReadFile would freeze every other fibre sharing its carrier thread, with no diagnostic -- and tiko's per-thread state (`err( )`, the TLS context table, window ownership, COM apartments) is keyed to the OS thread, not the fibre.

So:

- **Spawning is a queue push, not a thread creation.** Thousands of goroutines are fine; millions are not.
- **A goroutine blocked in a syscall holds an OS thread.** The pool grows when that happens, capped at 256 workers.
- **A goroutine runs on an arbitrary worker.** Never touch an HWND, a GDI object or a COM apartment belonging to another thread from one. Post the result back through a channel that the UI thread drains -- see [Background Work In A Desktop App](#background-work-in-a-desktop-app) below.
- **Nothing joins goroutines.** At program exit, work still running is abandoned, silently. Use a WaitGroup or a channel if it must finish.

## Spawn

```freebasic
spawn Worker( a, b )
```

Runs `Worker( a, b )` concurrently. The arguments are evaluated **here** and copied, which is the whole reason this is a statement rather than a library call:

```freebasic
for i as int32 = 1 to 10
    spawn Work( i )        ' each goroutine gets ITS OWN i
next
```

A closure-capturing design would share one `i`, and most goroutines would see 11. tiko's capturing lambdas build their closure on the stack, so handing one to another thread is a use-after-free that compiles cleanly.

**`spawn` is a contextual keyword.** Code can use it as a variable, a field, an array or a SUB name. The one exception: a paren-less call in statement position to a SUB named `spawn` -- `spawn x` -- parses as spawning x. `spawn( x )` calls it.

What can be spawned:

| Target | Spawnable? |
| --- | --- |
| a sub | yes |
| a function | yes -- **the result is discarded**, as in Go |
| an overloaded procedure | yes, resolved from the argument types |
| a sub of no parameters, written without parentheses: `spawn Worker` | yes |
| a method -- `obj.Method( a )`, `p->Method( a )`, a static `T.Method( a )` | no -- TKO0943 |
| a procedure inside a namespace, `NS.Worker( a )` | no -- TKO0943 |
| a procedure pointer or a lambda | no -- TKO0943 |

To run a method or a namespace's procedure concurrently, spawn a module-level sub that calls it, and pass the object by pointer.

**A BYREF parameter is a compile error at a spawn site.** Copying defeats the BYREF; honouring it would hand the goroutine a reference into a frame that is about to die. Pass a pointer if sharing is what you mean. That includes a STRING or UDT parameter written with neither keyword, which is byref by default: `sub Worker( s as string )` cannot be spawned, and `sub Worker( byval s as string )` can. With overloads, the first-declared procedure of the name is the one judged.

**Every argument must be written.** A default argument cannot be omitted at a spawn site: the argument count is taken from the target's parameter list, because the lexer looks ahead three tokens and the written arguments cannot be counted.

A goroutine returns nothing. The channel is the return path.

`tasks.Spawn( @Worker, @ctx )` is the library form the statement lowers to. It is public, and it puts the entire lifetime of `ctx` on you -- prefer the statement.

## Channel

```freebasic
dim ch as Channel( of int32 ) = Channel( of int32 )( 16 )   ' buffered
dim rv as Channel( of int32 ) = Channel( of int32 )( 0 )    ' rendezvous
dim nl as Channel( of int32 )                              ' NIL
```

```text
Send( v )              blocks until there is room, or a receiver
Receive( out )         blocks until there is a value; FALSE at end of stream
TrySend / TryReceive   never block; FALSE if they would
SendFor / ReceiveFor   with a timeout in ms
Close( )               "no more values will be sent"
IsClosed, IsNil, Count, Capacity
for each v in ch       drains until closed and empty
```

**Capacity 0 is a rendezvous**, not a zero-length buffer. Send does not return until a receiver has taken the value: it is a handoff *and* an ordering point.

**Capacity N buffers N items**; Send blocks only when full. That backpressure is what keeps a fast producer from consuming all memory. There is no unbounded capacity, because an unbounded channel turns a slow consumer into an out-of-memory kill far from the cause.

**Copies share.** A Channel is a refcounted handle, so handing a copy to each of four workers gives four handles on **one** queue. This is deliberately unlike `containers.Array`, whose copy is deep. The destructor does not close.

### What Every Operation Returns

| | Open, ready | Open, would block | Closed, has items | Closed, empty | Nil channel |
| --- | --- | --- | --- | --- | --- |
| Send | TRUE | blocks | raises | raises | blocks forever |
| Receive | TRUE | blocks | TRUE, drains | FALSE | blocks forever |
| TrySend | TRUE | FALSE | raises | raises | FALSE |
| TryReceive | TRUE | FALSE | TRUE | FALSE | FALSE |
| SendFor | TRUE | FALSE after ms | raises | raises | FALSE after ms |
| ReceiveFor | TRUE | FALSE after ms | TRUE | FALSE | FALSE after ms |
| Close | -- | -- | raises | raises | raises |

"Raises" is runtime error 1, illegal function call -- the same one `Optional.Value( )` raises on an empty Optional.

**Receive returning FALSE on a closed, drained channel is the termination signal**, not a failure. It is what makes the drain loop work:

```freebasic
while ch.Receive( v )
    Process( v )
wend            ' falls out when the producer closes and the buffer drains
```

`out` is not modified when Receive returns FALSE.

**Send after close raises** rather than returning FALSE, and so does closing twice. Each means two parties disagree about who owns the producer role -- a structural bug, not a runtime condition.

Closing does not discard buffered items, and it wakes every blocked waiter.

**The nil channel.** A default-constructed Channel is nil, and Send and Receive on it block **forever**. That looks like a defect until you meet `select channel`, where assigning a nil channel is how a case is disabled. `IsNil( )` exists so a program can assert its own initialisation, because "my program hangs" is the symptom of forgetting it.

T must be default-constructible, copy-constructible and destructible -- the same requirement `containers.Array` makes. Every send copies, and a buffered send copies twice; there is no move constructor in the language. For a large T, send a pointer.

## Select

```freebasic
select channel
    case receive job from jobs    : Process( job )
    case receive from ctx.Done( ) : exit do
    case send result to results   : sent += 1
    case timeout 500              : Heartbeat( )
    case else                     : DoOtherWork( )
end select
```

Waits on several channels at once and runs the case that becomes ready first. The file that uses it needs `#import "std/tasks"`, and the build needs `-mt`.

- **`case else` makes the whole statement non-blocking**: it fires the moment nothing is ready. This is Go's `default`.
- **`case timeout <ms>`** fires if nothing becomes ready in time. At most one, and it cannot appear beside `case else` -- ELSE would fire first, every time, so the timeout could never be reached. That combination is a compile error.
- **`case receive v from ch`** needs v already declared. `case receive from ch` receives and discards, which is how a `Done( )` channel is used.
- **The cases are polled in a pseudo-random order.** With a fixed order a channel that is always ready starves every case after it, and the failure only shows under load.
- **A nil channel case is permanently not-ready.** That is how you disable a case without rewriting the statement.
- **A closed channel is ready for receive**, and fires with the closed-channel answer -- so a select case cannot by itself tell "received" from "closed". Nil out the channel on close, or re-check inside the body.
- **Each channel expression is evaluated exactly once**, even though the lowering needs it three times.
- **`exit do` or `goto` out of a case body is fine**; the wait records are still released.

`channel` is contextual: SELECT CASE, including SELECT CASE on a variable named `channel`, is untouched. Only the pair `select channel` claims the statement.

## WaitGroup

```freebasic
dim wg as WaitGroup
for i as int32 = 1 to 8
    wg.Add( )
    spawn Worker( i, @wg )      ' Worker calls wg.Done( ) on the way out
next
wg.Wait( )
```

```text
Add( delta = 1 )   Done( )   Wait( )   WaitFor( ms )   Count( )
```

**Add before the spawn, always.** Adding from inside the goroutine races the Wait.

Everything every counted goroutine did before its Done is visible after Wait returns, with no other synchronization.

**A WaitGroup is non-copyable** -- a copy would be a second counter, and one of them would never reach zero. Pass it BYREF, or by pointer into a goroutine.

Done below zero raises, Add below zero raises, and Add from zero while a Wait is in progress raises. The destructor does not wait; destroying one with waiters still parked on it raises rather than leaving them parked forever.

## Context

```freebasic
dim ctx as CancelContext = WithCancel( Context( ) )
defer ctx.Cancel( )                  ' releases the registration
spawn Worker( ctx )
...
ctx.Cancel( )                        ' ask it to stop
```

```text
Context( )                    the background context; never cancelled
WithCancel( parent )          a cancellable child
WithTimeout( parent, ms )     cancels itself when the deadline passes
InterruptContext( )           cancelled by the first Ctrl-C or SIGTERM (std/os)
IsCancelled( )   Err( )   Done( )
CancelContext.Cancel( )
```

**`Done( )` returns a channel that is closed on cancel.** That is the whole trick, and it is why cancellation is modelled as a channel: a closed channel is permanently ready, so cancellation composes with every other channel operation for free.

```freebasic
do
    select channel
        case receive job from jobs    : Process( job )
        case receive from ctx.Done( ) : exit do
    end select
loop
```

**Cancel is idempotent**, unlike `Channel.Close` -- a context is routinely cancelled by both a timeout and an explicit Cancel, so "two parties" is normal here.

**Cancellation propagates down, and only down.** Cancelling a parent cancels every context derived from it, transitively; cancelling a child never touches its parent. A context derived from an already-cancelled parent starts cancelled.

`Err( )` is `""`, `"cancelled"` or `"deadline exceeded"`.

**Nothing is ever killed.** A goroutine that never checks its context runs to completion, and Cancel changes nothing observable in it. Forced termination skips destructors and DEFER blocks and leaks every mutex the thread held; in a language that has DEFER, that means the cleanup written specifically to be unmissable is missed. Cancellation is a **request** -- the name suggests otherwise, which is why this paragraph exists.

A goroutine blocked in a syscall cannot be cancelled. That is the cost, and it is why every blocking operation here takes a timeout.

## Directional Channels

```freebasic
sub Produce( byval jobs as SendChan( of int32 ) )    ' cannot receive
sub Consume( byval jobs as RecvChan( of int32 ) )    ' cannot send or Close
```

RecvChan deliberately has no Close: closing is the producer's statement, and a consumer that closes its input is the most common channel bug there is.

**Conversion is one way.** There is no cast back to Channel, because a directional handle is a narrowing, and narrowing should not be reversible by accident.

**These are ergonomics, not safety.** Nothing stops a caller keeping the full Channel and using both ends; what they make checkable is the intent at the boundary where it is written down.

## Background Work In A Desktop App

This is the case that matters most in a Win32 program, and it has a rule.

A goroutine runs on an arbitrary worker thread. Window handles belong to the thread that created them, so a SetWindowText from a goroutine is a bug that appears to work for months. Compute in the goroutine, hand the result back through a channel, and let the UI thread pick it up:

```freebasic
' UI thread
dim shared as Channel( of ScanResult ) g_results

sub ScanFolder( byval path as ustring, byval jobs as Channel( of ScanResult ) )
    for each entry in WalkDir( path )
        if entry.IsOk( ) then jobs.Send( ToResult( entry.Value( ) ) )
    next
    jobs.Close( )
end sub

g_results = Channel( of ScanResult )( 64 )
spawn ScanFolder( selectedPath, g_results )

' in WM_TIMER, or after a PostMessage wakeup:
dim r as ScanResult
while g_results.TryReceive( r )        ' TryReceive: never block the UI
    AddRowToListView( r )
wend
```

TryReceive rather than Receive is the whole point of that loop: the UI thread drains whatever has arrived and returns to its message pump immediately. A Receive there would freeze the window -- the bug the goroutine was meant to fix.

## The Rules That Are Easy To Get Wrong

- **Requires `-mt`.** std/tasks says so rather than misbehaving.
- A goroutine still running at program exit is **abandoned**, silently.
- Send after close **raises**; Receive at end of stream returns FALSE. They are different on purpose.
- A nil channel blocks forever. `IsNil( )` tells you.
- `Count( )` is a snapshot, and stale the instant it returns. Use it for metrics only, never for control flow.
- Never touch a window, a GDI object or a COM apartment from a goroutine.
- `wg.Add` **before** the spawn, never inside the goroutine.
- Cancellation is advisory. A goroutine that ignores its context blocks its waiters forever.
- **A runtime error inside a goroutine does not propagate.** The worker's error state is reset between items so it cannot leak into the next goroutine, but nobody observes it. Send a `Result( of T, E )` instead.
- **There is no data-race protection of any kind.** A channel will happily carry a type holding a pointer into another goroutine's stack. This design makes concurrency ergonomic, not safe.

## What Is NOT Here

- **Cheap goroutines.** Thousands, not millions -- see [What A Goroutine Is](#what-a-goroutine-is----read-this-once).
- **Send/Sync markers, or any data-race detection.** They need a type system tiko does not have, and a marker the compiler cannot enforce is documentation in a costume.
- **Forced cancellation.** Argued above.
- **A value returned from a goroutine.** Go has none either; the channel is the return path.
- **WithDeadline.** WithTimeout covers it without dragging std/chrono into every program that wants cancellation.
- **sync.Once, RWMutex, a scoped lock guard.** Worth having, orthogonal to this, and MutexCreate/MutexLock already exist.
- **Broadcast channels, priorities, peek.** A channel is a FIFO queue, and each item goes to exactly one receiver.
- **A deadlock detector.** Go can say "all goroutines are asleep" because it knows about every block; this cannot see a goroutine blocked in ReadFile.
- **`spawn` inside a generic member body.** It does not compile, and neither does a plain lambda there -- a limitation of how a generic member's body is replayed, not something `spawn` introduced. A generic *procedure* is fine.

## Implementation

Both statements are desugared in tiko's parser (src/parser/spawn.tiko, src/parser/selchan.tiko) into ordinary statements that the rest of the compiler already lowers. `spawn` builds the argument frame itself and hands a plain thunk straight to fb_Spawn; the arguments are copied at the spawn, and the frame is destroyed and freed afterwards. `select channel` becomes calls into the generics of std/tasks' select.tiko.

The runtime side is tiko-rt's, written in tiko: the park/unpark layer (lib/rt/src/thread/park.tiko), the scheduler (sched.tiko) and the process-wide claim lock (claimlock.tiko).

Channel, select, WaitGroup, Context and the directional views are ordinary tiko in the std/tasks module (pkg/std/tasks/) -- written on generics, with no compiler privileges.

## Tests

The library's suites run in tiko-lang's test suite: tests/std/concurrency/ holds channel, sched and sync.

tiko's own suite also pins the language side. tests/mir/spawn.test covers the lowering of `spawn`, tests/mir/spawn-contextual.test `spawn` used as an ordinary variable, and tests/mir/spawn-conv-arg.test an argument converted to the parameter's type, as a call converts it. tests/diagnostics/spawn-byref.test holds the BYREF rule above (TKO0812). For `select channel`, tests/driver/select-channel-link.test builds every case form and checks that it links, and tests/driver/select-channel-run.test builds a program that covers every case form, which build/goldenrun.sh runs.

Build a program that uses this module with a packaged toolchain -- no `-i`, no `-p`, because the modules and the runtime are in it:

```text
toolchains\tiko-windows\tiko.exe -mt yourprogram.tiko
toolchains/tiko-linux/bin/tiko   -mt yourprogram.tiko
toolchains/tiko-macos/bin/tiko   -mt yourprogram.tiko
```

<!-- finder:start -->

## API reference

Every entry, grouped by task. [Running things at once](Functions-Concurrency) lists them beside the rest of the area.

### Start a goroutine

| Function | What it does | From |
|---|---|---|
| [spawn](Modern-Chan-Spawn) | Runs a procedure alongside the program, copying its arguments at that moment. | `std/tasks` |

### Make a channel

| Function | What it does | From |
|---|---|---|
| [Channel](Modern-Chan-Channel-Channel) | Holds a typed queue between goroutines; copies share it, and a new one is nil. | `std/tasks` |
| [Channel.Capacity](Modern-Chan-Channel-Capacity) | Returns the buffer size the channel was made with; 0 means each value is handed over. | `std/tasks` |
| [Channel.IsNil](Modern-Chan-Channel-IsNil) | Returns true for a default-constructed channel, which blocks forever if used. | `std/tasks` |

### Send and receive values

| Function | What it does | From |
|---|---|---|
| [Channel.Send](Modern-Chan-Channel-Send) | Sends a value, waiting for room or a receiver; raises an error if the channel is closed. | `std/tasks` |
| [Channel.Receive](Modern-Chan-Channel-Receive) | Receives a value, waiting for one; returns false once closed and drained. | `std/tasks` |
| [Channel.TrySend](Modern-Chan-Channel-TrySend) | Sends a value only if it can go at once; returns false if it would have to wait. | `std/tasks` |
| [Channel.TryReceive](Modern-Chan-Channel-TryReceive) | Receives a value only if one is ready; returns false if empty or closed. | `std/tasks` |
| [Channel.SendFor](Modern-Chan-Channel-SendFor) | Sends a value, waiting at most ms milliseconds; returns false on a timeout. | `std/tasks` |
| [Channel.ReceiveFor](Modern-Chan-Channel-ReceiveFor) | Receives a value, waiting at most ms milliseconds; false on a timeout or end of stream. | `std/tasks` |

### Close and drain a channel

| Function | What it does | From |
|---|---|---|
| [Channel.Close](Modern-Chan-Channel-Close) | Marks that no more values will be sent; values already buffered are still delivered. | `std/tasks` |
| [Channel.IsClosed](Modern-Chan-Channel-IsClosed) | Returns true once the channel is closed, even while values are still buffered. | `std/tasks` |
| [Channel.Count](Modern-Chan-Channel-Count) | Returns how many values are buffered right now, as a snapshot. | `std/tasks` |
| [Channel.GetIterator](Modern-Chan-Channel-GetIterator) | Returns the iterator a for each loop uses to receive until the channel is drained. | `std/tasks` |
| [ChannelIterator](Modern-Chan-Channel-ChannelIterator) | Holds a for each loop's place while it receives from a channel. | `std/tasks` |

### Hand out one end of a channel

| Function | What it does | From |
|---|---|---|
| [SendChan](Modern-Chan-Channel-SendChan) | Holds a send-only view of a channel, for a procedure that only produces. | `std/tasks` |
| [RecvChan](Modern-Chan-Channel-RecvChan) | Holds a receive-only view of a channel, which cannot send to it or close it. | `std/tasks` |

### Wait for a group of goroutines

| Function | What it does | From |
|---|---|---|
| [WaitGroup.Add](Modern-Chan-Add) | Adds 1, or a given amount, to the work outstanding; call it before the spawn. | `std/tasks` |
| [WaitGroup.Done](Modern-Chan-Done) | Subtracts one from the work outstanding; raises an error if it would go below zero. | `std/tasks` |
| [WaitGroup.Wait](Modern-Chan-Wait) | Waits until the work outstanding reaches zero. | `std/tasks` |
| [WaitGroup.WaitFor](Modern-Chan-WaitFor) | Waits at most ms milliseconds for the work to reach zero; returns false on a timeout. | `std/tasks` |
| [WaitGroup.Count](Modern-Chan-Count) | Returns how much work is still outstanding, as a snapshot. | `std/tasks` |

### Ask goroutines to stop

| Function | What it does | From |
|---|---|---|
| [Context](Modern-Chan-Context) | Holds the background context, which is never cancelled and is the root of all others. | `std/tasks` |
| [WithCancel](Modern-Chan-WithCancel) | Returns a child context that you cancel yourself. | `std/tasks` |
| [WithTimeout](Modern-Chan-WithTimeout) | Returns a child context that cancels itself after the given milliseconds. | `std/tasks` |
| [CancelContext.Cancel](Modern-Chan-Cancel) | Cancels the context and every context made from it; a second call is harmless. | `std/tasks` |
| [Context.IsCancelled](Modern-Chan-IsCancelled) | Returns true once the context is cancelled or its deadline has passed. | `std/tasks` |
| [Context.Err](Modern-Chan-Err) | Returns why the context ended: "cancelled", "deadline exceeded", or "" while live. | `std/tasks` |

### Check on the scheduler

| Function | What it does | From |
|---|---|---|
| [GoroutineCount](Modern-Chan-GoroutineCount) | Returns how many goroutines exist right now, as a snapshot for diagnostics. | `std/tasks` |
| [WorkerCount](Modern-Chan-WorkerCount) | Returns how many OS threads the scheduler is running goroutines on. | `std/tasks` |

<!-- finder:end -->

---



---

[Home](Home) · [Keyword Index](Keyword-Index)
