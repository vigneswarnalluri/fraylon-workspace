import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Smooth fade + slight upward-slide transition for all routes
CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      final slideCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
      );
      return FadeTransition(
        opacity: fadeCurve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02), // subtle 2% upward drift
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
// The router is a static singleton — never recreated, never causes Riverpod
// provider crashes. Auth-based navigation is handled by:
//   • SplashScreen: listens to authStateProvider and routes on app start.
//   • Sign-out handlers: call context.go('/login') explicitly.
//   • Sign-in handlers: call context.go('/') explicitly.
final _appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const SplashScreen(),
      ),
    ),

    // Auth routes
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const ResponsiveLoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/email-verification',
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const EmailVerificationScreen(),
      ),
    ),
    GoRoute(
      path: '/reset-password',
      pageBuilder: (context, state) {
        final oobCode = state.uri.queryParameters['oobCode'];
        return _fadePage(
          state: state,
          child: ResetPasswordScreen(oobCode: oobCode),
        );
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
);

/// Exposes the static router as a Riverpod provider for use in [app.dart].
final routerProvider = Provider<GoRouter>((ref) => _appRouter);

