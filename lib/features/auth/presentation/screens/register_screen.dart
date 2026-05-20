import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/dialogs/loading_dialog.dart';
import '../providers/auth_provider.dart';
import '../../utils/auth_helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _autovalidate = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String _userTypeLabel = '';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim().toLowerCase();
    String label = '';
    if (email.isNotEmpty && email.contains('@')) {
      final userType = detectUserTypeFromEmail(email);
      if (userType == 'student') {
        label = 'نوع الحساب: طالب';
      } else if (userType == 'employee') {
        label = 'نوع الحساب: موظف';
      } else {
        label = 'نوع الحساب: مستخدم عادي';
      }
    }
    
    if (label != _userTypeLabel) {
      setState(() {
        _userTypeLabel = label;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        final File file = File(image.path);
        final int sizeInBytes = await file.length();
        final double sizeInMB = sizeInBytes / (1024 * 1024);

        if (sizeInMB > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('حجم الصورة يجب ألا يتجاوز 5 ميجابايت'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        setState(() {
          _profileImage = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر اختيار الصورة'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    
    if (!_autovalidate) {
      setState(() {
        _autovalidate = true;
      });
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب الموافقة على الشروط وسياسة الخصوصية'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    LoadingDialog.show(context, message: 'جاري إنشاء الحساب...');

    try {
      await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
        profileImage: _profileImage,
      );
    } catch (e) {
      // Handled by Provider
    } finally {
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }

    if (!mounted) return;

    if (authProvider.status == AuthStatus.error && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (authProvider.status == AuthStatus.emailNotVerified) {
      Navigator.pushReplacementNamed(context, AppRoutes.emailVerification);
    } else if (authProvider.status == AuthStatus.authenticated) {
      final nextRoute = authProvider.isCategorySelectionCompleted
          ? AppRoutes.home
          : AppRoutes.categorySelection;
      Navigator.pushNamedAndRemoveUntil(context, nextRoute, (_) => false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();

    LoadingDialog.show(context, message: 'جاري تسجيل الدخول بجوجل...');

    try {
      await authProvider.signInWithGoogle();
    } catch (e) {
      // Handled by Provider
    } finally {
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }

    if (!mounted) return;

    if (authProvider.status == AuthStatus.error &&
        authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage!,
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (authProvider.status == AuthStatus.emailNotVerified) {
      Navigator.pushReplacementNamed(context, AppRoutes.emailVerification);
    } else if (authProvider.status == AuthStatus.authenticated) {
      final nextRoute = authProvider.isCategorySelectionCompleted
          ? AppRoutes.home
          : AppRoutes.categorySelection;
      Navigator.pushNamedAndRemoveUntil(context, nextRoute, (_) => false);
    }
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'إنشاء حساب جديد',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'سنرسل رسالة تفعيل إلى بريدك بعد التسجيل',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null,
                                child: _profileImage == null
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          context,
                          label: 'الاسم',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: AuthValidators.validateFullName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        autofillHints: const [AutofillHints.email],
                        decoration: _inputDecoration(
                          context,
                          label: 'البريد الإلكتروني',
                          icon: Icons.mail_outline_rounded,
                        ),
                        validator: AuthValidators.validateEmail,
                      ),
                      if (_userTypeLabel.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _userTypeLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                      const SizedBox(height: 16),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _passwordController,
                        builder: (context, value, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.newPassword],
                                textDirection: TextDirection.ltr,
                                decoration: _inputDecoration(
                                  context,
                                  label: 'كلمة المرور',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: AuthValidators.validatePassword,
                              ),
                              if (value.text.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _PasswordStrengthIndicator(password: value.text),
                                const SizedBox(height: 12),
                                _PasswordChecklist(password: value.text),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _passwordController,
                        builder: (context, passwordValue, child) {
                          return TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            autofillHints: const [AutofillHints.newPassword],
                            textDirection: TextDirection.ltr,
                            decoration: _inputDecoration(
                              context,
                              label: 'تأكيد كلمة المرور',
                              icon: Icons.lock_reset_rounded,
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                ),
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => AuthValidators.validateConfirmPassword(value, passwordValue.text),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'أوافق على الشروط والأحكام وسياسة الخصوصية',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: (isLoading) ? null : _register,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text('إنشاء الحساب'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('تسجيل الدخول بجوجل'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'لديك حساب بالفعل؟',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  ),
                            child: const Text('تسجيل الدخول'),
                          ),
                        ],
                      ),
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

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = AuthValidators.calculatePasswordStrength(password);
    Color color;
    String label;
    double widthFactor;

    switch (strength) {
      case PasswordStrength.empty:
        color = Colors.transparent;
        label = '';
        widthFactor = 0;
        break;
      case PasswordStrength.weak:
        color = Colors.redAccent;
        label = 'ضعيفة';
        widthFactor = 0.25;
        break;
      case PasswordStrength.medium:
        color = Colors.orangeAccent;
        label = 'متوسطة';
        widthFactor = 0.5;
        break;
      case PasswordStrength.strong:
        color = Colors.lightGreen;
        label = 'قوية';
        widthFactor = 0.75;
        break;
      case PasswordStrength.veryStrong:
        color = Colors.green;
        label = 'قوية جدًا';
        widthFactor = 1.0;
        break;
    }

    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'قوة كلمة المرور',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  width: constraints.maxWidth * widthFactor,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            );
          }
        ),
      ],
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChecklistItem(
          label: '8 أحرف على الأقل',
          isValid: AuthValidators.hasMinLength(password),
        ),
        _ChecklistItem(
          label: 'حرف كبير',
          isValid: AuthValidators.hasUppercase(password),
        ),
        _ChecklistItem(
          label: 'حرف صغير',
          isValid: AuthValidators.hasLowercase(password),
        ),
        _ChecklistItem(
          label: 'رقم',
          isValid: AuthValidators.hasNumber(password),
        ),
        _ChecklistItem(
          label: 'رمز خاص',
          isValid: AuthValidators.hasSpecialCharacter(password),
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.label, required this.isValid});
  final String label;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isValid ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isValid ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
