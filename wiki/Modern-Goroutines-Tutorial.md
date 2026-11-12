[Home](Home) › [Goroutines and Channels](Category-Goroutines-and-Channels) › **Goroutines Tutorial**

# Goroutines Tutorial

**Who this is for:** a tiko programmer who has never written a thread.
No prior knowledge of concurrency, threads, locks or message passing is assumed.
By the end you will be able to write a worker pool, a pipeline, a cancellable
background scan, and a Win32 app that stays responsive — and you will know which
of those you *shouldn't* write.

**What you need:**

* A tiko toolchain: `toolchains\tiko-windows\tiko.exe` on Windows,
  `toolchains/tiko-linux/bin/tiko` on Linux, `toolchains/tiko-macos/bin/tiko` on macOS.
* The `-mt` flag on **every** build. `std/tasks` refuses to compile without it
  (TKO0309, its `#error`) rather than link a single-threaded runtime and misbehave quietly.

```bash
toolchains\tiko-windows\tiko.exe -mt example.tiko
```

**The reference** — every rule, every table, every edge case — is
[`goroutines.txt`](Category-Goroutines-and-Channels) in this folder. This document teaches; that
one specifies. When you finish here, read that.

Every program in this tutorial was compiled and run. The outputs shown are real
program output, not illustrations. Under tiko, on windows-x86_64:

* **The output shown:** every program, ex01–ex07 and ex09–ex19, up to
  what varies from run to run: the interleaving of
  concurrent lines, ex01's elapsed seconds, which worker takes which job in ex07,
  ex10's hit count before its deadline, and ex15's lost-update count, which is
  random by design.
* ex08 is two procedures rather than a program; with the `#import` and
  `using tasks` it needs, it compiles.

tiko reports its compiler messages with `TKOnnnn` ids: a `byref` parameter at
a spawn site is TKO0812, and a `RecvChan` or `SendChan` in a `select channel`
case is TKO0809, which names the `std/tasks` generic that could not be
instantiated.

---

## Table of contents

