[Home](Home) › [Threading Support Functions](Category-Threading-Support-Functions) › **CondBroadcast**

# CondBroadcast

Wakes every thread waiting on the condition.

## Syntax

```freebasic
Declare Sub CondBroadcast ( ByVal handle As Any Ptr )
```

## Parameters

- `handle`

## Description

Once the conditional is [`CondCreate`](Condcreate) and the threads are started, one of more of them (including the implicit main thread executing main program) can be set to [`CondWait`](Condwait) for the conditional, they will be stopped until some other thread [`CondSignal`](Condsignal)s that the waiting thread can restart. [`CondBroadcast`](Condbroadcast) can be used to restart all threads waiting for the conditional. At the end of the program [`CondDestroy`](Conddestroy) must be used to avoid leaking resources in the OS.

 **Condbroadcast** must be used instead of [`CondSignal`](Condsignal) to restart all threads waiting on the conditional.

## Remarks

### Usage

`CondBroadcast ( handle )`

### Platform Differences

- **Condbroadcast** is not available with the DOS version / target of FreeBASIC, because multithreading is not supported by DOS kernel nor the used extender.
  In Linux the threads are always started in the order they are created, this can't be assumed in Win32. It's an OS, not a FreeBASIC issue.

### Dialect Differences

- Threading is not allowed in *[-lang qb](Compiler-Option-Lang)*

### Differences from QB

- New to FreeBASIC

### See also

- [`CondCreate`](Condcreate)
- [`CondDestroy`](Conddestroy)
- [`CondSignal`](Condsignal)
- [`CondWait`](Condwait)
- [`ThreadCreate`](Threadcreate)

## Examples

See also [`CondCreate`](Condcreate)

```freebasic
'' How can all threads wait for each other before continuing to execute their concomitant sections of code ?

''

'' This is the main code that manages the synchronization of concomitant sections of code:

''    - Each thread signals to main code that it is waiting for synchronization.

''    - The main code waits for each of all threads, then sends the synchronization signal to all threads.

''

'' The synchronization uses the following keywords from threading:

''   - In each thread : 'Condsignal' (to send signal to main code) then 'Condwait' (to wait signal from main code).

''   - In main code : 'Condwait' (to wait signal from each thread) then 'Condbroadcast' (to send signal to all threads).

'' With the associated mutexes and conditional variables and flags.

''

'' Test example highlighting the structure of threads and their behaviors, when synchronizing all threads to execute their concomitant sections of code:

Dim threadnumber As Integer = 4

'' global data for all threads

    Dim Shared restart As Integer = 0

    Dim Shared threadcount As Integer = 0

    Dim Shared hmutexrestart As Any Ptr

    Dim Shared hcondrestart As Any Ptr

    Dim Shared hmutexready As Any Ptr

    Dim Shared hcondready As Any Ptr

Sub mythread(ByVal p As Any Ptr)

    Dim id As Integer = Cast(Integer, p)

    '' for visualizing thread status

        Print "   Thread #" & id & " is started..."

    '' instead of starting user code

        Sleep id * 40, 1

    '' for visualizing thread status

        Print "      Thread #" & id & " is running..."

        Sleep id * 20, 1  '' just to well visualize thread interlacing

        Print "   Thread #" & id & " is waiting for synchronization..."

    '' for sending signal to main code

        MutexLock hmutexready

        threadcount += 1

        CondSignal hcondready

        MutexUnlock hmutexready

    '' for waiting signal from main code

        MutexLock hmutexrestart

        Do While restart = 0

            CondWait hcondrestart, hmutexrestart

        Loop

        MutexUnlock hmutexrestart

    '' for visualizing thread status

        Print "   Thread #" & id & " is reactivated..."

    '' instead of synchronized user code

        Sleep id * 40, 1

    '' for visualizing thread status

        Print "      Thread #" & id & " is continuing..."

        Sleep id * 20, 1  '' just to well visualize thread interlacing

        Print "   Thread #" & id & " is finishing execution..."

End Sub

Dim threads(1 To threadnumber) As Any Ptr

hcondrestart = CondCreate()

hmutexrestart = MutexCreate()

hcondready = CondCreate()

hmutexready = MutexCreate()

'' for visualizing main code status

    Print "Start all threads from main code :"

'' for starting all threads

    For i As Integer = 1 To threadnumber

        threads(i) = ThreadCreate(@mythread, Cast(Any Ptr, i))

    Next i

'' for waiting for all threads waiting for synchronisation

    MutexLock hmutexready

    Do Until threadcount = threadnumber

        CondWait(hcondready, hmutexready)

    Loop

    MutexUnlock hmutexready

'' for visualizing main code status

    Print "All thread seen waiting from main code"

    Print

    Print "Reactivate all threads from main code :"

'' for reactivating all threads

    MutexLock hmutexrestart

    restart = 1

    CondBroadcast hcondrestart

    MutexUnlock hmutexrestart

'' for waiting for all threads to be completed

    For Each t As Any Ptr In threads

        If t <> 0 Then

            ThreadWait t

        End If

    Next

'' for visualizing main code status

    Print "All thread seen completed from main code"

MutexDestroy hmutexready

CondDestroy hcondready

MutexDestroy hmutexrestart

CondDestroy hcondrestart

Sleep
```

---

**Category:** [Threading Support Functions](Category-Threading-Support-Functions)  
**Kind:** sub

---

*Reproduced from the [FreeBASIC Wiki Manual](https://www.freebasic.net/wiki/) under the [GNU Free Documentation License 1.3](https://www.gnu.org/licenses/fdl-1.3.html) — with no Invariant Sections, no Front-Cover Texts and no Back-Cover Texts. Copyright © the FreeBASIC project and wiki contributors. See [License](License).*
