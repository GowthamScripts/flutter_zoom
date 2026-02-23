import 'dart:core';
import 'dart:io';
import 'dart:convert';
//import 'package:dio/dio.dart';

const _androidFolderPrefix = 'zoom-sdk-android-';
const _iosFolderPrefix = 'zoom-sdk-ios-';
const _supportedMajor = 6;
const _supportedMinor = 6;

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
    throw StateError(
      'Zoom SDK folders not found in the app root.\n'
      '\nTo use flutter_zoom, place these folders in your Flutter project root:\n'
      '- ${_androidFolderPrefix}$_supportedMajor.$_supportedMinor.x*/\n'
      '- ${_iosFolderPrefix}$_supportedMajor.$_supportedMinor.x*/\n'
      '\nExpected files:\n'
      '- <appRoot>/${_androidFolderPrefix}$_supportedMajor.$_supportedMinor.x*/mobilertc-android-studio/mobilertc/mobilertc.aar\n'
      '- <appRoot>/${_iosFolderPrefix}$_supportedMajor.$_supportedMinor.x*/lib/MobileRTC.xcframework\n'
      '- <appRoot>/${_iosFolderPrefix}$_supportedMajor.$_supportedMinor.x*/lib/MobileRTCScreenShare.xcframework\n'
      '- <appRoot>/${_iosFolderPrefix}$_supportedMajor.$_supportedMinor.x*/lib/zoomcml.xcframework\n'
      '- <appRoot>/${_iosFolderPrefix}$_supportedMajor.$_supportedMinor.x*/lib/MobileRTCResources.bundle\n'
      '\nThen re-run:\n'
      'flutter pub run flutter_zoom:unzip_zoom_sdk\n',
    );
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

  final androidSdk = _findLatestSdkFolder(appRoot, _androidFolderPrefix);
  final iosSdk = _findLatestSdkFolder(appRoot, _iosFolderPrefix);
  if (androidSdk == null || iosSdk == null) return false;

  final iosLibDir = Directory('${iosSdk.path}/lib');
  final androidAarFile = File(
      '${androidSdk.path}/mobilertc-android-studio/mobilertc/mobilertc.aar');

  if (!iosLibDir.existsSync() || !androidAarFile.existsSync()) return false;

  print('Using local Zoom SDK folders from app root: $appRoot');
  print('Android SDK folder: ${androidSdk.name}');
  print('iOS SDK folder: ${iosSdk.name}');

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

class _SdkFolder {
  final String name;
  final String path;
  final List<int> versionParts;

  const _SdkFolder({
    required this.name,
    required this.path,
    required this.versionParts,
  });
}

_SdkFolder? _findLatestSdkFolder(String appRoot, String prefix) {
  final dir = Directory(appRoot);
  if (!dir.existsSync()) return null;

  _SdkFolder? best;

  for (final entity in dir.listSync(followLinks: false)) {
    final name = entity.path.split(Platform.pathSeparator).last;

    if (!name.startsWith(prefix)) continue;

    final versionStr = name.substring(prefix.length);
    final parts = _parseVersionParts(versionStr);
    if (parts == null) continue;
    if (parts.length < 2 ||
        parts[0] != _supportedMajor ||
        parts[1] != _supportedMinor) {
      continue;
    }

    final path = '${dir.path}/$name';
    if (!FileSystemEntity.isDirectorySync(path)) continue;

    final candidate = _SdkFolder(name: name, path: path, versionParts: parts);
    if (best == null ||
        _compareVersions(candidate.versionParts, best.versionParts) > 0) {
      best = candidate;
    }
  }

  return best;
}

List<int>? _parseVersionParts(String versionStr) {
  final raw = versionStr.split('.');
  if (raw.isEmpty) return null;
  final parts = <int>[];
  for (final p in raw) {
    final v = int.tryParse(p);
    if (v == null) return null;
    parts.add(v);
  }
  return parts;
}

int _compareVersions(List<int> a, List<int> b) {
  // Compare lexicographically, padding to 4 components (major.minor.patch.build).
  final aa = List<int>.from(a);
  final bb = List<int>.from(b);
  while (aa.length < 4) aa.add(0);
  while (bb.length < 4) bb.add(0);
  for (var i = 0; i < 4; i++) {
    if (aa[i] != bb[i]) return aa[i].compareTo(bb[i]);
  }
  return 0;
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
