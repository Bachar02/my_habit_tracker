// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api'; // Change for production
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Auth endpoints
  static Future<Map<String, dynamic>> register(String email, String password, String displayName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'display_name': displayName,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['token']);
      return data;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Login failed';
      throw Exception(error);
    }
  }

  // Habit endpoints
  static Future<List<Habit>> getHabits() async {
    final response = await http.get(
      Uri.parse('$baseUrl/habits'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Habit.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch habits');
    }
  }

  static Future<Habit> createHabit(Habit habit) async {
    final response = await http.post(
      Uri.parse('$baseUrl/habits'),
      headers: _headers,
      body: jsonEncode(habit.toJson()),
    );

    if (response.statusCode == 201) {
      return Habit.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create habit');
    }
  }

  static Future<void> deleteHabit(int habitId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/habits/$habitId'),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete habit');
    }
  }

  // Completion endpoints
  static Future<void> markHabitComplete(int habitId, DateTime date) async {
    final response = await http.post(
      Uri.parse('$baseUrl/habits/$habitId/complete'),
      headers: _headers,
      body: jsonEncode({
        'completion_date': date.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to mark habit complete');
    }
  }

  static Future<void> markHabitIncomplete(int habitId, DateTime date) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/habits/$habitId/complete'),
      headers: _headers,
      body: jsonEncode({
        'completion_date': date.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to mark habit incomplete');
    }
  }

  static Future<Map<String, int>> getHeatmapData(int year) async {
    final response = await http.get(
      Uri.parse('$baseUrl/completions/heatmap?year=$year'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data.map((key, value) => MapEntry(key, value as int));
    } else {
      throw Exception('Failed to fetch heatmap data');
    }
  }

  static Future<int> getHabitStreak(int habitId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/habits/$habitId/streak'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['current_streak'] ?? 0;
    } else {
      throw Exception('Failed to fetch streak');
    }
  }
}

