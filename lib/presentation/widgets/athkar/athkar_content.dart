import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/athkar/athkar_body_content.dart';
import 'package:huda/presentation/widgets/athkar/sliver_app_bar_content.dart';

class AthkarContent extends StatefulWidget {
  const AthkarContent({super.key});

  @override
  State<AthkarContent> createState() => _AthkarContentState();
}

class _AthkarContentState extends State<AthkarContent>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  late AnimationController _searchAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> searchAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeInOut,
    );

    // Start list animation
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (_showSearch) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? context.darkCardBackground : context.lightSurface,
      body: CustomScrollView(
        slivers: [
          SliverAppBarContent(
            isDark: isDark,
            showSearch: _showSearch,
            searchAnimationController: _searchAnimationController,
            searchController: _searchController,
            searchQuery: _searchQuery,
            toggleSearch: _toggleSearch,
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
          ),
          AthkarBodyContent(
            fadeAnimation: _fadeAnimation,
            searchQuery: _searchQuery,
          ),
        ],
      ),
    );
  }
}

