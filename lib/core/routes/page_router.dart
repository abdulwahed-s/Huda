import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/gemini_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/athkar/athkar_cubit.dart';
import 'package:huda/cubit/athkar_details/athkar_details_cubit.dart';
import 'package:huda/cubit/book_detail/book_detail_cubit.dart';
import 'package:huda/cubit/book_languages/book_languages_cubit.dart';
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
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/presentation/screens/athkar.dart';
import 'package:huda/presentation/screens/athkar_details.dart';
import 'package:huda/presentation/screens/book_detail.dart';
import 'package:huda/presentation/screens/books.dart';
import 'package:huda/presentation/screens/checklist.dart';
import 'package:huda/presentation/screens/hadith.dart';
import 'package:huda/presentation/screens/hadith_chapters.dart';
import 'package:huda/presentation/screens/hadith_details.dart';
import 'package:huda/presentation/screens/hijri_calendar_simple.dart';
import 'package:huda/presentation/screens/home.dart';
import 'package:huda/presentation/screens/home_quran.dart';
import 'package:huda/presentation/screens/huda_ai.dart';
import 'package:huda/presentation/screens/notifications.dart';
import 'package:huda/presentation/screens/pdf_view.dart';
import 'package:huda/presentation/screens/prayer_times.dart';
import 'package:huda/presentation/screens/qiblah.dart';
import 'package:huda/presentation/screens/settings.dart';
import 'package:huda/presentation/screens/tasbih.dart';
import 'package:huda/presentation/screens/feedback_screen.dart';
import 'package:huda/presentation/screens/widget_management_screen.dart';

class PageRouter {
  Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
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
            create: (context) => HadithCubit(),
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
              create: (context) => ChaptersCubit(),
              child: HadithChapters(
                bookId: args['bookSlug']!,
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
              create: (context) => HadithDetailsCubit(),
              child: HadithDetails(
                chapterId: args['chapterId']!,
                bookId: args['bookId']!,
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
            create: (context) => QiblahCubit(),
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
            create: (context) => TasbihCubit(),
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
    }
    return null;
  }
}
