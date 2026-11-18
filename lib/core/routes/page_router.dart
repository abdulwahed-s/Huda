import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/athkar/athkar_cubit.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/cubit/books/books_cubit.dart';
import 'package:huda/cubit/books/languages_cubit.dart';
import 'package:huda/cubit/audios/audios_cubit.dart';
import 'package:huda/cubit/audios/audio_languages_cubit.dart';
import 'package:huda/presentation/screens/audios.dart';
import 'package:huda/presentation/screens/audio_detail.dart';
import 'package:huda/cubit/checklist/checklist_cubit.dart';
import 'package:huda/cubit/hadith/hadith_cubit.dart';
import 'package:huda/cubit/hijri_calendar/hijri_calendar_cubit.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_cubit.dart';
import 'package:huda/core/services/home_preferences_service.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/cubit/islamic_event/islamic_event_cubit.dart';
import 'package:huda/core/services/islamic_event_service.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/cubit/qiblah/qiblah_cubit.dart';
import 'package:huda/cubit/quran/quran_cubit.dart';
import 'package:huda/cubit/settings/settings_cubit.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/cubit/onboarding/onboarding_environment.dart';
import 'package:huda/presentation/screens/athkar.dart';
import 'package:huda/presentation/screens/athkar_details.dart';
import 'package:huda/presentation/screens/book_detail.dart';
import 'package:huda/presentation/screens/bookmarks.dart';
import 'package:huda/presentation/screens/books.dart';
import 'package:huda/presentation/screens/checklist.dart';
import 'package:huda/presentation/screens/hadith.dart';
import 'package:huda/presentation/screens/hadith_chapters.dart';
import 'package:huda/presentation/screens/hadith_details.dart';
import 'package:huda/presentation/widgets/hadith/hadith_refs.dart';
import 'package:huda/presentation/screens/hijri_calendar.dart';
import 'package:huda/presentation/screens/home.dart';
import 'package:huda/presentation/screens/home_quran.dart';
import 'package:huda/presentation/screens/huda_ai.dart';
import 'package:huda/presentation/screens/notifications.dart';
import 'package:huda/presentation/screens/pdf_view.dart';
import 'package:huda/presentation/screens/prayer_times.dart';
import 'package:huda/presentation/screens/qiblah.dart';
import 'package:huda/presentation/screens/settings.dart';
import 'package:huda/presentation/screens/home_customization.dart';
import 'package:huda/presentation/screens/surah_screen.dart';
import 'package:huda/presentation/screens/tasbih.dart';
import 'package:huda/presentation/screens/onboarding_screen.dart';
import 'package:huda/presentation/screens/feedback_screen.dart';
import 'package:huda/presentation/screens/widget_management_screen.dart';
import 'package:huda/presentation/screens/zakat_calculator.dart';
import 'package:huda/presentation/screens/miqaat_lock_screen.dart';
import 'package:huda/cubit/ramadan/ramadan_cubit.dart';
import 'package:huda/presentation/screens/ramadan_screen.dart';
import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/quran_player/download_progress_cubit.dart';
import 'package:huda/presentation/screens/reciters_screen.dart';
import 'package:huda/cubit/quran_radio/quran_radio_cubit.dart';
import 'package:huda/presentation/screens/quran_radio_screen.dart';

