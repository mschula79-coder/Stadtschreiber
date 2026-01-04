import '../config/debug.dart';

class DebugService {
  static void log(String message) {
    // ignore: avoid_print
    if (enableDebugging) print(message);
  }
}
