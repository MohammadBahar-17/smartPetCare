import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../widgets/camera_preview.dart';
import '../widgets/mock_camera_preview.dart';
import '../widgets/optimized_camera_preview.dart';

class SmartCameraWidget extends StatelessWidget {
  const SmartCameraWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppConfig.useMockCamera) {
      return const MockCameraPreview();
    } else if (AppConfig.useOptimizedCamera) {
      return const OptimizedCameraPreview();
    } else {
      return const CameraPreviewWidget();
    }
  }
}
