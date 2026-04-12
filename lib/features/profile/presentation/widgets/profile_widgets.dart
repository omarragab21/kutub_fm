import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/user_profile.dart';

/// Animated avatar with a glowing golden gradient border.
class ProfileHeaderWidget extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback? onEditAvatar;

  const ProfileHeaderWidget({
    super.key,
    required this.profile,
    this.onEditAvatar,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.onEditAvatar,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final glowRadius = 12.0 + _glowController.value * 10;
              return Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primaryContainer,
                      Color(0xFFE5A800),
                      AppTheme.primary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4 + _glowController.value * 0.3),
                      blurRadius: glowRadius,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: _buildAvatar(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.profile.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        if (widget.profile.bio != null && widget.profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.profile.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar() {
    final url = widget.profile.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(url),
        backgroundColor: const Color(0xFF1A1A1A),
      );
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFF1A1A1A),
      child: Text(
        _initials(widget.profile.name),
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].isNotEmpty ? parts[0][0] : '?';
  }
}

// ─── Stats ──────────────────────────────────────────────────────────────────

class StatsWidget extends StatelessWidget {
  final UserProfile profile;

  const StatsWidget({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(Icons.menu_book_rounded, profile.totalBooksListened.toString(), 'كتاب'),
          _buildDivider(),
          _buildStat(Icons.access_time_rounded, profile.totalListeningHours, 'ساعة'),
          _buildDivider(),
          _buildStat(Icons.favorite_rounded, profile.favoritesCount.toString(), 'مفضلة'),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
      ],
    );
  }

  Widget _buildDivider() =>
      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.08));
}

// ─── Continue Listening Carousel ────────────────────────────────────────────

class ContinueListeningCarousel extends StatelessWidget {
  final List<ContinueListeningItem> items;

  const ContinueListeningCarousel({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) => _ContinueCard(item: items[index]),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final ContinueListeningItem item;

  const _ContinueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF1C1C1C),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(item.coverUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.surfaceContainerHighest,
                      child: const Icon(Icons.book, color: AppTheme.primary, size: 40),
                    )),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 3,
                    backgroundColor: Colors.black38,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(item.progress * 100).toInt()}% مكتمل',
                  style: TextStyle(
                    color: AppTheme.primary.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Weekly Activity Heatmap ─────────────────────────────────────────────────

class ListeningHeatmap extends StatelessWidget {
  /// 7 values representing minutes listened on Mon-Sun.
  final List<int> weeklyMinutes;

  const ListeningHeatmap({super.key, required this.weeklyMinutes});

  @override
  Widget build(BuildContext context) {
    final days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    final maxMinutes = weeklyMinutes.isEmpty ? 1
        : weeklyMinutes.reduce(math.max).clamp(1, 999999);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('النشاط الأسبوعي',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              )),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final minutes = i < weeklyMinutes.length ? weeklyMinutes[i] : 0;
              final ratio = minutes / maxMinutes;
              final maxBarHeight = 60.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 400 + (i * 60)),
                    curve: Curves.easeOut,
                    width: 28,
                    height: math.max(4.0, maxBarHeight * ratio),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withOpacity(0.4 + 0.6 * ratio),
                        ],
                      ),
                      boxShadow: ratio > 0.5
                          ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8)]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[i].substring(0, 1),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: Colors.deepOrange.shade400, size: 14),
              const SizedBox(width: 4),
              Text('استمعت هذا الأسبوع',
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
