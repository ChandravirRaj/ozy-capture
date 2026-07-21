# macOS build

## Prerequisites

- Flutter 3.x stable
- Xcode 15+
- macOS 13+ (macOS 14+ recommended for `SCScreenshotManager`)

## Build

```bash
cd app
flutter pub get
flutter build macos
```

## Run

```bash
flutter run -d macos
```

## Native APIs

- ScreenCaptureKit (`SCShareableContent`, `SCContentFilter`, `SCScreenshotManager`, `SCStream`)
- Core Graphics screen recording permission (`CGPreflightScreenCaptureAccess`)
- ImageIO JPEG/PNG encoding

## SDK

- macOS deployment target: 13.0
- Swift 5
