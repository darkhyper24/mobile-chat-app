import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/db.dart';
import '../models/users.dart' as models;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _db = DatabaseService();

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';

  // Get current user
  User? get currentUser => _db.client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? firstname,
    String? lastname,
    String? username,
    String? phoneNumber,
    String? gender,
  }) async {
    final response = await _db.client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.session != null && response.user != null) {
      await _saveTokens(response.session!);
      
      // Create user record in users table
      final user = models.User(
        userId: response.user!.id,
        email: email,
        firstname: firstname,
        lastname: lastname,
        username: username,
        phoneNumber: phoneNumber,
        gender: gender,
        createdAt: DateTime.now(),
      );

      await _db.client.from('users').insert(user.toJson());
    }

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _db.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.session != null) {
      await _saveTokens(response.session!);
    }

    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await _db.client.auth.signOut();
    await clearTokens();
  }

  // Save tokens securely
  Future<void> _saveTokens(Session session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    await _storage.write(key: _userIdKey, value: session.user.id);
  }

  // Clear all stored tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _userIdKey);
  }

  // Get stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Get stored user ID
  Future<String?> getStoredUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // Check if access token exists
  Future<bool> hasStoredToken() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    return accessToken != null;
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _db.client.auth.onAuthStateChange;
}
