import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/podcast_provider.dart';
import '../widgets/podcast_card.dart';
import '../../../../core/routes/app_routes.dart';

class PodcastListPage extends StatelessWidget {
  const PodcastListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final podcastProvider = context.watch<PodcastProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'بودكاست المعرفة',
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 22),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: podcastProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : podcastProvider.error != null
              ? Center(child: Text(podcastProvider.error!))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: podcastProvider.episodes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final episode = podcastProvider.episodes[index];
                    return PodcastCard(
                      episode: episode,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.podcastDetail,
                          arguments: episode.id,
                        );
                      },
                    );
                  },
                ),
    );
  }
}
