import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Cross-platform permission management for camera and microphone
class PermissionService {
  /// Request camera and microphone permissions
  /// Returns true if both are granted, false otherwise
  static Future<bool> requestCameraAndMicrophonePermissions() async {
    if (kIsWeb) {
      // Web browsers handle permissions via getUserMedia API
      return true; // Permission dialog will appear when camera/mic is accessed
    }

    try {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

      if (!cameraGranted || !micGranted) {
        // Check if denied or permanently denied
        final cameraDenied = statuses[Permission.camera]?.isDenied ?? false;
        final micDenied = statuses[Permission.microphone]?.isDenied ?? false;
        
        if (cameraDenied || micDenied) {
          print('Camera/Microphone permission denied');
        } else {
          print('Camera/Microphone permission permanently denied');
        }
        return false;
      }

      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraGranted() async {
    if (kIsWeb) return true;
    return (await Permission.camera.status).isGranted;
  }

  /// Check if microphone permission is granted
  static Future<bool> isMicrophoneGranted() async {
    if (kIsWeb) return true;
    return (await Permission.microphone.status).isGranted;
  }

  /// Request to open app settings if permissions are denied
  static Future<void> openAppSettings() async {
    if (!kIsWeb) {
      openAppSettings();
    }
  }
}
