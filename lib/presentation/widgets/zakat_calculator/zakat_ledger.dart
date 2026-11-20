import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/data/zakat/zakat_currencies.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_identity.dart';

class ZakatFields {
  ZakatFields() {
    for (final category in AssetCategory.values) {
      amounts[category] = TextEditingController();
    }
  }

  final Map<AssetCategory, TextEditingController> amounts = {};
  final TextEditingController goldPrice = TextEditingController();
  final TextEditingController silverPrice = TextEditingController();

  void fill(ZakatCalculatorLoaded state) {
    for (final category in AssetCategory.values) {
      final controller = amounts[category]!;
      final value = state.calculation.assets[category] ?? 0;
      if (controller.text.isEmpty && value > 0) {
        controller.text = ZakatAmounts.field(value);
      }
    }
    _sync(goldPrice, state.goldPricePerGram);
    _sync(silverPrice, state.silverPricePerGram);
  }

  static void _sync(TextEditingController controller, double price) {
    final shown = ZakatAmounts.field(price);
    if (ZakatAmounts.field(_parse(controller.text)) != shown) {
      controller.text = shown;
    }
  }

  void clearAmounts() {
    for (final controller in amounts.values) {
      controller.clear();
    }
  }

  void dispose() {
    for (final controller in amounts.values) {
      controller.dispose();
    }
    goldPrice.dispose();
    silverPrice.dispose();
  }
}

double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

class ZakatLedger extends StatelessWidget {
  const ZakatLedger({
    super.key,
    required this.state,
    required this.fields,
    required this.overlayContext,
    this.revealFrom = 0,
  });

  final ZakatCalculatorLoaded state;
  final ZakatFields fields;

  final BuildContext overlayContext;

  final int revealFrom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final cubit = context.read<ZakatCalculatorCubit>();
    Widget line(AssetCategory category) => ZakatAmountLine(
      key: ValueKey(category),
      icon: category.icon,
      title: category.title(l10n),
      description: category.description(l10n),
      currency: state.selectedCurrency,
      controller: fields.amounts[category]!,
      onChanged: (text) => cubit.updateAssetValue(category, _parse(text)),
    );
    final basis = state.nisabType;
    final gold = basis == NisabType.gold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HudaReveal(
          index: revealFrom,
          child: HudaSection(
            title: l10n.assets,
            children: [for (final c in zakatAssetCategories) line(c)],
          ),
        ),
        SizedBox(height: space.xl),
        HudaReveal(
          index: revealFrom + 1,
          child: HudaSection(
            title: l10n.liabilities,
            children: [line(AssetCategory.debts)],
          ),
        ),
        SizedBox(height: space.xl),
        HudaReveal(
          index: revealFrom + 2,
          child: HudaSection(
            title: l10n.nisabSettings,
            footer: l10n.nisabDescription,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  space.md,
                  space.md,
                  space.md,
                  space.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.nisabCalculationBasedOn,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: space.sm),
                    SegmentedButton<NisabType>(
                      key: const ValueKey('zakat-basis'),
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: NisabType.gold,
                          label: Text(l10n.gold),
                        ),
                        ButtonSegment(
                          value: NisabType.silver,
                          label: Text(l10n.silver),
                        ),
                      ],
                      selected: {basis},
                      onSelectionChanged: (selection) {
                        HudaHaptics.selection(context);
                        cubit.changeNisabType(selection.first);
                      },
                    ),
                  ],
                ),
              ),
              HudaStateSwitcher(
                stateKey: basis,
                sequential: true,
                child: ZakatAmountLine(
                  key: ValueKey(basis),
                  icon: gold
                      ? AssetCategory.gold.icon
                      : AssetCategory.silver.icon,
                  title: gold ? l10n.goldPricePerGram : l10n.silverPricePerGram,
                  description: l10n.zakatNisabIs(basis.weight(l10n)),
                  currency: state.selectedCurrency,
                  controller: gold ? fields.goldPrice : fields.silverPrice,
                  onChanged: (text) => gold
                      ? cubit.updateGoldPrice(_parse(text))
                      : cubit.updateSilverPrice(_parse(text)),
                  footer: state.nisabPriceIsManual
                      ? Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: space.xs,
                          children: [
                            Text(
                              l10n.zakatPriceYours,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            TextButton(
                              key: const ValueKey('zakat-use-market'),
                              onPressed: () => cubit.useMarketPrice(basis),
                              child: Text(l10n.zakatUseMarketPrice),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              if (ZakatCurrencies.unsteady.contains(state.selectedCurrency))
                _LocalPriceNote(currency: state.selectedCurrency),
              _CurrencyLine(state: state, overlayContext: overlayContext),
            ],
          ),
        ),
      ],
    );
  }
}

