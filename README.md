# Oxy Capture

Desktop screenshot capture proof-of-concept built with Flutter and native platform APIs (ScreenCaptureKit on macOS, Windows Graphics Capture on Windows).

## Features

- **Welcome launch dialog** — consent and permission explanation on first run (all desktop platforms)
- **Auto-capture** — selects the primary monitor and starts capturing (default **15 second** JPEG interval)
- **System tray background mode** — main window hides to the tray when capture starts; control via tray menu

## Repository structure

```text
app/                                    Flutter desktop app (BLoC UI)
packages/desktop_screenshot_capture/    Public Dart API + mock provider
packages/desktop_screenshot_capture_platform_interface/
packages/desktop_screenshot_capture_macos/   ScreenCaptureKit
packages/desktop_screenshot_capture_windows/ WGC
packages/desktop_screenshot_capture_linux/   stub (phase 2)
docs/                                   Build guides and manual test checklists
scripts/                                install-macos.sh, build-windows-portable.ps1
```

## Requirements

- Flutter 3.x stable
- **macOS:** Xcode
- **Windows:** Visual Studio 2022 with Desktop development with C++
- **Linux:** Flutter Linux desktop support (capture backend not yet implemented)

## Quick start

```bash
git clone https://github.com/ChandravirRaj/ozy-capture.git
cd ozy-capture/app
flutter pub get
flutter run -d macos
```

Install as a normal Mac app:

```bash
../scripts/install-macos.sh
```

## Documentation

| Topic | Link |
|-------|------|
| Full build & run guide | [docs/README.md](docs/README.md) |
| macOS manual tests | [docs/macos/manual-test-steps.md](docs/macos/manual-test-steps.md) |
| Windows build | [docs/windows/build.md](docs/windows/build.md) |
| Windows manual tests | [docs/windows/manual-test-steps.md](docs/windows/manual-test-steps.md) |
| Linux manual tests | [docs/linux/manual-test-steps.md](docs/linux/manual-test-steps.md) |

## Platform notes

**Windows builds** cannot run on macOS (`flutter build windows` requires a Windows host). Recommended options:

### GitHub Actions (no local Windows PC)

After pushing this repository, build from the GitHub UI:

1. Open **Actions** → **Build Windows** → **Run workflow** → **Run workflow**
2. Wait for the job to finish (~5–15 minutes on first run)
3. Open the completed run → **Artifacts** → download **OxyCapture-windows-x64**
4. Extract the ZIP and run `oxy_capture.exe` (keep all DLLs and the `data\` folder together)

See [docs/windows/build.md](docs/windows/build.md) for details.

### Local Windows build

On a Windows machine with Flutter and Visual Studio 2022:

```powershell
.\scripts\build-windows-portable.ps1
```

**Linux** uses the same launch-dialog UI as macOS and Windows; native screen capture is deferred to phase 2.

## Output location

Screenshots are saved locally (not uploaded):

```text
~/Documents/OxyCapture/session_YYYY-MM-DD_HH-mm-ss/   (macOS/Linux)
%USERPROFILE%\Documents\OxyCapture\session_.../       (Windows)
```

## Mock mode (UI only)

```bash
flutter run -d macos --dart-define=USE_MOCK_CAPTURE=true
```
