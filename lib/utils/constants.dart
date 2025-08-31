// lib/utils/constants.dart
class AppConstants {
  static const String appName = 'Habit Tracker';
  static const String apiBaseUrl = 'http://localhost:3000/api'; // Change for production

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // App settings
  static const int maxHabitsPerDay = 10;
  static const int defaultYear = 2024;
}
