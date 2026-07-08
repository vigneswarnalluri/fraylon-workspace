import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../widgets/auth_widgets.dart';

/// Handles deep-link password reset (oobCode from Firebase or mock param).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? oobCode;

  const ResetPasswordScreen({super.key, this.oobCode});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late final AnimationController _entryController;
  late final AnimationController _successController;

  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _successFade;
  late final Animation<double> _successScale;

  bool _autoValidate = false;
  bool _resetDone = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );

    _entryController.forward();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _successController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    // In mock mode, we just simulate a reset.
    // In Firebase mode, this would use confirmPasswordReset(oobCode, newPassword).
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() => _resetDone = true);
      _successController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthGradientScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: _resetDone
                ? _buildSuccessState(theme)
                : _buildFormState(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => context.go('/login'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded,
                            size: 16, color: theme.colorScheme.onSurface),
                        const SizedBox(width: 6),
                        Text('Login', style: theme.textTheme.labelMedium),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.key_rounded,
                  color: theme.colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Set new password',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your new password must be different from previous passwords.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              if (widget.oobCode != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Reset token verified',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // New Password
              CustomTextField(
                controller: _passwordController,
                label: 'New Password',
                hint: 'Min. 8 characters recommended',
                isPassword: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Password is required';
                  if (val.length < 6) return 'Must be at least 6 characters';
                  return null;
                },
              ),

              // Strength bar
              PasswordStrengthBar(password: _passwordController.text),
              const SizedBox(height: 14),

              // Confirm Password
              CustomTextField(
                controller: _confirmController,
                label: 'Confirm Password',
                hint: '••••••••',
                isPassword: true,
                prefixIcon: Icons.lock_reset_rounded,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please confirm your password';
                  if (val != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              GradientAuthButton(
                label: 'Reset Password',
                onPressed: _resetPassword,
                icon: Icons.lock_open_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return ScaleTransition(
      scale: _successScale,
      child: FadeTransition(
        opacity: _successFade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF22C7D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Password reset!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your password has been successfully reset.\nYou can now sign in with your new password.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            GradientAuthButton(
              label: 'Sign In',
              onPressed: () => context.go('/login'),
              icon: Icons.login_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
