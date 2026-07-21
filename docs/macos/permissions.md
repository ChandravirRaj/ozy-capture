# macOS permissions

**Oxy Capture** requires **Screen Recording** permission.

## Grant permission

1. Launch **Oxy Capture** from **Applications** (not an old `flutter run` build)
2. Open **System Settings → Privacy & Security → Screen Recording**
3. Enable **Oxy Capture**
4. If you already enabled it after a previous install, **turn it OFF then ON again** — each rebuild changes the app signature
5. **Quit and relaunch** the app (Cmd+Q, then open from Applications again)

## If permission is denied

The app shows guidance in the Capture setup section. Click **Refresh permission status** after changing Settings. Check the **Diagnostics** line (e.g. `preflight=true` means macOS reports access granted).

## Revocation

If permission is revoked during capture, the app receives a native event, stops capture, and shows an error.

Do not attempt to bypass macOS privacy authorization in this POC.
