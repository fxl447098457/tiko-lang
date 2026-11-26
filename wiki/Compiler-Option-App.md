[Home](Home) › **Compiler Option: -app**

# Compiler Option: -app

Build an Android app (an APK, or an App Bundle for Play) of an SDL3 program

> **Experimental.** Android support is new and still settling: these options and how tkControls behaves on a phone may still change. See [Android](Android).

Syntax

`-app [ -appid id ] [ -applabel text ] [ -appversion name[,code] ] [ -appicon file.png ] [ -appassets dir ] [ -apppermission name ]... [ -appkey keystore[,alias] ] [ -appbundle ]`

Parameters

| Option | |
| --- | --- |
| `-appid id` | the application id, two or more dot-separated names (`org.example.game`); default `org.tiko.<name>` |
| `-applabel text` | the name shown under the app's icon; default the program's name |
| `-appversion name[,code]` | the version name a user sees and the version code Android compares, a whole number from 1 to 2100000000; default `1.0,1` |
| `-appicon file.png` | the launcher icon; default Android's own |
| `-apppermission name` | a permission the app uses, one `<uses-permission>` in the manifest; repeatable. A name with no dot is `android.permission.<name>`, so `-apppermission INTERNET` is what any network use (sockets, HTTP) needs. Default none |
| `-appassets dir` | a directory whose files, subdirectories included, become the app's assets |
| `-appkey keystore[,alias]` | sign with this key rather than the debug key. Its passwords are read from the environment variables `TIKO_ANDROID_KS_PASS` and `TIKO_ANDROID_KEY_PASS` (the key's, when it differs), never from the command line. `-appbundle` needs the alias |
| `-appbundle` | write an Android App Bundle (`.aab`), what Google Play takes, rather than an `.apk` |

Description

`-app` builds the program for `-target android-x86_64` or `-target android-arm64` as an Android app: a shared library that SDL3's Java side loads and runs, packaged with the Android SDK's tools and signed. The output is `<name>.apk`, or `<name>.aab` with `-appbundle`. Any other target is refused with `TKO0195`, and an `-app*` option without `-app` with `TKO0197`.

The program must import `vendor/SDL3`, directly or through a package such as tkControls. Its `print` output goes to the device's log (`adb logcat -s tiko`); its `exepath` is `"."`; its working directory is the app's private storage; and a read-only `open` (or `std/fs` read) of a relative name that is not a file there reads the app's asset of that name.

Needed besides the toolchain: the Android NDK (`ANDROID_NDK_HOME`), the SDK's build-tools and platform 36 (`ANDROID_HOME`), and a JDK 17 or newer (`JAVA_HOME`); for `-appbundle`, bundletool (`TIKO_ANDROID_BUNDLETOOL`, or `bundletool*.jar` in a `bundletool` folder beside the SDK).

In a project, `kind = "app"` in `[target.<name>]` builds the target with `-app`, and a `[target.<name>.app]` table sets the others: `id`, `label`, `version`, `icon`, `assets`, `key`, `permissions` (an array: `permissions = ["INTERNET"]`) and `bundle = true`.

Examples

```text
tiko -target android-arm64 -app game.tiko
tiko -target android-arm64 -app -appbundle -appid org.example.game -appversion 1.0,1 -appkey release.jks,upload game.tiko
```

Differences from FB

- New to tiko. fbc's `-target android` builds a program, not an app.

See also

- [Compiler Option: -target](Compiler-Option-Target)
- [Compiler Option: -dll](Compiler-Option-Dll)
- [Android](Android), [Android Setup Tutorial](Android-Setup-Tutorial), [Android App Tutorial: Fasting](Android-Fasting-App-Tutorial)
- [__FB_ANDROID__](Fb-Android)
