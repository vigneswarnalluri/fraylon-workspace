import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraylon_workspace/features/auth/presentation/screens/login_screen.dart';
import 'package:fraylon_workspace/core/theme/app_theme.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: child,
      ),
    );

void main() {
  testWidgets('Login screen renders all key elements correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const ResponsiveLoginScreen()));
    await tester.pumpAndSettle();

    // Heading
    expect(find.text('Welcome back'), findsOneWidget);
    // Fields
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    // Actions
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('Login form validates empty fields on submit',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const ResponsiveLoginScreen()));
    await tester.pumpAndSettle();

    // Tap Sign In without entering any data
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Validation errors should appear
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
