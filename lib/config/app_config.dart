class AppConfig {
  // Development flags
  static const bool useMockCamera = true; // Use mock camera to avoid buffer issues
  static const bool useOptimizedCamera = false; // Disable optimized camera for now
  static const bool enableDebugMode = true;
  static const bool showPerformanceOverlay = false;
  
  // Camera settings
  static const int maxCameraBuffers = 2; // Reduce buffer to prevent overflow
  
  // App settings
  static const String appName = 'Smart Pet Care';
  static const String appVersion = '1.0.0';
  
  // Feature flags
  static const bool enableAIChat = true;
  static const bool enableNotifications = true;
}
