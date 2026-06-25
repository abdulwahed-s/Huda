import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/connection/network_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/data/models/reciter_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/quran_player/player_bar_widget.dart';
import 'package:huda/presentation/widgets/reciters/reciter_card.dart';
import 'package:huda/presentation/widgets/reciters/reciters_offline_empty_state.dart';
import 'package:huda/presentation/widgets/reciters/reciters_offline_no_results.dart';
import 'package:huda/presentation/widgets/reciters/reciters_search_bar_delegate.dart';
import 'package:huda/presentation/widgets/reciters/reciters_search_empty_state.dart';
import 'package:huda/presentation/widgets/reciters/reciters_sliver_app_bar.dart';

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen>
    with SingleTickerProviderStateMixin {
  List<Reciter> reciters = [];
  List<Reciter> filteredReciters = [];
  List<Moshaf> rewayat = [];
  List suwar = [];
  bool isLoading = true;
  bool isOffline = false;
  String searchQuery = '';
  String? _downloadDirPath;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _listAnimController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _scrollController.addListener(_onScroll);
    _init();
  }

  void _onScroll() {
    final collapsed = _scrollController.hasClients &&
        _scrollController.offset > (160.h - kToolbarHeight);
    if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
  }

  @override
  void deactivate() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _checkConnectivity();
    await _loadDownloadDir();
    await _fetchReciters();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await NetworkInfo.checkInternetConnectivity();
    if (mounted) {
      setState(() {
        isOffline = !isConnected;
      });
    }
  }

  Future<void> _loadDownloadDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/huda_audio');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }
    if (mounted) setState(() => _downloadDirPath = audioDir.path);
  }

  String _langCode(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'en' ? 'eng' : code;
  }

  Future<void> _fetchAndStoreData() async {
    final lang = _langCode(context);
    final prefs = await SharedPreferences.getInstance();

    try {
      final responses = await Future.wait([
        Dio().get('http://mp3quran.net/api/v3/reciters?language=$lang'),
        Dio().get('http://mp3quran.net/api/v3/moshaf?language=$lang'),
        Dio().get('http://mp3quran.net/api/v3/suwar?language=$lang'),
      ]);

      if (responses[0].data != null) {
        prefs.setString(
            'huda_reciters_$lang', json.encode(responses[0].data['reciters']));
      }
      if (responses[1].data != null) {
        prefs.setString('huda_moshaf_$lang', json.encode(responses[1].data));
      }
      if (responses[2].data != null) {
        prefs.setString(
            'huda_suwar_$lang', json.encode(responses[2].data['suwar']));
      }
    } catch (e) {
      debugPrint('Error storing reciters data: $e');
    }
  }

  Future<void> _fetchReciters() async {
    try {
      final lang = _langCode(context);
      final prefs = await SharedPreferences.getInstance();

      if (prefs.getString('huda_reciters_$lang') == null) {
        if (isOffline) {
          setState(() => isLoading = false);
          return;
        }
        await _fetchAndStoreData();
      }

      final recitersJson = prefs.getString('huda_reciters_$lang');
      final moshafJson = prefs.getString('huda_moshaf_$lang');
      final suwarJson = prefs.getString('huda_suwar_$lang');

      if (recitersJson != null) {
        final data = json.decode(recitersJson) as List<dynamic>;
        final data2 = json.decode(moshafJson!)['riwayat'] as List<dynamic>;
        final data3 = json.decode(suwarJson!) as List<dynamic>;

        var allReciters = data.map((r) => Reciter.fromJson(r)).toList();
        allReciters
            .sort((a, b) => a.letter.toString().compareTo(b.letter.toString()));

        setState(() {
          reciters = allReciters;
          rewayat = data2.map((r) => Moshaf.fromJson(r)).toList();
          suwar = data3;

          if (isOffline) {
            filteredReciters = _filterToDownloadedOnly(allReciters);
          } else {
            filteredReciters = allReciters;
          }
          isLoading = false;
        });
        _listAnimController.forward(from: 0);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching reciters: $e');
      setState(() => isLoading = false);
    }
  }

  List<Reciter> _filterToDownloadedOnly(List<Reciter> allReciters) {
    if (_downloadDirPath == null) return [];
    final dir = Directory(_downloadDirPath!);
    if (!dir.existsSync()) return [];

    final files = dir.listSync().map((f) => f.path.split('/').last).toSet();
    if (files.isEmpty) return [];

    List<Reciter> result = [];
    for (final reciter in allReciters) {
      List<Moshaf> downloadedMoshafs = [];
      for (final moshaf in reciter.moshaf) {
        final surahNumbers = moshaf.surahList.toString().split(',');
        final hasAny = surahNumbers.any((sn) {
          final cubit = context.read<QuranPlayerCubit>();
          return cubit.isDownloaded(reciter, moshaf, sn, _downloadDirPath!);
        });
        if (hasAny) downloadedMoshafs.add(moshaf);
      }
      if (downloadedMoshafs.isNotEmpty) {
        result.add(Reciter(
          id: reciter.id,
          name: reciter.name,
          letter: reciter.letter,
          moshaf: downloadedMoshafs,
        ));
      }
    }
    return result;
  }

  void _filterReciters(String query) {
    setState(() {
      searchQuery = query;
      var base = isOffline ? _filterToDownloadedOnly(reciters) : reciters;
      filteredReciters = base
          .where((r) =>
              r.name.toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
    _listAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              RecitersSliverAppBar(
                l10n: l10n,
                theme: theme,
                isCollapsed: _isCollapsed,
                reciterCount: filteredReciters.length,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: RecitersSearchBarDelegate(
                  controller: _searchController,
                  onChanged: _filterReciters,
                  onClear: () {
                    _searchController.clear();
                    _filterReciters('');
                  },
                  query: searchQuery,
                  isDark: isDark,
                  theme: theme,
                  l10n: l10n,
                  isOffline: isOffline,
                ),
              ),
              _buildBodySliver(l10n, theme, isDark),
              SliverToBoxAdapter(child: SizedBox(height: 90.h)),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PlayerBarWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodySliver(AppLocalizations l10n, ThemeData theme, bool isDark) {
    if (isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (isOffline && filteredReciters.isEmpty && reciters.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: RecitersOfflineEmptyState(
          onRetry: () async {
            setState(() => isLoading = true);
            await _checkConnectivity();
            await _fetchReciters();
          },
        ),
      );
    }

    if (isOffline && filteredReciters.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: RecitersOfflineNoResults(),
      );
    }

    if (filteredReciters.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: RecitersSearchEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final reciter = filteredReciters[index];
          return ReciterCard(
            reciter: reciter,
            suwar: suwar,
            isDark: isDark,
            theme: theme,
            isOffline: isOffline,
            listAnimController: _listAnimController,
            itemIndex: index,
          );
        },
        childCount: filteredReciters.length,
      ),
    );
  }
}
