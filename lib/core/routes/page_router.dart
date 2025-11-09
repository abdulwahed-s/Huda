import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/bookmark_service.dart';
import 'package:huda/core/services/gemini_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/athkar/athkar_cubit.dart';
import 'package:huda/cubit/athkar_details/athkar_details_cubit.dart';
import 'package:huda/cubit/audio/audio_cubit.dart';
import 'package:huda/cubit/book_detail/book_detail_cubit.dart';
import 'package:huda/cubit/book_languages/book_languages_cubit.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/cubit/books/books_cubit.dart';
import 'package:huda/cubit/books/languages_cubit.dart';
import 'package:huda/cubit/chapters/chapters_cubit.dart';
import 'package:huda/cubit/chat/chat_cubit.dart';
import 'package:huda/cubit/checklist/checklist_cubit.dart';
import 'package:huda/cubit/download_manager/download_manager_cubit.dart';
import 'package:huda/cubit/hadith/hadith_cubit.dart';
import 'package:huda/cubit/hadith_details/hadith_details_cubit.dart';
import 'package:huda/cubit/hijri_calendar/hijri_calendar_cubit.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/cubit/qiblah/qiblah_cubit.dart';
import 'package:huda/cubit/quran/quran_cubit.dart';
import 'package:huda/cubit/settings/settings_cubit.dart';
import 'package:huda/cubit/tafsir/tafsir_cubit.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/cubit/translation/translation_cubit.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/data/api/audio_services.dart';
import 'package:huda/data/api/tafsir_services.dart';
import 'package:huda/data/api/translation_services.dart';
import 'package:huda/data/repository/audio_repository.dart';
import 'package:huda/data/repository/tafsir_repository.dart';
import 'package:huda/data/repository/translation_repository.dart';
import 'package:huda/presentation/screens/athkar.dart';
import 'package:huda/presentation/screens/athkar_details.dart';
import 'package:huda/presentation/screens/book_detail.dart';
import 'package:huda/presentation/screens/bookmarks.dart';
import 'package:huda/presentation/screens/books.dart';
import 'package:huda/presentation/screens/checklist.dart';
import 'package:huda/presentation/screens/hadith.dart';
import 'package:huda/presentation/screens/hadith_chapters.dart';
import 'package:huda/presentation/screens/hadith_details.dart';
import 'package:huda/presentation/screens/hijri_calendar.dart';
import 'package:huda/presentation/screens/home.dart';
import 'package:huda/presentation/screens/home_quran.dart';
import 'package:huda/presentation/screens/huda_ai.dart';
import 'package:huda/presentation/screens/notifications.dart';
import 'package:huda/presentation/screens/pdf_view.dart';
import 'package:huda/presentation/screens/prayer_times.dart';
import 'package:huda/presentation/screens/qiblah.dart';
import 'package:huda/presentation/screens/settings.dart';
import 'package:huda/presentation/screens/surah_screen.dart';
import 'package:huda/presentation/screens/tasbih.dart';
import 'package:huda/presentation/screens/onboarding_screen.dart';
import 'package:huda/presentation/screens/feedback_screen.dart';
import 'package:huda/presentation/screens/widget_management_screen.dart';
import 'package:huda/presentation/screens/zakat_calculator.dart';

