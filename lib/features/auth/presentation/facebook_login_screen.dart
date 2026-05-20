import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:kutub_fm/core/services/firebase_facebook_auth_service.dart';

class FacebookLoginScreen extends StatefulWidget {
  const FacebookLoginScreen({super.key});

  @override
  State<FacebookLoginScreen> createState() => _FacebookLoginScreenState();
}

class _FacebookLoginScreenState extends State<FacebookLoginScreen> {
  final FirebaseFacebookAuthService _authService =
      FirebaseFacebookAuthService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithFacebook() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithFacebook();
    } on FacebookAuthCancelledException catch (error) {
      _setError(error.message);
    } on FirebaseAuthException catch (error) {
      _setError(_mapFirebaseAuthError(error));
    } on FacebookAuthServiceException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Unable to sign in with Facebook. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signOut();
    } on FirebaseAuthException catch (error) {
      _setError(_mapFirebaseAuthError(error));
    } on FacebookAuthServiceException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Unable to sign out. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'The Facebook credential is invalid or has expired.';
      case 'operation-not-allowed':
        return 'Facebook sign-in is not enabled in Firebase Authentication.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Firebase Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facebook Login')),
      body: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        initialData: _authService.getCurrentUser(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLoading) const LinearProgressIndicator(),
                  if (_isLoading) const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    _ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 24),
                  ],
                  if (user == null)
                    _SignedOutContent(
                      isLoading: _isLoading,
                      onLoginPressed: _signInWithFacebook,
                    )
                  else
                    _SignedInContent(
                      user: user,
                      isLoading: _isLoading,
                      onLogoutPressed: _signOut,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SignedOutContent extends StatelessWidget {
  const _SignedOutContent({
    required this.isLoading,
    required this.onLoginPressed,
  });

  final bool isLoading;
  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.facebook,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onLoginPressed,
          icon: const Icon(Icons.facebook),
          label: const Text('Login with Facebook'),
        ),
      ],
    );
  }
}

class _SignedInContent extends StatelessWidget {
  const _SignedInContent({
    required this.user,
    required this.isLoading,
    required this.onLogoutPressed,
  });

  final User user;
  final bool isLoading;
  final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoURL;
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'No name returned';
    final email = user.email?.trim().isNotEmpty == true
        ? user.email!.trim()
        : 'No email returned';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundImage: photoUrl?.trim().isNotEmpty == true
                ? NetworkImage(photoUrl!)
                : null,
            child: photoUrl?.trim().isNotEmpty == true
                ? null
                : const Icon(Icons.person, size: 48),
          ),
        ),
        const SizedBox(height: 32),
        _InfoRow(label: 'Name', value: name),
        _InfoRow(label: 'Email', value: email),
        _InfoRow(label: 'Photo URL', value: photoUrl ?? 'No photo returned'),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onLogoutPressed,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelLarge),
          const SizedBox(height: 6),
          SelectableText(value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
    );
  }
}
