// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';

class ApiService {
  // Dynamic base URL based on platform
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:3000/api';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost directly
      return 'http://localhost:3000/api';
    } else {
      // Web/Desktop
      return 'http://localhost:3000/api';
    }
  }
  
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Helper method to handle HTTP errors
  static void _handleHttpError(http.Response response) {
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Request failed');
    }
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> register(String email, String password, String displayName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'displayName': displayName,
        }),
      );

      _handleHttpError(response);
      final data = jsonDecode(response.body);
      setToken(data['token']);
      return data;
    } on SocketException {
      throw Exception('Unable to connect to server. Make sure the backend is running.');
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      _handleHttpError(response);
      final data = jsonDecode(response.body);
      setToken(data['token']);
      return data;
    } on SocketException {
      throw Exception('Unable to connect to server. Make sure the backend is running.');
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  static Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );

      _handleHttpError(response);
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    } on SocketException {
      throw Exception('Unable to connect to server');
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  // Habit endpoints
  static Future<List<Habit>> getHabits() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/habits'),
        headers: _headers,
      );

      _handleHttpError(response);
      final data = jsonDecode(response.body);
      final List<dynamic> habitsJson = data['habits'];
      return habitsJson.map((json) => Habit.fromJson(json)).toList();
    } on SocketException {
      throw Exception('Unable to connect to server');
    } catch (e) {
      throw Exception('Failed to fetch habits: ${e.toString()}');
    }
  }

  static Future<Habit> createHabit(Habit habit) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/habits'),
        headers: _headers,
        body: jsonEncode(habit.toJson()),
      );

      _handleHttpError(response);
      final data = jsonDecode(response.body);
      return Habit.fromJson(data['habit']);
    } on SocketException {
      throw Exception('Unable to connect to server');
    } catch (e) {
      throw Exception('Failed to create habit: ${e.toString()}');
    }
  }

  static Future<void> deleteHabit(int habitId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/habits/$habitId'),
        headers: _headers,
      );

      _handleHttpError(response);
    } on SocketException {
      throw Exception('Unable to connect to server');
    } catch (e) {
      throw Exception('Failed to delete habit: ${e.toString()}');
    }
  }

  // Completion endpoints
  static Future<void> markHabitComplete(int habitId, DateTime date) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/habits/$habitId/complete'),
        headers: _headers,
        body: jsonEncode({
          'date': date.toIso8601String(),
        }),
      );

      _handleHttpError(response);
    } on SocketException {
      throw Exception('Unable to connect to server');
    } catch (e) {
      throw Exception('Failed to mark habit complete: ${e.toString()}');
    }
  }

  static Future<void> markHabitIncomplete(int habitId, DateTime date) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/habits/$habitId/complete'),
        headers: _headers,
        body: jsonEncode({
          'date': date.toIso8601String(),
        }),
      );

      _handleHttpError(response);
    } on SocketException {
      throw Exception('Unable to connect to server');
    } catch (e) {
      throw Exception('Failed to mark habit incomplete: ${e.toString()}');
    }
  }

  static Future<Map<String, int>> getHeatmapData(int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31);
      
      final response = await http.get(
        Uri.parse('$baseUrl/habits/completions/all?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}'),
        headers: _headers,
      );

      _handleHttpError(response);
      final data = jsonDecode(response.body);
      final List<dynamic> completions = data['completions'];
      
      final Map<String, int> heatmapData = {};
      for (final completion in completions) {
        heatmapData[completion['completion_date']] = completion['completion_count'];
      }
      
      return heatmapData;
    } on SocketException {
      throw Exception('Unable to connect to server');
    } catch (e) {
      throw Exception('Failed to fetch heatmap data: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getHabitStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/habits/stats'),
        headers: _headers,
      );

      _handleHttpError(response);
      final data = jsonDecode(response.body);
      return data['stats'];
    } on SocketException {
      throw Exception('Unable to connect to server');
    } catch (e) {
      throw Exception('Failed to fetch stats: ${e.toString()}');
    }
  }

  static Future<int> getHabitStreak(int habitId) async {
    try {
      // This endpoint doesn't exist in your backend yet, 
      // so let's calculate it from completions
      final response = await http.get(
        Uri.parse('$baseUrl/habits/$habitId/completions'),
        headers: _headers,
      );

      _handleHttpError(response);
      final data = jsonDecode(response.body);
      final List<dynamic> completions = data['completions'];
      
      if (completions.isEmpty) return 0;
      
      // Simple streak calculation (consecutive days from most recent)
      final sortedDates = completions
          .map((c) => DateTime.parse(c['completion_date']))
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Sort descending
      
      if (sortedDates.isEmpty) return 0;
      
      int streak = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      for (int i = 0; i < sortedDates.length; i++) {
        final date = DateTime(sortedDates[i].year, sortedDates[i].month, sortedDates[i].day);
        final expectedDate = today.subtract(Duration(days: i));
        
        if (date.isAtSameMomentAs(expectedDate)) {
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } on SocketException {
      throw Exception('Unable to connect to server');
    } catch (e) {
      throw Exception('Failed to fetch streak: ${e.toString()}');
    }
  }

  // Test connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}