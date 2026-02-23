import 'dart:core';
import 'dart:io';
import 'dart:convert';
//import 'package:dio/dio.dart';

const _androidSdkVersion = '6.6.11.35500';
const _iosSdkVersion = '6.6.10.30439';

const _androidFolder = 'zoom-sdk-android-6.6.11';
const _iosFolder = 'zoom-sdk-ios-6.6.10';

String _baseUrl() =>
    Platform.environment['GR_ZOOM_SDK_BASE_URL'] ??
    'https://your-host.example.com/zoom';

Uri _androidUri(String fileName) =>
    Uri.parse('${_baseUrl()}/android/$_androidSdkVersion/$fileName');

Uri _iosUri(String slice, String fileName) =>
    Uri.parse('${_baseUrl()}/ios/$_iosSdkVersion/$slice/$fileName');

void main(List<String> args) async {
  var location = Platform.script.toString();
  var isNewFlutter = location.contains(".snapshot");

  final appRoot = _findFlutterAppRoot();
  if (isNewFlutter && appRoot != null) {
    final packageConfigPath = '$appRoot/.dart_tool/package_config.json';
    final jsonString = File(packageConfigPath).readAsStringSync();
    final Map<String, dynamic> packages = jsonDecode(jsonString);
    final packageList = packages["packages"];

    String? zoomRootUri;
    for (final package in packageList) {
      if (package["name"] == "flutter_zoom") {
        zoomRootUri = package["rootUri"];
        break;
      }
    }
    if (zoomRootUri == null) {
      throw StateError('flutter_zoom package not found in $packageConfigPath');
    }

    final base = Uri.directory('$appRoot/.dart_tool/');
    final rootUri = Uri.parse(zoomRootUri);
    final resolved = rootUri.isAbsolute ? rootUri : base.resolveUri(rootUri);
    location = resolved.toString();
  }

  if (Platform.isWindows) {
    location = location.replaceFirst("file:///", "");
  } else {
    location = location.replaceFirst("file://", "");
  }
  if (!isNewFlutter) {
    location = location.replaceFirst("/bin/unzip_zoom_sdk.dart", "");
  }
  // var filename =
  //     location + '/ios-sdk/MobileRTC${(args.length == 0) ? "" : "-dev"}.zip';

  final usedLocal = await _tryCopyFromLocalSdk(
    pluginRoot: location,
    appRoot: appRoot,
  );
  if (!usedLocal) {
    final baseUrl = Platform.environment['GR_ZOOM_SDK_BASE_URL'];
    final baseUrlLooksConfigured = baseUrl != null && baseUrl.trim().isNotEmpty;
    if (!baseUrlLooksConfigured) {
      throw StateError(
        'Zoom SDK folders not found in the app root, and GR_ZOOM_SDK_BASE_URL is not set.\n'
        'To use flutter_zoom without hosting, place these folders in your Flutter project root:\n'
        '- $_androidFolder/\n'
        '- $_iosFolder/\n'
        '\nExpected files:\n'
        '- <appRoot>/$_androidFolder/mobilertc-android-studio/mobilertc/mobilertc.aar\n'
        '- <appRoot>/$_iosFolder/lib/MobileRTC.xcframework\n'
        '- <appRoot>/$_iosFolder/lib/MobileRTCScreenShare.xcframework\n'
        '- <appRoot>/$_iosFolder/lib/zoomcml.xcframework\n'
        '- <appRoot>/$_iosFolder/lib/MobileRTCResources.bundle\n'
        'Then re-run: flutter pub run flutter_zoom:unzip_zoom_sdk\n',
      );
    }
    await checkAndDownloadSDK(location);
  }
  // print('Decompressing ' + filename);

  // final bytes = File(filename).readAsBytesSync();

  // final archive = ZipDecoder().decodeBytes(bytes);

  // var current = new File(location + '/ios/MobileRTC.framework/MobileRTC');
  // var exist = await current.exists();
  // if (exist) current.deleteSync();

  // for (final file in archive) {
  //   final filename = file.name;
  //   if (file.isFile) {
  //     final data = file.content as List<int>;
  //     File(location + '/ios/MobileRTC.framework/' + filename)
  //       ..createSync(recursive: true)
  //       ..writeAsBytesSync(data);
  //   }
  // }

  print('Complete');
}

