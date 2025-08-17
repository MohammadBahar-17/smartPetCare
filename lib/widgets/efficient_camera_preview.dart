import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';

class EfficientCameraPreview extends StatefulWidget {
  const EfficientCameraPreview({super.key});

  @override
  State<EfficientCameraPreview> createState() => _EfficientCameraPreviewState();
}

class _EfficientCameraPreviewState extends State<EfficientCameraPreview>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isDisposed = false;
  Timer? _frameSkipTimer;
  static const int _skipFramesCount = 3; // Skip 3 out of 4 frames

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _frameSkipTimer?.cancel();
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;

    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
          });
        }
        return;
      }

      // Find back camera first, then front camera
      CameraDescription? selectedCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }
      selectedCamera ??= _cameras!.first;

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.low, // Use lowest resolution to reduce buffer load
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: false, // Disable audio completely
      );

      await _cameraController!.initialize();

      if (_isDisposed) {
        await _cameraController!.dispose();
        return;
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      try {
        await _cameraController!.dispose();
      } catch (e) {
        debugPrint('Error disposing camera: $e');
      } finally {
        _cameraController = null;
      }
    }
    _frameSkipTimer?.cancel();
    _frameSkipTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return _buildCameraPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: _cameraController!.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Throttled camera preview
            _ThrottledCameraPreview(
              controller: _cameraController!,
              skipFrames: _skipFramesCount,
            ),
            // Overlay with recording indicator
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ECO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[300]!, Colors.grey[400]!],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Camera Loading...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThrottledCameraPreview extends StatefulWidget {
  final CameraController controller;
  final int skipFrames;

  const _ThrottledCameraPreview({
    required this.controller,
    required this.skipFrames,
  });

  @override
  State<_ThrottledCameraPreview> createState() =>
      _ThrottledCameraPreviewState();
}

class _ThrottledCameraPreviewState extends State<_ThrottledCameraPreview> {
  int _frameCount = 0;
  Widget? _lastFrame;

  @override
  Widget build(BuildContext context) {
    // Skip frames to reduce buffer pressure
    _frameCount++;
    if (_frameCount <= widget.skipFrames) {
      // Return cached frame or black screen
      return _lastFrame ?? Container(color: Colors.black);
    }

    // Reset counter and show new frame
    _frameCount = 0;
    _lastFrame = CameraPreview(widget.controller);
    return _lastFrame!;
  }
}
