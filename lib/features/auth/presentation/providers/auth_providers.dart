import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../../profile/domain/models/user_profile.dart';

// We need to export userProfileProvider for profile_providers.dart
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/firebase_user_repository.dart';
import '../../data/repositories/mock_user_repository.dart';

/// Determines whether the app uses Firebase or Mock implementations.
final useFirebaseProvider = StateProvider<bool>((ref) {
  return const bool.fromEnvironment('USE_FIREBASE', defaultValue: true);
});

/// Resolves the active AuthRepository implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final useFirebase = ref.watch(useFirebaseProvider);
  
  bool isFirebaseReady = false;
  try {
    isFirebaseReady = Firebase.apps.isNotEmpty;
  } catch (_) {}

  return (useFirebase && isFirebaseReady) ? FirebaseAuthRepository() : MockAuthRepository();
});

/// Emits auth state (current User ID or null when unauthenticated).
final authStateProvider = StreamProvider<String?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// Resolves the active UserRepository implementation.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final useFirebase = ref.watch(useFirebaseProvider);
  bool isFirebaseReady = false;
  try {
    isFirebaseReady = Firebase.apps.isNotEmpty;
  } catch (_) {}

  return (useFirebase && isFirebaseReady) ? FirebaseUserRepository() : MockUserRepository();
});

/// Emits the current logged-in user profile document.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull;
  if (uid == null) return Stream.value(null);

  final repository = ref.watch(userRepositoryProvider);
  return repository.watchUserProfile(uid);
});

/// Resolves the current user's role.
final userRoleProvider = Provider<String>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.valueOrNull?.role ?? 'Employee';
});

// ---------------------------------------------------------------------------
// AuthController State
// ---------------------------------------------------------------------------

class AuthControllerState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool emailSent;

  const AuthControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.emailSent = false,
  });

  AuthControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? emailSent,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      emailSent: emailSent ?? this.emailSent,
    );
  }
}

// ---------------------------------------------------------------------------
// AuthController
// ---------------------------------------------------------------------------

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository, ref);
});

class AuthController extends StateNotifier<AuthControllerState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthController(this._repo, this._ref) : super(const AuthControllerState());

  // --- Sign In ---

  Future<bool> signIn(String email, String password) async {
    state = const AuthControllerState(isLoading: true);
    try {
      await _repo.signInWithEmailAndPassword(email, password);
      state = const AuthControllerState();
      return true;
    } catch (e) {
      state = AuthControllerState(errorMessage: _clean(e));
      return false;
    }
  }

  // --- Sign Up ---

  Future<bool> signUp(String email, String password, {String? displayName}) async {
    state = const AuthControllerState(isLoading: true);
    try {
      await _repo.signUpWithEmailAndPassword(email, password, displayName: displayName);
      
      // Synchronously seed the user profile document in Firestore
      final userRepo = _ref.read(userRepositoryProvider);
      final uid = _ref.read(authStateProvider).valueOrNull;
      
      if (uid != null) {
        final now = DateTime.now();
        final name = displayName ?? email.split('@')[0];
        
        String role = 'Employee';
        String dept = 'Engineering';
        String org = 'Fraylon Technologies LLP';
        
        if (email.startsWith('superadmin@')) {
          role = 'Super Admin';
          dept = 'HQ';
          org = 'Fraylon Global Inc';
        } else if (email.startsWith('orgadmin@')) {
          role = 'Organization Admin';
          dept = 'Operations';
        } else if (email.startsWith('manager@')) {
          role = 'Manager';
          dept = 'Engineering';
        }
        
        final profile = UserProfile(
          uid: uid,
          name: name,
          email: email,
          role: role,
          phone: '',
          organizationId: role == 'Super Admin' ? 'org_global' : 'org_fraylon',
          departmentId: role == 'Super Admin' ? 'dept_hq' : (role == 'Organization Admin' ? 'dept_ops' : 'dept_engineering'),
          designation: role == 'Super Admin' ? 'System Director' : (role == 'Organization Admin' ? 'VP of Operations' : (role == 'Manager' ? 'Engineering Manager' : 'Software Engineer')),
          createdAt: now,
          lastLogin: now,
          status: 'Active',
          department: dept,
          organization: org,
          employeeId: 'EMP_${now.millisecondsSinceEpoch.toString().substring(7)}',
          joinedDate: now,
        );
        
        await userRepo.createUser(profile);
      }
      
      state = const AuthControllerState();
      return true;
    } catch (e) {
      state = AuthControllerState(errorMessage: _clean(e));
      return false;
    }
  }

  // --- Google Sign In ---

  Future<bool> signInWithGoogle() async {
    state = const AuthControllerState(isLoading: true);
    try {
      await _repo.signInWithGoogle();
      
      // Synchronously check and seed Google User Profile if missing
      final userRepo = _ref.read(userRepositoryProvider);
      final uid = _ref.read(authStateProvider).valueOrNull;
      
      if (uid != null) {
        final existing = await userRepo.getUserProfile(uid);
        if (existing == null) {
          final now = DateTime.now();
          final email = '';
          final name = 'Google User';
          
          final profile = UserProfile(
            uid: uid,
            name: name,
            email: email,
            role: 'Employee',
            phone: '',
            organizationId: 'org_fraylon',
            departmentId: 'dept_engineering',
            designation: 'Software Engineer',
            createdAt: now,
            lastLogin: now,
            status: 'Active',
            department: 'Engineering',
            organization: 'Fraylon Technologies LLP',
            employeeId: 'EMP_${now.millisecondsSinceEpoch.toString().substring(7)}',
            joinedDate: now,
          );
          await userRepo.createUser(profile);
        }
      }
      
      state = const AuthControllerState();
      return true;
    } catch (e) {
      state = AuthControllerState(errorMessage: _clean(e));
      return false;
    }
  }

  // --- Forgot Password ---

  Future<bool> sendPasswordResetEmail(String email) async {
    state = const AuthControllerState(isLoading: true);
    try {
      await _repo.sendPasswordResetEmail(email);
      state = const AuthControllerState(
        emailSent: true,
        successMessage: 'Password reset link sent! Check your inbox.',
      );
      return true;
    } catch (e) {
      state = AuthControllerState(errorMessage: _clean(e));
      return false;
    }
  }

  // --- Email Verification ---

  Future<bool> sendEmailVerification() async {
    state = const AuthControllerState(isLoading: true);
    try {
      await _repo.sendEmailVerification();
      state = const AuthControllerState(
        emailSent: true,
        successMessage: 'Verification email sent! Check your inbox.',
      );
      return true;
    } catch (e) {
      state = AuthControllerState(errorMessage: _clean(e));
      return false;
    }
  }

  Future<bool> checkEmailVerified() async {
    state = const AuthControllerState(isLoading: true);
    try {
      final verified = await _repo.isEmailVerified();
      state = const AuthControllerState();
      return verified;
    } catch (e) {
      state = AuthControllerState(errorMessage: _clean(e));
      return false;
    }
  }

  // --- Sign Out ---

  Future<void> signOut() async {
    state = const AuthControllerState(isLoading: true);
    try {
      await _repo.signOut();
      state = const AuthControllerState();
    } catch (e) {
      state = AuthControllerState(errorMessage: _clean(e));
    }
  }

  // --- Helpers ---

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void clearSuccess() {
    if (state.successMessage != null) {
      state = state.copyWith(clearSuccess: true);
    }
  }

  void reset() {
    state = const AuthControllerState();
  }

  String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '').trim();
}

final userDisplayNameProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final name = await repo.getCurrentUserDisplayName();
  return name ?? 'Jane Doe';
});
