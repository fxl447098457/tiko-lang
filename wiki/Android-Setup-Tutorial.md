[Home](Home) › [Android](Android) › **Android Setup Tutorial**

# Android Setup Tutorial: Android Studio and your first app

> **Experimental.** Android support is new and still settling: the `-app` options and how
> tkControls behaves on a phone may still change. See [Android](Android) for what works today.

This tutorial starts from a Windows PC with nothing Android on it and ends with your own app on
the Android emulator or a phone: one button, and pressing it closes the app. Android Studio
supplies Android's tools and the emulator. You will not write any Java or Kotlin, and you will not
make an Android Studio project: you write tiko, and tiko builds the app.

What you will do:

1. [Install LLVM](#step-1-install-llvm-clang)
2. [Install Android Studio](#step-2-install-android-studio)
3. [Add the Android parts tiko needs](#step-3-add-the-android-parts-tiko-needs)
4. [Install tiko](#step-4-install-tiko)
5. [Get a device: the emulator or a phone](#step-5-get-a-device-to-run-the-app-on)
6. [Make `adb` easy to type](#step-6-make-adb-easy-to-type)
7. [Write the app](#step-7-write-the-app)
8. [Build the APK](#step-8-build-the-apk)
9. [Install it and run it](#step-9-install-it-and-run-it)
10. [Give it a name, an id and a version](#step-10-give-it-a-name-an-id-and-a-version)
11. [Sign it with your own key, and make an App Bundle for Google Play](#step-11-share-it)

When you are done, the [Fasting app tutorial](Android-Fasting-App-Tutorial) shows how a complete
app with several screens, a database and a server was built the same way.

---

## What you need

- Windows 10 or 11, 64-bit (x64). Android apps are built on Windows only.
- About 15 GB of free disk space. Android Studio and an emulator image are most of it.
- For the emulator: hardware virtualization turned on in the PC's firmware (most PCs have it on).
  You can use a real phone instead.
- A phone, if you use one, with **Android 10 or newer**.

## Step 1: Install LLVM (clang)

tiko turns your program into machine code with **clang**, which comes with LLVM.

1. Go to <https://github.com/llvm/llvm-project/releases> and download the newest
   `LLVM-<version>-win64.exe`. tiko needs clang 18 or newer.
2. Run the installer and keep the default folder, `C:\Program Files\LLVM`. tiko looks for clang
   there.

## Step 2: Install Android Studio

Android Studio is the easiest way to get Android's tools. You use it only to download Android's
parts and to run the emulator.

1. Download it from <https://developer.android.com/studio> and run the installer with its
   defaults.
2. Start Android Studio and let the **Setup Wizard** run; choose **Standard**. It downloads the
   Android SDK into `C:\Users\<you>\AppData\Local\Android\Sdk`.

That folder is where tiko looks for the SDK. The installer also puts a Java runtime inside
Android Studio, `C:\Program Files\Android\Android Studio\jbr`, and tiko finds that one too. So
with Android Studio's default folders you set **no environment variables** at all.

## Step 3: Add the Android parts tiko needs

In Android Studio's welcome window choose **More Actions › SDK Manager** (with a project open:
**Tools › SDK Manager**).

- On the **SDK Platforms** tab, tick **Android 16 ("Baklava"), API Level 36**. A newer one
  works too.
- On the **SDK Tools** tab, tick **Show Package Details** at the bottom, then:
  - **Android SDK Build-Tools**: the newest version;
  - **NDK (Side by side)**: version **30** or newer;
  - **Android SDK Platform-Tools**;
  - **Android Emulator**.

Click **Apply**, accept the licences, and wait for the downloads to finish (about 3 GB).

| Part | What tiko uses it for |
| --- | --- |
| NDK | every Android build: Android's C library, which your program links against |
| Platform 36 and Build-Tools | turning the program into an APK and signing it |
| Platform-Tools | `adb`, which installs apps on a device and shows their output |
| Emulator | a virtual phone on your PC |

## Step 4: Install tiko

Download the newest **tiko toolchains** release from
[Releases](https://github.com/PaulSquires/tiko-lang/releases): the file
`tiko-windows-x86_64-<commit>.zip`. The Windows toolchain carries the two Android targets; the
Linux and macOS ones do not.

1. Unzip it to a folder whose path has no spaces, for example `C:\`. You then have
   `C:\tiko-lang\tiko.exe`, and beside it `lib\android-arm64` and `lib\android-x86_64`.
2. Put that folder on your `PATH`, so that `tiko` works in any terminal. In PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\tiko-lang", "User")
```

3. **Close the terminal and open a new one**, so that it sees the new `PATH`. Check that tiko
   runs:

```powershell
tiko --version
```

## Step 5: Get a device to run the app on

**The emulator.** In Android Studio's welcome window choose **More Actions › Virtual Device
Manager** and click **+** (*Create Virtual Device*). Pick a phone, for example **Medium Phone**.
For the system image pick **API 36** and an **x86_64** image. Finish the wizard, then press **▶**
beside the new device. A phone appears in a window; leave it running.

**A phone.**

1. On the phone, open **Settings › About phone** and tap **Build number** seven times. This turns
   on *Developer options*.
2. Open **Settings › System › Developer options** and turn on **USB debugging**.
3. Connect the phone with a USB cable. When it asks *Allow USB debugging?*, tap **Allow**.

## Step 6: Make `adb` easy to type

`adb` is Android's tool for talking to a device. It is in the SDK's `platform-tools` folder, which
is not on your `PATH`. For the current terminal only:

```powershell
$env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
```

Then check that it sees your emulator or phone:

```powershell
adb devices
```

You should see a line ending in `device`, such as `emulator-5554  device`. If a phone shows
`unauthorized`, unlock it and allow USB debugging.

---

## Step 7: Write the app

Make a folder for the app, for example `C:\apps\hello`, and in it a file named **`hello.tiko`**:

```freebasic
'' hello.tiko -- one button; pressing it closes the app.
#import "vendor/tkControls/tkApp"
#import "vendor/tkControls/tkButton"
using tkApp
using tkButton
using tkHost

dim shared as TK_WIDGET ptr gButton

'' Called when the button is pressed: tkApp_Run below returns, and the program ends.
sub OnClose( byval button as TK_WIDGET ptr, byval id as int32 )
    print "hello: button pressed, closing"
    tkApp_Quit( )
end sub

'' Called whenever the form gets a size (at the start, and when the phone turns): centre the button.
sub OnSize( byval f as TK_FORM ptr, byval cx as int32, byval cy as int32 )
    dim as int32 bw = tkForm_Scale( f, 200 ), bh = tkForm_Scale( f, 56 )
    tkWidget_SetPos( gButton, (cx - bw) \ 2, (cy - bh) \ 2, bw, bh )
end sub

if tkApp_Init( ) = false then print "tkApp_Init: " & *SDL_GetError( ) : end 1
var form = tkApp_NewForm( "Hello", 360, 640 )
gButton = tkButton_Create( tkForm_Widget( form ), 1 )
tkButton_SetText( gButton, "Close the app" )
tkButton_SetClickCallback( gButton, @OnClose )
tkForm_OnSize( form, @OnSize )
dim as int32 rc = tkApp_Run( form )
print "hello: bye"
end rc
```

What it does:

- **`#import "vendor/tkControls/tkApp"`** brings in [tkControls](Category-tkControls), tiko's
  controls. They draw with **SDL3**, which runs on Windows, Linux, macOS and Android, so this one
  source is a desktop program and an Android app.
- **`tkApp_NewForm`** makes the window. On a PC it is 360 × 640; on Android it is the whole
  screen, and the size is ignored.
- **`tkButton_Create`** puts a button on it, and `tkButton_SetClickCallback` names the `sub` to
  call when it is pressed.
- **`OnSize`** puts the button in the middle whenever the form gets a size, which includes turning
  the phone. `tkForm_Scale` turns *design units* into pixels: on a phone one unit is one dp, so
  a 56-unit-high button suits a finger on any screen.
- **`tkApp_Run`** waits for taps, keys and redraws until **`tkApp_Quit`** is called. When the
  program then ends, **Android closes the app**.
- **`print`** has no console on a phone: its text goes to Android's log, where `adb logcat`
  shows it.

To try it on the PC first: `tiko hello.tiko`, then `.\hello.exe`. tiko puts the SDL3 DLLs and the
fonts beside `hello.exe`.

## Step 8: Build the APK

An **APK** is the file Android installs. `-app` makes one, and `-target` says which kind of device
it is for:

| Device | `-target` |
| --- | --- |
| The emulator on your PC | `android-x86_64` |
| A phone or tablet | `android-arm64` |

```powershell
cd C:\apps\hello
tiko -target android-x86_64 -app hello.tiko
```

You get **`hello.apk`** beside `hello.tiko`. Building it compiles the program for Android, links
it with SDL3 and tkControls into one library, adds Android's start-up code and the fonts tkControls
uses, writes the app's *manifest*, and signs the APK with a **debug key**. tiko makes that key the
first time, in `C:\Users\<you>\.android\debug.keystore`, the same one Android Studio uses. A debug
key is fine for testing on your own devices.

## Step 9: Install it and run it

With the emulator running, or the phone connected:

```powershell
adb install -r hello.apk
```

It answers `Success`; `-r` installs over an older copy. Open the device's app list and tap
**hello**:

![The hello app on the Android emulator: a light grey screen with one rounded button in the middle labelled Close the app.](Android-Hello.png)

Tap **Close the app**, and you are back on the home screen. To see the `print` output, start this
in a second terminal before you tap:

```powershell
adb logcat -s tiko
```

Among the lines it shows (on the emulator, a few from its graphics driver come first):

```text
I tiko    : hello: button pressed, closing
I tiko    : hello: bye
```

Press Ctrl+C to stop `logcat`.

## Step 10: Give it a name, an id and a version

The app is called `hello`, and its **application id** is `org.tiko.hello`. Android and Google Play
tell apps apart by the id, and it can never change once an app is published, so choose your own
before you share the app: usually your domain backwards and the app's name.

```powershell
tiko -target android-arm64 -app -appid com.example.hello -applabel "Hello" -appversion 1.0,1 -appicon icon.png hello.tiko
```

| Option | Sets | Default |
| --- | --- | --- |
| `-appid com.example.hello` | the application id | `org.tiko.<file name>` |
| `-applabel "Hello"` | the name under the icon | the file name |
| `-appversion 1.0,1` | the version people see (`1.0`) and the number Android compares (`1`) | `1.0,1` |
| `-appicon icon.png` | the launcher icon: a square PNG, 512 × 512 for example | Android's default |
| `-apppermission INTERNET` | a permission the app asks for; repeat it for each. Any use of the network needs `INTERNET` | none |
| `-appassets data` | a folder whose files go into the app; the program opens them by name with `open`, read-only | none |

**Each new release needs a higher version number** (the part after the comma), or Android and
Play refuse it as an update. All the options are on [Compiler Option: -app](Compiler-Option-App).

### A project file instead of long commands

A **`tiko.toml`** beside `hello.tiko` keeps the options in a file:

```toml
[package]
name = "hello"

[target.hello]
main = "hello.tiko"
kind = "app"

[target.hello.app]
id      = "com.example.hello"
label   = "Hello"
version = "1.0,1"
# icon        = "icon.png"
# assets      = "data"
# permissions = ["INTERNET"]
```

```powershell
tiko build hello -target android-arm64
```

This writes **`out\debug\hello.apk`**; with `--profile release` it writes `out\release\hello.apk`.
See [tiko build](Category-Tiko-Build).

## Step 11: Share it

### Your own signing key

Every update of an app must be signed with **the same key** as the version before it. Before you
give the app to anyone, make a key of your own **once**, and keep the file and its password safe:
without them you can never update the app. `keytool` comes with Android Studio's Java:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -keystore C:\keys\release.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

It asks for a password and your name. Give tiko the password in an environment variable, never on
the command line, and build with `-appkey keystore,alias`:

```powershell
$env:TIKO_ANDROID_KS_PASS = Read-Host "Keystore password"
tiko -target android-arm64 -app -appid com.example.hello -appversion 1.0,1 -appkey C:\keys\release.jks,upload hello.tiko
```

If the key has a password of its own, put it in `TIKO_ANDROID_KEY_PASS` too. In `tiko.toml` the key
is `key = "C:/keys/release.jks,upload"` in `[target.hello.app]`.

### Google Play takes an App Bundle

Play takes an **App Bundle** (`.aab`), not an APK. Add **`-appbundle`**, or `bundle = true` in
`tiko.toml`:

```powershell
tiko -target android-arm64 -app -appbundle -appid com.example.hello -appversion 1.0,1 -appkey C:\keys\release.jks,upload hello.tiko
```

This writes `hello.aab`. It needs **bundletool**, one `.jar` from
<https://github.com/google/bundletool/releases>: save it as
`C:\Users\<you>\AppData\Local\Android\bundletool\bundletool-all-<version>.jar`, or set
`TIKO_ANDROID_BUNDLETOOL` to where you saved it.

---

## When something goes wrong

| You see | What to do |
| --- | --- |
| `'tiko' is not recognized` | Open a new terminal after step 4, or check that `C:\tiko-lang\tiko.exe` exists |
| `no Android NDK -- set ANDROID_NDK_HOME ...` | Install **NDK (Side by side)** in the SDK Manager (step 3) |
| `no Android SDK with build-tools ...` | Install **Build-Tools** and **Platform 36** (step 3). If your SDK is not in `AppData\Local\Android\Sdk`, set `ANDROID_HOME` to it |
| `no JDK -- set JAVA_HOME ...` | Android Studio is not in its default folder: set `JAVA_HOME` to its `jbr` folder, or to any Java 17 or newer |
| `error TKO0111: ... fbrt0.o is on no library path` | `TIKO_LIBPATH` is set: it replaces the library folders for **every** target, Android's too. Clear it for the terminal (`$env:TIKO_LIBPATH = $null`) |
| clang not found, or `clang failed` | Install LLVM (step 1), or set `TIKO_CLANG` to your `clang.exe` |
| `'-app' builds an Android app; target ... is not android-x86_64 or android-arm64` | Add `-target android-x86_64` or `-target android-arm64` |
| `an app is an SDL3 program, and this one does not '#import "vendor/SDL3"'` | An app needs a window: import tkControls or SDL3 |
| `INSTALL_FAILED_OLDER_SDK` | The device runs Android 9 or older. tiko apps need Android 10 or newer |
| `INSTALL_FAILED_NO_MATCHING_ABIS` | The APK is for the other kind of device: `android-x86_64` for the emulator, `android-arm64` for a phone |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | The copy on the device was signed with another key. Remove it first: `adb uninstall com.example.hello` |
| `WARNING: A restricted method in java.lang.System has been called` while the APK is built | Harmless: a Java newer than 17 warns about the APK signer. The APK is still built and signed |
| A Java tool fails with `Unable to establish loopback connection` | Seen on some PCs. Set `$env:JAVA_TOOL_OPTIONS = "-Djdk.net.unixdomain.tmpdir=C:/no-such-dir-afunix"` and build again |
| `adb: more than one device/emulator` | Say which: `adb -s emulator-5554 install -r hello.apk` |
| `adb devices` lists nothing | Start the emulator, or check the cable and USB debugging (step 5) |

## See also

- [Android](Android): what works, what to know, the limits
- [Android App Tutorial: Fasting](Android-Fasting-App-Tutorial)
- [Compiler Option: -app](Compiler-Option-App)
- [tkApp](tkApp), [tkButton](tkButton), [tkStack](tkStack)
