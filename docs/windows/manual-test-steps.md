# Windows manual test steps

## Launch dialog and auto-capture

1. Launch **Oxy Capture** (`flutter run -d windows` or the Release `.exe`)
2. Confirm a **Welcome to Oxy Capture** alert dialog appears (no consent card, no setup fields)
3. Tap **Cancel** — app quits
4. Relaunch and tap **Continue** on the launch dialog
5. If screen capture is not granted, confirm a **permission required** dialog appears with **Open Privacy Settings** and **Retry**
6. Grant screen capture in **Settings → Privacy & security** if prompted
7. Tap **Retry** or relaunch — capture **starts automatically** on the primary monitor (default **15 second** interval)
8. Confirm the main window **hides to the system tray** once capture is active
9. Confirm system tray icon appears
10. Confirm JPEGs appear in `%USERPROFILE%\Documents\OxyCapture\session_*\` every ~15 seconds

## Tray controls

11. Click tray icon or choose **Open Oxy Capture** — main window opens
12. Close window while capturing — floating stop bar or tray hide (existing behavior)
13. Choose **Stop Recording** from tray — capture stops
14. Choose **Quit** from tray — app exits completely

## Completed session

15. After stopping, open from tray — **Capture completed** section shows duration, count, and **Open Folder**
16. **Open Folder** opens the session directory in File Explorer

## Error cases

17. Revoke screen capture mid-capture — error shown, capture stops cleanly
18. Deny permission at launch — permission dialog remains until granted or quit
19. Disconnect a secondary monitor mid-capture on multi-monitor setups — verify error handling

Record results in `acceptance-results.md`.
