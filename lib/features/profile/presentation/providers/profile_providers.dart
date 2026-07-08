import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileNotifier extends StateNotifier<UserProfile> {
  final Ref _ref;

  ProfileNotifier(this._ref)
      : super(UserProfile(
          uid: 'placeholder',
          name: 'Jane Doe',
          email: 'jane.doe@fraylontech.com',
          role: 'Employee',
          phone: '',
          organizationId: '',
          departmentId: '',
          designation: '',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          status: 'Active',
          department: '',
          organization: '',
          employeeId: '',
          joinedDate: DateTime.now(),
        )) {
    // Listen to userProfileProvider to keep the notifier state in sync
    _ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user != null) {
        state = user;
      }
    }, fireImmediately: true);
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    state = updatedProfile;
    try {
      final repo = _ref.read(userRepositoryProvider);
      await repo.updateUser(updatedProfile);
    } catch (_) {}
  }

  Future<bool> uploadAvatar(Uint8List bytes, String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profiles').child('$userId.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      
      // Upload bytes
      await ref.putData(bytes, metadata);
      
      // Obtain download URL
      final downloadUrl = await ref.getDownloadURL();
      
      // Update profile with new image URL
      final updated = state.copyWith(photo: downloadUrl, imageUrl: downloadUrl);
      await updateProfile(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    final updated = state.copyWith(notificationsEnabled: enabled);
    await updateProfile(updated);
  }

  Future<void> updateLanguage(String lang) async {
    final updated = state.copyWith(language: lang);
    await updateProfile(updated);
  }
}

// Global provider for user profile state
final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  return ProfileNotifier(ref);
});

// Hidden developer options unlocked status provider
final developerModeProvider = StateProvider<bool>((ref) => false);
