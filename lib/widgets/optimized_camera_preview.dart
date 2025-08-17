import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';

class OptimizedCameraPreview extends StatefulWidget {
  const OptimizedCameraPreview({super.key});

  @override
  State<OptimizedCameraPreview> createState() => _OptimizedCameraPreviewState();
}

class _OptimizedCameraPreviewState extends State<OptimizedCameraPreview>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isDisposed = false;
  Timer? _bufferLimitTimer;
  int _frameCount = 0;
  static const int _maxFramesPerSecond = 15; // Limit to reduce buffer issues

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
    _bufferLimitTimer?.cancel();
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
        ResolutionPreset.medium, // Lower resolution to reduce buffer load
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: false, // Disable audio to reduce resource usage
      );

      await _cameraController!.initialize();
      
      if (_isDisposed) {
        await _cameraController!.dispose();
        return;
      }

      // Set up frame rate limiting
      _setupFrameRateLimiting();

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

  void _setupFrameRateLimiting() {
    // Timer to reset frame count every second
    _bufferLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _frameCount = 0;
    });
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
    _bufferLimitTimer?.cancel();
    _bufferLimitTimer = null;
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
            // Use a custom wrapper to limit frame updates
            _FrameLimitedCameraPreview(
              controller: _cameraController!,
              onFrameUpdate: () {
                _frameCount++;
                return _frameCount <= _maxFramesPerSecond;
              },
            ),
            // Overlay with recording indicator
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      'LIVE',
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
          colors: [
            Colors.grey[300]!,
            Colors.grey[400]!,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Camera Initializing...',
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

class _FrameLimitedCameraPreview extends StatefulWidget {
  final CameraController controller;
  final bool Function() onFrameUpdate;

  const _FrameLimitedCameraPreview({
    required this.controller,
    required this.onFrameUpdate,
  });

  @override
  State<_FrameLimitedCameraPreview> createState() => _FrameLimitedCameraPreviewState();
}

class _FrameLimitedCameraPreviewState extends State<_FrameLimitedCameraPreview> {
  @override
  Widget build(BuildContext context) {
    // Only show camera preview if frame limit not exceeded
    if (!widget.onFrameUpdate()) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.videocam,
            color: Colors.white54,
            size: 32,
          ),
        ),
      );
    }

    return CameraPreview(widget.controller);
  }
}
