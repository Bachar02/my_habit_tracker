// lib/providers/habit_provider.dart
import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../services/api_service.dart';

class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];
  Map<String, int> _heatmapData = {};
  Map<int, int> _streaks = {};
  bool _isLoading = false;
  String? _error;

  List<Habit> get habits => _habits;
  Map<String, int> get heatmapData => _heatmapData;
  Map<int, int> get streaks => _streaks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHabits() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _habits = await ApiService.getHabits();

      // Load streaks for all habits
      for (final habit in _habits) {
        if (habit.id != null) {
          _streaks[habit.id!] = await ApiService.getHabitStreak(habit.id!);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createHabit(Habit habit) async {
    try {
      final newHabit = await ApiService.createHabit(habit);
      _habits.insert(0, newHabit);
      if (newHabit.id != null) {
        _streaks[newHabit.id!] = 0;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteHabit(int habitId) async {
    try {
      await ApiService.deleteHabit(habitId);
      _habits.removeWhere((habit) => habit.id == habitId);
      _streaks.remove(habitId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markHabitComplete(int habitId, DateTime date) async {
    try {
      await ApiService.markHabitComplete(habitId, date);

      // Update local heatmap data
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _heatmapData[dateStr] = (_heatmapData[dateStr] ?? 0) + 1;

      // Refresh streak
      _streaks[habitId] = await ApiService.getHabitStreak(habitId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markHabitIncomplete(int habitId, DateTime date) async {
    try {
      await ApiService.markHabitIncomplete(habitId, date);

      // Update local heatmap data
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (_heatmapData[dateStr] != null && _heatmapData[dateStr]! > 0) {
        _heatmapData[dateStr] = _heatmapData[dateStr]! - 1;
        if (_heatmapData[dateStr] == 0) {
          _heatmapData.remove(dateStr);
        }
      }

      // Refresh streak
      _streaks[habitId] = await ApiService.getHabitStreak(habitId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadHeatmapData(int year) async {
    try {
      _heatmapData = await ApiService.getHeatmapData(year);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  int getCompletionsForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _heatmapData[dateStr] ?? 0;
  }

  int getStreakForHabit(int habitId) {
    return _streaks[habitId] ?? 0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }}
