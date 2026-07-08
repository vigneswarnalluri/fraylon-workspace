import '../../../profile/domain/models/user_profile.dart';

abstract class UserRepository {
  Stream<UserProfile?> watchUserProfile(String uid);
  Future<UserProfile?> getUserProfile(String uid);
  Future<void> saveUserProfile(UserProfile profile);
  Future<List<UserProfile>> getAllUsers();
  Future<void> createUser(UserProfile profile);
  Future<void> updateUser(UserProfile profile);
  Future<void> deleteUser(String uid);
}
