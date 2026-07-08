import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class MockUserRepository implements UserRepository {
  final _controller = StreamController<UserProfile?>.broadcast();
  static const _usersKey = 'mock_users_data';
  List<UserProfile> _users = [];
  String? _activeUid;

  MockUserRepository() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_usersKey);
      if (jsonStr != null) {
        final List decoded = jsonDecode(jsonStr);
        _users = decoded.map((x) => UserProfile.fromMap(x)).toList();
      } else {
        _users = _getSeedUsers();
        await _save();
      }
    } catch (_) {
      _users = _getSeedUsers();
    }
    _notifyActiveUser();
  }

  void _notifyActiveUser() {
    if (_activeUid != null) {
      final user = _users.firstWhere((u) => u.uid == _activeUid, orElse: () {
        if (_activeUid!.startsWith('mock_user_uid_')) {
          final username = _activeUid!.replaceFirst('mock_user_uid_', '');
          return UserProfile(
            uid: _activeUid!,
            name: username[0].toUpperCase() + username.substring(1),
            email: '$username@fraylontech.com',
            role: 'Employee',
            organizationId: 'org_fraylon',
            departmentId: 'dept_engineering',
            designation: 'Associate Engineer',
            phone: '',
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
            status: 'Active',
          );
        }
        return _users.first;
      });
      _controller.add(user);
    }
  }

  List<UserProfile> _getSeedUsers() {
    final now = DateTime(2026, 7, 7);
    return [
      UserProfile(
        uid: 'mock_super_admin',
        name: 'Sam Super',
        email: 'superadmin@fraylontech.com',
        role: 'Super Admin',
        organizationId: 'org_global',
        organization: 'Fraylon Global Inc',
        departmentId: 'dept_hq',
        department: 'HQ',
        designation: 'System Director',
        phone: '+1 (555) 901-2345',
        createdAt: now.subtract(const Duration(days: 300)),
        lastLogin: now,
        status: 'Active',
      ),
      UserProfile(
        uid: 'mock_org_admin',
        name: 'Olivia Org',
        email: 'orgadmin@fraylontech.com',
        role: 'Organization Admin',
        organizationId: 'org_fraylon',
        organization: 'Fraylon Technologies LLP',
        departmentId: 'dept_ops',
        department: 'Operations',
        designation: 'VP of Operations',
        phone: '+1 (555) 123-4567',
        createdAt: now.subtract(const Duration(days: 200)),
        lastLogin: now,
        status: 'Active',
      ),
      UserProfile(
        uid: 'mock_manager',
        name: 'Mark Manager',
        email: 'manager@fraylontech.com',
        role: 'Manager',
        organizationId: 'org_fraylon',
        organization: 'Fraylon Technologies LLP',
        departmentId: 'dept_engineering',
        department: 'Engineering',
        designation: 'Engineering Manager',
        phone: '+1 (555) 234-5678',
        createdAt: now.subtract(const Duration(days: 150)),
        lastLogin: now,
        status: 'Active',
      ),
      UserProfile(
        uid: 'mock_employee_1',
        name: 'Emily Employee',
        email: 'employee1@fraylontech.com',
        role: 'Employee',
        organizationId: 'org_fraylon',
        organization: 'Fraylon Technologies LLP',
        departmentId: 'dept_engineering',
        department: 'Engineering',
        designation: 'Software Engineer',
        phone: '+1 (555) 345-6789',
        createdAt: now.subtract(const Duration(days: 100)),
        lastLogin: now,
        status: 'Active',
      ),
      UserProfile(
        uid: 'mock_employee_2',
        name: 'Evan Employee',
        email: 'employee2@fraylontech.com',
        role: 'Employee',
        organizationId: 'org_fraylon',
        organization: 'Fraylon Technologies LLP',
        departmentId: 'dept_design',
        department: 'Design',
        designation: 'UX Designer',
        phone: '+1 (555) 456-7890',
        createdAt: now.subtract(const Duration(days: 50)),
        lastLogin: now,
        status: 'Active',
      ),
      UserProfile(
        uid: 'mock_employee_3',
        name: 'Ethan Employee',
        email: 'employee3@fraylontech.com',
        role: 'Employee',
        organizationId: 'org_fraylon',
        organization: 'Fraylon Technologies LLP',
        departmentId: 'dept_support',
        department: 'Support',
        designation: 'Support Representative',
        phone: '+1 (555) 567-8901',
        createdAt: now.subtract(const Duration(days: 10)),
        lastLogin: now,
        status: 'Active',
      ),
    ];
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _users.map((x) => x.toMap()).toList();
      await prefs.setString(_usersKey, jsonEncode(list));
    } catch (_) {}
  }

  @override
  Stream<UserProfile?> watchUserProfile(String uid) {
    _activeUid = uid;
    // Push the current user profile immediately if we have it
    Future.microtask(() => _notifyActiveUser());
    return _controller.stream;
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index >= 0) return _users[index];
    
    // Check fallback
    if (uid.startsWith('mock_user_uid_')) {
      final username = uid.replaceFirst('mock_user_uid_', '');
      final email = '$username@fraylontech.com';
      return UserProfile(
        uid: uid,
        name: username[0].toUpperCase() + username.substring(1),
        email: email,
        role: 'Employee',
        organizationId: 'org_fraylon',
        departmentId: 'dept_engineering',
        designation: 'Associate Engineer',
        phone: '',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        status: 'Active',
      );
    }
    return null;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _users.indexWhere((u) => u.uid == profile.uid);
    if (index >= 0) {
      _users[index] = profile;
    } else {
      _users.add(profile);
    }
    await _save();
    if (_activeUid == profile.uid) {
      _controller.add(profile);
    }
  }

  @override
  Future<List<UserProfile>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _users;
  }

  @override
  Future<void> createUser(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_users.any((u) => u.uid == profile.uid || u.email == profile.email)) {
      throw Exception('User with this email or ID already exists.');
    }
    _users.add(profile);
    await _save();
  }

  @override
  Future<void> updateUser(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _users.indexWhere((u) => u.uid == profile.uid);
    if (index >= 0) {
      _users[index] = profile;
      await _save();
      if (_activeUid == profile.uid) {
        _controller.add(profile);
      }
    } else {
      throw Exception('User not found.');
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _users.removeWhere((u) => u.uid == uid);
    await _save();
    if (_activeUid == uid) {
      _controller.add(null);
    }
  }
}
