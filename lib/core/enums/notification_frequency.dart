enum NotificationFrequency {
  none,
  low, // 1 per day
  medium, // 2 per day
  high, // 3 per day
}

extension NotificationFrequencyExtension on NotificationFrequency {
  int get dailyCount {
    switch (this) {
      case NotificationFrequency.none:
        return 0;
      case NotificationFrequency.low:
        return 1;
      case NotificationFrequency.medium:
        return 2;
      case NotificationFrequency.high:
        return 3;
    }
  }

  String toValueString() {
    switch (this) {
      case NotificationFrequency.none:
        return 'none';
      case NotificationFrequency.low:
        return 'low';
      case NotificationFrequency.medium:
        return 'medium';
      case NotificationFrequency.high:
        return 'high';
    }
  }

  static NotificationFrequency fromValueString(String? value) {
    switch (value) {
      case 'none':
        return NotificationFrequency.none;
      case 'low':
        return NotificationFrequency.low;
      case 'medium':
        return NotificationFrequency.medium;
      case 'high':
        return NotificationFrequency.high;
      default:
        return NotificationFrequency.none; // Default is none to not spam users
    }
  }
}
