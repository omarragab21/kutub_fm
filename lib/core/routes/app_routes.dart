import 'package:flutter/material.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_discover_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/facebook_login_screen.dart';
import '../../features/auth/presentation/pages/category_selection_screen.dart';
import '../../features/home/presentation/pages/main_screen.dart';
import '../../features/book_details/presentation/pages/book_details_page.dart';
import '../../features/book_details/presentation/pages/creator_details_page.dart';
import '../../features/audio_player/presentation/pages/audio_player_screen.dart';
import '../../features/book_reader/presentation/pages/book_reader_screen.dart';
import '../../features/radio/domain/fm_station.dart';
import '../../features/radio/presentation/pages/fm_radio_screen.dart';
import '../../features/radio/presentation/pages/fm_station_detail_screen.dart';
import '../../features/reader_sessions/presentation/pages/create_post_screen.dart';
import '../../features/reader_sessions/presentation/pages/reader_post_detail_screen.dart';
import '../../features/reader_sessions/presentation/pages/reader_sessions_screen.dart';
import '../../features/podcast/presentation/pages/podcast_list_page.dart';
import '../../features/podcast/presentation/pages/podcast_detail_page.dart';
import '../../features/reels/presentation/pages/reel_preview_page.dart';
import '../../features/audio_library/presentation/pages/audio_library_screen.dart';

import 'package:provider/provider.dart';
import '../../features/profile/presentation/pages/settings_screen.dart';
import '../../features/search/presentation/pages/search_screen.dart';
import '../../features/search/presentation/viewmodels/search_view_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String facebookLogin = '/facebook-login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String categorySelection = '/category_selection';
  static const String home = '/home';
  static const String bookDetails = '/book_details';
  static const String creatorDetails = '/creator_details';
  static const String bookReader = '/book_reader';
  static const String audioPlayer = '/audio_player';
  static const String fmRadio = '/fm_radio';
  static const String fmStationDetail = '/fm_station_detail';
  static const String readerSessions = '/reader_sessions';
  static const String readerPostDetail = '/reader_post_detail';
  static const String readerCreatePost = '/reader_create_post';
  static const String settings = '/settings';
  static const String podcastList = '/podcast_list';
  static const String podcastDetail = '/podcast_detail';
  static const String phoneLogin = '/phone-login';
  static const String otpVerification = '/otp-verification';
  static const String search = '/search';
  static const String reelPreview = '/reel_preview';
  static const String library = '/library';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const SplashScreen(),
        );
      case onboarding:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const OnboardingDiscoverScreen(),
        );
      case login:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const LoginScreen(),
        );
      case facebookLogin:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const FacebookLoginScreen(),
        );
      case register:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const RegisterScreen(),
        );
      case emailVerification:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const EmailVerificationScreen(),
        );
      case phoneLogin:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const PhoneLoginScreen(),
        );
      case otpVerification:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const OtpVerificationScreen(),
        );
      case categorySelection:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const CategorySelectionScreen(),
        );
      case home:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const MainScreen(),
        );
      case search:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) => SearchViewModel(),
            child: const SearchScreen(),
          ),
        );
      case bookDetails:
        final bookId = routeSettings.arguments as String?;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => BookDetailsPage(bookId: bookId),
        );
      case creatorDetails:
        final arg = routeSettings.arguments;
        if (arg is! CreatorDetailsArgs) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('بيانات الصفحة غير صالحة')),
            ),
          );
        }
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => CreatorDetailsPage(args: arg),
        );
      case bookReader:
        final arg = routeSettings.arguments;
        if (arg is! BookReaderScreenArgs) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('بيانات الكتاب غير صالحة')),
            ),
          );
        }
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => BookReaderScreen(
            pdfAssetPath: arg.pdfAssetPath,
            bookTitle: arg.bookTitle,
            audioUrl: arg.audioUrl,
            chapterId: arg.chapterId,
            transcript: arg.transcript,
            bookCoverUrl: arg.bookCoverUrl,
          ),
        );
      case audioPlayer:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const AudioPlayerScreen(),
        );
      case fmRadio:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const FMRadioScreen(),
        );
      case readerSessions:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const ReaderSessionsScreen(),
        );
      case readerCreatePost:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const CreatePostScreen(),
          fullscreenDialog: true,
        );
      case settings:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const SettingsScreen(),
        );
      case podcastList:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const PodcastListPage(),
        );
      case podcastDetail:
        final episodeId = routeSettings.arguments as String;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => PodcastDetailPage(episodeId: episodeId),
        );
      case fmStationDetail:
        final arg = routeSettings.arguments;
        if (arg is! FmStation) {
          return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('محطة غير صالحة'))),
          );
        }
        return PageRouteBuilder<void>(
          settings: routeSettings,
          pageBuilder: (context, animation, secondaryAnimation) {
            return FmStationDetailScreen(station: arg);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 420),
        );
      case readerPostDetail:
        final arg = routeSettings.arguments;
        if (arg is! ReaderPostDetailArgs) {
          return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('منشور غير صالح'))),
          );
        }
        return PageRouteBuilder<void>(
          settings: routeSettings,
          pageBuilder: (context, animation, secondaryAnimation) {
            return ReaderPostDetailScreen(postId: arg.postId);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 420),
        );
      case reelPreview:
        final arg = routeSettings.arguments;
        if (arg is! ReelPreviewArgs) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('بيانات المقطع غير صالحة')),
            ),
          );
        }
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => ReelPreviewPage(args: arg),
        );
      case library:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const AudioLibraryScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
