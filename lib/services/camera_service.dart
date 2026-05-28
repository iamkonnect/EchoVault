import 'dart:async';
import 'dart:html' as html;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'permission_service.dart';

/// Platform-agnostic camera service.
///
/// Web: uses `getUserMedia` and renders a real HTML <video> element.
/// Mobile: uses the `camera` plugin.
class CameraService {
  // Mobile (camera plugin)
  CameraController? _mobileController;

  // Web (getUserMedia)
  html.VideoElement? _webVideo;
  html.MediaStream? _webStream;
  html.DivElement? _hostDiv;

  bool get isInitialized {
    if (kIsWeb) return _webStream != null;
    return _mobileController != null && _mobileController!.value.isInitialized;
  }

  Future<void> initialize() async {
    final hasPermission =
        await PermissionService.requestCameraAndMicrophonePermissions();

    if (!hasPermission && !kIsWeb) {
      throw Exception(
          'Camera and microphone permissions are required for live streaming');
    }

    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeMobile();
    }
  }

  Future<void> _initializeMobile() async {
    final cameraGranted = await PermissionService.isCameraGranted();
    final micGranted = await PermissionService.isMicrophoneGranted();

    if (!cameraGranted || !micGranted) {
      throw Exception(
          'Camera or microphone permission denied. Please enable in app settings.');
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available on this device');
    }

    _mobileController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _mobileController!.initialize();
  }

  Future<void> _initializeWeb() async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw Exception('MediaDevices API not available in this browser.');
    }

    final stream = await mediaDevices.getUserMedia(<String, dynamic>{
      'video': true,
      'audio': true,
    });

    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..controls = false
      ..srcObject = stream
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    await video.play();

    _webVideo = video;
    _webStream = stream;
  }

  /// Preview widget.
  ///
  /// On web we return a widget that hosts a DOM container. The <video>
  /// element created in `_initializeWeb()` is appended into that container.
  Widget getPreview() {
    if (!kIsWeb) {
      if (_mobileController != null && _mobileController!.value.isInitialized) {
        return CameraPreview(_mobileController!);
      }
      return const Center(
          child: SizedBox(width: 40, height: 40, child: Placeholder()));
    }

    if (_webVideo == null || _webStream == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.purple),
      );
    }

    // Re-create hostDiv lazily.
    _hostDiv ??= html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#000000';

    // Ensure the latest video element is attached.
    if (_webVideo != null && _webVideo!.parent != _hostDiv) {
      _hostDiv!.children.clear();
      _hostDiv!.append(_webVideo!);
    }

    // Html element widgets are not supported uniformly across Flutter versions
    // without platform-view registry. However, appending the DOM into the
    // current document body works when Flutter web is configured with
    // `ui.platformViewRegistry`.
    //
    // To avoid that mismatch, we use a Web-only fallback: we overlay the video
    // element absolutely on top of the widget using `IgnorePointer`.

    // Attach the host div to body once so the browser paints it.
    if (_hostDiv != null && !_hostDiv!.isConnected) {
      _hostDiv!.style.position = 'absolute';
      _hostDiv!.style.left = '0';
      _hostDiv!.style.top = '0';
      _hostDiv!.style.zIndex = '0';
      html.document.body?.append(_hostDiv!);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // This widget only provides layout bounds; the actual <video>
        // is drawn by the attached DOM.
        Container(color: Colors.black),
        const IgnorePointer(),
      ],
    );
  }

  Future<void> startRecording() async {
    if (!kIsWeb) {
      if (_mobileController != null &&
          !_mobileController!.value.isRecordingVideo) {
        await _mobileController!.startVideoRecording();
      }
      return;
    }

    if (_webStream == null || _webVideo == null) {
      await _initializeWeb();
    }
  }

  Future<String?> stopRecording() async {
    if (!kIsWeb) {
      if (_mobileController != null &&
          _mobileController!.value.isRecordingVideo) {
        final xFile = await _mobileController!.stopVideoRecording();
        return xFile.path;
      }
      return null;
    }

    final stream = _webStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }

    _webStream = null;
    _webVideo = null;

    return null;
  }

  Future<void> dispose() async {
    if (!kIsWeb) {
      await _mobileController?.dispose();
      _mobileController = null;
      return;
    }

    final stream = _webStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }

    _webStream = null;
    _webVideo = null;

    if (_hostDiv != null) {
      _hostDiv!.remove();
      _hostDiv = null;
    }
  }
}