class PageRouter {
  Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
      case AppRoute.home:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<HomeCubit>(
            create: (context) => HomeCubit(),
            child: const Home(),
          ),
        );
      case AppRoute.homeQuran:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<QuranCubit>(
            create: (context) => (QuranCubit()),
            child: const HomeQuran(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case AppRoute.surahScreen:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) {
            final args = settings.arguments as Map<String, dynamic>;
            return MultiRepositoryProvider(
              providers: [
                RepositoryProvider<AudioRepository>(
                  create: (_) =>
                      AudioRepository(audioServices: AudioServices()),
                ),
                RepositoryProvider<TafsirRepository>(
                  create: (_) =>
                      TafsirRepository(tafsirServices: TafsirServices()),
                ),
                RepositoryProvider<TranslationRepository>(
                  create: (_) => TranslationRepository(
                      translationServices: TranslationServices()),
                ),
              ],
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<AudioCubit>(
                    create: (context) =>
                        AudioCubit(context.read<AudioRepository>()),
                  ),
                  BlocProvider<TafsirCubit>(
                    create: (context) =>
                        TafsirCubit(context.read<TafsirRepository>()),
                  ),
                  BlocProvider<TranslationCubit>(
                    create: (context) =>
                        TranslationCubit(context.read<TranslationRepository>()),
                  ),
                ],
                child: SurahScreen(
                  surahInfo: args['surahInfo'],
                  scrollToAyah: args['scrollToAyah'],
                  shouldRestorePosition: args['shouldRestorePosition'],
                ),
              ),
            );
          },
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.settings:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<SettingsCubit>(
            create: (context) => SettingsCubit(),
            child: const Settings(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case AppRoute.bookmarks:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<BookmarksCubit>(
            create: (context) => BookmarksCubit(
              bookmarkService: getIt<BookmarkService>(),
            ),
            child: const BookmarksPage(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case AppRoute.widgetManagement:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => const WidgetManagementScreen(),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case AppRoute.prayerTimes:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<PrayerTimesCubit>(
            create: (context) => PrayerTimesCubit(getIt<CacheHelper>()),
            child: const PrayerTimes(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );

      case AppRoute.notification:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<NotificationsCubit>(
            create: (context) => NotificationsCubit(),
            child: const Notifications(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.athkar:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<AthkarCubit>(
            create: (context) => AthkarCubit(),
            child: const AthkarScreen(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.athkarDetail:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) {
            final args = settings.arguments as Map<String, String>;
            return BlocProvider<AthkarDetailsCubit>(
              create: (context) => AthkarDetailsCubit(),
              child: AthkarDetails(
                athkarId: args['athkarId']!,
                title: args['title']!,
                titleEn: args['titleEn']!,
              ),
            );
          },
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.hadith:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<HadithCubit>(
            create: (context) => HadithCubit()..fetchHadithBooks(),
            child: const Hadith(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.hadithChapters:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) {
            final args = settings.arguments as Map<String, String>;
            return BlocProvider<ChaptersCubit>(
              create: (context) =>
                  ChaptersCubit()..fetchChaptersByBook(args['bookName']!),
              child: HadithChapters(
                fullBookName: args['fullBookName']!,
                bookName: args['bookName']!,
              ),
            );
          },
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.hadithDetails:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) {
            final args = settings.arguments as Map<String, String>;
            return BlocProvider<HadithDetailsCubit>(
              create: (context) => HadithDetailsCubit()
                ..fetchHadithDetails(args['chapterNumber']!, args['bookName']!, 1),
              child: HadithDetails(
                chapterNumber: args['chapterNumber']!,
                bookName: args['bookName']!,
                chapterName: args['chapterName']!,
              ),
            );
          },
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.qiblah:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<QiblahCubit>(
            create: (context) => QiblahCubit()..loadQiblah(),
            child: const QiblahScreen(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );

      case AppRoute.tasbih:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<TasbihCubit>(
            create: (context) => TasbihCubit()..loadTasbih(),
            child: const Tasbih(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.hijriCalendar:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<HijriCalendarCubit>(
            create: (context) => HijriCalendarCubit(),
            child: const HijriCalendarScreenNew(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.books:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => MultiBlocProvider(
            providers: [
              BlocProvider<BooksCubit>(
                create: (context) => BooksCubit(),
              ),
              BlocProvider<LanguagesCubit>(
                create: (context) => LanguagesCubit(),
              ),
            ],
            child: const BooksScreen(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.bookDetail:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) {
            final args = settings.arguments as Map<String, String>;
            return MultiBlocProvider(
              providers: [
                BlocProvider<BookDetailCubit>(
                  create: (context) => BookDetailCubit(),
                ),
                BlocProvider<BookLanguagesCubit>(
                  create: (context) => BookLanguagesCubit(),
                ),
                BlocProvider<DownloadManagerCubit>(
                  create: (context) => DownloadManagerCubit(),
                ),
              ],
              child: BookDetailScreen(
                bookId: int.parse(args['bookId']!),
                language: args['language']!,
                title: args['title']!,
              ),
            );
          },
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.pdfView:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => PdfView(
            pdfUrl: settings.arguments as String,
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.hudaAI:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<ChatCubit>(
            create: (context) => ChatCubit(GeminiService()),
            child: const ChatScreen(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.islamicChecklist:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<ChecklistCubit>(
            create: (context) => ChecklistCubit(),
            child: const IslamicChecklistScreen(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.feedback:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<RatingCubit>(
            create: (context) => RatingCubit(),
            child: const FeedbackScreen(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.zakatCalculator:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<ZakatCalculatorCubit>(
            create: (context) => ZakatCalculatorCubit(),
            child: const ZakatCalculator(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
    }
    return null;
  }
}
