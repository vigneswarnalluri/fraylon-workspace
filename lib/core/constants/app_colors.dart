import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Premium Brand Colors
  static const Color primary = Color(0xFF2563EB);      // Enterprise Blue
  static const Color dark = Color(0xFF16224A);         // Deep Dark Navy
  static const Color secondary = Color(0xFF22C7D6);    // Vibrant Teal
  static const Color accent = Color(0xFF69D36E);       // Active Green
  static const Color lightBackground = Color(0xFFF8FAFC); // Clean Light Slate

  // Light Mode Theme Colors
  static const Color lightPrimary = primary;
  static const Color lightOnPrimary = Colors.white;
  static const Color lightPrimaryContainer = Color(0xFFEFF6FF); // Light blue tint
  static const Color lightOnPrimaryContainer = Color(0xFF1E40AF);
  static const Color lightSecondary = secondary;
  static const Color lightOnSecondary = Colors.white;
  static const Color lightBackgroundCard = Colors.white;
  static const Color lightOnBackground = Color(0xFF0F172A); // Slate 900
  static const Color lightSurface = Colors.white;
  static const Color lightOnSurface = Color(0xFF0F172A);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color lightOnSurfaceVariant = Color(0xFF475569); // Slate 600
  static const Color lightOutline = Color(0xFFE2E8F0); // Slate 200 (Very soft)

  // Dark Mode Theme Colors
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkOnPrimary = Color(0xFF0B0F19);
  static const Color darkPrimaryContainer = Color(0xFF1E3A8A);
  static const Color darkOnPrimaryContainer = Color(0xFFEFF6FF);
  static const Color darkSecondary = secondary;
  static const Color darkOnSecondary = Color(0xFF0B0F19);
  static const Color darkBackground = Color(0xFF0A0F24); // Matching Brand Dark
  static const Color darkOnBackground = Color(0xFFF8FAFC);
  static const Color darkSurface = Color(0xFF111827); // Charcoal
  static const Color darkOnSurface = Color(0xFFF8FAFC);
  static const Color darkSurfaceVariant = Color(0xFF1F2937);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkOutline = Color(0xFF374151);

  // Status/Alert Colors
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Colors.white;
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
