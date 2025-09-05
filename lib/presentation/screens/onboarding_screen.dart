import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_bottom_controls.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_page_content.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_pages.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_top_bar.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() async {
    final cacheHelper = getIt<CacheHelper>();
    await cacheHelper.saveData(key: 'onboarding_completed', value: true);

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoute.home,
        (route) => false,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < getOnboardingPages(context).length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              getOnboardingPages(context)[_currentPage]
                  .primaryColor
                  .withValues(alpha: 0.1),
              getOnboardingPages(context)[_currentPage]
                  .secondaryColor
                  .withValues(alpha: 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              OnboardingTopBar(
                currentPage: _currentPage,
                totalPages: getOnboardingPages(context).length,
                currentPageData: getOnboardingPages(context)[_currentPage],
                onSkipPressed: _skipOnboarding,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: getOnboardingPages(context).length,
                  itemBuilder: (context, index) {
                    return OnboardingPageContent(
                      data: getOnboardingPages(context)[index],
                    );
                  },
                ),
              ),
              OnboardingBottomControls(
                currentPage: _currentPage,
                totalPages: getOnboardingPages(context).length,
                onboardingPages: getOnboardingPages(context),
                onPreviousPressed: _previousPage,
                onNextPressed: _nextPage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
