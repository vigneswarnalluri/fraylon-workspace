import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ---------------------------------------------------------------------------
// Google Logo Vector Painter
// ---------------------------------------------------------------------------

class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;

    // Segment paints
    final Paint redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill..isAntiAlias = true;
    final Paint yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill..isAntiAlias = true;
    final Paint greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill..isAntiAlias = true;
    final Paint bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill..isAntiAlias = true;

    final double outerRadius = r;
    final double innerRadius = r * 0.55;
    final Offset center = Offset(r, r);

    Path getSectorPath(double startAngle, double sweepAngle) {
      final Path path = Path();
      path.arcTo(Rect.fromCircle(center: center, radius: outerRadius), startAngle, sweepAngle, true);
      path.arcTo(Rect.fromCircle(center: center, radius: innerRadius), startAngle + sweepAngle, -sweepAngle, false);
      path.close();
      return path;
    }

    final double degToRad = math.pi / 180;

    // 1. Red sector (top): from -222 to -144 deg
    canvas.drawPath(getSectorPath(-222 * degToRad, -78 * degToRad), redPaint);

    // 2. Yellow sector (left): from -144 to -45 deg
    canvas.drawPath(getSectorPath(-144 * degToRad, -78 * degToRad), yellowPaint);

    // 3. Green sector (bottom): from -45 to 45 deg
    canvas.drawPath(getSectorPath(-66 * degToRad, -114 * degToRad), greenPaint);

    // 4. Blue sector (right/bar): from 45 to 135 deg
    canvas.drawPath(getSectorPath(45 * degToRad, -90 * degToRad), bluePaint);

    // Blue Bar: horizontal rectangle starting from center to outerRadius
    final double barHeight = outerRadius - innerRadius;
    final Rect barRect = Rect.fromLTWH(
      center.dx,
      center.dy - barHeight / 2,
      outerRadius,
      barHeight,
    );
    canvas.drawRect(barRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/google_logo.svg',
      width: size,
      height: size,
    );
  }
}

// ---------------------------------------------------------------------------
// Fraylon Logo Widget
// ---------------------------------------------------------------------------

class FraylonLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool lightMode; // true = dark text (for dark backgrounds), false = light-adaptive

  const FraylonLogo({
    super.key,
    this.size = 56,
    this.showWordmark = false,
    this.lightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = lightMode
        ? Colors.white
        : (isDark ? Colors.white : AppColors.dark);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.18),
          Text(
            'Fraylon',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          Text(
            'Workspace',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w400,
              color: textColor.withValues(alpha: 0.65),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient Auth Button
// ---------------------------------------------------------------------------

class GradientAuthButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const GradientAuthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<GradientAuthButton> createState() => _GradientAuthButtonState();
}

class _GradientAuthButtonState extends State<GradientAuthButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: isDisabled ? 1.0 : (_pressed ? 0.97 : (_hovered ? 1.02 : 1.0)),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            decoration: BoxDecoration(
              gradient: isDisabled
                  ? null
                  : LinearGradient(
                      colors: _hovered
                          ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                          : [AppColors.primary, const Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isDisabled ? Colors.grey.shade400 : null,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: _hovered ? 0.35 : 0.25),
                        blurRadius: _hovered ? 16 : 8,
                        spreadRadius: _hovered ? 2 : 0,
                        offset: Offset(0, _hovered ? 5 : 3),
                      ),
                    ],
            ),
            child: widget.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Google Sign-In Button
// ---------------------------------------------------------------------------

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: isDisabled ? 1.0 : (_isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0)),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? (_isHovered ? const Color(0xFF334155) : const Color(0xFF1E293B))
                  : (_isHovered ? const Color(0xFFF8FAFC) : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? theme.colorScheme.primary
                    : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                width: 1.5,
              ),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.03),
                        blurRadius: _isHovered ? 12 : 6,
                        offset: Offset(0, _isHovered ? 4 : 2),
                      ),
                    ],
            ),
            child: widget.isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogoWidget(size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.dark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Gradient Scaffold
// ---------------------------------------------------------------------------

class AuthGradientScaffold extends StatelessWidget {
  final Widget child;
  final bool resizeToAvoidBottomInset;

  const AuthGradientScaffold({
    super.key,
    required this.child,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        child: SafeArea(child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Password Strength Indicator
// ---------------------------------------------------------------------------

class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  (double, Color, String) _evaluate(String pw) {
    if (pw.isEmpty) return (0, Colors.transparent, '');
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.length >= 12) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9]'))) score++;
    if (pw.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 1) return (0.2, const Color(0xFFEF4444), 'Weak');
    if (score <= 2) return (0.45, const Color(0xFFF59E0B), 'Fair');
    if (score <= 3) return (0.65, const Color(0xFF3B82F6), 'Good');
    if (score <= 4) return (0.82, const Color(0xFF10B981), 'Strong');
    return (1.0, const Color(0xFF059669), 'Very Strong');
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final (strength, color, label) = _evaluate(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Divider ("or")
// ---------------------------------------------------------------------------

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.4);
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Backend Mode Indicator (compact pill)
// ---------------------------------------------------------------------------

class BackendModePill extends StatelessWidget {
  final bool useFirebase;
  final bool isLoading;
  final ValueChanged<bool>? onChanged;

  const BackendModePill({
    super.key,
    required this.useFirebase,
    this.isLoading = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: useFirebase
                      ? const Color(0xFFF59E0B)
                      : AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    useFirebase ? 'Firebase' : 'Mock Mode',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Dev integration',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: useFirebase,
              onChanged: isLoading ? null : onChanged,
              activeThumbColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
