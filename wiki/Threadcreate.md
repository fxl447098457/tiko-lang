[Home](Home) › [Threading Support Functions](Category-Threading-Support-Functions) › **ThreadCreate**

# ThreadCreate

Starts a procedure on a new thread, passing it one pointer; returns the thread handle.

## Syntax

```freebasic
Declare Function ThreadCreate _
( _
ByVal procptr As Sub ( ByVal userdata As Any Ptr ), _
ByVal param As Any Ptr = 0, _
ByVal stack_size As Integer = 0 _
) As Any Ptr
```

## Parameters

- `procptr`
- `userdata`
- `param`
- `procptr`
- `stack_size`

## Description

The sub pointed to by *procptr* is started as a thread. It will be passed the content of *param*, or 0 (zero) if not specified, in its *userdata* parameter.

 The sub that was started as a thread will execute in parallel with the main part of the program. The OS achieves this by assigning it to a different processor if it exists, or by alternating between execution threads on a single processor.  
 There is no guarantee about the order in which different threads execute, and no assumptions can be made about the order in which multiple created threads actually start executing.  
 The time between **ThreadCreate** and the actual start of execution of the thread is variable and can be longer or shorter depending on the context (so some statements following the **ThreadCreate** statement can be executed before the actual launch of the thread).  
 In the fastest launch cases, the thread body may start executing even before **ThreadCreate** returns.

 Each running thread can be identified by its handle which is unique among all running threads. See [`ThreadSelf`](Threadself).

 Before closing, programs should wait for the termination of all launched threads by using [`ThreadWait`](Threadwait). Alternatively, if it's not necessary to safely wait for a thread to finish execution, [`ThreadDetach`](Threaddetach) can be used. However, if a program exits while some threads are still active, those threads will be aborted by the system. For every thread created, programs should call either [`ThreadWait`](Threadwait) or [`ThreadDetach`](Threaddetach) to ensure that the system resources associated with the thread handles are released. Otherwise, there may be memory or system resource leaks.

 Due to the nature of threads, no assumptions about execution order can be made. In order to exchange data between multiple threads, including a thread and the main part of the program, mutexes must be used. These mutual exclusion locks can be "owned" by a single thread while doing critical work, causing other threads to wait for their turn. See [`MutexCreate`](Mutexcreate), [`MutexLock`](Mutexlock), [`MutexUnlock`](Mutexunlock), [`MutexDestroy`](Mutexdestroy).

 `stack_size` can be used to change the thread's stack size from the system's default. This can be useful when the program requires a big stack, for example due to lots of procedure recursion or when allocating huge strings/arrays on the stack. On some systems (Linux), the stack automatically grows beyond `stack_size` if more space is needed; on others (Win32), this is the fixed maximum allowed. Behavior is undefined when more stack is used than the reserved size on systems where stacks are not able to grow.

 The intrinsic macro [`__FB_MT__`](Fb-Mt) is only automatically set from the point of usage of **ThreadCreate** onward.

 **Note:**

**-** The `userdata` parameter can be unused in the body of the `myThread` sub, but declaring it as an `Any Ptr` parameter is always mandatory in the header. In this case, the corresponding `param` parameter can then be omitted when calling **ThreadCreate**, or else a needless argument can still be passed ('0' is commonly used because this value is directly compatible with any pointer). See the 2nd and 3rd example.
 **-** In the case where data must be passed to `myThread`, the Any Ptr `param` can be used to reference them, usually requiring a type conversion (implicit or explicit) into `Any Ptr` before passing it to **ThreadCreate**, and a reverse type conversion from `Any Ptr` in the body of `myThread` before using it. See the 1st example.

## Return Value

**ThreadCreate** returns an `Any Ptr` handle to the thread created, or a null pointer (`0`) on failure.

## Remarks

### Usage

`result = ThreadCreate ( procptr [, [ param ] [, stack_size ] ] )`

### Dialect Differences

- Threading is not allowed in the *[-lang qb](Compiler-Option-Lang)* dialect.

### Platform Differences

- **Threadcreate** is not available with the DOS version / target of FreeBASIC, because multithreading is not supported by DOS kernel nor the used extender.
  In Linux the threads are always started in the order they are created, this can't be assumed in Win32. It's an OS, not a FreeBASIC issue.

### Differences from QB

- New to FreeBASIC

### See also

