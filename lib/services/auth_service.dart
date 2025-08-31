// lib/services/auth_service.dart
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static Future<User> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);
      final user = User.fromJson(response['user']);

      // Store token locally
      await StorageService.setToken(response['token']);
      await StorageService.setUser(user);

      return user;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  static Future<User> register(String email, String password, String displayName) async {
    try {
      final response = await ApiService.register(email, password, displayName);
      final user = User.fromJson(response['user']);

      // Store token locally
      await StorageService.setToken(response['token']);
      await StorageService.setUser(user);

      return user;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    ApiService.setToken(null);
    await StorageService.clearAll();
  }

  static Future<User?> getCurrentUser() async {
    final token = await StorageService.getToken();
    if (token != null) {
      ApiService.setToken(token);
      return await StorageService.getUser();
    }
    return null;
  }
}

