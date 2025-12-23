class AppConstants {
  // App Info
  static const String appName = 'SmartPetCare';
  static const String appVersion = '1.0.0';

  // Firebase Paths (DO NOT CHANGE)
  static const String feedingSensorsPath = 'feeding/sensors';
  static const String feedingMealsPath = 'feeding/meals';
  static const String feedingCommandsPath = 'feeding/commands';
  static const String profilesPath = 'profiles';
  static const String waterSensorsPath = 'water/sensors';
  static const String waterStatusPath = 'water/status';
  static const String waterAlertsPath = 'water/alerts';
  static const String waterControlsPath = 'water/controls';
  static const String entertainmentCommandsPath = 'entertainment/commands';
  static const String logsCommandsPath = 'logs/commands';
  static const String logsAlertsPath = 'logs/alerts';

  // Thresholds
  static const int lowFoodThreshold = 20;
  static const int criticalFoodThreshold = 10;
  static const int lowWaterThreshold = 30;
  static const int criticalWaterThreshold = 10;

  // Animals
  static const String cat = 'cat';
  static const String dog = 'dog';

  // Icons
  static const Map<String, String> animalEmojis = {
    'cat': '🐱',
    'dog': '🐕',
  };
}
