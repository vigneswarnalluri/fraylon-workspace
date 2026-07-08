import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<String?>.broadcast();
  static const _userIdKey = 'mock_user_id';
  static const _userEmailKey = 'mock_user_email';
  static const _userDisplayNameKey = 'mock_user_display_name';

  String? _currentUserId;
  String? _currentEmail;
  String? _currentDisplayName;

  MockAuthRepository() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString(_userIdKey);
      _currentEmail = prefs.getString(_userEmailKey);
      _currentDisplayName = prefs.getString(_userDisplayNameKey);
      _controller.add(_currentUserId);
    } catch (_) {
      _controller.add(null);
    }
  }

  @override
  Stream<String?> get authStateChanges => _controller.stream;

  @override
  Future<String?> getCurrentUserId() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUserId;
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentEmail;
  }

  @override
  Future<String?> getCurrentUserDisplayName() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentDisplayName;
  }

  String _getMockUidForEmail(String email) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == 'superadmin@fraylontech.com') return 'mock_super_admin';
    if (cleanEmail == 'orgadmin@fraylontech.com') return 'mock_org_admin';
    if (cleanEmail == 'manager@fraylontech.com') return 'mock_manager';
    if (cleanEmail == 'employee1@fraylontech.com') return 'mock_employee_1';
    if (cleanEmail == 'employee2@fraylontech.com') return 'mock_employee_2';
    if (cleanEmail == 'employee3@fraylontech.com') return 'mock_employee_3';
    return 'mock_user_uid_${email.split('@')[0]}';
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!email.contains('@') || email.length < 5) {
      throw Exception('Invalid email address format.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    _currentUserId = _getMockUidForEmail(email);
    _currentEmail = email;
    _currentDisplayName = email.split('@')[0];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, _currentUserId!);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userDisplayNameKey, _currentDisplayName!);
    _controller.add(_currentUserId);
  }

  @override
  Future<void> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!email.contains('@') || email.length < 5) {
      throw Exception('Invalid email address format.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    _currentUserId = _getMockUidForEmail(email);
    _currentEmail = email;
    _currentDisplayName = displayName ?? email.split('@')[0];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, _currentUserId!);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userDisplayNameKey, _currentDisplayName!);
    _controller.add(_currentUserId);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // Simulate a Google sign-in with a mock Google account (defaulting to Employee role mock_employee_1)
    _currentUserId = 'mock_employee_1';
    _currentEmail = 'employee1@fraylontech.com';
    _currentDisplayName = 'Emily Employee';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, _currentUserId!);
    await prefs.setString(_userEmailKey, _currentEmail!);
    await prefs.setString(_userDisplayNameKey, _currentDisplayName!);
    _controller.add(_currentUserId);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!email.contains('@') || email.length < 5) {
      throw Exception('Enter a valid email address to receive a reset link.');
    }
    // Mock: just simulates the send — no actual email sent
  }

  @override
  Future<void> sendEmailVerification() async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Mock: simulates sending a verification email
  }

  @override
  Future<bool> isEmailVerified() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: always returns true (simulating verified state)
    return true;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUserId = null;
    _currentEmail = null;
    _currentDisplayName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userDisplayNameKey);
    _controller.add(null);
  }
}
