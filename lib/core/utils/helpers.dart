class Helpers {
  /// Format time with leading zeros (e.g., 08:05)
  static String formatTime(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Format timestamp to readable date
  static String formatTimestamp(dynamic ts) {
    if (ts is int) {
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} "
          "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }
    return "-";
  }

  /// Get animal emoji
  static String getAnimalEmoji(String animal) {
    switch (animal.toLowerCase()) {
      case 'cat':
        return '🐱';
      case 'dog':
        return '🐕';
      default:
        return '🐾';
    }
  }

  /// Get severity emoji
  static String getSeverityEmoji(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟠';
      case 'low':
      default:
        return '🟢';
    }
  }
}