| # | Chapter | What you learn |
|---|---------|----------------|
| 0 | [Why bother](#0-why-bother) | The three problems concurrency actually solves |
| 1 | [Your first goroutine](#1-your-first-goroutine) | `spawn`, and what it really costs |
| 2 | [Getting an answer back](#2-getting-an-answer-back) | `Channel`, `Send`, `Receive` |
| 3 | [Buffer size and backpressure](#3-buffer-size-and-backpressure) | Rendezvous vs buffered |
| 4 | [Closing and draining](#4-closing-and-draining) | `Close`, `for each`, end-of-stream |
| 5 | [Waiting for everyone](#5-waiting-for-everyone-waitgroup) | `WaitGroup`, and the abandonment trap |
| 6 | [A worker pool](#6-a-worker-pool) | Fan-out, fan-in, who closes what |
| 7 | [One-way channels](#7-one-way-channels) | `SendChan` / `RecvChan` |
| 8 | [Waiting on several things](#8-waiting-on-several-things-select-channel) | `select channel` |
| 9 | [Deadlines](#9-deadlines-on-a-single-operation) | `ReceiveFor`, `SendFor` |
| 10 | [Cancellation](#10-cancellation-context) | `Context`, `WithCancel`, `WithTimeout` |
| 11 | [Errors](#11-errors-in-a-goroutine) | Why exceptions don't work here |
| 12 | [Pipelines](#12-pipelines) | Multi-stage streaming |
| 13 | [Limiting concurrency](#13-limiting-concurrency) | Semaphores and rate limits |
| 14 | [Shared state](#14-shared-state-and-why-you-should-avoid-it) | The data race, demonstrated |
| 15 | [Desktop apps](#15-background-work-in-a-desktop-app) | The one rule that matters in Win32 |
| 16 | [Pitfalls](#16-pitfalls-a-checklist) | The checklist to re-read |
| — | [Reference tables](#reference-tables) | Every operation, every state |
| — | [Glossary](#glossary) | Every term used above |

---

## 0. Why bother

Almost every program that "needs threads" needs them for one of exactly three
reasons. It is worth knowing which one you have, because the answer changes what
you write.

**1. Waiting.** Your program asks for something slow — a web page, a database
row, a file on a network share — and then does nothing until the answer comes
back. A CPU that is waiting on a network is not working. If you have five things
to fetch, fetching them one at a time takes five times as long as fetching them
together, and *none* of that extra time is your program computing anything.

**2. Cores.** Your machine has eight cores. A single-threaded program uses one.
Hashing ten thousand files, resizing a folder of images, parsing a large log —
these are jobs where eight cores really do finish in something close to an
eighth of the time.

**3. Responsiveness.** A Win32 program has a message loop. While your code is
running, that loop is not running, so the window does not repaint and does not
respond to clicks. Windows notices after a few seconds and paints "(Not
Responding)" over your title bar. Anything that takes longer than about 100 ms
has to happen somewhere other than the UI thread.

### Concurrency is not parallelism

These two words get used interchangeably and they are not the same thing.

* **Concurrency** is *structure*: your program is written as several independent
  activities that make progress without waiting for each other.
* **Parallelism** is *execution*: several things literally running at the same
  instant, on different cores.

Concurrency is what you write. Parallelism is what you sometimes get. A
concurrent program on a single-core machine still wins problem 1 (waiting) and
problem 3 (responsiveness), because those aren't about compute at all.

### Why not raw threads?

tiko has built-in threads, and their entire surface is four opaque
pointers: `ThreadCreate` returns an `any ptr`, and so do `MutexCreate` and
`CondCreate`. There is no way to return a value from a thread, no message
passing, no timed wait anywhere, and no way to wake one specific waiter. So
every concurrent program written on them invents the same shared-global-plus-mutex
protocol from scratch, and nothing checks any of it.

Goroutines and channels replace that with two ideas:

* **`spawn`** — run this procedure concurrently.
* **`Channel`** — a typed queue that safely carries values between concurrent
  activities, and blocks when it should.

That is the whole model. Everything else in this tutorial is a pattern built out
of those two things.

---

## 1. Your first goroutine

### The problem, sequentially

Three pages to fetch. Each takes 300 ms, and every millisecond of that is spent
waiting on a server.

```basic
'' ex01 -- the sequential baseline
sub FetchPage( byval id as int32 )
	sleep 300, 1                        '' pretend: a network round-trip
	print "fetched page " & id
end sub

dim as float64 t0 = timer
for i as int32 = 1 to 3
	FetchPage( i )
next
print using "sequential: #.## seconds"; timer - t0
```

```
fetched page 1
fetched page 2
fetched page 3
sequential: 0.93 seconds
```

> `sleep 300, 1` sleeps 300 ms. The `, 1` means "do not wake early if the user
> presses a key" — always write it in a worker.

Nearly a second, and the CPU was idle for all of it.

### The same work, concurrently

One new word: `spawn`.

```basic
'' ex02 -- the same three fetches, concurrently
#import "std/tasks"
using tasks

sub FetchPage( byval id as int32 )
	sleep 300, 1
	print "fetched page " & id
end sub

dim as float64 t0 = timer
for i as int32 = 1 to 3
	spawn FetchPage( i )
next
sleep 1000, 1                           '' PLACEHOLDER -- chapter 5 removes this
print using "concurrent: #.## seconds"; timer - t0
```

```
fetched page 3
fetched page 1
fetched page 2
concurrent: 1.00 seconds
```

Three 300 ms waits overlapped into one. (The measured second is our crude
`sleep 1000` placeholder, not the work — chapter 5 replaces it with something
that waits exactly as long as necessary.)

### Read the output again

`3`, `1`, `2`. Not `1`, `2`, `3`.

**Concurrent work completes in an order nobody promised.** Run it again and you
may get a different order. This is not a bug and it will not be fixed by trying
harder; it is the defining property of concurrent code. If your program needs an
order, you must *impose* one — chapters 4 and 6 show how. If it doesn't, don't
assume one.

### What `spawn` actually does

```basic
spawn FetchPage( i )
```

The arguments are evaluated **here, at the spawn site, and copied** into the
goroutine. That is the whole reason `spawn` is a statement in the language and
not a library call, and it makes the obvious loop do the obvious thing:

```basic
for i as int32 = 1 to 10
	spawn Work( i )        '' each goroutine gets ITS OWN copy of i
next
```

A design based on closures would have all ten goroutines share one `i`, and most
of them would see `11`. (tiko's capturing lambdas build their closure on the
**stack**, so handing one to another thread is a use-after-free that compiles
cleanly. This is why lambdas cannot be spawned.)

### What a goroutine *is* — read this once

A goroutine here is **a work item on a thread pool**. It is not Go's goroutine,
and the difference is not a matter of effort. Go can multiplex millions of
goroutines onto a handful of OS threads because the Go runtime owns every
blocking operation in the language. tiko programs call Win32 and libc
directly; a fibre that called `Sleep` or `ReadFile` would freeze every other
fibre sharing its carrier thread, silently.

The practical consequences:

* **Spawning is a queue push, not a thread creation.** It is cheap. Thousands of
  goroutines are fine. **Millions are not.**
* **A goroutine blocked in a syscall holds an OS thread.** The pool grows when
  that happens, capped at 256 workers.
* **A goroutine runs on an arbitrary worker thread.** Never touch an `HWND`, a
  GDI object or a COM apartment from one — see chapter 15.
* **Nothing joins goroutines.** Work still running at program exit is
  *abandoned, silently* — see chapter 5.

### What can and cannot be spawned

| | |
|---|---|
| `sub` | yes |
| `function` | yes — **the result is discarded**, as in Go |
| overloaded procedure | yes, resolved from the argument types |
| `obj.Method( a )` | **no** — the compiler stops with an internal error (TKO0994) |
| a procedure inside a `namespace` | **no** — the compiler stops with an internal error (TKO0994) |
| a procedure pointer or lambda | **no** — TKO0943 |

Two more rules the compiler enforces:

* **A `byref` parameter is a compile error at a spawn site.** Copying would
  defeat the `byref`; honouring it would hand the goroutine a reference into a
  stack frame that is about to die. Pass a pointer if sharing is what you mean.

  ```
  error 358: SPAWN cannot pass a BYREF parameter, at parameter 1 (n) of WORK()
  ```

* **Every argument must be written out.** A default argument cannot be omitted
  at a spawn site.

---

## 2. Getting an answer back

A goroutine returns nothing. Not "returns void" — there is no mechanism at all,
and Go has none either. **The channel is the return path.**

A `Channel( of T )` is a typed queue with two fundamental operations:

* `Send( v )` — put a value in; **blocks** if there is no room.
* `Receive( out )` — take a value out; **blocks** until there is one.

"Blocks" means the goroutine stops there and the worker thread goes off and runs
something else. That is the point: blocking on a channel is cheap and correct,
unlike blocking on a UI thread.

```basic
'' ex03 -- getting an answer back
#import "std/tasks"
using tasks

sub CountWords( byval text_ as ustring, byval reply as Channel( of int32 ) )
	dim as int32 n = 0
	for i as int32 = 0 to len( text_ ) - 1
		if( text_[i] = asc( " " ) ) then n += 1
	next
	reply.Send( n + 1 )
end sub

dim reply as Channel( of int32 ) = Channel( of int32 )( 1 )
spawn CountWords( "the quick brown fox jumps", reply )

dim as int32 words
reply.Receive( words )                  '' blocks until the answer arrives
print "words: " & words
```

```
words: 5
```

Compare that with what you would write without a channel: a shared global for
the result, a shared boolean for "is it ready", a mutex, a condition variable,
and a predicate loop — around twenty lines and three globals, none of them
checked by anything. Above, the type of the answer is written once, in the type
of the channel, and a second worker returning a `ustring` is a second channel and
not a second global.

### Channels are handles, and copies share

```basic
dim a as Channel( of int32 ) = Channel( of int32 )( 8 )
dim b as Channel( of int32 ) = a          '' NOT a copy of the queue
```

A `Channel` is a **refcounted handle**. Handing a copy to each of four workers
gives four handles on **one** queue. This is deliberately unlike `containers.Array`,
whose copy is deep. It is what makes `spawn Worker( jobs )` work at all, since
`spawn` copies its arguments.

The destructor does **not** close the channel. Closing is an explicit statement
about the stream (chapter 4), never a side effect of a variable going out of
scope.

### Naming: watch the reserved words

tiko identifiers are case-insensitive and the language has a large keyword
list. `name`, `line`, `close`, `open`, `error`, `time`, `date`, `left`, `right`
and friends are all statements. In this tutorial you will see `text_`, `out_`,
`in_`, `line_`, `final_`, `left_` — the trailing underscore is a house habit for
exactly this reason. Get it wrong and the error can be baffling:

```
error 59: Illegal specification, at parameter 1 (name) of Greeter()
```

---

## 3. Buffer size and backpressure

The number you pass to the constructor is the **buffer capacity**, and choosing
it is a real design decision, not a tuning knob.

```basic
dim ch as Channel( of int32 ) = Channel( of int32 )( 16 )   '' buffered: holds 16
dim rv as Channel( of int32 ) = Channel( of int32 )( 0 )    '' rendezvous
dim nl as Channel( of int32 )                              '' NIL -- see below
```

### Capacity 0 is a rendezvous, not a zero-length buffer

`Send` on a capacity-0 channel does not return **until a receiver has taken the
value**. It is a handoff *and* a synchronisation point: after `Send` returns, you
know the other side got it. Use it when the handoff itself is the meaning.

### Capacity N is a buffer, and the buffer is a shock absorber

`Send` blocks only when the buffer is full. This is **backpressure**: a producer
that outruns its consumer is forced to slow down to the consumer's rate.

```basic
'' ex04 -- backpressure: a fast producer against a slow consumer
#import "std/tasks"
using tasks

sub FastProducer( byval out_ as Channel( of int32 ) )
	for i as int32 = 1 to 6
		out_.Send( i )
		print "  produced " & i & " (buffer now holds " & out_.Count( ) & ")"
	next
	out_.Close( )
end sub

dim q as Channel( of int32 ) = Channel( of int32 )( 2 )   '' room for two
spawn FastProducer( q )

dim as int32 v
while q.Receive( v )
	sleep 120, 1                        '' the slow consumer
	print "consumed " & v
wend
```

```
  produced 1 (buffer now holds 0)
  produced 2 (buffer now holds 1)
  produced 3 (buffer now holds 2)
consumed 1
  produced 4 (buffer now holds 2)
consumed 2
  produced 5 (buffer now holds 2)
consumed 3
  produced 6 (buffer now holds 2)
consumed 4
consumed 5
consumed 6
```

Read the shape of that: the producer sprints to fill the buffer, then locks step
with the consumer — one produced for each one consumed — because the buffer stays
full. The producer's speed is now the consumer's speed. That is the mechanism
that keeps a fast producer from eating all your memory.

**There is no unbounded capacity, on purpose.** An unbounded channel converts a
slow consumer into an out-of-memory kill, hours later, far from the cause.

### Choosing a capacity

| Capacity | Use when |
|---|---|
| `0` | The handoff is a synchronisation point; you want the sender to know it landed. |
| `1` | A single result, or a "latest value" slot. |
| small (4–64) | Smoothing out jitter between a producer and a consumer of roughly equal speed. |
| = number of jobs | You want to enqueue all work up front and never block the filler (chapter 6). |

### The nil channel

A default-constructed `Channel` — `dim nl as Channel( of int32 )` with no
constructor argument — is **nil**, and `Send` and `Receive` on it block
**forever**.

That looks like a defect until chapter 8, where assigning a nil channel turns out
to be how you *disable* a case in a `select`. `IsNil( )` exists so a program can
assert its own initialisation, because "my program hangs and prints nothing" is
the symptom of forgetting to construct one.

---

## 4. Closing and draining

A producer that has finished says so by calling `Close( )`.

`Close` means exactly one thing: **"no more values will be sent."** It does not
discard buffered items, it does not free anything, and it is not a destructor. It
wakes every blocked waiter.

```basic
'' ex05 -- close, and the two ways to drain
#import "std/tasks"
using tasks

sub ReadLines( byval out_ as Channel( of ustring ) )
	dim as ustring lines_(0 to 2) = { "alpha", "beta", "gamma" }
	for i as int32 = 0 to 2
		out_.Send( lines_(i) )
	next
	out_.Close( )                       '' "no more values will be sent"
end sub

sub Main( )
	dim src as Channel( of ustring ) = Channel( of ustring )( 4 )
	spawn ReadLines( src )

	for each s in src                   '' drains until closed AND empty
		print "for each: " & s
	next

	dim src2 as Channel( of ustring ) = Channel( of ustring )( 4 )
	spawn ReadLines( src2 )

	dim as ustring s2
	while src2.Receive( s2 )            '' FALSE = end of stream
		print "while  : " & s2
	wend
	print "done"
end sub

Main( )
```

```
for each: alpha
for each: beta
for each: gamma
while  : alpha
while  : beta
while  : gamma
done
```

### The termination signal

`Receive` returns `FALSE` **only** when the channel is closed *and* drained. That
is the end-of-stream signal, not a failure, and it is what makes both loops
above terminate. Note the ordering: a closed channel with items still buffered
keeps returning `TRUE` and handing them over. Nothing is lost by closing.

When `Receive` returns `FALSE`, **the output variable is not modified.** Remember
that — chapter 8 turns it into a technique.

`for each v in ch` is the same loop with less typing. Prefer it when you want
every value and nothing else.

### Close is a statement about ownership

Two operations **raise** a runtime error (error 1, illegal function call) rather
than returning `FALSE`:

* `Send` after `Close`
* `Close` twice

Both mean the same thing: **two parties disagree about who owns the producer
role.** That is a structural bug in your program, not a runtime condition you
should handle, and it deserves to be loud. Hence the two rules:

* **The producer closes. Never the consumer.**
* **Exactly one producer closes.** With several producers on one channel, none of
  them may close it — chapter 6 shows who does.

---

## 5. Waiting for everyone (`WaitGroup`)

### First, the trap

```basic
'' ex19 -- work still running at program exit is ABANDONED, silently
#import "std/tasks"
using tasks

sub SaveDraft( byval id as int32 )
	sleep 300, 1
	print "draft " & id & " saved"       '' you may never see this line
end sub

for i as int32 = 1 to 3
	spawn SaveDraft( i )
next
print "main is done"
```

```
main is done
```

Three drafts, none saved, no error, no warning, exit code 0. **Nothing joins
goroutines.** When the main program ends, everything still running is dropped
where it stands.

The `sleep 1000` in chapter 1 was papering over this: guess too low and you lose
work, guess too high and you waste time, and either way the guess is wrong on a
different machine. Never ship it.

### `WaitGroup` — a counter you can wait on

A `WaitGroup` is a counter with a queue attached. `Add` raises it, `Done` lowers
it, and `Wait` blocks until it reaches zero.

```basic
'' ex06 -- wait for a fan-out to finish, with a WaitGroup
#import "std/tasks"
using tasks

sub UploadFile( byval id as int32, byval wg as WaitGroup ptr )
	sleep 100 + id * 40, 1
	print "uploaded file " & id
	wg->Done( )                         '' always, on every exit path
end sub

sub Main( )
	dim wg as WaitGroup
	for i as int32 = 1 to 5
		wg.Add( )                       '' BEFORE the spawn, never inside it
		spawn UploadFile( i, @wg )
	next
	wg.Wait( )
	print "all 5 uploads finished"
end sub

Main( )
```

```
uploaded file 1
uploaded file 2
uploaded file 3
uploaded file 4
uploaded file 5
all 5 uploads finished
```

Three rules, all of which bite:

1. **`Add` before the `spawn`, always.** Calling `Add` from inside the goroutine
   races `Wait`: if the main thread reaches `Wait` before the goroutine gets
   scheduled, the counter is still zero and `Wait` returns immediately.

2. **`Done` on every exit path.** A goroutine that returns early without calling
   `Done` leaves `Wait` blocked forever. If the body is complicated, use `defer`.

3. **A `WaitGroup` is non-copyable, so pass a pointer.** A copy would be a second
   counter, and one of them would never reach zero. `spawn` copies its
   arguments, and `byref` is a compile error at a spawn site, so `@wg` — a
   pointer — is the way in. That is why `Worker` takes a `WaitGroup ptr` and
   calls `wg->Done( )`.

### The memory guarantee

Everything every counted goroutine did before its `Done` is **visible** after
`Wait` returns, with no other synchronisation. This matters more than it sounds:
without such a guarantee, a value written by a worker might still be sitting in
another core's cache when you read it.

Also available: `WaitFor( ms )` returns `FALSE` on timeout instead of waiting
forever, and `Count( )` reports the current value.

`Add` below zero, `Done` below zero, and `Add` from zero while a `Wait` is in
progress all raise. The destructor does **not** wait; destroying a `WaitGroup`
with waiters still parked on it raises rather than leaving them parked forever.

---

## 6. A worker pool

This is the shape you will write most often: **N workers, one shared queue of
jobs, one shared stream of results.** Hashing every file in a folder, resizing a
folder of images, checking a list of URLs — all the same program.

Two ideas make it work:

* **Fan-out.** Several goroutines `Receive` from the *same* channel. A channel is
  a FIFO queue and **each item goes to exactly one receiver**, so the workers
  share the work automatically, and a worker that finishes early simply takes the
  next job. You get load balancing for free, with no scheduling code.
* **Fan-in.** Several goroutines `Send` to the *same* results channel. Safe by
  construction; the only question is who closes it.

```basic
'' ex07 -- a worker pool: fan-out to N workers, fan-in to one result stream
#import "std/tasks"
using tasks

sub Worker( byval id      as int32, _
            byval jobs    as RecvChan( of int32 ), _
            byval results as SendChan( of ustring ), _
            byval wg      as WaitGroup ptr )
	for each n in jobs                  '' every worker pulls from the SAME queue
		sleep 60, 1                     '' pretend: hash a file
		results.Send( "worker " & id & " finished job " & n )
	next
	wg->Done( )
end sub

'' Somebody has to close 'results', and it cannot be a worker: the first one
'' to finish would close it under the others.  This goroutine waits for all
'' of them and then closes -- the only correct owner of that Close.
sub CloseWhenDone( byval results as Channel( of ustring ), byval wg as WaitGroup ptr )
	wg->Wait( )
	results.Close( )
end sub

sub Main( )
	const NJOBS   = 12
	const NWORKER = 4

	dim jobs    as Channel( of int32 )    = Channel( of int32 )( NJOBS )
	dim results as Channel( of ustring ) = Channel( of ustring )( NJOBS )
	dim wg      as WaitGroup

	for i as int32 = 1 to NJOBS
		jobs.Send( i )
	next
	jobs.Close( )                       '' workers' 'for each' ends when it drains

	for i as int32 = 1 to NWORKER
		wg.Add( )
		spawn Worker( i, jobs, results, @wg )
	next
	spawn CloseWhenDone( results, @wg )

	dim as int32 got = 0
	for each r in results
		got += 1
		print r
	next
	print "collected " & got & " results"
end sub

Main( )
```

```
worker 1 finished job 1
worker 3 finished job 3
worker 2 finished job 2
worker 4 finished job 4
worker 2 finished job 7
worker 4 finished job 8
worker 1 finished job 5
worker 3 finished job 6
worker 1 finished job 11
worker 3 finished job 12
worker 2 finished job 9
worker 4 finished job 10
collected 12 results
```

### The closer goroutine

The one genuinely non-obvious piece is `CloseWhenDone`. Trace why the naive
alternatives fail:

* **A worker closes `results` when it finishes.** The first worker to finish
  closes the channel out from under the other three, and their next `Send`
  raises.
* **`Main` closes `results` after `wg.Wait( )`.** `Main` is blocked in the
  `for each` draining `results`, and never reaches the `Wait`. Deadlock: the
  workers block on a full `results` channel, and `Main` blocks waiting for a
  close that can only happen after it stops draining.

So the close has to happen *concurrently with* the drain, by something whose only
job is to wait and close. That is `CloseWhenDone` — three lines, and the whole
program hangs without it.

**Rule of thumb: the channel a fan-in writes to is closed by a dedicated
goroutine that does `wg.Wait( )` then `Close( )`.**

### How many workers?

* **CPU-bound work** (hashing, parsing, compressing): roughly the number of
  cores. More just adds context switching. `WorkerCount( )` reports the pool's
  current size.
* **I/O-bound work** (network, disk): more than the core count, because most
  workers are blocked in a syscall and not using a core at all. But every one
  blocked in a syscall holds an OS thread, and the pool caps at 256.
* Enqueueing 10,000 jobs into a channel is fine and normal. Spawning 10,000
  goroutines is fine too. Spawning 10,000,000 is not.

---

## 7. One-way channels

Look at `Worker`'s signature in the previous chapter:

```basic
sub Worker( byval id      as int32, _
            byval jobs    as RecvChan( of int32 ), _
            byval results as SendChan( of ustring ), _
            byval wg      as WaitGroup ptr )
```

`RecvChan` and `SendChan` are one-way views of a `Channel`:

* `SendChan( of T )` — has `Send`, `TrySend`, `SendFor`, `Close`. **No receive.**
* `RecvChan( of T )` — has `Receive`, `TryReceive`, `ReceiveFor`, `for each`.
  **No send, and deliberately no `Close`.**

The reason `RecvChan` has no `Close` is chapter 4's rule made mechanical: closing
is the producer's statement, and *a consumer that closes its input is the single
most common channel bug there is.*

```basic
'' ex08 -- directional channels write the contract into the signature
sub Produce( byval out_ as SendChan( of int32 ) )     '' can send + close, cannot receive
	for i as int32 = 1 to 3
		out_.Send( i * 10 )
	next
	out_.Close( )
end sub

sub Consume( byval in_ as RecvChan( of int32 ), byval done_ as SendChan( of boolean ) )
	dim as int32 v                                    '' cannot send, cannot close
	while in_.Receive( v )
		print "consumed " & v
	wend
	done_.Send( TRUE )
end sub
```

A `Channel` converts to either view implicitly, so callers just pass the channel.
**The conversion is one-way** — there is no cast back to `Channel`, because a
directional handle is a narrowing and narrowing should not be reversible by
accident.

Two honest caveats:

* **These are ergonomics, not safety.** Nothing stops a caller from keeping the
  full `Channel` and using both ends. What they buy you is that the *intent* is
  written down at the boundary, where it can be checked by a reader and by the
  compiler.
* **`select channel` does not accept them.** Its cases require a real
  `Channel( of T )`; a `RecvChan` produces
  `TKO0809`. If a procedure
  needs to `select` over a channel, take the `Channel` (see chapter 10's
  `SearchFolder`).

---

## 8. Waiting on several things (`select channel`)

`Receive` waits on **one** channel. Real programs wait on several: a job queue
*and* a cancel signal, a cache *and* a network, an inbox *and* a timer.

`select channel` waits on all of them at once and runs the case that becomes
ready first. It needs no extra import -- the statement comes from the same
module as the channels:

```basic
#import "std/tasks"
```

```basic
'' ex09 -- select channel: whichever source answers first
#import "std/tasks"
using tasks

sub Feed( byval ch as Channel( of ustring ), byval label_ as ustring, _
          byval ms as uint32, byval n as int32 )
	for i as int32 = 1 to n
		sleep ms, 1
		ch.Send( label_ & " #" & i )
	next
end sub

sub Main( )
	dim cache_ as Channel( of ustring ) = Channel( of ustring )( 4 )
	dim net    as Channel( of ustring ) = Channel( of ustring )( 4 )

	spawn Feed( cache_, "cache", 120, 3 )
	spawn Feed( net,    "net",   300, 2 )

	dim as ustring a, b
	dim as int32 left_ = 5
	do
		select channel
			case receive a from cache_ : print "from cache: " & a
			case receive b from net    : print "from net  : " & b
			case timeout 1000          : print "nothing in 1 s -- giving up" : exit do
		end select
		left_ -= 1
	loop until left_ = 0
	print "done"
end sub

Main( )
```

```
from cache: cache #1
from cache: cache #2
from net  : net #1
from cache: cache #3
from net  : net #2
done
```

### The five case forms

```basic
select channel
	case receive job from jobs    : Process( job )     '' receive into a variable
	case receive from ctx.Done( ) : exit do            '' receive and discard
	case send result to results   : sent += 1          '' send, when there is room
	case timeout 500              : Heartbeat( )       '' nothing ready in 500 ms
	case else                     : DoOtherWork( )     '' nothing ready RIGHT NOW
end select
```

* **`case receive v from ch`** needs `v` already declared — the statement does not
  introduce it.
* **`case receive from ch`** receives and throws the value away. This is how a
  `Done( )` signal channel is used, where the arrival is the whole message.
* **`case send v to ch`** waits for room in `ch`. `select` is not receive-only.
* **`case timeout <ms>`** fires when nothing else became ready in time. At most
  one per statement.
* **`case else` makes the whole statement non-blocking** — it fires the instant
  nothing is ready. This is Go's `default`.

**`case else` and `case timeout` cannot appear together**, and that is a compile
error rather than a puzzle: `else` would fire immediately, every time, so the
timeout could never be reached.

### Two properties worth knowing

**Cases are polled in a pseudo-random order.** With a fixed order, a channel that
is always ready would starve every case after it — and the failure would only
appear under load, which is the worst time to discover it.

**A nil channel case is permanently not-ready.** That is how you disable a case
without rewriting the statement — and it is what the nil channel from chapter 3
is *for*.

### The trap: a closed channel is always ready

A closed channel is permanently ready for receive, and it fires with the
closed-channel answer. **A `select` case cannot, by itself, tell "received a
value" from "the channel closed."** A `select` in a loop over a channel that has
closed will spin at full speed forever.

The fix uses the rule from chapter 4: **`Receive` does not modify its output when
it returns `FALSE`.** So write a sentinel into the variable before the wait; if
it is still there afterwards, the case fired on the close. Then nil the channel
out, which permanently disables that case.

```basic
'' ex09b -- a closed channel is ALWAYS ready.  Detect it, then nil the case out.
sub Main( )
	dim cache_ as Channel( of ustring ) = Channel( of ustring )( 4 )
	dim net    as Channel( of ustring ) = Channel( of ustring )( 4 )

	spawn Feed( cache_, "cache", 100, 3 )   '' Feed now Closes when finished
	spawn Feed( net,    "net",   250, 2 )

	dim as ustring a, b
	dim as int32 live = 2

	do
		'' Receive leaves the variable UNTOUCHED when the channel is closed and
		'' drained, so a sentinel written before the wait says which happened.
		a = "" : b = ""
		select channel
			case receive a from cache_
				if( len( a ) = 0 ) then
					cache_ = Channel( of ustring )( )   '' nil -> case disabled
					live -= 1
					print "cache stream ended"
				else
					print "from cache: " & a
				end if
			case receive b from net
				if( len( b ) = 0 ) then
					net = Channel( of ustring )( )
					live -= 1
					print "net stream ended"
				else
					print "from net  : " & b
				end if
			case timeout 2000
				print "stalled" : exit do
		end select
	loop until live = 0
	print "both streams closed"
end sub
```

```
from cache: cache #1
from cache: cache #2
from net  : net #1
from cache: cache #3
cache stream ended
from net  : net #2
net stream ended
both streams closed
```

### Getting out of a select

`exit do` and `goto` out of a case body are supported; the wait records are still
released properly.

**`exit for` out of a case body is not.** In a scope holding objects or var-length
strings — which any program using channels does — it fails to compile:

```
error 105: Branch crossing local array, var-len string or object definition
```

Write `select channel` loops as `do ... loop`, not `for ... next`. Both examples
above do.

Two more small guarantees: each channel expression is evaluated **exactly once**
even though the lowering needs it three times, and `channel` is contextual —
ordinary `select case`, including `select case` on a variable named `channel`, is
untouched. Only the pair `select channel` claims the statement.

---

## 9. Deadlines on a single operation

When you need a timeout on exactly one channel operation, `select` is more
machinery than the job needs. Every blocking operation has a timed form.

| Blocking | Never blocks | With a deadline |
|---|---|---|
| `Send( v )` | `TrySend( v )` | `SendFor( v, ms )` |
| `Receive( out )` | `TryReceive( out )` | `ReceiveFor( out, ms )` |

The `Try*` and `*For` forms return `FALSE` rather than raising when they give up.

```basic
'' ex18 -- a deadline on ONE operation, without a select
#import "std/tasks"
using tasks

sub SlowService( byval reply as Channel( of ustring ), byval ms as uint32 )
	sleep ms, 1
	reply.Send( "server said hello" )
end sub

sub Ask( byval delay_ as uint32, byval budget as uint32 )
	dim reply as Channel( of ustring ) = Channel( of ustring )( 1 )
	spawn SlowService( reply, delay_ )

	dim as ustring answer
	if( reply.ReceiveFor( answer, budget ) ) then
		print "within " & budget & " ms: " & answer
	else
		print "timed out after " & budget & " ms"
	end if
end sub

Ask( 100, 400 )
Ask( 600, 300 )
sleep 500, 1        '' let the abandoned goroutine finish before we exit
```

```
within 400 ms: server said hello
timed out after 300 ms
```

Note the honest bit at the end. Giving up on the *answer* does not stop the
*work*: `SlowService` is still running after `Ask` returns. That is what chapter
10 is for.

Why every blocking operation here offers a timeout at all: **a goroutine blocked
in a syscall cannot be cancelled.** Timeouts are the mechanism you actually have,
so they are everywhere.

---

## 10. Cancellation (`Context`)

The user clicks Stop. The deadline passes. One worker in a pool of eight hits a
fatal error and the other seven are now wasting their time.

A `Context` is the standard way to say "you can stop now" to any number of
goroutines at once.

```basic
dim ctx as CancelContext = WithCancel( Context( ) )
spawn Worker( ctx )
...
ctx.Cancel( )                        '' ask it to stop
```

| | |
|---|---|
| `Context( )` | the background context; never cancelled |
| `WithCancel( parent )` | a cancellable child |
| `WithTimeout( parent, ms )` | cancels itself when the deadline passes |
| `ctx.IsCancelled( )` | a cheap boolean poll |
| `ctx.Done( )` | a channel that is **closed** on cancel |
| `ctx.Err( )` | `""`, `"cancelled"`, or `"deadline exceeded"` |
| `CancelContext.Cancel( )` | ask everything derived from this context to stop |

### The trick is `Done( )`

`Done( )` returns a channel that is **closed** when the context is cancelled.
That is the entire design, and it is why cancellation is modelled as a channel:
*a closed channel is permanently ready*, so cancellation composes with every
other channel operation for free — including `select`.

```basic
do
	select channel
		case receive job from jobs    : Process( job )
		case receive from ctx.Done( ) : exit do
	end select
loop
```

That loop takes work while there is work, and leaves the moment cancellation
arrives, with no polling and no flag.

```basic
'' ex10 -- cancellation: the user hits Stop, or the deadline passes
#import "std/tasks"
using tasks

sub SearchFolder( byval ctx  as Context, _
                  byval jobs as Channel( of int32 ), _
                  byval hits as SendChan( of ustring ), _
                  byval wg   as WaitGroup ptr )
	dim as int32 n
	do
		select channel
			case receive from ctx.Done( )        '' cancelled -- pack up
				exit do
			case receive n from jobs
				if( n = 0 ) then exit do         '' sentinel: stream ended
				sleep 80, 1                      '' pretend: scan a file
				if( n mod 3 = 0 ) then hits.Send( "match in file " & n )
		end select
	loop
	wg->Done( )
end sub

sub Main( )
	dim ctx  as CancelContext         = WithTimeout( Context( ), 500 )
	dim jobs as Channel( of int32 )    = Channel( of int32 )( 64 )
	dim hits as Channel( of ustring ) = Channel( of ustring )( 64 )
	dim wg   as WaitGroup

	for i as int32 = 1 to 40
		jobs.Send( i )
	next

	for i as int32 = 1 to 3
		wg.Add( )
		spawn SearchFolder( ctx, jobs, hits, @wg )
	next

	wg.Wait( )
	hits.Close( )

	dim as int32 found = 0
	for each h in hits
		found += 1
	next
	print "stopped after " & found & " hits; reason: " & ctx.Err( )
end sub

Main( )
```

```
stopped after 7 hits; reason: deadline exceeded
```

Forty files of work, a 500 ms budget, three workers, a clean stop, and an
accurate reason. `WithCancel` instead of `WithTimeout` gives you the Stop-button
version — same code, and `ctx.Err( )` then reads `"cancelled"`.

### The four rules

1. **Cancellation is a request. Nothing is ever killed.** A goroutine that never
   checks its context runs to completion, and `Cancel` changes nothing
   observable in it. This is deliberate: `TerminateThread` skips destructors and
   `defer` blocks and leaks every mutex the thread held. In a language that has
   `defer`, forced termination means the cleanup written specifically to be
   unmissable is missed. The *name* suggests otherwise, which is why this
   paragraph exists.

2. **`Cancel` is idempotent**, unlike `Channel.Close`. A context is routinely
   cancelled by both a timeout and an explicit `Cancel`, so "two parties" is
   normal here rather than a bug.

3. **Cancellation propagates down, and only down.** Cancelling a parent cancels
   every context derived from it, transitively; cancelling a child never touches
   its parent. A context derived from an already-cancelled parent starts
   cancelled.

4. **Use `defer ctx.Cancel( )`** after creating a context, to release the
   registration even on an early return. It is safe precisely because `Cancel` is
   idempotent.

---

## 11. Errors in a goroutine

**A runtime error inside a goroutine does not propagate anywhere.** The
worker's error state is reset between work items so it cannot leak into the next
goroutine — and nobody observes it. There is no `on error` in the caller that can
see it, because there is no caller.

So an error is a value you send, like any other result. `Result( of T, E )` is
made for it: it holds either a value or a reason, and `IsOk( )` says which.

```basic
'' ex11 -- errors do not propagate out of a goroutine.  Send them.
#import "std/tasks"
#import "std/outcome"
using tasks, outcome

type ParseResult as Result( of int32, ustring )

sub ParseNumber( byval text_ as ustring, byval out_ as Channel( of ParseResult ) )
	dim as int32 v = 0
	if( len( text_ ) = 0 ) then
		out_.Send( Fail( of int32, ustring )( "empty input" ) )
		exit sub
	end if
	for i as int32 = 0 to len( text_ ) - 1
		dim as int32 d = text_[i] - asc( "0" )
		if( d < 0 orelse d > 9 ) then
			out_.Send( Fail( of int32, ustring )( "'" & text_ & "' is not a number" ) )
			exit sub
		end if
		v = v * 10 + d
	next
	out_.Send( Ok( of int32, ustring )( v ) )
end sub

sub Main( )
	dim res as Channel( of ParseResult ) = Channel( of ParseResult )( 4 )
	dim as ustring inputs(0 to 2) = { "1234", "12x4", "" }

	for each text in inputs
		spawn ParseNumber( text, res )
	next

	dim as ParseResult r
	for i as int32 = 0 to 2
		res.Receive( r )
		if( r.IsOk( ) ) then
			print "ok  : " & r.Value( )
		else
			print "fail: " & r.Failure( )
		end if
	next
end sub

Main( )
```

```
ok  : 1234
fail: '12x4' is not a number
fail: empty input
```

Notes on `Result`:

* Both type arguments must be written out at construction — `Ok( of int32, ustring )( v )`
  — because inference reads parameter positions only and each factory mentions
  just one of `T` and `E`. The `type ParseResult as Result( of int32, ustring )`
  alias is the usual way to say it once.
* `Value( )` on a failure and `Failure( )` on a success both raise. `IsOk( )` is
  the guard, and it costs nothing.
* Note that the results arrive in a different order from the inputs — three
  independent goroutines, no promised order. If you need to know which input a
  result belongs to, **put the key in the message**: send a type with both the id
  and the `Result`, not a bare `Result`.

---

## 12. Pipelines

A pipeline is a chain of stages, each a goroutine, connected by channels: stage 1
reads, stage 2 transforms, stage 3 writes. All three run **at the same time**, on
different items — like an assembly line, where the first item is being painted
while the third is still being cut.

The rule that makes it compose: **each stage owns its output channel and closes
it when its input runs dry.** That way the close cascades down the chain on its
own.

```basic
'' ex12 -- a pipeline: read -> clean -> count, three stages running at once
#import "std/tasks"
using tasks

sub Stage1_Read( byval out_ as SendChan( of ustring ) )
	dim as ustring src(0 to 4) = { "  Hello ", "WORLD", "", " Fbc  ", "Modern" }
	for each s in src
		sleep 40, 1
		out_.Send( s )
	next
	out_.Close( )                       '' each stage closes ONLY its own output
end sub

sub Stage2_Clean( byval in_ as Channel( of ustring ), byval out_ as SendChan( of ustring ) )
	dim as ustring s
	while in_.Receive( s )
		s = lcase( trim( s ) )
		if( len( s ) > 0 ) then out_.Send( s )    '' a stage may drop items
	wend
	out_.Close( )
end sub

sub Stage3_Number( byval in_ as Channel( of ustring ), byval out_ as SendChan( of ustring ) )
	dim as ustring s
	dim as int32 n = 0
	while in_.Receive( s )
		n += 1                          '' stage-local state: nobody else sees it
		out_.Send( n & ": " & s )
	wend
	out_.Close( )
end sub

sub Main( )
	dim raw    as Channel( of ustring ) = Channel( of ustring )( 2 )
	dim clean  as Channel( of ustring ) = Channel( of ustring )( 2 )
	dim final_ as Channel( of ustring ) = Channel( of ustring )( 2 )

	spawn Stage1_Read( raw )
	spawn Stage2_Clean( raw, clean )
	spawn Stage3_Number( clean, final_ )

	for each line_ in final_
		print line_
	next
end sub

Main( )
```

```
1: hello
2: world
3: fbc
4: modern
```

Things a pipeline gives you that a loop does not:

* **Overlap.** Stage 1 is fetching item 4 while stage 3 is writing item 2.
* **Backpressure end to end.** Small buffers mean a slow final stage throttles the
  reader automatically, and memory use stays bounded no matter how big the input.
* **Stage-local state.** `Stage3_Number`'s counter `n` is a plain local. Only one
  goroutine touches it, so it needs no protection whatsoever. This is the deepest
  idea in the whole model — see chapter 14.
* **A widenable stage.** If one stage is the bottleneck, spawn several copies of
  *that stage* reading the same input channel (chapter 6's fan-out), and let a
  closer goroutine close its output. Ordering is lost when you do; if it matters,
  carry a sequence number in the item.

---

## 13. Limiting concurrency

"Concurrent" does not mean "all at once, unbounded." Fifty simultaneous HTTP
requests will get you rate-limited; fifty simultaneous disk readers will thrash.

### A semaphore: at most N in flight

A channel with capacity N, pre-filled with N permits, is a counting semaphore.
Take a permit before the work, give it back after.

```basic
'' ex17 -- a channel as a semaphore: at most N things in flight at once
#import "std/tasks"
using tasks

sub Download( byval id as int32, byval slots as Channel( of boolean ), byval wg as WaitGroup ptr )
	dim as boolean tok
	slots.Receive( tok )                '' take a permit (blocks if none free)
	print "  -> start " & id
	sleep 200, 1
	print "  <- done  " & id
	slots.Send( TRUE )                  '' give it back
	wg->Done( )
end sub

sub Main( )
	const LIMIT = 3
	dim slots as Channel( of boolean ) = Channel( of boolean )( LIMIT )
	dim wg    as WaitGroup

	for i as int32 = 1 to LIMIT
		slots.Send( TRUE )              '' LIMIT permits in the pool
	next

	for i as int32 = 1 to 9
		wg.Add( )
		spawn Download( i, slots, @wg )
	next
	wg.Wait( )
	print "all downloads finished, never more than " & LIMIT & " at once"
end sub

Main( )
```

```
  -> start 1
  -> start 2
  -> start 3
  <- done  2
  <- done  3
  <- done  1
  -> start 4
  -> start 5
  -> start 6
  <- done  4
  <- done  5
  <- done  6
  -> start 8
  -> start 7
  -> start 9
  <- done  9
  <- done  7
  <- done  8
all downloads finished, never more than 3 at once
```

Never more than three `->` lines before a `<-`. All nine goroutines were spawned
immediately; six of them were parked on `slots.Receive` costing nothing.

> A worker pool (chapter 6) limits concurrency too, and is usually the better
> tool. Reach for a semaphore when the goroutines are already structured some
> other way — a per-request goroutine, say — and you only want to cap one
> particular resource.

### A rate limit: at most one per interval

A semaphore caps how many run *at once*. A rate limit caps how many start *per
unit of time*. A ticker goroutine gives you one.

```basic
'' ex13 -- polling without blocking, and pacing a loop
#import "std/tasks"
using tasks

'' A ticker: one value every 'ms', for 'n' ticks, then closed.
sub Ticker( byval ch as Channel( of boolean ), byval ms as uint32, byval n as int32 )
	for i as int32 = 1 to n
		sleep ms, 1
		ch.Send( TRUE )
	next
	ch.Close( )
end sub

sub Main( )
	dim work as Channel( of int32 )    = Channel( of int32 )( 16 )
	dim tick as Channel( of boolean ) = Channel( of boolean )( 1 )

	for i as int32 = 1 to 5
		work.Send( i * 100 )
	next
	spawn Ticker( tick, 150, 5 )

	'' Rate limit: do at most one request per tick.
	dim as boolean t
	dim as int32 v
	dim as int32 served = 0
	while served < 5
		tick.Receive( t )               '' the pacing gate
		if( work.TryReceive( v ) ) then '' TryReceive: never blocks
			served += 1
			print "request " & served & " sent (payload " & v & ")"
		else
			print "nothing queued this tick"
		end if
	wend

	'' CASE ELSE makes a select non-blocking: it fires when nothing is ready.
	select channel
		case receive v from work : print "unexpected leftover " & v
		case else                : print "queue is empty, as expected"
	end select
end sub

Main( )
```

```
request 1 sent (payload 100)
request 2 sent (payload 200)
request 3 sent (payload 300)
request 4 sent (payload 400)
request 5 sent (payload 500)
queue is empty, as expected
```

The last statement shows the other non-blocking tool: **`case else` turns a
`select` into a poll.** It fires the moment nothing is ready, instead of waiting.

Give the ticker channel capacity 1 and the whole thing tolerates a slow consumer
gracefully: ticks that nobody collects are simply not produced, because the
ticker blocks on a full channel rather than building a backlog of catch-up ticks.

---

## 14. Shared state, and why you should avoid it

This chapter is the one to read twice.

**There is no data-race protection of any kind here.** None. A channel will
happily carry a type holding a pointer into another goroutine's stack. This
design makes concurrency *ergonomic*, not *safe*.

Here is what that means in practice. Eight goroutines, each adding 1 to a shared
global 200,000 times. The answer must be 1,600,000.

```basic
'' ex15 -- there is NO data-race protection.  This is a broken program.
#import "std/tasks"
using tasks

dim shared as int32 g_counter

sub BumpUnsafe( byval times_ as int32, byval wg as WaitGroup ptr )
	for i as int32 = 1 to times_
		g_counter += 1                  '' read, add, write -- three steps
	next
	wg->Done( )
end sub

sub Main( )
	dim wg as WaitGroup
	for i as int32 = 1 to 8
		wg.Add( )
		spawn BumpUnsafe( 200000, @wg )
	next
	wg.Wait( )
	print "expected 1600000, got " & g_counter
end sub

Main( )
```

```
expected 1600000, got 193575
```

**Seven-eighths of the increments vanished.** No crash, no error, no warning —
just a wrong number. Run it again and you get a different wrong number; the next
run of that exact program printed `304394`.

`g_counter += 1` is not one operation. It is *read the value*, *add one*, *write
it back*. Two goroutines that read `41` at the same time both write `42`, and one
increment is gone. Nothing in the language, the compiler, or this library will tell
you: a data race is silent, machine-dependent, and load-dependent, which is why
it reliably passes your tests and fails on a customer's machine.

### The fix that scales: don't share

You could reach for a mutex. The better fix is to arrange for **exactly one
goroutine to own the variable**, and have the others send it messages.

> **Do not communicate by sharing memory; share memory by communicating.**

```basic
'' ex16 -- the same count, owned by ONE goroutine.  Correct by construction.
#import "std/tasks"
using tasks

sub Bump( byval times_ as int32, byval ticks as SendChan( of int32 ), byval wg as WaitGroup ptr )
	for i as int32 = 1 to times_
		ticks.Send( 1 )
	next
	wg->Done( )
end sub

sub CloseWhenDone( byval ticks as Channel( of int32 ), byval wg as WaitGroup ptr )
	wg->Wait( )
	ticks.Close( )
end sub

sub Main( )
	dim ticks as Channel( of int32 ) = Channel( of int32 )( 1024 )
	dim wg    as WaitGroup

	for i as int32 = 1 to 8
		wg.Add( )
		spawn Bump( 50000, ticks, @wg )
	next
	spawn CloseWhenDone( ticks, @wg )

	dim as int32 total = 0                '' only THIS goroutine touches it
	for each t in ticks
		total += t
	next
	print "expected 400000, got " & total
end sub

Main( )
```

```
expected 400000, got 400000
```

Correct, and correct *by construction*: `total` is a plain local, in one
goroutine, and no amount of concurrency elsewhere can reach it. There is nothing
to get wrong, so there is nothing to review, and no test can pass by luck.

(Sending one message per increment is of course slower than an atomic add. The
point is the *ownership pattern*. In a real program each message carries a
meaningful unit of work, not one integer.)

### The three ownership rules

1. **A value is owned by exactly one goroutine at a time.** Sending it through a
   channel transfers ownership; the sender must not touch it afterwards.
2. **Prefer stage-local state.** `Stage3_Number`'s counter in chapter 12 needs no
   protection because only one goroutine can see it.
3. **If you must share, share immutable data.** A value nobody writes cannot
   race.

### If you genuinely need a mutex

`MutexCreate` / `MutexLock` / `MutexUnlock` exist and are orthogonal to all
of this. They are the right tool when the shared thing is a real resource with an
identity — a log file, a cache, a hardware handle — rather than a value that
could just as well be passed along. But reach for them second, not first.

### `Count( )` is a metric, never a control

```basic
if( ch.Count( ) > 0 ) then ch.Receive( v )   '' WRONG -- and it will pass your tests
```

`Count( )` is a snapshot and is stale the instant it returns; another goroutine
can drain the channel between the `if` and the `Receive`, and now you are blocked
forever. Use `TryReceive`, which does the check and the take as one indivisible
step. `Count( )` is for progress bars and logging. So is `IsClosed( )`.

---

## 15. Background work in a desktop app

This is the case that matters most in a Win32 program, and it has one rule.

**Window handles belong to the thread that created them.** A goroutine runs on an
arbitrary worker thread. So a `SetWindowText`, a `ListView_InsertItem`, a
`SelectObject` or a COM call from a goroutine is a bug — and the worst kind,
because it appears to work for months and then corrupts state on a customer's
machine under load.

The rule:

> **Compute in the goroutine. Hand the result back through a channel. Let the UI
> thread pick it up.**

And the corollary that makes it work: the UI thread drains with **`TryReceive`**,
never `Receive`. A blocking `Receive` on the UI thread freezes the window — which
is the exact bug the goroutine was introduced to fix.

```basic
'' ex14 -- the desktop-app shape: a background scan, drained by the UI thread
#import "std/tasks"
using tasks

type ScanResult
	as ustring path_
	as int64 bytes_
end type

'' Runs on an ARBITRARY worker thread.  It must not touch a window, a GDI
'' object, or anything else owned by the UI thread.
sub ScanFolder( byval out_ as Channel( of ScanResult ), byval n as int32 )
	for i as int32 = 1 to n
		sleep 90, 1                     '' pretend: stat a file
		dim as ScanResult r
		r.path_  = "C:\data\file" & i & ".dat"
		r.bytes_ = i * 4096
		out_.Send( r )
	next
	out_.Close( )
end sub

'' Stands in for WM_TIMER: called on the UI thread, must return immediately.
function OnTimerTick( byref results as Channel( of ScanResult ), byref rows as int32 ) as boolean
	dim as ScanResult r
	while results.TryReceive( r )       '' TryReceive, never Receive
		rows += 1
		print "  row " & rows & ": " & r.path_ & "  (" & r.bytes_ & " bytes)"
	wend
	return ( results.IsClosed( ) andalso results.Count( ) = 0 )
end function

sub Main( )
	dim results as Channel( of ScanResult ) = Channel( of ScanResult )( 64 )
	spawn ScanFolder( results, 6 )

	dim as int32 rows = 0
	do
		print "[pump] window still responsive"
		sleep 200, 1                    '' stands in for the message loop idling
	loop until OnTimerTick( results, rows )

	print "scan complete: " & rows & " rows"
end sub

Main( )
```

```
[pump] window still responsive
  row 1: C:\data\file1.dat  (4096 bytes)
  row 2: C:\data\file2.dat  (8192 bytes)
[pump] window still responsive
  row 3: C:\data\file3.dat  (12288 bytes)
  row 4: C:\data\file4.dat  (16384 bytes)
[pump] window still responsive
  row 5: C:\data\file5.dat  (20480 bytes)
  row 6: C:\data\file6.dat  (24576 bytes)
scan complete: 6 rows
```

### Wiring it into a real window

Replace the `do ... loop` with your message loop and `OnTimerTick` with a real
handler. Two ways to trigger it:

* **`WM_TIMER`.** `SetTimer` at, say, 100 ms; drain in the handler; `KillTimer`
  when the channel is closed and empty. Simplest, and the drain rate is
  predictable — good for a progress list where a hundred rows a tick is fine.
* **`PostMessage` wakeup.** The goroutine calls
  `PostMessage( hwnd, WM_APP + 1, 0, 0 )` after sending, and the handler drains.
  Lower latency, no polling. `PostMessage` is one of the few Win32 calls that is
  explicitly safe to make from another thread — it queues a message rather than
  touching the window. **`SendMessage` is not**: it blocks until the target
  thread processes it, so it can deadlock.

Either way the handler drains with `TryReceive` in a `while` loop and returns to
the pump immediately.

Three more notes:

* **Cancel with a `Context`** (chapter 10) so the Stop button and window
  destruction can both end the scan. Do not close the window while a goroutine
  still holds its `HWND`.
* **The channel type carries plain data.** `ScanResult` holds a `ustring` and a
  `int64` — no `HWND`, no GDI handle, no interface pointer. Keep it that way.
* **Buffer generously** (64, 256) so the scan is not throttled by your timer
  interval. If you *want* it throttled, a small buffer does that for free.

---

## 16. Pitfalls — a checklist

Print this. Almost every bug in a first concurrent program is on it.

**Build**

* [ ] **`-mt` on every build.** `std/tasks` refuses to compile without it, rather
      than linking a single-threaded runtime and misbehaving quietly.

**Lifetime**

* [ ] **A goroutine still running at program exit is abandoned, silently.** Use a
      `WaitGroup` or a channel if it must finish.
* [ ] **`wg.Add` before the `spawn`,** never inside the goroutine.
* [ ] **`wg.Done` on every exit path** — a missed one leaves `Wait` blocked
      forever. Use `defer`.
* [ ] **A `WaitGroup` is non-copyable.** Pass `@wg`, use `wg->Done( )`.

**Channels**

* [ ] **The producer closes; the consumer never does.** `RecvChan` has no `Close`
      for this reason.
* [ ] **Several producers: none of them closes.** A dedicated closer goroutine
      does `wg.Wait( )` then `Close( )`.
* [ ] **`Send` after `Close` raises. `Close` twice raises.** These are structural
      bugs, not conditions to handle.
* [ ] **`Receive` returning `FALSE` is end-of-stream, not an error** — and the
      output variable is left untouched.
* [ ] **A nil channel blocks forever.** `IsNil( )` tells you. Constructing without
      a capacity argument gives you one.
* [ ] **`Count( )` and `IsClosed( )` are snapshots.** Metrics only, never control
      flow. Use `TryReceive`.
* [ ] **Capacity 0 is a rendezvous**, not a zero-length buffer.
* [ ] **For a large `T`, send a pointer.** Every send copies, and a buffered send
      copies twice; there is no move constructor in the language. `T` must be
      default-constructible, copy-constructible and destructible.

**`spawn`**

* [ ] **A `byref` parameter is a compile error** at a spawn site. Pass a pointer
      if sharing is what you mean.
* [ ] **Every argument must be written out** — no omitted default arguments.
* [ ] **No methods, no lambdas, no procedure pointers, no procedures inside a
      namespace.** Procedure pointers and lambdas are TKO0943; a method or a
      namespace procedure stops the compiler with an internal error (TKO0994).
* [ ] **A spawned `function`'s return value is discarded.**
* [ ] **Thousands of goroutines, not millions.**
* [ ] **`spawn` does not work inside a generic *member* body** (a generic
      *procedure* is fine) — a pre-existing limitation of nested body replay.

**`select channel`**

* [ ] **`#import "std/tasks"` in the file that uses it.**
* [ ] **A closed channel is always ready.** Detect the close and nil the channel
      out, or your loop spins at full speed forever.
* [ ] **`case else` and `case timeout` cannot coexist** — a compile error.
* [ ] **`case receive v from ch` needs `v` already declared.**
* [ ] **Cases require a real `Channel( of T )`,** not a `SendChan`/`RecvChan`.
      Otherwise: `TKO0809`.
* [ ] **Use `do ... loop`, not `for ... next`.** `exit for` out of a case body
      hits `error 105: Branch crossing local ... object definition`. `exit do`
      and `goto` are fine.

**Correctness**

* [ ] **There is no data-race protection of any kind.** Own values; don't share
      them.
* [ ] **A runtime error inside a goroutine propagates nowhere.** Send a
      `Result( of T, E )` instead.
* [ ] **Cancellation is advisory.** A goroutine that ignores its context blocks
      its waiters forever. Nothing is ever killed.
* [ ] **Never touch a window, a GDI object or a COM apartment from a goroutine.**
      `PostMessage` is safe; `SendMessage` is not.
* [ ] **Beware reserved words** as parameter names: `name`, `line`, `close`,
      `time`, `date`, `error`, `left`, `right`.

**Diagnosing a hang**

There is no deadlock detector, and there cannot be a useful one: Go can say "all
goroutines are asleep" because it knows about every block, but this runtime
cannot see a goroutine parked in `ReadFile`. When a program hangs, walk this
list in order — it is nearly always one of the first three:

1. A channel nobody closed, with a `for each` or `while Receive` waiting on it.
2. A `wg.Done( )` that some path skips.
3. A nil channel — check `IsNil( )`.
4. A rendezvous channel (capacity 0) with no receiver ready.
5. Two goroutines each blocked sending to a full channel the other should drain.
6. A `Receive` on the UI thread. (The window is frozen, not the program.)

Add a `WaitFor( ms )` or a `ReceiveFor( v, ms )` in place of the blocking form
and print when it times out; that usually names the culprit in one run.

---

## Reference tables

### What every channel operation returns

| | Open, ready | Open, would block | Closed, has items | Closed, empty | Nil channel |
|---|---|---|---|---|---|
| `Send` | TRUE | blocks | **raises** | **raises** | blocks forever |
| `Receive` | TRUE | blocks | TRUE, drains | FALSE | blocks forever |
| `TrySend` | TRUE | FALSE | **raises** | **raises** | FALSE |
| `TryReceive` | TRUE | FALSE | TRUE | FALSE | FALSE |
| `SendFor` | TRUE | FALSE @ms | **raises** | **raises** | FALSE @ms |
| `ReceiveFor` | TRUE | FALSE @ms | TRUE | FALSE | FALSE @ms |
| `Close` | — | — | **raises** | **raises** | **raises** |

"raises" is runtime error 1, illegal function call — the same one
`Optional.Value( )` raises on an empty `Optional`.

### The module

Everything is one module, `#import "std/tasks"`; its files are:

| File | What it brings |
|---|---|
| `channel.tiko` | `Channel`, `SendChan`, `RecvChan` |
| `scheduler.tiko` | `tasks.Spawn`, `GoroutineCount`, `WorkerCount` |
| `select.tiko` | the `SELECT CHANNEL` runtime — the statement needs the import |
| `sync.tiko` | `WaitGroup`, `Context` |

In practice: `#import "std/tasks"` plus `-mt` covers everything.

### Which tool for which job

| You want to… | Use |
|---|---|
| run something concurrently | `spawn` |
| get one answer back | `Channel( of T )( 1 )` + `Receive` |
| stream many values | buffered channel + `Close` + `for each` |
| know when N things have finished | `WaitGroup` |
| spread work over cores | worker pool: N × `spawn` on one jobs channel |
| collect results from N workers | fan-in + a closer goroutine |
| wait on several channels | `select channel` |
| poll without blocking | `TryReceive` / `TrySend`, or `case else` |
| give up after a while | `ReceiveFor` / `SendFor`, or `case timeout` |
| stop work early | `Context` + `WithCancel` / `WithTimeout` |
| report a failure from a goroutine | send a `Result( of T, E )` |
| cap concurrent operations | channel-as-semaphore, or a worker pool |
| cap operations per second | ticker goroutine |
| keep a window responsive | goroutine + `TryReceive` in `WM_TIMER` |
| document a channel's direction | `SendChan` / `RecvChan` |

### What is deliberately not here

* **Cheap goroutines.** Thousands, not millions — see chapter 1.
* **Data-race detection**, or `Send`/`Sync` markers. They need a type system
  tiko does not have, and a marker the compiler cannot enforce is
  documentation in a costume.
* **Forced cancellation.** See chapter 10.
* **A value returned from a goroutine.** Go has none either; the channel is the
  return path.
* **Broadcast channels, priorities, peek.** A channel is a FIFO queue and each
  item goes to exactly one receiver.
* **A deadlock detector.** See chapter 16.
* **`sync.Once`, `RWMutex`, a scoped lock guard.** Worth having, orthogonal to
  this, and `MutexCreate`/`MutexLock` already exist.

---

## Glossary

**Abandoned** — a goroutine still running when the program exits. It is dropped
silently. Prevent with a `WaitGroup`.

**Backpressure** — a full channel blocking its producer, forcing it down to the
consumer's rate. The reason capacity is bounded.

**Blocking** — an operation that does not return until it can proceed. Cheap and
correct in a goroutine; fatal on a UI thread.

**Buffered channel** — capacity ≥ 1. `Send` blocks only when full.

**Concurrency** — a program *structured* as independent activities. Contrast
parallelism: activities *executing* at the same instant.

**Context** — a cancellation signal that composes, because `Done( )` is a channel
that closes on cancel. Advisory: nothing is ever killed.

**Data race** — two goroutines touching the same memory with at least one
writing, unordered. Silent, machine-dependent, and undetected here.

**Deadlock** — every party waiting for another, so nothing proceeds. There is no
detector; see the checklist in chapter 16.

**Drain** — receive from a channel until it is closed and empty.
`for each v in ch` is the idiom.

**Fan-in** — several goroutines sending to one channel. Needs a closer goroutine.

**Fan-out** — several goroutines receiving from one channel. Each item goes to
exactly one of them, so the work self-balances.

**Goroutine** — a work item on a thread pool. *Not* Go's stackful coroutine.

**Nil channel** — a default-constructed `Channel`. Blocks forever; used to
disable a `select` case.

**Parked** — blocked, with the worker thread released to run something else.

**Pipeline** — stages connected by channels, all running at once on different
items.

**Rendezvous channel** — capacity 0. `Send` returns only after a receiver takes
the value: a handoff *and* a synchronisation point.

**Semaphore** — here, a channel pre-filled with N permits, capping how many
operations run at once.

**Spawn** — start a goroutine. Arguments are evaluated at the spawn site and
copied.

**WaitGroup** — a counter with a queue: `Add`, `Done`, `Wait`. Non-copyable.

**Worker pool** — N goroutines fanning out from one jobs channel and fanning in
to one results channel. The most common shape you will write.

---

## Where to go next

* **[`goroutines.txt`](Category-Goroutines-and-Channels)** — the reference. Every rule, tersely.
  Read it now that the ideas have names.
* **`tests/mir/spawn.test`** in the tiko-lang tree — how `spawn` is lowered;
  `tests/mir/spawn-contextual.test` beside it keeps `spawn` usable as a name.

---

**Category:** [Goroutines and Channels](Category-Goroutines-and-Channels)
