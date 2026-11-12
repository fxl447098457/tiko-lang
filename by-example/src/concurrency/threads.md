# Threads

Under goroutines are operating-system threads, and you can start one directly.
`threadcreate( @Proc, arg )` starts a thread running `Proc( arg )`, and
`threadwait( handle )` waits for it to finish.

```tiko
{{#include ../../examples/concurrency/threads.tiko}}
```

**Output**

```text
{{#include ../../examples/concurrency/threads.out}}
```

The thread procedure takes exactly one parameter, `byval p as any ptr`, so
everything a thread needs travels in one record whose address is passed. Here
each thread gets a `Slice` of its own: it reads its range and writes its
result into that record, and no two threads touch the same memory. That is why
the program needs no lock.

`threadwait` is the **join**: once it returns, the thread has finished and
everything it wrote is visible, so the main program can read
each slice's `result` safely. Every thread you create should be waited for
before the data it uses goes away.

The `#cmdline "-mt"` line is optional here. Without `std/tasks`, the call to
`threadcreate` is enough: the compiler sees it and links the runtime that is
safe to call from several threads at once by itself. The line just makes the
program's needs explicit.

Use a thread rather than a goroutine for something that must own a thread for
its whole life, such as a loop that blocks for a long time. For ordinary
fan-out work, [spawn](spawn.md) and a channel are shorter. When threads do
share a variable, it needs a [mutex](mutex.md) or an [atomic](atomics.md).

### Activities

1. Split the range 1 to 1000 between five threads.
2. Add a field to `Slice` that each thread fills with its count of even
   squares, and print the counts.
