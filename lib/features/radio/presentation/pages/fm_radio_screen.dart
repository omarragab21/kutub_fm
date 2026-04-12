import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/fm_station.dart';
import '../theme/fm_radio_theme.dart';
import '../widgets/radio_ambient_background.dart';
import '../widgets/fm_station_list_tile.dart';
import '../provider/fm_radio_provider.dart';

/// FM stations directory mapped to an API
class FMRadioScreen extends StatelessWidget {
  const FMRadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FMRadioScreenContent();
  }
}

class _FMRadioScreenContent extends StatefulWidget {
  const _FMRadioScreenContent();

  @override
  State<_FMRadioScreenContent> createState() => _FMRadioScreenContentState();
}

class _FMRadioScreenContentState extends State<_FMRadioScreenContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _openStation(FmStation station) {
    context.read<FmRadioProvider>().playStation(station);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: FmRadioTheme.deepSpace,
        body: Consumer<FmRadioProvider>(
          builder: (context, provider, child) {
            final stations = provider.stations;
            final currentStation = provider.currentStation;
            return Stack(
              children: [
                RadioAmbientBackground(
                  accentArgb: currentStation?.accentColorArgb ?? 0xFFF2CA50,
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  16,
                                ),
                                child: Row(
                                  children: [
                                    if (Navigator.of(context).canPop())
                                      IconButton(
                                        onPressed: () =>
                                            Navigator.of(context).maybePop(),
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                        ),
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '🇪🇬 راديو مصر',
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.5,
                                                  color: Colors.white,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            provider.isDataLoading
                                                ? 'جاري جلب المحطات...'
                                                : '${stations.length} محطة متاحة',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.65),
                                                  height: 1.35,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quran Filter Toggle
                                    _buildFilterToggle(provider),
                                  ],
                                ),
                              ),
                            ),

                            // Search Bar
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                child: TextField(
                                  onChanged: provider.searchStations,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'ابحث عن محطة...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withValues(
                                      alpha: 0.05,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFF2CA50),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            if (provider.isDataLoading)
                              const SliverFillRemaining(
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF2CA50),
                                  ),
                                ),
                              )
                            else if (provider.errorMessage != null)
                              SliverFillRemaining(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Text(
                                      provider.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else if (stations.isEmpty)
                              SliverFillRemaining(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Text(
                                      'لم يتم العثور على محطات تطابق بحثك.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  160,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final station = stations[index];
                                    final n = stations.length > 15
                                        ? 15
                                        : stations.length;
                                    final animIndex = index < n ? index : n;
                                    final start =
                                        animIndex / (n + 1 == 1 ? 2 : n + 1);
                                    final end = (start + 0.38).clamp(0.0, 1.0);
                                    final anim = Tween<double>(begin: 0, end: 1)
                                        .animate(
                                          CurvedAnimation(
                                            parent: _entrance,
                                            curve: Interval(
                                              start,
                                              end,
                                              curve: Curves.easeOutCubic,
                                            ),
                                          ),
                                        );
                                    return FmStationListTile(
                                      station: station,
                                      animation: anim,
                                      onTap: _openStation,
                                    );
                                  }, childCount: stations.length),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _buildFilterToggle(FmRadioProvider provider) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: const []),
  );
}
