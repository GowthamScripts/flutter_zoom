import 'package:flutter/material.dart';
import 'package:flutter_zoom/flutter_zoom.dart';

import 'zoom_config.dart';
import 'zoom_jwt.dart';

void main() => runApp(const ZoomExampleApp());

class ZoomExampleApp extends StatelessWidget {
  const ZoomExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_zoom example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ZoomExampleHomePage(),
    );
  }
}

class ZoomExampleHomePage extends StatefulWidget {
  const ZoomExampleHomePage({super.key});

  @override
  State<ZoomExampleHomePage> createState() => _ZoomExampleHomePageState();
}

class _ZoomExampleHomePageState extends State<ZoomExampleHomePage> {
  final _zoom = Zoom();
  final _displayName = TextEditingController(text: ZoomConfig.displayName);
  final _meetingId = TextEditingController(text: ZoomConfig.meetingId);
  final _meetingPassword =
      TextEditingController(text: ZoomConfig.meetingPassword);

  String _status = 'Not initialized';
  bool _initOk = false;
  bool _busy = false;

  @override
  void dispose() {
    _displayName.dispose();
    _meetingId.dispose();
    _meetingPassword.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _busy = true;
      _initOk = false;
      _status = 'Initializing…';
    });
    try {
      final jwtToken = generateZoomJwtToken();
      final response = await _zoom.init(
        ZoomOptions(
          domain: ZoomConfig.domain,
          jwtToken: jwtToken,
        ),
      );
      final ok = response.length >= 2 && response[0] == 0 && response[1] == 0;
      setState(() {
        _busy = false;
        _initOk = ok;
        _status = 'Init response: $response';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _initOk = false;
        _status = 'Init error: $e';
      });
    }
  }

  Future<void> _join() async {
    if (!_initOk) {
      setState(() => _status = 'Please init the SDK first.');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Joining…';
    });
    try {
      final userId = _displayName.text.trim().isEmpty
          ? ZoomConfig.displayName
          : _displayName.text.trim();
      final ok = await _zoom.joinMeeting(
        ZoomMeetingOptions(
          userId: userId,
          meetingId: _meetingId.text.trim(),
          meetingPassword: _meetingPassword.text,
          disableDialIn: 'true',
          disableDrive: 'true',
          disableInvite: 'true',
          disableShare: 'false',
          noDisconnectAudio: 'false',
          noAudio: 'false',
        ),
      );
      setState(() {
        _busy = false;
        _status = ok ? 'Join requested' : 'Join failed';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _status = 'Join error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sdkKeyState = ZoomConfig.sdkKey.isEmpty ? '(missing)' : '(set)';
    final sdkSecretState = ZoomConfig.sdkSecret.isEmpty ? '(missing)' : '(set)';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('flutter_zoom example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Domain: ${ZoomConfig.domain}\nSDK Key: $sdkKeyState\nSDK Secret: $sdkSecretState',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _init,
            child: const Text('Init Zoom SDK'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _displayName,
            decoration: const InputDecoration(labelText: 'Display name'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _meetingId,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Meeting ID'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _meetingPassword,
            decoration: const InputDecoration(labelText: 'Meeting password'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (_busy || !_initOk) ? null : _join,
            child: const Text('Join Meeting'),
          ),
          const SizedBox(height: 16),
          Text(_status),
        ],
      ),
    );
  }
}
