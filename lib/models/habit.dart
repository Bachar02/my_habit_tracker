// lib/models/habit.dart
import 'package:flutter/material.dart';
class Habit {
  final int? id;
  final int? userId;
  final String title;
  final String? description;
  final String color;
  final bool isActive;
  final DateTime createdAt;

  Habit({
    this.id,
    this.userId,
    required this.title,
    this.description,
    this.color = '#4285f4',
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      color: json['color'] ?? '#4285f4',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'color': color,
      'is_active': isActive,
    };
  }

  Color get colorValue {
    return Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000);
  }

  Habit copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? color,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
