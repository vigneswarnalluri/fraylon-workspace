import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _shimmerController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _shimmerAnim;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    _shimmerAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _logoController.forward();

    // Navigate after minimum display time of 2s
    Future.delayed(const Duration(milliseconds: 2000), _checkAndNavigate);
  }

  void _checkAndNavigate() {
    if (!mounted || _hasNavigated) return;
    // GoRouter redirect will handle the right destination.
    // We just need to push away from splash.
    // The redirect logic in app_router will do the rest.
    _hasNavigated = true;
    context.go('/login');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to auth state; if it resolves quickly, navigate sooner
    ref.listen(authStateProvider, (_, next) {
      if (!mounted || _hasNavigated) return;
      next.whenData((userId) {
        if (userId != null) {
          _hasNavigated = true;
          context.go('/');
        }
      });
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF060B1C),
                    const Color(0xFF0D1433),
                    const Color(0xFF16224A),
                  ]
                : [
                    const Color(0xFFEFF6FF),
                    const Color(0xFFF0FFFE),
                    const Color(0xFFF8FAFC),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Background accent circles
            Positioned(
              top: -80,
              right: -60,
              child: _buildGlowCircle(200, AppColors.primary.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _buildGlowCircle(280, AppColors.secondary.withValues(alpha: 0.07)),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo mark
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom loading shimmer bar
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _wordmarkFade,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _shimmerAnim,
                      builder: (context, _) {
                        return Opacity(
                          opacity: _shimmerAnim.value,
                          child: Container(
                            width: 48,
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 180),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading workspace...',
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? Colors.white : AppColors.dark)
                            .withValues(alpha: 0.35),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
