import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:camera/camera.dart';
import 'permission_service.dart';

/// Platform-agnostic camera service
/// Uses WebRTC on web, native camera on mobile
class CameraService {
  // Web (WebRTC)
  RTCVideoRenderer? _webRenderer;
  RTCPeerConnection? _peerConnection;
  
  // Mobile (camera plugin)
  CameraController? _mobileController;
  
  bool get isInitialized {
    if (kIsWeb) {
      return _webRenderer != null && _webRenderer!.renderVideo;
    }
    return _mobileController != null && _mobileController!.value.isInitialized;
  }
  
  /// Initialize camera based on platform
  Future<void> initialize() async {
    // Request permissions first
    final hasPermission = await PermissionService.requestCameraAndMicrophonePermissions();
    if (!hasPermission && !kIsWeb) {
      throw Exception('Camera and microphone permissions are required for live streaming');
    }

    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeMobile();
    }
  }
  
  /// Web: Initialize WebRTC with camera and microphone
  Future<void> _initializeWeb() async {
    try {
      _webRenderer = RTCVideoRenderer();
      await _webRenderer!.initialize();
      
      // Get user media (camera + audio)
      // Browser will show permission dialog here
      final mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': {
          'mandatory': {
            'minWidth': 640,
            'minHeight': 480,
            'minFrameRate': 30,
          },
          'facingMode': 'user',
          'optional': [],
        }
      };
      
      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _webRenderer!.srcObject = stream;
      
      // Create peer connection for streaming
      final configuration = {
        'iceServers': [
          {'urls': ['stun:stun.l.google.com:19302']},
          {'urls': ['stun:stun1.l.google.com:19302']},
        ]
      };
      
      _peerConnection = await createPeerConnection(configuration as Map<String, dynamic>);
      
      // Add local stream to peer connection
      stream.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, stream);
      });

      print('WebRTC initialized with camera and microphone');
    } catch (e) {
      print('WebRTC initialization error: $e');
      rethrow;
    }
  }
  
  /// Mobile: Initialize native camera with permission check
  Future<void> _initializeMobile() async {
    try {
      // Verify permissions before accessing camera
      final cameraGranted = await PermissionService.isCameraGranted();
      final micGranted = await PermissionService.isMicrophoneGranted();

      if (!cameraGranted || !micGranted) {
        throw Exception('Camera or microphone permission denied. Please enable in app settings.');
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras available on this device');
      
      _mobileController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: true,
      );
      
      await _mobileController!.initialize();
      print('Mobile camera initialized with audio enabled');
    } catch (e) {
      print('Camera initialization error: $e');
      rethrow;
    }
  }
  
  /// Get renderer widget for display
  Widget getPreview() {
    if (kIsWeb) {
      return _webRenderer != null
          ? RTCVideoView(
              _webRenderer!,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          : const Center(child: CircularProgressIndicator());
    }
    
    if (_mobileController != null && _mobileController!.value.isInitialized) {
      return CameraPreview(_mobileController!);
    }
    
    return const Center(child: CircularProgressIndicator());
  }
  
  /// Start recording
  Future<void> startRecording() async {
    try {
      if (kIsWeb) {
        // WebRTC recording would be handled by backend via WebSocket/Stream
        print('Recording started on web');
      } else {
        if (_mobileController != null && !_mobileController!.value.isRecordingVideo) {
          await _mobileController!.startVideoRecording();
          print('Video recording started on mobile');
        }
      }
    } catch (e) {
      print('Recording error: $e');
      rethrow;
    }
  }
  
  /// Stop recording and get file path
  Future<String?> stopRecording() async {
    try {
      if (kIsWeb) {
        // WebRTC recording handled by backend
        return null;
      }
      
      if (_mobileController != null && _mobileController!.value.isRecordingVideo) {
        final xFile = await _mobileController!.stopVideoRecording();
        print('Video recording stopped: ${xFile.path}');
        return xFile.path;
      }
      return null;
    } catch (e) {
      print('Stop recording error: $e');
      rethrow;
    }
  }
  
  /// Get peer connection for WebRTC streaming
  RTCPeerConnection? getPeerConnection() => _peerConnection;
  
  /// Get camera stream for WebRTC
  MediaStream? getMediaStream() => _webRenderer?.srcObject;
  
  /// Dispose resources
  Future<void> dispose() async {
    if (kIsWeb) {
      await _webRenderer?.dispose();
      await _peerConnection?.close();
    } else {
      await _mobileController?.dispose();
    }
  }
}
