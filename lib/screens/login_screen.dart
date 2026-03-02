import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/theme_provider.dart';

/// Login screen with email/password authentication.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Missing Fields'),
          description: Text('Please enter both email and password.'),
        ),
      );
      return;
    }

    final authProvider = context.read<app.AuthProvider>();
    final success = await authProvider.signIn(
      email: email,
      password: password,
    );

    if (!success && mounted) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Login Failed'),
          description: Text(authProvider.error ?? 'Unknown error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app.AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Theme toggle (top right)
            Positioned(
              top: 12,
              right: 12,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return GestureDetector(
                    onTap: () => themeProvider.toggleTheme(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Main content
            Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Branding
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // App Name
                Text(
                  'Stokya',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: ShadTheme.of(context).colorScheme.foreground,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sari-sari Store Inventory',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 48),

                // Email field
                ShadInput(
                  controller: _emailController,
                  placeholder: const Text('Email address'),
                  keyboardType: TextInputType.emailAddress,
                  prefix: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.email_outlined,
                        size: 18, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                ShadInput(
                  controller: _passwordController,
                  placeholder: const Text('Password'),
                  obscureText: _obscurePassword,
                  prefix: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.lock_outlined,
                        size: 18, color: Colors.grey[600]),
                  ),
                  suffix: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 16),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _RegisterRedirect(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
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
}

/// Simple redirect widget to navigate to RegisterScreen.
/// This avoids a circular import.
class _RegisterRedirect extends StatelessWidget {
  const _RegisterRedirect();

  @override
  Widget build(BuildContext context) {
    // Lazy import via navigation
    return const _RegisterScreenWrapper();
  }
}

class _RegisterScreenWrapper extends StatelessWidget {
  const _RegisterScreenWrapper();

  @override
  Widget build(BuildContext context) {
    // Will be replaced by actual import path in main navigation
    return const RegisterScreenInline();
  }
}

/// Inline register screen to keep it in the same file for simplicity.
/// Alternatively, this can live in register_screen.dart
class RegisterScreenInline extends StatefulWidget {
  const RegisterScreenInline({super.key});

  @override
  State<RegisterScreenInline> createState() => _RegisterScreenInlineState();
}

class _RegisterScreenInlineState extends State<RegisterScreenInline> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Missing Fields'),
          description: Text('Please fill in all fields.'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Password Mismatch'),
          description: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Weak Password'),
          description: Text('Password must be at least 6 characters.'),
        ),
      );
      return;
    }

    final authProvider = context.read<app.AuthProvider>();
    final success = await authProvider.register(
      email: email,
      password: password,
    );

    if (success && mounted) {
      Navigator.of(context).pop(); // Go back to login (auth state will redirect)
    } else if (mounted) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Registration Failed'),
          description: Text(authProvider.error ?? 'Unknown error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app.AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 22,
                ),
                tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                const Text(
                  'Join Stokya',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your store account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 40),

                // Email
                ShadInput(
                  controller: _emailController,
                  placeholder: const Text('Email address'),
                  keyboardType: TextInputType.emailAddress,
                  prefix: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.email_outlined,
                        size: 18, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                ShadInput(
                  controller: _passwordController,
                  placeholder: const Text('Password'),
                  obscureText: _obscurePassword,
                  prefix: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.lock_outlined,
                        size: 18, color: Colors.grey[600]),
                  ),
                  suffix: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                ShadInput(
                  controller: _confirmPasswordController,
                  placeholder: const Text('Confirm password'),
                  obscureText: _obscureConfirmPassword,
                  prefix: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.lock_outlined,
                        size: 18, color: Colors.grey[600]),
                  ),
                  suffix: GestureDetector(
                    onTap: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed:
                        authProvider.isLoading ? null : _handleRegister,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 16),

                // Back to login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
