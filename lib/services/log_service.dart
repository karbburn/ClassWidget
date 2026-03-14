import 'package:flutter/foundation.dart';

class LogService {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final String timestamp = DateTime.now().toIso8601String();
      final String tagStr = tag != null ? '[$tag] ' : '';
      print('$timestamp: $tagStr$message');
    }
  }

  static void info(String message) {
    log(message, tag: 'INFO');
  }

  static void warning(String message) {
    log(message, tag: 'WARNING');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('ERROR: $message');
      if (error != null) print('Details: $error');
      if (stackTrace != null) print(stackTrace);
    }
  }
}
