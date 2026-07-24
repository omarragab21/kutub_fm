import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../core/audio/audio_provider.dart';
import '../../../../core/audio/audio_models.dart';
import '../../data/datasources/firebase_fm_radio_data_source.dart';
import '../../domain/fm_station.dart';
import '../provider/fm_radio_provider.dart';

class FmStationDetailScreen extends StatefulWidget {
  const FmStationDetailScreen({super.key, required this.station});

  final FmStation station;

  @override
  State<FmStationDetailScreen> createState() => _FmStationDetailScreenState();
}

class _FmStationDetailScreenState extends State<FmStationDetailScreen> {
  late FmRadioProvider _radioProvider;
  Timer? _timer;
  int _listeningSeconds = 0;

  @override
  void initState() {
    super.initState();
    _radioProvider = context.read<FmRadioProvider>();

    // Start a timer to mock the live elapsed duration counter if playing
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final audioProvider = context.read<AudioProvider>();
      final isFmPlaying =
          audioProvider.currentMode == AudioMode.fmRadio &&
          audioProvider.isPlaying;
      if (isFmPlaying) {
        if (mounted) {
          setState(() {
            _listeningSeconds++;
          });
        }
      }
    });

    // Automatically trigger play if not already playing this station
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = context.read<AudioProvider>();
      if (audioProvider.currentMode != AudioMode.fmRadio ||
          audioProvider.currentStation?.id != widget.station.id) {
        _radioProvider.playStation(widget.station);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatListeningTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<FmRadioProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final isPlaying =
        audioProvider.currentMode == AudioMode.fmRadio &&
        audioProvider.isPlaying;
    final isLoading =
        audioProvider.currentMode == AudioMode.fmRadio &&
        audioProvider.isLoading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.47, -0.00),
              radius: 1.00,
              colors: [Color(0xFFF46D6E), Colors.black],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Top Navigation Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Share Button (Circular) on the right (first child in RTL)
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 41,
                          height: 41,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/share.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Title
                      const Text(
                        'البث المباشر',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ThmanyahSans',
                        ),
                      ),

                      // Back Button (Circular) on the left (third child in RTL)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 41,
                          height: 41,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Cover Image & Overlapping Badge Stack
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Cover Image Container
                      Container(
                        width: 240,
                        height: 309,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(21),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          image: DecorationImage(
                            image: widget.station.coverImageUrl.startsWith('http')
                                ? NetworkImage(widget.station.coverImageUrl)
                                : AssetImage(
                                    widget.station.coverImageUrl.isNotEmpty
                                        ? widget.station.coverImageUrl
                                        : 'assets/generated/kotob_fm_logo.png',
                                  ) as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Overlapping LIVE Badge
                      Positioned(
                        top: -15,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 72),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x4CF84749),
                              border: Border.all(
                                width: 1,
                                color: const Color(0xFFF36C6D),
                              ),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '● LIVE',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: Color(0xFFFF5A5A),
                                    fontSize: 14,
                                    fontFamily: 'ThmanyahSans',
                                    fontWeight: FontWeight.w700,
                                    height: 1.50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Station Name Info
                  Text(
                    widget.station.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontFamily: 'ThmanyahSans',
                      fontWeight: FontWeight.w700,
                      height: 1.50,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.station.tagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontFamily: 'ThmanyahSans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Custom Progress Slider & Duration info
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom Progress Bar
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Align(
                          alignment:
                              Alignment.centerRight, // RTL starting point
                          child: FractionallySizedBox(
                            widthFactor: isPlaying ? 0.75 : 0.0,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF36C6D),
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Timings Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Elapsed Counter on the right in RTL layout
                          Text(
                            isPlaying
                                ? _formatListeningTime(_listeningSeconds)
                                : '00:00',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'ThmanyahSans',
                              fontWeight: FontWeight.w400,
                              height: 1.50,
                            ),
                          ),

                          // Live indicator on the left in RTL layout
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF36C6D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Color(0xFFF36C6D),
                                  fontSize: 14,
                                  fontFamily: 'ThmanyahSans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Replay 10s
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/replay_10.svg',
                          width: 30,
                          height: 30,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 22),

                      // Play Button
                      GestureDetector(
                        onTap: () {
                          if (isPlaying) {
                            radioProvider.stop();
                          } else {
                            radioProvider.playStation(widget.station);
                          }
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF46D6E),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : SvgPicture.asset(
                                    isPlaying
                                        ? 'assets/pause.svg'
                                        : 'assets/play.svg',
                                    width: 30,
                                    height: 30,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),

                      // Forward 10s
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/forward_10.svg',
                          width: 30,
                          height: 30,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Programs & Episodes Section
                  _buildProgramsSection(context, radioProvider),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramsSection(
    BuildContext context,
    FmRadioProvider radioProvider,
  ) {
    final programs = widget.station.programs.isNotEmpty
        ? widget.station.programs
        : FirebaseFmRadioDataSource.defaultKutubFmStation.programs;

    if (programs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'برامج الإذاعة والحلقات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'ThmanyahSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final program in programs) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              program.title,
              style: const TextStyle(
                color: Color(0xFFF36C6D),
                fontSize: 16,
                fontFamily: 'ThmanyahSans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final audio in program.audios)
            _buildProgramEpisodeTile(
              context,
              radioProvider,
              program,
              audio,
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildProgramEpisodeTile(
    BuildContext context,
    FmRadioProvider radioProvider,
    RadioProgram program,
    RadioAudio audio,
  ) {
    final isPlayingEpisode = radioProvider.isEpisodePlaying(audio.id);

    return GestureDetector(
      onTap: () {
        radioProvider.playRadioEpisode(
          station: widget.station,
          program: program,
          audio: audio,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isPlayingEpisode
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isPlayingEpisode
                ? const Color(0xFFF36C6D)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPlayingEpisode
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: const Color(0xFFF36C6D),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isPlayingEpisode
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  if (audio.subtitle != null && audio.subtitle!.isNotEmpty)
                    Text(
                      audio.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
