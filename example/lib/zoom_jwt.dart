import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'zoom_config.dart';

String generateZoomJwtToken({
  DateTime? now,
  Duration expiresIn = const Duration(minutes: 60),
}) {
  final sdkKey = ZoomConfig.sdkKey;
  final sdkSecret = ZoomConfig.sdkSecret;

  if (sdkKey.isEmpty || sdkSecret.isEmpty) {
    throw StateError(
      'Missing Zoom credentials. Pass --dart-define=ZOOM_SDK_KEY=... and --dart-define=ZOOM_SDK_SECRET=...',
    );
  }

  final iat = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  final exp = iat + expiresIn.inSeconds;

  final jwt = JWT(
    <String, dynamic>{
      'appKey': sdkKey,
      'iat': iat,
      'exp': exp,
      'tokenExp': exp,
    },
  );

  return jwt.sign(SecretKey(sdkSecret), algorithm: JWTAlgorithm.HS256);
}

