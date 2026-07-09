import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_widgets.dart';

// ---------------------------------------------------------------------------
// Stripe-Style Text Field
// ---------------------------------------------------------------------------

class CleanTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  const CleanTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
  });

  @override
  State<CleanTextField> createState() => _CleanTextFieldState();
}

class _CleanTextFieldState extends State<CleanTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          enabled: widget.enabled,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Login Screen
// ---------------------------------------------------------------------------

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _entryController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  bool _autoValidate = false;
  int _activeTab = 0; // 0 = Work Account, 1 = Sandbox Access

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    ref.read(authControllerProvider.notifier).clearError();
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _signInWithGoogle() async {
    ref.read(authControllerProvider.notifier).clearError();
    final success =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final useFirebase = ref.watch(useFirebaseProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Redirect if already authenticated or when auth state changes to authenticated
    final currentUserId = ref.watch(authStateProvider).valueOrNull;
    if (currentUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
    }

    ref.listen(authStateProvider, (previous, next) {
      if (!mounted) return;
      next.whenData((userId) {
        if (userId != null) {
          context.go('/');
        }
      });
    });

    ref.listen(authControllerProvider, (_, next) {
      if (!mounted) return;
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    final formWidget = FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Badge
                      const Center(child: FraylonLogo(size: 120)),
                      const SizedBox(height: 32),

                      // Segment Tab Switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(0, 'Work Account', theme, isDark),
                            ),
                            Expanded(
                              child: _buildTabButton(1, 'Sandbox Access', theme, isDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Tab Contents
                      _activeTab == 0
                          ? _buildProductionForm(theme, authState)
                          : _buildSandboxConsole(theme, useFirebase, authState),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return formWidget;
  }

  Widget _buildTabButton(int index, String label, ThemeData theme, bool isDark) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? (isDark ? Colors.white : AppColors.dark)
                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProductionForm(ThemeData theme, AuthControllerState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        CleanTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'you@fraylontech.com',
          keyboardType: TextInputType.emailAddress,
          enabled: !authState.isLoading,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Email is required';
            final email = val.trim().toLowerCase();
            if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,}$').hasMatch(email)) {
              return 'Enter a valid email address';
            }
            if (!email.endsWith('@fraylontech.com')) {
              return 'Email must end with @fraylontech.com';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // Password
        CleanTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '••••••••',
          isPassword: true,
          enabled: !authState.isLoading,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Password is required';
            if (val.length < 6) return 'Must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 10),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: authState.isLoading
                ? null
                : () => context.push('/forgot-password'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot password?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Sign In Button
        GradientAuthButton(
          label: 'Sign In',
          onPressed: authState.isLoading ? null : _signIn,
          isLoading: authState.isLoading,
          icon: Icons.login_rounded,
        ),
        const SizedBox(height: 20),

        // Divider
        const AuthDivider(),
        const SizedBox(height: 20),

        // Google Button
        GoogleSignInButton(
          onPressed: authState.isLoading ? null : _signInWithGoogle,
          isLoading: authState.isLoading,
        ),
        const SizedBox(height: 28),

        // Register link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                "Don't have an account?",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: authState.isLoading
                  ? null
                  : () => context.push('/register'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Create account',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSandboxConsole(ThemeData theme, bool useFirebase, AuthControllerState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ENVIRONMENT INTEGRATION',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        BackendModePill(
          useFirebase: useFirebase,
          isLoading: authState.isLoading,
          onChanged: (val) {
            ref.read(useFirebaseProvider.notifier).state = val;
          },
        ),
        const SizedBox(height: 24),

        Text(
          'QUICK SIGN-IN REVIEWER ACCOUNTS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        if (useFirebase) ...[
          const SizedBox(height: 6),
          Text(
            'Note: Accounts will be auto-seeded to your live Firebase project on first tap.',
            style: TextStyle(
              fontSize: 10.5,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            _buildQuickLoginCard('Super Admin', 'superadmin@fraylontech.com', theme, useFirebase),
            _buildQuickLoginCard('Org Admin', 'orgadmin@fraylontech.com', theme, useFirebase),
            _buildQuickLoginCard('Manager', 'manager@fraylontech.com', theme, useFirebase),
            _buildQuickLoginCard('Employee 1', 'employee1@fraylontech.com', theme, useFirebase),
            _buildQuickLoginCard('Employee 2', 'employee2@fraylontech.com', theme, useFirebase),
            _buildQuickLoginCard('Employee 3', 'employee3@fraylontech.com', theme, useFirebase),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickLoginCard(String role, String email, ThemeData theme, bool useFirebase) {
    final isDark = theme.brightness == Brightness.dark;
    
    String displayName = role;
    if (email.startsWith('superadmin@')) {
      displayName = 'Sam Super';
    } else if (email.startsWith('orgadmin@')) {
      displayName = 'Olivia Org';
    } else if (email.startsWith('manager@')) {
      displayName = 'Mark Manager';
    } else if (email.startsWith('employee1@')) {
      displayName = 'Emily Employee';
    } else if (email.startsWith('employee2@')) {
      displayName = 'Evan Employee';
    } else if (email.startsWith('employee3@')) {
      displayName = 'Ethan Employee';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            _emailController.text = email;
            _passwordController.text = '123456';
            
            final success = await ref.read(authControllerProvider.notifier).signIn(email, '123456');
            if (!success && useFirebase) {
              // Auto-create on Firebase Auth if doesn't exist yet
              final registerSuccess = await ref.read(authControllerProvider.notifier).signUp(
                    email,
                    '123456',
                    displayName: displayName,
                  );
              if (registerSuccess) {
                await ref.read(authControllerProvider.notifier).signIn(email, '123456');
              }
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontSize: 9.5,
                  ),
                  overflow: TextOverflow.ellipsis,
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
// Desktop Layout
// ---------------------------------------------------------------------------

class _LoginDesktopPanel extends StatelessWidget {
  const _LoginDesktopPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F19), // Solid high-contrast deep slate-navy
      ),
      padding: const EdgeInsets.all(56),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FraylonLogo(size: 52, lightMode: true),
          SizedBox(height: 48),
          Text(
            'A workspace built\nfor modern teams.',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1.5,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Streamline your projects, coordinate announcements, and collaborate in real-time. Beautifully simple, enterprise grade.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF94A3B8),
              height: 1.6,
            ),
          ),
          SizedBox(height: 48),
          Center(child: _WorkspaceMockupCard()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Workspace Dashboard Mockup Card (Static, clean representation)
// ---------------------------------------------------------------------------

class _WorkspaceMockupCard extends StatelessWidget {
  const _WorkspaceMockupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mock Dashboard Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'v1.2 Active',
                    style: TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Card Title
            const Text(
              'Workspace Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),

            // Active Tasks Section
            _buildMockTask('API Gateway Integration', 0.75, Colors.blue),
            const SizedBox(height: 10),
            _buildMockTask('UI Refresh & Animations', 0.90, Colors.teal),
            const SizedBox(height: 10),
            _buildMockTask('Firebase Auth Bridge', 0.45, Colors.amber),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 12),

            // Team members + Announcement Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Project Members',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    _buildAvatarStack(),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Active Channel',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '#announcements',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockTask(String title, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF0F172A),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarStack() {
    final initials = ['JD', 'SM', 'TL', 'AK'];
    final colors = [Colors.redAccent, Colors.purpleAccent, Colors.blueAccent, Colors.greenAccent];

    return Row(
      children: [
        for (int i = 0; i < initials.length; i++)
          Transform.translate(
            offset: Offset(-i * 6.0, 0),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF16224A), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                initials[i],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Transform.translate(
          offset: Offset(-initials.length * 6.0 + 2, 0),
          child: const Text(
            '+3',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive wrapper
// ---------------------------------------------------------------------------

class ResponsiveLoginScreen extends StatelessWidget {
  const ResponsiveLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: AuthGradientScaffold(
        child: const LoginScreen(key: ValueKey('login_mobile')),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            const Expanded(child: _LoginDesktopPanel()),
            SizedBox(
              width: 520,
              child: AuthGradientScaffold(
                child: const LoginScreen(key: ValueKey('login_desktop')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
