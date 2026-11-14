class NotificationPreferences {
  NotificationPreferences({
    this.enabled = false,
    this.reminder = false,
    this.hour = 20,
    this.minute = 0,
    Set<int>? days,
    this.reservations = true,
    this.finishedBooks = true,
    this.goals = true,
  }) : days = days ?? {1, 2, 3, 4, 5, 6, 7};

  bool enabled, reminder, reservations, finishedBooks, goals;
  int hour, minute;
  Set<int> days;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'reminder': reminder,
    'hour': hour,
    'minute': minute,
    'days': days.toList()..sort(),
    'reservations': reservations,
    'finishedBooks': finishedBooks,
    'goals': goals,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        enabled: json['enabled'] == true,
        reminder: json['reminder'] == true,
        hour: ((json['hour'] as num?)?.toInt() ?? 20).clamp(0, 23),
        minute: ((json['minute'] as num?)?.toInt() ?? 0).clamp(0, 59),
        days: json['days'] is List
            ? (json['days'] as List)
                  .whereType<int>()
                  .where((d) => d >= 1 && d <= 7)
                  .toSet()
            : null,
        reservations: json['reservations'] != false,
        finishedBooks: json['finishedBooks'] != false,
        goals: json['goals'] != false,
      );
}