- [`ThreadSelf`](Threadself)
- [`ThreadWait`](Threadwait)
- [`ThreadDetach`](Threaddetach)
- [`MutexCreate`](Mutexcreate)
- [`MutexLock`](Mutexlock)
- [`MutexUnlock`](Mutexunlock)
- [`MutexDestroy`](Mutexdestroy)
- [`Operator Procptr (Procedure Pointer And Vtable Index)`](Operator-Procptr-Procedure-Pointer-and-Vtable-Index)

## Examples

```freebasic
'' Threading synchronization using Mutexes

'' If you comment out the lines containing "MutexLock" and "MutexUnlock",

'' the threads will not be in sync and some of the data may be printed

'' out of place.

Const MAX_THREADS = 10

Dim Shared As Any Ptr ttylock

'' Teletype unfurls some text across the screen at a given location

Sub teletype( ByRef text As String, ByVal x As Long, ByVal y As Long )

    ''

    '' This MutexLock makes simultaneously running threads wait for each

    '' other, so only one at a time can continue and print output.

    '' Otherwise, their Locates would interfere, since there is only one

    '' cursor.

    ''

    '' It's impossible to predict the order in which threads will arrive

    '' here and which one will be the first to acquire the lock thus

    '' causing the rest to wait.

    ''

    MutexLock ttylock

    For i As Integer = 0 To (Len(text) - 1)

        Locate x, y + i

        Print Chr(text[i])

        Sleep 25, 1

    Next

    '' MutexUnlock releases the lock and lets other threads acquire it.

    MutexUnlock ttylock

End Sub

Sub thread( ByVal userdata As Any Ptr )

    Dim As Integer id = CInt(userdata)

    teletype "Thread (" & id & ").........", 1 + id, 1

End Sub

    '' Create a mutex to syncronize the threads

    ttylock = MutexCreate()

    '' Create child threads

    Dim As Any Ptr handles(0 To MAX_THREADS-1)

    For i As Integer = 0 To MAX_THREADS-1

        handles(i) = ThreadCreate(@thread, CPtr(Any Ptr, i))

        If handles(i) = 0 Then

            Print "Error creating thread:"; i

            Exit For

        End If

    Next

    '' This is the main thread. Now wait until all child threads have finished.

    For Each h As Any Ptr In handles

        If h <> 0 Then

            ThreadWait(h)

        End If

    Next

    '' Clean up when finished

    MutexDestroy(ttylock)
```

```freebasic
Sub print_dots(ByRef char As String)

    For i As Integer = 0 To 29

        Print char;

        Sleep CInt(Rnd() * 100), 1

    Next

End Sub

Sub mythread(param As Any Ptr)

    '' Work (other thread)

    print_dots("*")

End Sub

    Randomize(Timer())

    Print " main thread: ."

    Print "other thread: *"

    '' Launch another thread

    Dim As Any Ptr thread = ThreadCreate(@mythread, 0)

    '' Work (main thread)

    print_dots(".")

    '' Wait until other thread has finished, if needed

    ThreadWait(thread)

    Print

    Sleep
```

```freebasic
'' Threaded consumer/producer example using mutexes

Dim Shared As Any Ptr produced, consumed

Sub consumer( ByVal param As Any Ptr )

    For i As Integer = 0 To 9

        MutexLock produced

        Print ", consumer gets:", i

        Sleep 500, 1

        MutexUnlock consumed

    Next

End Sub

Sub producer( ByVal param As Any Ptr )

    For i As Integer = 0 To 9

        Print "Producer puts:", i;

        Sleep 500, 1

        MutexUnlock produced

        MutexLock consumed

    Next i

End Sub

    Dim As Any Ptr consumer_id, producer_id

    produced = MutexCreate

    consumed = MutexCreate

    If( ( produced = 0 ) Or ( consumed = 0 ) ) Then

        Print "Error creating mutexes! Exiting..."

        End 1

    End If

    MutexLock produced

    MutexLock consumed

    consumer_id = ThreadCreate(@consumer)

    producer_id = ThreadCreate(@producer)

    If( ( producer_id = 0 ) Or ( consumer_id = 0 ) ) Then

        Print "Error creating threads! Exiting..."

        End 1

    End If

    ThreadWait consumer_id

    ThreadWait producer_id

    MutexDestroy consumed

    MutexDestroy produced

    Sleep
```

---

**Category:** [Threading Support Functions](Category-Threading-Support-Functions)  
**Kind:** function

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
