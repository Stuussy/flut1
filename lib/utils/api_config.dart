import 'package:flutter/foundation.dart';

/// Returns the correct base URL depending on the runtime platform.
///
/// - Web (Chrome/browser) → http://localhost:3001
/// - Android emulator     → http://10.0.2.2:3001  (host machine loopback)
/// - iOS simulator        → http://localhost:3001  (simulator shares host network)
/// - Real Android/iOS     → change [_deviceServerIP] to your router IP
class ApiConfig {
  /// Change this to your machine's local IP address when testing on a real device.
  /// Example: '192.168.1.42'
  static const String _deviceServerIP = '192.168.1.100';

  static const int _port = 3001;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_port';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator uses 10.0.2.2 to reach the host machine
      return 'http://10.0.2.2:$_port';
    }
    // iOS simulator and desktop share the host network
    return 'http://localhost:$_port';
  }

  /// Base URL for real physical devices (not emulator/simulator).
  /// Use this when deploying to a real phone connected to the same Wi-Fi.
  static String get deviceBaseUrl => 'http://$_deviceServerIP:$_port';
}
