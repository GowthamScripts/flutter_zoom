import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zoom/flutter_zoom.dart';

void main() {
  const MethodChannel channel = MethodChannel('plugins.webcare/zoom_channel');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    Zoom grZoomPlugin = Zoom();
    expect(await grZoomPlugin.getPlatformVersion(), '42');
  });
}