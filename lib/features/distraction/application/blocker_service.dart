import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final blockerServiceProvider = Provider<BlockerService>((ref) {
  return BlockerService();
});

class BlockerService {
  static const MethodChannel _channel = MethodChannel('com.smartcontent/blocker');

  /// Syncs the list of blocked package IDs to the Native Android Accessibility Service
  Future<void> syncBlockedApps(List<String> packages) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('syncBlockedApps', {'packages': packages});
    } on PlatformException catch (e) {
      print("Failed to sync blocked apps: '${e.message}'.");
    }
  }

  /// Checks if the Accessibility Service is currently enabled in Android Settings
  Future<bool> isAccessibilityEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool result = await _channel.invokeMethod('isAccessibilityEnabled');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check accessibility status: '${e.message}'.");
      return false;
    }
  }

  /// Opens the Android Accessibility Settings screen so the user can enable the service
  Future<void> openAccessibilitySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print("Failed to open accessibility settings: '${e.message}'.");
    }
  }
}
