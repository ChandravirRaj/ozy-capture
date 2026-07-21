# Oxy Capture

Desktop screenshot capture proof-of-concept using Flutter and native platform APIs.

## Structure

```text
app/                                    Flutter desktop app (BLoC UI)
packages/desktop_screenshot_capture/    Public Dart API + mock provider
packages/desktop_screenshot_capture_platform_interface/
packages/desktop_screenshot_capture_macos/   ScreenCaptureKit
packages/desktop_screenshot_capture_windows/ WGC
packages/desktop_screenshot_capture_linux/   stub (phase 2)
docs/
```

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

1. Launch the app
2. If permission is denied, open **System Settings → Privacy & Security → Screen Recording**
3. Enable **Oxy Capture**
4. Quit and relaunch the app

### Output location

```text
~/Documents/OxyCapture/session_YYYY-MM-DD_HH-mm-ss/
  screenshot_YYYY-MM-DD_HH-mm-ss-SSS.jpg
```

### Mock mode (UI only)

```bash
flutter run -d macos --dart-define=USE_MOCK_CAPTURE=true
```

### Background mode (menu bar / system tray)

After **Screen Recording permission is granted**:

- A menu bar icon appears (macOS) or system tray icon (Windows/Linux)
- Closing the main window **hides** the app instead of quitting
- During active capture, screenshots continue while hidden
- Use the tray menu: **Open Oxy Capture**, **Stop Capture**, **Quit**

**Linux tray dependencies** (Ubuntu/GNOME):

```bash
sudo apt install libayatana-appindicator3-1
# or: sudo apt install libappindicator3-1
```

On some GNOME Wayland setups, install **AppIndicator** extension for tray visibility.

## Windows — build & run

```bash
cd app
flutter pub get
flutter run -d windows
```

Release build:

```bash
flutter build windows --release
```

See [`docs/windows/build.md`](windows/build.md) and [`docs/windows/manual-test-steps.md`](windows/manual-test-steps.md).

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

Deferred to phase 2 (Wayland portal + PipeWire).

## Manual test flow

1. Launch **Oxy Capture** — consent unchecked, Select Monitor disabled
2. Check **I understand and agree**
3. Grant Screen Recording if prompted — capture **starts automatically** on the primary monitor
4. Verify JPEGs appear in Documents folder ~every interval
5. **Stop Capture** — no new files after stop
6. **Open Folder** works
7. Close window while capturing — app hides to tray, capture continues
8. Open from tray — main window returns

See `docs/macos/manual-test-steps.md` for the full macOS checklist including background capture.  
See `docs/windows/manual-test-steps.md` for the Windows checklist.
