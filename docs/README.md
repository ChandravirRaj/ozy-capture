# Oxy Capture — documentation

Desktop screenshot capture proof-of-concept using Flutter and native platform APIs.

See also the [repository README](../README.md) for a quick overview.

## Structure

```text
app/                                    Flutter desktop app (BLoC UI)
packages/desktop_screenshot_capture/    Public Dart API + mock provider
packages/desktop_screenshot_capture_platform_interface/
packages/desktop_screenshot_capture_macos/   ScreenCaptureKit
packages/desktop_screenshot_capture_windows/ WGC
packages/desktop_screenshot_capture_linux/   stub (phase 2)
docs/
scripts/                                install-macos.sh, build-windows-portable.ps1
```

## App flow (all desktop platforms)

The same UX applies on macOS, Windows, and Linux:

1. **Welcome to Oxy Capture** alert dialog on launch (replaces the old consent card and setup UI)
2. **Continue** — consent accepted; permission is checked
3. If permission is denied — **permission required** dialog (Open Settings on macOS/Windows, Retry + Quit on Linux)
4. When permission is granted — capture **starts automatically** on the primary monitor (default **15 second** interval)
5. Main window **hides to the system tray** when capture starts
6. Use the tray menu: **Open Oxy Capture**, **Stop Capture**, **Quit**

## macOS — build & run

```bash
cd app
flutter pub get
flutter run -d macos
```

Release build:

```bash
flutter build macos
```

Install to **Applications** (so it appears in Launchpad, Spotlight, and Screen Recording settings):

```bash
../scripts/install-macos.sh
```

Or manually:

```bash
ditto build/macos/Build/Products/Release/oxy_capture.app "/Applications/Oxy Capture.app"
open "/Applications/Oxy Capture.app"
```

`flutter run` builds a temporary copy under `build/` only — it is **not** installed as a normal Mac app until you copy it to `/Applications`.

### Screen Recording permission

1. Launch the app and tap **Continue** on the welcome dialog
2. If permission is denied, use **Open Screen Recording Settings** in the permission dialog, or open **System Settings → Privacy & Security → Screen Recording**
3. Enable **Oxy Capture** (toggle OFF then ON after reinstall if needed)
4. Tap **Retry** or relaunch the app

### Output location

```text
~/Documents/OxyCapture/session_YYYY-MM-DD_HH-mm-ss/
  screenshot_YYYY-MM-DD_HH-mm-ss-SSS.jpg
```

### Mock mode (UI only)

```bash
flutter run -d macos --dart-define=USE_MOCK_CAPTURE=true
```

See [macos/manual-test-steps.md](macos/manual-test-steps.md) for the full checklist.

## Windows — build & run

```bash
cd app
flutter pub get
flutter run -d windows
```

Release build (must run on Windows):

```bash
flutter build windows --release
```

Portable ZIP packaging (Windows PowerShell, from repo root):

```powershell
.\scripts\build-windows-portable.ps1
```

Output: `dist/OxyCapture-<version>-windows-x64.zip`

See [windows/build.md](windows/build.md) and [windows/manual-test-steps.md](windows/manual-test-steps.md).

### Output location

```text
%USERPROFILE%\Documents\OxyCapture\session_YYYY-MM-DD_HH-mm-ss\
  screenshot_YYYY-MM-DD_HH-mm-ss-SSS.jpg
```

### Mock mode (UI only)

```bash
flutter run -d windows --dart-define=USE_MOCK_CAPTURE=true
```

## Linux — status

The launch dialog and tray flow match macOS and Windows. Native screen capture (Wayland portal + PipeWire) is deferred to phase 2 — permission checks and capture may fail until the Linux backend is implemented.

**Tray dependencies** (Ubuntu/GNOME):

```bash
sudo apt install libayatana-appindicator3-1
# or: sudo apt install libappindicator3-1
```

On some GNOME Wayland setups, install the **AppIndicator** extension for tray visibility.

See [linux/manual-test-steps.md](linux/manual-test-steps.md).

## Background mode (system tray)

After capture permission is granted:

- A menu bar icon (macOS) or system tray icon (Windows/Linux) appears
- The main window **auto-hides to the tray** when capture starts
- Closing the window while capturing hides the app instead of quitting
- Screenshots continue while the app is hidden
- Tray menu: **Open Oxy Capture**, **Stop Capture**, **Quit**

## Manual test flow

1. Launch **Oxy Capture** — confirm the **Welcome to Oxy Capture** dialog (no consent card or setup fields)
2. Tap **Continue** on the launch dialog
3. Grant screen capture permission if prompted (platform-specific settings)
4. Confirm capture **starts automatically** on the primary monitor (~15 second interval)
5. Confirm the main window **hides to the tray** and JPEGs appear in the Documents output folder
6. Open from tray — main window returns; **Stop Recording** stops capture
7. **Open Folder** from the completed session view works
8. **Quit** from tray exits the app completely

Platform-specific checklists:

- [macos/manual-test-steps.md](macos/manual-test-steps.md)
- [windows/manual-test-steps.md](windows/manual-test-steps.md)
- [linux/manual-test-steps.md](linux/manual-test-steps.md)
