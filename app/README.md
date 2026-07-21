# Oxy Capture (app)

Flutter desktop app for the Oxy Capture screenshot POC. Uses the shared **launch-dialog flow** on all desktop platforms (welcome dialog → permission → auto-capture → tray).

See the [repository README](../README.md) for an overview and [../docs/README.md](../docs/README.md) for build, permissions, and testing.

```bash
cd app
flutter pub get
flutter run -d macos
```

Install as a normal Mac app (Launchpad / Applications):

```bash
../scripts/install-macos.sh
```
