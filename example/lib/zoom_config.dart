class ZoomConfig {
  static const domain = String.fromEnvironment(
    'ZOOM_DOMAIN',
    defaultValue: 'zoom.us',
  );

  static const sdkKey = String.fromEnvironment('ZOOM_SDK_KEY');
  static const sdkSecret = String.fromEnvironment('ZOOM_SDK_SECRET');

  static const meetingId = String.fromEnvironment('ZOOM_MEETING_ID');
  static const meetingPassword =
      String.fromEnvironment('ZOOM_MEETING_PASSWORD');
  static const displayName = String.fromEnvironment(
    'ZOOM_DISPLAY_NAME',
    defaultValue: 'Flutter User',
  );
}

