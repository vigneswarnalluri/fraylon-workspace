/// Abstract contract for authentication operations.
/// Implementations include [MockAuthRepository] and [FirebaseAuthRepository].
abstract class AuthRepository {
  /// Stream that emits the current user's ID or null if unauthenticated.
  Stream<String?> get authStateChanges;

  /// Returns the current user's ID or null if not logged in.
  Future<String?> getCurrentUserId();

  /// Returns the current user's email or null.
  Future<String?> getCurrentUserEmail();

  /// Returns the current user's display name or null.
  Future<String?> getCurrentUserDisplayName();

  /// Signs in a user using email and password.
  Future<void> signInWithEmailAndPassword(String email, String password);

  /// Registers a new user using email and password.
  Future<void> signUpWithEmailAndPassword(String email, String password, {String? displayName});

  /// Signs in a user via Google OAuth.
  Future<void> signInWithGoogle();

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordResetEmail(String email);

  /// Sends an email verification to the currently signed-in user.
  Future<void> sendEmailVerification();

  /// Returns true if the current user's email is verified.
  Future<bool> isEmailVerified();

  /// Signs out the current user.
  Future<void> signOut();
}
