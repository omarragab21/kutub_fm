import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kutub_fm/features/profile/data/repositories/profile_repository.dart';
import 'package:kutub_fm/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:kutub_fm/features/subscription/data/datasources/apple_pay_data_source.dart';
import 'package:kutub_fm/features/subscription/data/datasources/credit_card_payment_data_source.dart';
import 'package:kutub_fm/features/subscription/data/datasources/google_play_data_source.dart';
import 'package:kutub_fm/features/subscription/data/datasources/wallet_payment_data_source.dart';
import 'package:kutub_fm/features/subscription/data/repositories_impl/payment_repository_impl.dart';
import 'package:kutub_fm/features/subscription/presentation/providers/subscription_provider.dart';
import 'core/layout/app_shell.dart';
import 'core/navigation/app_navigation_service.dart';
import 'core/navigation/app_navigation_state.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:kutub_fm/features/auth/presentation/providers/auth_provider.dart';
import 'package:kutub_fm/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:kutub_fm/features/home/data/repositories/home_repository_impl.dart';
import 'core/audio/audio_provider.dart';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:kutub_fm/features/radio/presentation/provider/fm_radio_provider.dart';
import 'package:kutub_fm/features/reader_sessions/presentation/providers/reader_sessions_provider.dart';
import 'package:kutub_fm/features/podcast/presentation/providers/podcast_provider.dart';

// FM radio: `AppRoutes.fmRadio` (list), `AppRoutes.fmStationDetail` (pass `FmStation` as route arguments).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime fetching to use bundled fonts and avoid SocketException
  GoogleFonts.config.allowRuntimeFetching = false;

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AppNavigationState()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AudioProvider, FmRadioProvider>(
          create: (_) => FmRadioProvider()..fetchStations(),
          update: (_, audioProvider, fmRadioProvider) {
            fmRadioProvider!.bindAudioProvider(audioProvider);
            return fmRadioProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ReaderSessionsProvider()),
        ChangeNotifierProvider(create: (_) => PodcastProvider()),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(repository: HomeRepositoryImpl()),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(repository: ProfileRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(
            repository: PaymentRepositoryImpl(
              applePayDataSource: ApplePayDataSource(),
              googlePlayDataSource: GooglePlayDataSource(),
              walletDataSource: WalletPaymentDataSource(),
              creditCardDataSource: CreditCardPaymentDataSource(),
            ),
          ),
        ),
      ],
      child: const KutubFmApp(),
    ),
  );
}

class KutubFmApp extends StatelessWidget {
  const KutubFmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationState = context.read<AppNavigationState>();

    return MaterialApp(
      title: 'كتب FM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: AppNavigationService.navigatorKey,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      navigatorObservers: [navigationState.observer],
      builder: (context, child) => AppShell(child: child ?? const SizedBox()),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'SA')],
      locale: const Locale('ar', 'SA'),
    );
  }
}
