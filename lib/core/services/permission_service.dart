import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/domain/models/user_profile.dart';

class PermissionService {
  const PermissionService();

  bool canAccessRoute(UserProfile user, String route) {
    if (user.status == 'Disabled') return false; // Disabled users have zero access
    
    switch (route) {
      case '/organizations':
        return user.role == 'Super Admin';
      case '/users':
        return user.role == 'Super Admin' || user.role == 'Organization Admin';
      case '/departments':
        return user.role == 'Super Admin' || user.role == 'Organization Admin';
      case '/team':
        return user.role == 'Manager';
      case '/reports':
        return user.role == 'Super Admin' || user.role == 'Organization Admin' || user.role == 'Manager';
      case '/settings':
        return user.role == 'Super Admin';
      case '/notifications':
        return true; // Notifications page itself is authorized, but navbar tab is Employee specific
      default:
        return true;
    }
  }

  bool canCreateTasks(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin' || user.role == 'Organization Admin' || user.role == 'Manager';
  }

  bool canAssignTasks(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin' || user.role == 'Organization Admin' || user.role == 'Manager';
  }

  bool canDeleteTasks(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin' || user.role == 'Organization Admin' || user.role == 'Manager';
  }

  bool canApproveTasks(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Manager' || user.role == 'Super Admin' || user.role == 'Organization Admin';
  }

  bool canCreateAnnouncements(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin' || user.role == 'Organization Admin' || user.role == 'Manager';
  }

  bool canEditAnnouncement(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin' || user.role == 'Organization Admin';
  }

  bool canDeleteAnnouncement(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin' || user.role == 'Organization Admin';
  }

  bool canPinAnnouncement(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin' || user.role == 'Organization Admin';
  }

  bool canManageUsers(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin' || user.role == 'Organization Admin';
  }

  bool canManageDepartments(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin' || user.role == 'Organization Admin';
  }

  bool canManageOrganizations(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin';
  }

  bool canViewReports(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin' || user.role == 'Organization Admin' || user.role == 'Manager';
  }

  bool canAccessWorkspaceSettings(UserProfile user) {
    if (user.status == 'Disabled') return false;
    return user.role == 'Super Admin';
  }
}

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return const PermissionService();
});
