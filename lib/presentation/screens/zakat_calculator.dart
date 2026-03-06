import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_calculator_app_bar.dart';
import 'package:huda/presentation/widgets/zakat_calculator/loading_view.dart';
import 'package:huda/presentation/widgets/zakat_calculator/error_view.dart';
import 'package:huda/presentation/widgets/zakat_calculator/calculate_tab.dart';
import 'package:huda/presentation/widgets/zakat_calculator/results_tab.dart';
import 'package:huda/presentation/widgets/zakat_calculator/settings_tab.dart';
import 'package:huda/presentation/widgets/zakat_calculator/info_dialog.dart';

class ZakatCalculator extends StatefulWidget {
  const ZakatCalculator({super.key});

  @override
  State<ZakatCalculator> createState() => _ZakatCalculatorState();
}

class _ZakatCalculatorState extends State<ZakatCalculator>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Map<AssetCategory, TextEditingController> _controllers = {};
  final _goldPriceController = TextEditingController();
  final _silverPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize controllers for all asset categories
    for (final category in AssetCategory.values) {
      _controllers[category] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _goldPriceController.dispose();
    _silverPriceController.dispose();
    super.dispose();
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => const InfoDialog(),
    );
  }

  void _resetAllFields() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
  }

  void _updateControllers(ZakatCalculatorLoaded state) {
    for (final category in AssetCategory.values) {
      final value = state.calculation.assets[category] ?? 0.0;
      if (_controllers[category]!.text.isEmpty && value > 0) {
        _controllers[category]!.text = value.toString();
      }
    }

    if (_goldPriceController.text.isEmpty) {
      _goldPriceController.text = state.goldPricePerGram.toString();
    }
    if (_silverPriceController.text.isEmpty) {
      _silverPriceController.text = state.silverPricePerGram.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  context.darkCardBackground,
                  context.darkCardBackground.withValues(alpha: 0.8),
                ]
              : [
                  Colors.grey[50]!,
                  Colors.grey[100]!,
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: ZakatCalculatorAppBar(
          onBackPressed: () => Navigator.pop(context),
          onHelpPressed: _showInfoDialog,
          tabController: _tabController,
        ),
        body: BlocBuilder<ZakatCalculatorCubit, ZakatCalculatorState>(
          builder: (context, state) {
            if (state is ZakatCalculatorLoading) {
              return const LoadingView();
            }

            if (state is ZakatCalculatorError) {
              return ErrorView(message: state.message);
            }

            if (state is ZakatCalculatorLoaded) {
              // Update controllers with current values
              _updateControllers(state);

              return TabBarView(
                controller: _tabController,
                children: [
                  CalculateTab(
                    controllers: _controllers,
                    state: state,
                    onResetAll: () {
                      _resetAllFields();
                      context.read<ZakatCalculatorCubit>().resetCalculation();
                    },
                  ),
                  ResultsTab(state: state),
                  SettingsTab(
                    state: state,
                    goldPriceController: _goldPriceController,
                    silverPriceController: _silverPriceController,
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
