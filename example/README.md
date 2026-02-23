# flutter_zoom example

This is a minimal example app showing how to initialize the Zoom SDK using a JWT (generated locally) and then join a meeting.

## 1) Place Zoom SDK folders (no host)

In this `example/` folder (same folder as this `README.md`), place:

- `zoom-sdk-android-6.6.*`
- `zoom-sdk-ios-6.6.*`

Then run:

```bash
flutter pub run flutter_zoom:unzip_zoom_sdk
```

## 2) Run the app with `--dart-define`

```bash
flutter run \
  --dart-define=ZOOM_SDK_KEY=YOUR_KEY \
  --dart-define=ZOOM_SDK_SECRET=YOUR_SECRET
```

Optional defines:

- `ZOOM_DOMAIN` (default: `zoom.us`)
- `ZOOM_DISPLAY_NAME`
- `ZOOM_MEETING_ID`
- `ZOOM_MEETING_PASSWORD`

# flutter_zoom_example

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
