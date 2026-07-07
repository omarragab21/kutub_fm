import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/audio/audio_provider.dart';
import '../../../../core/audio/audio_models.dart';
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
      final isFmPlaying = audioProvider.currentMode == AudioMode.fmRadio && audioProvider.isPlaying;
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
      if (audioProvider.currentMode != AudioMode.fmRadio || audioProvider.currentStation?.id != widget.station.id) {
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
    final isPlaying = audioProvider.currentMode == AudioMode.fmRadio && audioProvider.isPlaying;
    final isLoading = audioProvider.currentMode == AudioMode.fmRadio && audioProvider.isLoading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF3D1313), // Deep radiant red/brown center
                Color(0xFF090806), // Very dark outer layer
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button on the far right in RTL
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      // Screen Title in center
                      const Text(
                        'البث المباشر',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ThmanyahSans',
                        ),
                      ),
                      // Share icon on the far left in RTL
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Retro TV/Radio Cover Frame
                Center(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Main Album/Radio Frame
                      Container(
                        width: 280,
                        height: 280,
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF333333), width: 1.5),
                          image: DecorationImage(
                            image: AssetImage(widget.station.coverImageUrl.isNotEmpty 
                                ? widget.station.coverImageUrl 
                                : 'assets/generated/kotob_fm_logo.png'),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                      // Glowing Red LIVE Badge overlapping top center
                      Positioned(
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4B4B),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4B4B).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 8),
                              SizedBox(width: 6),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'ThmanyahSans',
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Station Title & Subtitle
                Text(
                  widget.station.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.station.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),

                const Spacer(flex: 2),

                // Custom Red Progress Bar Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          activeTrackColor: const Color(0xFFFF4B4B),
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: const Color(0xFFFF4B4B),
                          overlayColor: const Color(0xFFFF4B4B).withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                        ),
                        child: Slider(
                          value: isPlaying ? 0.75 : 0.0,
                          onChanged: (val) {},
                        ),
                      ),
                      // Timing indicator Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // "LIVE" status on the right (RTL layout)
                            const Row(
                              children: [
                                Icon(Icons.circle, color: Color(0xFFFF4B4B), size: 8),
                                SizedBox(width: 6),
                                Text(
                                  'مباشر',
                                  style: TextStyle(
                                    color: Color(0xFFFF4B4B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'ThmanyahSans',
                                  ),
                                ),
                              ],
                            ),
                            // Elapsed duration on the left (RTL layout)
                            Text(
                              isPlaying ? _formatListeningTime(_listeningSeconds) : '00:00',
                              style: const TextStyle(
                                color: Colors.white70,
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

                const SizedBox(height: 32),

                // Controls: Backward 10s, Play/Pause/Stop, Forward 10s
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Backward 10s button
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded),
                      color: Colors.white54,
                      iconSize: 32,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 32),
                    // Main Play/Stop Button
                    GestureDetector(
                      onTap: () {
                        if (isPlaying) {
                          radioProvider.stop();
                        } else {
                          radioProvider.playStation(widget.station);
                        }
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4B4B),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.black)
                              : Icon(
                                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 38,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Forward 10s button
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded),
                      color: Colors.white54,
                      iconSize: 32,
                      onPressed: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
