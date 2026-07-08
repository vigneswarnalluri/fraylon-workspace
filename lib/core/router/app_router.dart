import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/shell/presentation/screens/shell_screen.dart';
import '../../features/home/presentation/screens/design_system_gallery_screen.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/announcements/presentation/screens/announcements_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/assistant/presentation/screens/assistant_screen.dart';
import '../../features/admin/presentation/screens/users_screen.dart';
import '../../features/admin/presentation/screens/departments_screen.dart';
import '../../features/admin/presentation/screens/team_screen.dart';
import '../../features/admin/presentation/screens/reports_screen.dart';
import '../../features/admin/presentation/screens/settings_screen.dart';
import '../../features/admin/presentation/screens/organizations_screen.dart';
import '../services/permission_service.dart';

/// Smooth fade + slight upward-slide transition for all shell tab routes
CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );
      final slideCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: fadeCurve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03), // subtle 3% upward drift
            end: Offset.zero,
          ).animate(slideCurve),
          child: child,
        ),
      );
    },
  );
}

// Routes that are only accessible without authentication
const _authRoutes = {'/login', '/register', '/forgot-password', '/reset-password'};

// Routes that require authentication
const _verificationRoute = '/email-verification';

/// A ChangeNotifier that triggers GoRouter to re-evaluate its redirect
/// whenever the auth state changes (sign-in or sign-out).
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final _routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>(
  (ref) => _RouterNotifier(ref),
);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes (unauthenticated only)
      GoRoute(
        path: '/login',
        builder: (context, state) => const ResponsiveLoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final oobCode = state.uri.queryParameters['oobCode'];
          return ResetPasswordScreen(oobCode: oobCode);
        },
      ),

      // Authenticated shell routes
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/design-system',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const DesignSystemGalleryScreen(),
            ),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const TaskListScreen(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const CalendarScreen(),
            ),
          ),
          GoRoute(
            path: '/announcements',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const AnnouncementsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const NotificationCenterScreen(),
            ),
          ),
          GoRoute(
            path: '/assistant',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const AssistantScreen(),
            ),
          ),
          GoRoute(
            path: '/team',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const TeamScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const UsersScreen(),
            ),
          ),
          GoRoute(
            path: '/departments',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const DepartmentsScreen(),
            ),
          ),
          GoRoute(
            path: '/organizations',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const OrganizationsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _fadePage(
              state: state,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider).valueOrNull != null;
      final location = state.matchedLocation;

      // Splash is always allowed
      if (location == '/splash') return null;

      // Auth routes: redirect to home if already logged in
      if (isLoggedIn && _authRoutes.contains(location)) {
        return '/';
      }

      // Protected routes: redirect to login if not logged in
      if (!isLoggedIn &&
          !_authRoutes.contains(location) &&
          location != _verificationRoute) {
        return '/login';
      }

      // Role-based route guard
      if (isLoggedIn) {
        final profileAsync = ref.read(userProfileProvider);
        final profile = profileAsync.valueOrNull;
        if (profile != null) {
          final permissionService = ref.read(permissionServiceProvider);
          if (!permissionService.canAccessRoute(profile, location)) {
            return '/'; // Redirect to dashboard if unauthorized
          }
        }
      }

      return null;
    },
  );
});
