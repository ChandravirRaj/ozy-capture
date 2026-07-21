# Linux manual test steps

## Prerequisites

- Install tray support if needed: `libayatana-appindicator3-1` (or equivalent for your distro)
- **Note:** Linux native screen capture is not fully implemented in this POC. The launch dialog and tray flow match macOS/Windows, but permission checks and capture may fail until the Linux backend is added.

## Launch dialog and auto-capture

1. Launch **Oxy Capture** (`flutter run -d linux`)
2. Confirm a **Welcome to Oxy Capture** alert dialog appears (no consent card, no setup fields)
3. Tap **Cancel** — app quits
4. Relaunch and tap **Continue** on the launch dialog
5. If screen capture is not granted, confirm a **permission required** dialog appears with **Retry** and **Quit** (no settings button on Linux)
6. On Wayland, grant the portal prompt if it appears
7. Tap **Retry** or relaunch — if capture backend is available, capture **starts automatically** on the primary monitor (default **15 second** interval)
8. Confirm the main window **hides to the system tray** once capture is active
9. Confirm system tray icon appears (if libayatana-appindicator is installed)
10. If capture succeeds, confirm JPEGs appear in `~/Documents/OxyCapture/session_*/` every ~15 seconds

## Tray controls

11. Click tray icon or choose **Open Oxy Capture** — main window opens
12. Close window while capturing — floating stop bar or tray hide (existing behavior)
13. Choose **Stop Recording** from tray — capture stops
14. Choose **Quit** from tray — app exits completely

## Completed session

15. After stopping, open from tray — **Capture completed** section shows duration, count, and **Open Folder**
16. **Open Folder** opens the session directory in the file manager

## Error cases

17. With stub backend, expect permission or capture errors in the UI — app should not crash
18. Deny permission at launch — permission dialog remains until granted or quit

Record results in `acceptance-results.md`.