class PageRouter {
  Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.onboarding:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<OnboardingCubit>(
            create: (_) =>
                OnboardingCubit(environment: OnboardingEnvironment.live()),
            child: const OnboardingScreen(),
          ),
        );
      case AppRoute.home:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
              BlocProvider<HomeCustomizationCubit>(
                create: (_) =>
                    HomeCustomizationCubit(getIt<HomePreferencesService>()),
              ),
              BlocProvider<IslamicEventCubit>(
                create: (_) =>
                    IslamicEventCubit(service: getIt<IslamicEventService>()),
              ),
            ],
            // Redesigned: the Huda theme, and the theme's page transition.
            child: const Home(),
          ),
        );
      case AppRoute.homeQuran:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<QuranCubit>(
            create: (_) => QuranCubit(),
            child: const HomeQuran(),
          ),
        );
      case AppRoute.surahScreen:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) {
            final args = settings.arguments as Map<String, dynamic>;
            return SurahScreen.route(
              surahInfo: args['surahInfo'],
              scrollToAyah: args['scrollToAyah'],
              shouldRestorePosition: args['shouldRestorePosition'] ?? false,
            );
          },
        );
      case AppRoute.settings:
        // Redesigned: the Huda theme, and the theme's page transition.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<SettingsCubit>(
            create: (context) => SettingsCubit(),
            child: const Settings(),
          ),
        );
      case AppRoute.homeCustomization:
        // Home's editor, opened from Settings. Home reads the saved layout
        // again when it's back on top.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<HomeCustomizationCubit>(
            create: (_) =>
                HomeCustomizationCubit(getIt<HomePreferencesService>()),
            child: const HomeCustomizationScreen(),
          ),
        );
      case AppRoute.bookmarks:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<BookmarksCubit>(
            create: (context) =>
                BookmarksCubit(bookmarkService: getIt<BookmarkService>()),
            child: const BookmarksPage(),
          ),
        );
      case AppRoute.widgetManagement:
        // Redesigned: the Huda theme, and the theme's page transition.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const WidgetManagementScreen(),
        );
      case AppRoute.prayerTimes:
        // Redesigned: the Huda theme, and the theme's page transition.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              PrayerTimes(openSettingsOnLoad: settings.arguments == true),
        );

      case AppRoute.notification:
        // Redesigned: the Huda theme, and the theme's page transition.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<NotificationsCubit>(
            create: (context) => NotificationsCubit(),
            child: const Notifications(),
          ),
        );
      case AppRoute.athkar:
        // Redesigned: the Huda theme, and the theme's page transition
        // (mirrors in RTL).
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<AthkarCubit>(
            create: (context) => AthkarCubit(),
            child: const AthkarScreen(),
          ),
        );
      case AppRoute.athkarDetail:
        // Redesigned. The list opens chapters growing out of their tile;
        // this route is the same page for other callers.
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AthkarDetails.page(
            athkarId: args['athkarId']!,
            title: args['title']!,
            titleEn: args['titleEn']!,
          ),
        );
      case AppRoute.hadith:
        // Redesigned: the Huda theme, and the theme's page transition
        // (mirrors in RTL). Collections grow out of their tiles.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<HadithCubit>(
            create: (context) => HadithCubit()..fetchHadithBooks(),
            child: const Hadith(),
          ),
        );
      case AppRoute.hadithChapters:
        // Redesigned. A collection opens its books inside itself; this
        // route is the same screen for other callers.
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HadithChapters.page(
            collection: HadithCollectionRef(
              slug: args['bookName']!,
              title: args['fullBookName']!,
            ),
          ),
        );
      case AppRoute.hadithDetails:
        // Redesigned. `collectionTitle` is optional.
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HadithDetails.page(
            chapterNumber: args['chapterNumber']!,
            bookName: args['bookName']!,
            chapterName: args['chapterName']!,
            collectionTitle: args['collectionTitle'],
          ),
        );
      case AppRoute.qiblah:
        // Redesigned: the Huda theme, and the theme's page transition
        // (mirrors in RTL).
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<QiblahCubit>(
            create: (context) => QiblahCubit()..loadQiblah(),
            child: const QiblahScreen(),
          ),
        );

      case AppRoute.tasbih:
        // Redesigned: the Huda theme, and the theme's page transition
        // (mirrors in RTL).
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<TasbihCubit>(
            create: (context) => TasbihCubit()..loadTasbih(),
            child: const Tasbih(),
          ),
        );
      case AppRoute.hijriCalendar:
        // Redesigned: the Huda theme, and the theme's page transition.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<HijriCalendarCubit>(
            create: (context) => HijriCalendarCubit(),
            child: const HijriCalendarScreenNew(),
          ),
        );
      case AppRoute.books:
        // Redesigned (`books`): Lantern theme, the theme's page transitions.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<BooksCubit>(create: (context) => BooksCubit()),
              BlocProvider<LanguagesCubit>(
                create: (context) => LanguagesCubit(),
              ),
            ],
            child: const BooksScreen(),
          ),
        );
      case AppRoute.bookDetail:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BookDetailScreen.page(
            bookId: int.parse(args['bookId']!),
            language: args['language']!,
            title: args['title']!,
          ),
        );
      case AppRoute.pdfView:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PdfView(
            pdfUrl: args['url'] as String,
            bookId: args['bookId'] as int?,
            bookTitle: args['bookTitle'] as String?,
            language: args['language'] as String?,
            fallbackPdfUrl: args['fallbackPdfUrl'] as String?,
          ),
        );
      case AppRoute.audios:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider<AudiosCubit>(create: (_) => AudiosCubit()),
              BlocProvider<AudioLanguagesCubit>(
                create: (_) => AudioLanguagesCubit(),
              ),
            ],
            child: const AudiosScreen(),
          ),
        );
      case AppRoute.audioDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AudioDetailScreen.page(
            audioId: int.parse(args['audioId'].toString()),
            language: args['language'].toString(),
            title: args['title'].toString(),
          ),
        );
      case AppRoute.hudaAI:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ChatScreen(),
        );
      case AppRoute.islamicChecklist:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<ChecklistCubit>(
            create: (context) => ChecklistCubit(),
            child: const IslamicChecklistScreen(),
          ),
        );
      case AppRoute.feedback:
        // Redesigned: the Huda theme, and the theme's page transition.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<RatingCubit>(
            create: (context) => RatingCubit(),
            child: const FeedbackScreen(),
          ),
        );
      case AppRoute.zakatCalculator:
        // Redesigned: the Huda theme, and the theme's page transition
        // (mirrors in RTL).
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<ZakatCalculatorCubit>(
            create: (context) => ZakatCalculatorCubit(),
            child: const ZakatCalculator(),
          ),
        );
      case AppRoute.miqaatLock:
        // Redesigned: the Huda theme, and the theme's page transition.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MiqaatLockScreen(),
        );
      case AppRoute.ramadan:
        // Redesigned: the Huda theme, and the theme's page transition.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BlocProvider<RamadanCubit>(
            create: (context) => RamadanCubit(
              getIt<CacheHelper>(),
              hijriCalendarService: getIt<HijriCalendarService>(),
            ),
            child: const RamadanScreen(),
          ),
        );
      case AppRoute.quranAudio:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<DownloadProgressCubit>()),
              BlocProvider.value(value: context.read<QuranPlayerCubit>()),
              BlocProvider.value(value: context.read<PlayerBarCubit>()),
            ],
            child: const RecitersScreen(),
          ),
        );
      case AppRoute.quranRadio:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: context.read<QuranRadioCubit>(),
            child: const QuranRadioScreen(),
          ),
        );
    }
    return null;
  }
}
