import 'package:flutter/material.dart';
import 'package:kutub_fm/core/routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/profile_widgets.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..fetchProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    // Show error snackbar reactively
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.status == ProfileStatus.error &&
          viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // Loading state
    if (viewModel.isLoading || viewModel.profile == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final profile = viewModel.profile!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header App Bar ──────────────────────────────────────────
          SliverAppBar(
            pinned: false,
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 60,
            title: const Text(
              'الملف الشخصي',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              if (viewModel.isSaving)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Avatar & Name ────────────────────────────────────
                Center(child: ProfileHeaderWidget(profile: profile)),
                const SizedBox(height: 20),

                // ── Edit Profile Button ──────────────────────────────
                Center(
                  child: _EditButton(onTap: () => _openEditProfile(context)),
                ),
                const SizedBox(height: 28),

                // ── Stats ────────────────────────────────────────────
                StatsWidget(profile: profile),
                const SizedBox(height: 28),

                // ── Continue Listening ───────────────────────────────
                _SectionTitle(title: 'متابعة الاستماع'),
                const SizedBox(height: 12),
                ContinueListeningCarousel(items: profile.continueListening),
                const SizedBox(height: 28),

                // ── Category Interests ───────────────────────────────
                _SectionTitle(title: 'اهتماماتي'),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.favoriteCategories.map((cat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Weekly Heatmap ───────────────────────────────────
                _SectionTitle(title: 'نشاطي هذا الأسبوع'),
                const SizedBox(height: 12),
                ListeningHeatmap(weeklyMinutes: profile.weeklyActivityMinutes),
                const SizedBox(height: 28),

                // ── Achievements ─────────────────────────────────────
                _SectionTitle(title: 'الإنجازات 🏆'),
                const SizedBox(height: 12),
                _AchievementsRow(totalMinutes: profile.totalListeningMinutes),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditProfile(BuildContext context) {
    final viewModel = context.read<ProfileViewModel>();
    final profile = viewModel.profile;
    if (profile == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: EditProfileScreen(
              profile: profile,
              onSave: (name, bio, categories) {
                viewModel.updateProfile(
                  name: name,
                  bio: bio,
                  favoriteCategories: categories,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryContainer],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, color: Colors.black, size: 16),
            SizedBox(width: 8),
            Text(
              'تعديل الملف الشخصي',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementsRow extends StatelessWidget {
  final int totalMinutes;
  const _AchievementsRow({required this.totalMinutes});

  @override
  Widget build(BuildContext context) {
    final hours = totalMinutes ~/ 60;
    final badges = <({String icon, String title, String desc, bool unlocked})>[
      (icon: '📖', title: 'القارئ', desc: '10 كتب', unlocked: true),
      (icon: '🎧', title: 'المستمع', desc: '50 ساعة', unlocked: hours >= 50),
      (icon: '🌟', title: 'النجم', desc: '100 ساعة', unlocked: hours >= 100),
      (icon: '🔥', title: 'المتحمس', desc: '7 أيام متواصلة', unlocked: true),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final b = badges[i];
          return AnimatedOpacity(
            opacity: b.unlocked ? 1.0 : 0.35,
            duration: const Duration(milliseconds: 400),
            child: Container(
              width: 90,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: b.unlocked
                      ? AppTheme.primary.withOpacity(0.3)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(b.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(
                    b.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    b.desc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 9,
                    ),
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
