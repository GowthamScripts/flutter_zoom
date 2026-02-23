# flutter_zoom
A Flutter plugin for the Zoom Client SDK.

## Zoom SDK Versions

Android: zoom-sdk-android-6.6.11 (tested)
 
iOS: zoom-sdk-ios-6.6.10 (tested)

## Installation from pub.dev
https://pub.dev/packages/flutter_zoom

After install the library, must run the follow script to get some sdk stuff for the first time:
```shell script
flutter pub run flutter_zoom:unzip_zoom_sdk
```

This script copies the proprietary Zoom binaries (which are intentionally not committed to source control) from SDK folders you place in your app root.

### No-host setup (recommended)

1. Download the Zoom Meeting SDKs from Zoom.
2. In your **Flutter app root** (the folder containing `pubspec.yaml`), place the extracted SDK folders using this naming pattern:

- `zoom-sdk-android-6.6.*` (example: `zoom-sdk-android-6.6.11.35500/` or `zoom-sdk-android-6.6.11/`)
- `zoom-sdk-ios-6.6.*` (example: `zoom-sdk-ios-6.6.10.30439/` or `zoom-sdk-ios-6.6.10/`)

If multiple `6.6.*` folders exist, the script picks the newest one.

The script expects these files inside the folders:

- Android:
  - `zoom-sdk-android-6.6.*/mobilertc-android-studio/mobilertc/mobilertc.aar`
- iOS:
  - `zoom-sdk-ios-6.6.*/lib/MobileRTC.xcframework`
  - `zoom-sdk-ios-6.6.*/lib/MobileRTCScreenShare.xcframework`
  - `zoom-sdk-ios-6.6.*/lib/zoomcml.xcframework`
  - `zoom-sdk-ios-6.6.*/lib/MobileRTCResources.bundle`

3. Run:

```shell script
flutter pub run flutter_zoom:unzip_zoom_sdk
```

This copies the required binaries into the `flutter_zoom` package (in your `.pub-cache` or local path dependency), under `android/libs/` and `ios/`.

## Installation from github

```yaml
  flutter_zoom:
    git:
      url: <your-repo-url>
      ref: main
```
After install the library, must run the follow script to get some sdk stuff for the first time:
```shell script
flutter pub run flutter_zoom:unzip_zoom_sdk
```

### iOS

Add two rows to the `ios/Runner/Info.plist`:

- one with the key `Privacy - Camera Usage Description` and a usage description.
- and one with the key `Privacy - Microphone Usage Description` and a usage description.

Or in text format add the key:

```xml
<key>NSCameraUsageDescription</key>
<string>Need to use the camera for call</string>
<key>NSMicrophoneUsageDescription</key>
<string>Need to use the microphone for call</string>
```


Update your app to iOS 16+ and ensure your Podfile post_install does not exclude `arm64` for simulator builds (the XCFramework includes arm64 simulator slices).

Example `ios/Podfile` `post_install`:

```
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

**NOTE for testing on the iOS simulator**

If you want to use the iOS Simulator to test your app, you will need to ensure you have the iOS Dev Zoom SDK as a dependency. 

To use the Dev Zoom SDK, run the following
```shell script
flutter pub run flutter_zoom:unzip_zoom_sdk dev
```
    
To switch back to the normal Zoom SDK, simply run

```shell script
flutter pub run flutter_zoom:unzip_zoom_sdk
```

### Android

Change the minimum Android SDK version to at least 28 in your `android/app/build.gradle` file.

```
minSdkVersion 28
```

Disable shrinkResources for release buid
```
   buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig signingConfigs.debug
            shrinkResources false 
            minifyEnabled false
        }
    }
```

## example
- Auth zoom with "SDK App JWT Token"
  - Create SDK App JWT Token
    - Create SDK Key&Secret https://marketplace.zoom.us/docs/sdk/native-sdks/auth#key-secret-2
    - Generate JWT Token from https://jwt.io/ for testing. （Get it from your server for distribution，You can get current timestamp from https://www.unixtimestamp.com/. ）   
      Replace "PAYLOAD" as bellow, Enter your "SDK Secret" in "your-256-bit-secret",Get  "your jwtToken" from the left. 
      
      ```
      {
        "appKey": "string", // Your SDK key
        "iat": long, // access token issue timestamp
        "exp": long, // access token expire timestamp (The exp should be later than or equal to tokenExp)
        "tokenExp": long // should be a timestamp that is at least 30 minutes later than the iat)
      }
      ```
      PAYLOAD Example：  
      ```
      {
        "appKey": "xxxxxxxxxxxxxxxxxxxx", 
        "iat": 1615510799, 
        "exp": 1647017999, 
        "tokenExp": 1647017999 
      }
      ```
  - Use `ZoomOptions(jwtToken: "...")` in your app. `appKey`/`appSecret` are no longer passed to native code in SDK 6.x.

## Google Play: 16KB page size compatibility (Android 15+)

Google Play requires updates targeting Android 15+ (targetSdk 35) to support 16KB memory page sizes. This is determined by **native `.so` ELF segment alignment** inside your APK/AAB/AAR.

To pre-check your artifacts locally:

```shell script
# Check the Zoom AAR we ship inside the plugin
python3 tool/check_16kb_page_size.py android/libs/mobilertc.aar

# Check your app bundle/APK before uploading to Play
python3 tool/check_16kb_page_size.py path/to/app-release.aab
```

By default the checker validates only `arm64-v8a` and `x86_64`. To check all ABIs, run with `CHECK_ALL_ABIS=1`.
      



# reference
<your-repo-url>
