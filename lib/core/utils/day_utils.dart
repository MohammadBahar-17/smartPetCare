class DayUtils {
  /// ترتيب الأيام نفس ترتيب الـ RTC / ESP:
  /// 0 = sun, 1 = mon, ... 6 = sat
  static const List<String> dayKeys = [
    "sun",
    "mon",
    "tue",
    "wed",
    "thu",
    "fri",
    "sat",
  ];

  static const List<String> dayShortLabels = [
    "Su",
    "Mo",
    "Tu",
    "We",
    "Th",
    "Fr",
    "Sa",
  ];

  /// يحول `List<int>` -> "sun,mon,wed" أو "all"
  static String encodeDays(List<int> days) {
    if (days.length == 7) return "all";
    final mapped = days.map((i) => dayKeys[i]).toList();
    return mapped.join(",");
  }

  /// يحول "sun,mon,wed" أو "all" -> `List<int>`
  static List<int> decodeDays(String? value) {
    if (value == null || value.isEmpty || value == "all") {
      return List.generate(7, (i) => i);
    }
    final parts = value.split(",").map((e) => e.trim()).toList();
    final List<int> indices = [];
    for (int i = 0; i < dayKeys.length; i++) {
      if (parts.contains(dayKeys[i])) indices.add(i);
    }
    return indices;
  }

  static String labelFromString(String dayKey) {
    final idx = dayKeys.indexOf(dayKey);
    if (idx == -1) return dayKey;
    return dayShortLabels[idx];
  }
}
