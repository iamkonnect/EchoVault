import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../services/image_utils.dart';
import '../config/api_config.dart';

class AuthModal extends ConsumerStatefulWidget {
  const AuthModal({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AuthModal',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const AuthModal(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  ConsumerState<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends ConsumerState<AuthModal> {
  bool isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF9).withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildTextField(
                        isLogin ? Icons.person_outline : Icons.email_outlined,
                        isLogin ? 'Email or Username' : 'Email Address',
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Enter your email';
                          if (!isLogin &&
                              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        'Password',
                        _passwordController,
                        _obscurePassword,
                        () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Enter your password';
                          if (value.length < 6)
                            return 'Must be at least 6 characters';
                          return null;
                        },
                      ),
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          'Confirm Password',
                          _confirmPasswordController,
                          _obscureConfirmPassword,
                          () {
                            setState(() => _obscureConfirmPassword =
                                !_obscureConfirmPassword);
                          },
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          Icons.alternate_email,
                          'Username',
                          controller: _usernameController,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Enter a username'
                              : null,
                        ),
                      ],
                      if (isLogin) _buildForgotPassword(),
                      if (!isLogin) const SizedBox(height: 16),
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          Icons.person_outline,
                          'Full Name',
                          controller: _nameController,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Enter your name'
                              : null,
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildActionButton(),
                      const SizedBox(height: 24),
                      _buildToggleOption(),
                      _buildSocialLogins(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image(
          image: ImageUtils.getAppLogo(),
          height: 60,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        Text(
          isLogin ? 'Welcome Back' : 'Create Account',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLogin
              ? 'Sign in to continue your journey'
              : 'Join EchoVault and sync your music',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading
            ? null
            : () {
                final emailController = TextEditingController();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1E),
                    title: const Text('Reset Password',
                        style: TextStyle(color: Colors.white)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Enter your email address and we\'ll send you a link to reset your password.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Email Address',
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.3)),
                            prefixIcon: const Icon(Icons.email,
                                color: Color(0xFF8B5CF9)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) return;
                          final authNotifier =
                              ref.read(authStateProvider.notifier);
                          final message =
                              await authNotifier.forgotPassword(email);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message ??
                                    'Reset link sent if email exists'),
                                backgroundColor: const Color(0xFF8B5CF9),
                              ),
                            );
                          }
                        },
                        child: const Text('Send Reset Link',
                            style: TextStyle(
                                color: Color(0xFF8B5CF9),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
        child: Text(
          'Forgot Password?',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String hint, {
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: const Color(0xFF8B5CF9), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String hint,
    TextEditingController controller,
    bool obscureText,
    VoidCallback onToggle, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon:
            const Icon(Icons.lock_outline, color: Color(0xFF8B5CF9), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF8B5CF9),
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF9), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF9).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  final notifier = ref.read(userProvider.notifier);
                  final email = _emailController.text.trim();
                  final password = _passwordController.text;
                  final name = _nameController.text.trim();
                  final username = _usernameController.text.trim();
                  bool success;
                  if (isLogin) {
                    success = await notifier.signIn(email, password);
                  } else {
                    success =
                        await notifier.signUp(name, username, email, password);
                  }
                  if (mounted) {
                    setState(() => _isLoading = false);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isLogin
                              ? 'Signed in successfully!'
                              : 'Account created! Welcome to EchoVault!'),
                          backgroundColor: const Color(0xFF8B5CF9),
                        ),
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Invalid credentials. Please check your email and password.')),
                      );
                    }
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                isLogin ? 'Sign In' : 'Get Started',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildToggleOption() {
    return GestureDetector(
      onTap: () => setState(() => isLogin = !isLogin),
      child: RichText(
        text: TextSpan(
          text:
              isLogin ? "Don't have an account? " : 'Already have an account? ',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
          children: [
            TextSpan(
              text: isLogin ? 'Sign Up' : 'Log In',
              style: const TextStyle(
                color: Color(0xFF8B5CF9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the backend OAuth URL for the given provider
  Future<void> _launchOAuth(String provider) async {
    String baseUrl = ApiConfig.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    final oauthUrl = '$baseUrl/api/auth/$provider';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $provider Sign-In...'),
        backgroundColor: const Color(0xFF8B5CF9),
      ),
    );

    try {
      await launchUrl(
        Uri.parse(oauthUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('$provider OAuth error: $e');
    }
  }

  Widget _buildSocialLogins() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(Icons.g_mobiledata, 'Google', () {
                _launchOAuth('google');
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton(Icons.apple, 'Apple', () {
                _launchOAuth('apple');
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : onTap,
      icon: Icon(icon, color: Colors.white, size: 24),
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        backgroundColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: Colors.white,
      ),
    );
  }
}
