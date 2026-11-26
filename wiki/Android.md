[Home](Home) › **Android**

# Android

> **Experimental.** Android support is new and still settling. It builds and runs real apps, but
> the `-app` options, the `[target.x.app]` table in `tiko.toml` and how tkControls behaves under a
> finger may still change, and it has been tried on few devices. Report what you find on the
> [issue tracker](https://github.com/PaulSquires/tiko-lang/issues).

tiko builds programs and apps for Android phones, tablets and the Android emulator. You write
tiko; tiko compiles it, links it with Android's C library and packs it into a signed APK. There is
no Java, Kotlin or Gradle project to keep.

| | |
| --- | --- |
| [Android Setup Tutorial](Android-Setup-Tutorial) | Set up a Windows PC with Android Studio, then build, install and run a one-button app on the emulator or a phone |
| [Android App Tutorial: Fasting](Android-Fasting-App-Tutorial) | How a complete app was built: six screens in tkControls, SQLite on the phone, HTTPS sync with a server, light and dark themes, a signed release, with screenshots of each step |
| [Compiler Option: -app](Compiler-Option-App) | Every `-app` option, and the `[target.x.app]` table |
| [Compiler Option: -target](Compiler-Option-Target) | `android-x86_64` and `android-arm64` |
| [`__TIKO_COMPILER__` and the target names](Category-Tiko-Compiler-Define) | `TIKO_OS_ANDROID`, for code that only Android should compile |

## What you get

- **Two targets:** `android-arm64` for phones and tablets, and `android-x86_64` for the emulator
  on a PC.
- **Android 10 (API level 29) or newer** on the device.
- **Built on Windows.** The Windows toolchain carries both Android targets. The Linux and macOS
  toolchains do not build for Android.
- **A console program** with `-target android-arm64`: a plain executable you run over `adb shell`.
  `print`, files, threads and the standard library behave as on Linux.
- **An app** with `-app`: an SDL3 program packed as a signed APK, or as an App Bundle (`.aab`)
  for Google Play with `-appbundle`. [tkControls](Category-tkControls) is built on SDL3, so a
  tkControls program is the same source on the desktop and on the phone.

## tkControls on a phone

On Android every window is the whole screen, and tkControls adds what a phone needs:

- **Touch:** a tap is a click, a swipe scrolls with fling, a long press is a right click.
- **Screens instead of windows:** popups, dialogs and second forms are drawn inside the one
  window, and the **BACK** button closes the top one.
- **The safe area:** controls keep clear of the status bar, the navigation bar and a display
  cutout.
- **The screen keyboard** comes up for a focused text box, with the right kind of keys for it (a
  number pad for a numeric field, for example).
- **Sizes in dp:** `tkHost_Scale` turns design units into pixels at the screen's density, so a
  56-unit button suits a finger on any phone.
- **[tkStack](tkStack)** lays controls out one after another, the usual layout of a phone screen.

## Needed besides tiko

| Tool | For | Found through |
| --- | --- | --- |
| the Android NDK, r30 or newer | every Android build: Android's C library and linker files | `ANDROID_NDK_HOME`, else the newest `ndk\<version>` in the SDK |
| the Android SDK: Build-Tools and platform 36 | an app (`-app`) | `ANDROID_HOME`, else `%LOCALAPPDATA%\Android\Sdk` |
| a JDK, 17 or newer | an app: packing and signing are Java tools | `JAVA_HOME`, else Android Studio's own (`C:\Program Files\Android\Android Studio\jbr`) |
| bundletool | an App Bundle (`-appbundle`) | `TIKO_ANDROID_BUNDLETOOL`, else `bundletool*.jar` in `bundletool\` beside the SDK |
| clang 18 or newer | every build, as on the desktop | as on the desktop ([Quick Start](Quick-Start)) |

Android Studio installs the SDK and a JDK where tiko looks for them, and its SDK Manager adds the
NDK, so a PC set up as the [Android Setup Tutorial](Android-Setup-Tutorial) describes needs no
environment variables.

## In your code

```freebasic
#ifdef TIKO_OS_ANDROID
    print "on a phone"               '' goes to the device log: adb logcat -s tiko
#else
    print "on the desktop"
#endif
```

`TIKO_OS_ANDROID` is `1` on both Android targets. `TIKO_OS_LINUX` is **not** defined there:
Android's C library is not glibc, and code written for Linux would assume it is. In an app:

- `print` goes to the device log, which `adb logcat -s tiko` shows.
- The working directory is the app's private storage: files a program writes there stay until
  the app is removed.
- `open` for reading (and the read functions of `std/fs`) of a relative name that is not a file
  there reads the app's **asset** of that name, from the folder given with `-appassets`.
- `exepath` is `"."`.
- The program ends when its main code returns or reaches `end`; Android then closes the app.

## Known limits

- **No HTTPS from the standard library.** `std/tls` and `std/http` have no TLS library on
  Android. An app reaches a web server through Android's own `java.net.HttpURLConnection` over
  JNI, as the [Fasting app](Android-Fasting-App-Tutorial#7-talking-to-the-server) does.
- **A thread that calls Java needs a real stack.** Give `threadcreate` a stack size (1 MB is
  plenty): with the default, the first JNI call on that thread stops the app.
- **No Java or Kotlin host.** tiko makes the whole app; it cannot yet be a library inside an app
  written in Java or Kotlin.
- **Few devices tried:** the Android Studio emulator (API 29 and API 36, x86_64 and arm64) and one
  physical phone.

## See also

- [Compiler Option: -app](Compiler-Option-App)
- [Compiler Option: -target](Compiler-Option-Target)
- [tkControls](Category-tkControls)
- [`__FB_ANDROID__`](Fb-Android)
