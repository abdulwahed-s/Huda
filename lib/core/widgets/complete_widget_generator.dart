import 'dart:async';
import 'package:flutter/material.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/core/widgets/home_widget_renderer.dart';
import 'package:huda/core/services/widget_service.dart';

class BackgroundWidgetService {
  static Timer? _backgroundTimer;
  static bool _isInitialized = false;
  static bool _isGenerating = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔄 Initializing background widget service...');

    _backgroundTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      _performBackgroundUpdate();
    });

    _isInitialized = true;
    debugPrint('✅ Background widget service initialized with 2-hour intervals');
  }

  static void dispose() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _isInitialized = false;
    debugPrint('🛑 Background widget service disposed');
  }

  static Future<void> _performBackgroundUpdate() async {
    if (_isGenerating) return;

    try {
      _isGenerating = true;
      debugPrint('🔄 Background widget update check...');

      final needsGeneration = await WidgetService.needsCompleteWidgetImage();
      final shouldUpdate = await WidgetService.shouldUpdateWidget();

      debugPrint('🔄 Needs generation: $needsGeneration');
      debugPrint('⏰ Should update: $shouldUpdate');

      if (needsGeneration || shouldUpdate) {
        debugPrint('🎯 Performing background widget update...');

        if (shouldUpdate) {
          debugPrint('📅 Scheduled background update - refreshing verse...');
          await WidgetService.updateWidget();
        }

        await WidgetService.markCompleteWidgetImageNeeded();

        debugPrint('✅ Background update completed');
      }
    } catch (e) {
      debugPrint('❌ Error in background widget update: $e');
    } finally {
      _isGenerating = false;
    }
  }

  static Future<void> triggerUpdate() async {
    await _performBackgroundUpdate();
  }
}

class CompleteWidgetGenerator extends StatefulWidget {
  const CompleteWidgetGenerator({super.key});

  @override
  State<CompleteWidgetGenerator> createState() =>
      _CompleteWidgetGeneratorState();
}

class _CompleteWidgetGeneratorState extends State<CompleteWidgetGenerator>
    with WidgetsBindingObserver {
  bool _isGenerating = false;
  Timer? _uiTimer;
  StreamSubscription? _themeChangeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    BackgroundWidgetService.initialize();

    WidgetService.setThemeChangeCallback(_onThemeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        _checkAndGenerateWidget();
      });
    });

    _uiTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _checkAndGenerateWidget();
      }
    });
  }

  void _onThemeChanged() {
    if (mounted && !_isGenerating) {
      debugPrint(
          '🎨 Theme change received - triggering immediate widget regeneration');

      Future.delayed(const Duration(milliseconds: 100), () {
        _checkAndGenerateWidget();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiTimer?.cancel();
    _themeChangeSubscription?.cancel();

    WidgetService.clearThemeChangeCallback();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && PlatformUtils.isMobile) {
      debugPrint('📱 App resumed - checking for widget updates...');

      Future.delayed(const Duration(milliseconds: 500), () {
        _checkAndGenerateWidget();
      });
    }
  }

  Future<void> _checkAndGenerateWidget() async {
    if (_isGenerating || !mounted) return;

    try {
      setState(() {
        _isGenerating = true;
      });

      debugPrint('🎨 Starting widget generation check...');

      final widgetData = await WidgetService.getCurrentWidgetData();
      final needsGeneration = await WidgetService.needsCompleteWidgetImage();

      debugPrint('📊 Widget data: $widgetData');
      debugPrint('🔄 Needs generation: $needsGeneration');

      if (needsGeneration && mounted) {
        debugPrint('� Generating complete widget image...');

        await Future.delayed(const Duration(milliseconds: 500));

        final imagePath = await HomeWidgetRenderer.generateWidgetImage(
          ayah: widgetData['ayah'] ?? 'إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا',
          surahName: widgetData['surahName'] ?? '',
          verseNumber: widgetData['verseNumber'] ?? '',
          themeName: widgetData['themeName'] ?? 'purple',
          isDarkMode: widgetData['isDarkMode'] ?? false,
          timestamp: widgetData['timestamp'],
        );

        if (imagePath != null) {
          debugPrint('🎉 Image generated successfully: $imagePath');

          await WidgetService.saveCompleteWidgetImagePath(imagePath);

          await HomeWidgetRenderer.cleanupOldImages();
        } else {
          debugPrint('❌ Failed to generate widget image');
        }
      }
    } catch (e) {
      debugPrint('💥 Error in widget generation: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: WidgetService.needsCompleteWidgetImage(),
      builder: (context, snapshot) {
        final needsGeneration = snapshot.data ?? false;

        if (!needsGeneration && !_isGenerating) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: WidgetService.getCurrentWidgetData(),
          builder: (context, dataSnapshot) {
            if (!dataSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            final data = dataSnapshot.data!;

            return Opacity(
              opacity: 0.01,
              child: SizedBox(
                width: 320,
                height: 200,
                child: Material(
                  child: HomeWidgetRenderer.buildHomeWidget(
                    ayah: data['ayah'] ?? 'إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا',
                    surahName: data['surahName'] ?? '',
                    verseNumber: data['verseNumber'] ?? '',
                    themeName: data['themeName'] ?? 'purple',
                    isDarkMode: data['isDarkMode'] ?? false,
                    timestamp: data['timestamp'],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
