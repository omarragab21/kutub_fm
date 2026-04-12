import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileViewModel = context.watch<ProfileViewModel>();
    final authProvider = context.read<AuthProvider>();
    final profile = profileViewModel.profile;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'الإعدادات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Profile Section ──
              if (profile != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(
                              profile.avatarUrl ??
                                  'https://via.placeholder.com/150',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'user@example.com',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Already handled by _openEditProfile in ProfileScreen,
                          // but could be linked here as well.
                        },
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),
              _buildSectionTitle('الحساب'),
              const SizedBox(height: 12),
              SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'تعديل الملف الشخصي',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'التنبيهات',
                onTap: () {},
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('الدعم والقانونية'),
              const SizedBox(height: 12),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'سياسة الخصوصية',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'مركز المساعدة',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'عن التطبيق',
                onTap: () {},
              ),

              const SizedBox(height: 48),
              SettingsTile(
                icon: Icons.logout_rounded,
                title: 'تسجيل الخروج',
                isDestructive: true,
                onTap: () => _handleLogout(context, authProvider),
              ),
              const SizedBox(height: 40),

              // App Version Info
              Center(
                child: Text(
                  'كتب FM - إصدار 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.primary.withOpacity(0.7),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => LogoutConfirmationDialog(
        onConfirm: () async {
          // Perform logout logic
          await authProvider.logout();

          if (!context.mounted) return;

          // Clear stack and navigate to Login
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        },
      ),
    );
  }
}
