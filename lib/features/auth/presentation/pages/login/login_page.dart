import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'login_screen_controller.dart';
import 'widgets/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _autovalidate = false;

  late final LoginScreenController _controller = LoginScreenController(
    formKey: _formKey,
    emailController: _emailController,
    passwordController: _passwordController,
    enableAutovalidate: _enableAutovalidate,
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _enableAutovalidate() {
    if (_autovalidate) return;
    setState(() {
      _autovalidate = true;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _login() async {
    await _controller.login(context);
  }

  Future<void> _resetPassword() async {
    await _controller.resetPassword(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: LoginForm(
                  formKey: _formKey,
                  autovalidate: _autovalidate,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  isLoading: isLoading,
                  onTogglePasswordVisibility: _togglePasswordVisibility,
                  onResetPasswordPressed: _resetPassword,
                  onLoginPressed: _login,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
