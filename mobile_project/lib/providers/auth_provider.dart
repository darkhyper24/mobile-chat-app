import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/users.dart' as models;
import '../database/db.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.isAuthenticated;

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String username,
    String? phoneNumber,
    String? gender,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        firstname: firstname,
        lastname: lastname,
        username: username,
        phoneNumber: phoneNumber,
        gender: gender,
      );

      if (response.user != null) {
        await _loadCurrentUser();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadCurrentUser();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load current user data from database
  Future<void> _loadCurrentUser() async {
    if (_authService.currentUser != null) {
      try {
        final response = await DatabaseService().client
            .from('users')
            .select()
            .eq('user_id', _authService.currentUser!.id)
            .single();
        
        _currentUser = models.User.fromJson(response);
      } catch (e) {
        _errorMessage = e.toString();
      }
    }
  }

  // Check if user has stored token on app start
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasToken = await _authService.hasStoredToken();
      if (hasToken && _authService.isAuthenticated) {
        await _loadCurrentUser();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