class ZakatAmountLine extends StatelessWidget {
  const ZakatAmountLine({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.currency,
    required this.controller,
    required this.onChanged,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String description;
  final String currency;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final label = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudaIconMark(icon),
        SizedBox(width: space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              SizedBox(height: space.xxs / 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (footer != null) ...[SizedBox(height: space.xxs), footer!],
            ],
          ),
        ),
      ],
    );
    final border = OutlineInputBorder(
      borderRadius: tokens.radius.control,
      borderSide: BorderSide(color: scheme.outline),
    );
    final field = Semantics(
      label: title,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*$')),
        ],
        textAlign: TextAlign.end,
        textDirection: TextDirection.ltr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: ZakatAmounts.digits(0),
          hintStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          filled: true,
          fillColor: scheme.surfaceContainerLowest,
          prefixIcon: Padding(
            padding: EdgeInsetsDirectional.only(start: space.sm, end: space.xs),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                currency,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minHeight: 48),
          contentPadding: EdgeInsets.symmetric(
            horizontal: space.sm,
            vertical: space.sm,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: space.md, vertical: space.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final fieldWidth = 150 + 30 * scale;
          final beside = constraints.maxWidth >= fieldWidth + 220 * scale;
          if (beside) {
            return Row(
              children: [
                Expanded(child: label),
                SizedBox(width: space.md),
                SizedBox(width: fieldWidth, child: field),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              label,
              SizedBox(height: space.sm),
              Padding(
                padding: EdgeInsetsDirectional.only(start: 38 + space.md),
                child: field,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocalPriceNote extends StatelessWidget {
  const _LocalPriceNote({required this.currency});

  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    return Padding(
      padding: EdgeInsets.fromLTRB(space.md, space.xxs, space.md, space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: theme.colorScheme.tertiary,
            ),
          ),
          SizedBox(width: space.md),
          Expanded(
            child: Text(
              l10n.zakatLocalPriceNote(currency),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyLine extends StatelessWidget {
  const _CurrencyLine({required this.state, required this.overlayContext});

  final ZakatCalculatorLoaded state;
  final BuildContext overlayContext;

  void _pick(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ZakatCalculatorCubit>();
    final language = Localizations.localeOf(context).languageCode;
    showHudaSheet<void>(
      context: overlayContext,
      title: l10n.currency,
      maxDialogWidth: 440,
      builder: (sheet) => ZakatCurrencyPicker(
        current: state.selectedCurrency,
        languageCode: language,
        region: WidgetsBinding.instance.platformDispatcher.locale.countryCode,
        onPicked: (code) {
          final typed = state.goldIsManual || state.silverIsManual;
          if (code != state.selectedCurrency) {
            HudaHaptics.selection(sheet);
            cubit.changeCurrency(code);
          }
          Navigator.of(sheet).pop();
          if (typed && code != state.selectedCurrency) {
            showHudaToast(
              overlayContext,
              message: l10n.zakatTypedPricesReplaced(code),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final language = Localizations.localeOf(context).languageCode;
    final code = state.selectedCurrency;
    return InkWell(
      key: const ValueKey('zakat-currency'),
      onTap: () => _pick(context),
      child: Semantics(
        button: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: space.md,
              vertical: space.sm,
            ),
            child: Row(
              children: [
                const HudaIconMark(Icons.money_rounded),
                SizedBox(width: space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.currency, style: theme.textTheme.titleSmall),
                      Text(
                        ZakatCurrencies.name(code, language),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: space.xs),
                Text(
                  code,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ZakatCurrencyPicker extends StatefulWidget {
  const ZakatCurrencyPicker({
    super.key,
    required this.current,
    required this.languageCode,
    required this.onPicked,
    this.region,
  });

  final String current;
  final String languageCode;
  final String? region;
  final ValueChanged<String> onPicked;

  @override
  State<ZakatCurrencyPicker> createState() => _ZakatCurrencyPickerState();
}

class _ZakatCurrencyPickerState extends State<ZakatCurrencyPicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _name(String code) => ZakatCurrencies.name(code, widget.languageCode);

  bool _matches(String code) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return code.toLowerCase().contains(q) ||
        _name(code).toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final searching = _query.trim().isNotEmpty;
    final suggested = searching
        ? const <String>[]
        : ZakatCurrencies.suggested(
            current: widget.current,
            languageCode: widget.languageCode,
            region: widget.region,
          );
    final all = [
      for (final code in ZakatCurrencies.all)
        if (_matches(code)) code,
    ]..sort((a, b) => _name(a).compareTo(_name(b)));

    Widget row(String code) {
      final selected = code == widget.current;
      return Material(
        key: ValueKey('zakat-currency-$code'),
        color: selected
            ? scheme.secondaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: tokens.radius.control,
        child: InkWell(
          borderRadius: tokens.radius.control,
          onTap: () => widget.onPicked(code),
          child: Semantics(
            selected: selected,
            button: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: space.md,
                  vertical: space.xs,
                ),
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48),
                      child: Text(
                        code,
                        softWrap: false,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(width: space.md),
                    Expanded(
                      child: Text(
                        _name(code),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (selected) ...[
                      SizedBox(width: space.xs),
                      Icon(Icons.check_rounded, color: scheme.primary),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final border = OutlineInputBorder(
      borderRadius: tokens.radius.control,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    final height = (MediaQuery.sizeOf(context).height * 0.55).clamp(
      200.0,
      460.0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const ValueKey('zakat-currency-search'),
          controller: _search,
          onChanged: (value) => setState(() => _query = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.zakatCurrencySearch,
            filled: true,
            fillColor: scheme.surfaceContainerLowest,
            prefixIcon: const Icon(Icons.search_rounded),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
          ),
        ),
        SizedBox(height: space.sm),
        SizedBox(
          height: height,
          child: all.isEmpty
              ? Center(
                  child: Text(
                    l10n.zakatCurrencyNoMatch(_query.trim()),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    if (suggested.isNotEmpty) ...[
                      SizedBox(height: space.xs),
                      HudaSectionHeader(l10n.zakatCurrencySuggested),
                      for (final code in suggested) row(code),
                      SizedBox(height: space.md),
                      HudaSectionHeader(l10n.zakatCurrencyAll),
                    ],
                    for (final code in all) row(code),
                  ],
                ),
        ),
      ],
    );
  }
}
