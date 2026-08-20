import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// Handles OAuth callbacks (Google/Apple sign-in redirects)
/// The backend redirects to this screen with ?token=xxx&provider=xxx
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // Get token from URL parameters
      final uri = Uri.base;
      final token = uri.queryParameters['token'];
      final provider = uri.queryParameters['provider'];

      if (token == null || token.isEmpty) {
        _showError('No authentication token received');
        return;
      }

      // Save the token via auth provider
      await ref.read(authStateProvider.notifier).handleOAuthCallback(token, provider);

      if (!mounted) return;

      // Navigate to main screen
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      _showError('Authentication failed: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF7c3aed),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.music_note,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Completing sign in...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: Color(0xFF7c3aed),
            ),
          ],
        ),
      ),
    );
  }
}
</create_file>
