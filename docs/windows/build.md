# Windows build

## Prerequisites

- Flutter 3.x stable
- Visual Studio 2022 with **Desktop development with C++**
- Windows 10 version 2004 (build 19041) or later / Windows 11
- Windows 10/11 SDK with C++/WinRT support

## Build & run

```bash
cd app
flutter pub get
flutter run -d windows
```

Release build:

```bash
flutter build windows --release
```

Output executable:

```text
build/windows/x64/runner/Release/oxy_capture.exe
```

## Native capture API

The Windows plugin uses **Windows Graphics Capture (WGC)**:

- `GraphicsCaptureItem::CreateForMonitor`
- `Direct3D11CaptureFramePool`
- WIC JPEG/PNG encoding

Method channel: `dev.oxy.screen_capture/desktop_screenshot_capture`  
Event channel: `dev.oxy.screen_capture/events`

## Permission / capability

Windows does not use macOS-style Screen Recording TCC. The plugin probes WGC support on the primary monitor and returns `granted` when capture can start. If capture fails, use **Open Privacy Settings** in the app or check **Settings → Privacy & security** on Windows 11.

## Output location

```text
%USERPROFILE%\Documents\OxyCapture\session_YYYY-MM-DD_HH-mm-ss\
  screenshot_YYYY-MM-DD_HH-mm-ss-SSS.jpg
```

## Mock mode (UI only)

```bash
flutter run -d windows --dart-define=USE_MOCK_CAPTURE=true
```

See `manual-test-steps.md` for the full end-to-end checklist.
