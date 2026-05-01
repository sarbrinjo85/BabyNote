# Android setup

`flutter doctor` flagged two issues on this machine. Both are one-time, and Flutter cannot fix them itself — you have to do them through Android Studio's UI.

## 1. Install Android SDK Command-line Tools

1. Open **Android Studio**.
2. **Settings** (Ctrl+Alt+S) → **Languages & Frameworks** → **Android SDK**.
3. Switch to the **SDK Tools** tab.
4. Check **Android SDK Command-line Tools (latest)**.
5. Click **Apply** → wait for download → **OK**.

## 2. Accept Android SDK licenses

After step 1, in a fresh terminal (so the new tools are on PATH):

```bash
flutter doctor --android-licenses
```

Press `y` for each license prompt.

## 3. Install Flutter & Dart plugins for Android Studio

1. **Settings** → **Plugins** → **Marketplace** tab.
2. Search **Flutter** → **Install** → also installs Dart automatically.
3. Restart Android Studio.

## 4. Verify

```bash
flutter doctor
```

You should see green checkmarks for **Flutter**, **Android toolchain**, and **Connected device** — at minimum.
**Visual Studio** (Windows desktop builds) and **Xcode** (iOS, macOS only) can stay red — neither is needed for mobile dev on this machine.

## (Optional) Set JAVA_HOME

If `flutter doctor` complains about Java, point `JAVA_HOME` at the JBR bundled with Android Studio:

```powershell
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Android\Android Studio\jbr", "User")
```

Open a fresh shell after setting it.
