// lib/models/habit_completion.dart
class HabitCompletion {
  final int? id;
  final int userId;
  final int habitId;
  final DateTime completionDate;
  final DateTime createdAt;

  HabitCompletion({
    this.id,
    required this.userId,
    required this.habitId,
    required this.completionDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      id: json['id'],
      userId: json['user_id'],
      habitId: json['habit_id'],
      completionDate: DateTime.parse(json['completion_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'habit_id': habitId,
      'completion_date': completionDate.toIso8601String().split('T')[0],
    };
  }

  String get dateString {
    return '${completionDate.year}-${completionDate.month.toString().padLeft(2, '0')}-${completionDate.day.toString().padLeft(2, '0')}';
  }
}