String? _findFlutterAppRoot() {
  // `flutter pub run flutter_zoom:unzip_zoom_sdk` should be executed from the
  // consuming app's directory (or any subdirectory). We walk upwards until we
  // find `pubspec.yaml`.
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

Future<bool> _tryCopyFromLocalSdk({
  required String pluginRoot,
  required String? appRoot,
}) async {
  if (appRoot == null || appRoot.trim().isEmpty) return false;

  final iosLibDir = Directory('$appRoot/$_iosFolder/lib');
  final androidAarFile = File(
    '$appRoot/$_androidFolder/mobilertc-android-studio/mobilertc/mobilertc.aar',
  );

  if (!iosLibDir.existsSync() || !androidAarFile.existsSync()) return false;

  print('Using local Zoom SDK folders from app root: $appRoot');

  // iOS: replace entire frameworks/resources.
  await _replaceDir(
    src: '${iosLibDir.path}/MobileRTC.xcframework',
    dest: '$pluginRoot/ios/MobileRTC.xcframework',
  );
  await _replaceDir(
    src: '${iosLibDir.path}/MobileRTCScreenShare.xcframework',
    dest: '$pluginRoot/ios/MobileRTCScreenShare.xcframework',
  );
  await _replaceDir(
    src: '${iosLibDir.path}/zoomcml.xcframework',
    dest: '$pluginRoot/ios/zoomcml.xcframework',
  );
  await _replaceDir(
    src: '${iosLibDir.path}/MobileRTCResources.bundle',
    dest: '$pluginRoot/ios/MobileRTCResources.bundle',
  );

  // Android: ensure libs dir exists and copy mobilertc.aar.
  final androidLibsDir = Directory('$pluginRoot/android/libs');
  if (!androidLibsDir.existsSync()) {
    androidLibsDir.createSync(recursive: true);
  }
  await androidAarFile.copy('$pluginRoot/android/libs/mobilertc.aar');

  return true;
}

Future<void> _replaceDir({required String src, required String dest}) async {
  final srcDir = Directory(src);
  if (!srcDir.existsSync()) {
    throw StateError('Missing source directory: $src');
  }
  final destDir = Directory(dest);
  if (destDir.existsSync()) {
    await destDir.delete(recursive: true);
  }
  await _copyDirectory(srcDir, destDir);
}

Future<void> _copyDirectory(Directory src, Directory dest) async {
  await dest.create(recursive: true);
  await for (final entity in src.list(recursive: false, followLinks: false)) {
    final name = entity.uri.pathSegments.last;
    if (entity is Directory) {
      await _copyDirectory(entity, Directory('${dest.path}/$name'));
    } else if (entity is File) {
      await entity.copy('${dest.path}/$name');
    } else if (entity is Link) {
      // Best-effort: recreate symlink (rare in these SDK bundles).
      final target = await entity.target();
      await Link('${dest.path}/$name').create(target);
    }
  }
}

Future<void> checkAndDownloadSDK(String location) async {
  // iOS: Download the binary files inside XCFrameworks (device + simulator).
  final iosTargets = <_DownloadTarget>[
    // MobileRTC
    _DownloadTarget(
      url: _iosUri('ios-arm64', 'MobileRTC'),
      path: '$location/ios/MobileRTC.xcframework/ios-arm64/MobileRTC.framework/MobileRTC',
    ),
    _DownloadTarget(
      url: _iosUri('ios-arm64_x86_64-simulator', 'MobileRTC'),
      path: '$location/ios/MobileRTC.xcframework/ios-arm64_x86_64-simulator/MobileRTC.framework/MobileRTC',
    ),
    // MobileRTCScreenShare
    _DownloadTarget(
      url: _iosUri('ios-arm64', 'MobileRTCScreenShare'),
      path: '$location/ios/MobileRTCScreenShare.xcframework/ios-arm64/MobileRTCScreenShare.framework/MobileRTCScreenShare',
    ),
    _DownloadTarget(
      url: _iosUri('ios-arm64_x86_64-simulator', 'MobileRTCScreenShare'),
      path: '$location/ios/MobileRTCScreenShare.xcframework/ios-arm64_x86_64-simulator/MobileRTCScreenShare.framework/MobileRTCScreenShare',
    ),
    // zoomcml
    _DownloadTarget(
      url: _iosUri('ios-arm64', 'zoomcml'),
      path: '$location/ios/zoomcml.xcframework/ios-arm64/zoomcml.framework/zoomcml',
    ),
    _DownloadTarget(
      url: _iosUri('ios-arm64_x86_64-simulator', 'zoomcml'),
      path: '$location/ios/zoomcml.xcframework/ios-arm64_x86_64-simulator/zoomcml.framework/zoomcml',
    ),
  ];

  for (final target in iosTargets) {
    await _downloadIfMissing(target);
  }

  // Android: Download only mobilertc.aar (commonlib is removed in 6.x).
  final androidRTCLibFile = '$location/android/libs/mobilertc.aar';
  await _downloadIfMissing(_DownloadTarget(
    url: _androidUri('mobilertc.aar'),
    path: androidRTCLibFile,
  ));
}

class _DownloadTarget {
  final Uri url;
  final String path;

  const _DownloadTarget({required this.url, required this.path});
}

Future<void> _downloadIfMissing(_DownloadTarget target) async {
  final exists = await File(target.path).exists();
  if (exists) return;
  await downloadFile(target.url, target.path);
}

Future<void> downloadFile(Uri uri, String savePath) async {
  print('Download ${uri.toString()} to $savePath');
  File destinationFile = await File(savePath).create(recursive: true);
  // var dio = Dio();
  // dio.options.connectTimeout = 1000000;
  // dio.options.receiveTimeout = 1000000;
  // dio.options.sendTimeout = 1000000;
  // await dio.downloadUri(uri, savePath);
  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  await response.pipe(destinationFile.openWrite());
}
