import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zoom/flutter_zoom.dart';

void main() {
  const MethodChannel channel = MethodChannel('plugins.webcare/zoom_channel');

  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async => '42',
    );
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    Zoom zoomPlugin = Zoom();
    expect(await zoomPlugin.getPlatformVersion(), '42');
  });
}
