import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/onboarding/onboarding_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/onboarding/onboarding_frame.dart';
import 'package:huda/presentation/widgets/surah/quran_mushaf_page_view.dart';

class MushafStep extends StatefulWidget {
  const MushafStep({super.key});

  @override
  State<MushafStep> createState() => _MushafStepState();
}

class _MushafStepState extends State<MushafStep> {
  late QuranReadingMode _mode = QuranReadingMode.fromStorageValue(
    OnboardingScope.read(
          context,
        ).environment.cache.getData(key: QuranReadingMode.key)
        as String?,
  );

  bool? _wifi;
  bool? _download;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final environment = OnboardingScope.read(context).environment;
      bool wifi;
      try {
        wifi = await environment.onWifi();
      } catch (_) {
        wifi = false;
      }
      if (mounted) setState(() => _wifi = wifi);
    });
  }

  Future<void> _save() async {
    final scope = OnboardingScope.read(context);
    final onboarding = context.read<OnboardingCubit>();
    final environment = scope.environment;
    await environment.cache.saveData(
      key: QuranReadingMode.key,
      value: _mode.storageValue,
    );
    final pack = _mode.pack;
    if (pack != null &&
        (_download ?? _wifi ?? false) &&
        !environment.mushafInstalled(pack)) {
      environment.downloadMushaf(pack);
    }
    if (!mounted) return;
    onboarding.next();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final environment = OnboardingScope.of(context).environment;
    final pack = _mode.pack;
    final installed = pack != null && environment.mushafInstalled(pack);
    final download = _download ?? _wifi ?? false;

    String subtitle(QuranReadingMode mode) {
      final pack = mode.pack;
      if (pack == null) return l10n.setupScrollListHint;
      return environment.mushafInstalled(pack)
          ? l10n.setupMushafReady
          : l10n.setupMushafSize(pack.sizeLabel);
    }

    final Widget? downloadRow;
    if (pack == null) {
      downloadRow = null;
    } else if (installed) {
      downloadRow = OnboardingNotice(
        key: const ValueKey('installed'),
        icon: Icons.download_done_rounded,
        message: l10n.setupMushafReady,
      );
    } else {
      final wifi = _wifi;
      downloadRow = HudaCard(
        key: const ValueKey('download'),
        padding: EdgeInsets.zero,
        child: MergeSemantics(
          child: HudaSettingsRow(
            icon: Icons.download_rounded,
            title: l10n.setupDownloadNow,
            subtitle: wifi == false && !download
                ? l10n.setupDownloadCellular
                : l10n.setupDownloadWifi(pack.sizeLabel),
            trailing: wifi == null
                ? const SizedBox(
                    width: 52,
                    child: Center(child: HudaLampSpinner(size: 20)),
                  )
                : Switch(
                    key: const ValueKey('onboarding-mushaf-download'),
                    value: download,
                    onChanged: (value) {
                      HudaHaptics.selection(context);
                      setState(() => _download = value);
                    },
                  ),
          ),
        ),
      );
    }

    return OnboardingStepFrame(
      message: l10n.setupMushafMessage,
      primary: OnboardingAction(
        l10n.continueButton,
        advances: true,
        onPressed: _save,
      ),
      children: [
        OnboardingOptionGrid(
          minTileWidth: 150,
          children: [
            for (final mode in QuranReadingMode.values)
              OnboardingOption(
                key: ValueKey('onboarding-mushaf-${mode.name}'),
                title: mode.localizedLabel(context),
                subtitle: subtitle(mode),
                selected: _mode == mode,
                previewWidth: 96,
                preview: _MushafPreview(mode: mode),
                onTap: () => setState(() => _mode = mode),
              ),
          ],
        ),
        if (downloadRow != null) ...[
          SizedBox(height: space.md),
          HudaStateSwitcher(
            stateKey: installed ? 'installed' : 'download',
            child: downloadRow,
          ),
        ],
      ],
    );
  }
}

class _MushafPreview extends StatelessWidget {
  const _MushafPreview({required this.mode});

  final QuranReadingMode mode;

  static String? asset(QuranReadingMode mode) => switch (mode) {
    QuranReadingMode.scrollList => null,
    QuranReadingMode.horizontalPages =>
      'assets/images/onboarding/mushaf_hafs.webp',
    QuranReadingMode.tajweed => 'assets/images/onboarding/mushaf_tajweed.webp',
    QuranReadingMode.indopak => 'assets/images/onboarding/mushaf_indopak.webp',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final path = asset(mode);
    final Widget page;
    if (path == null) {
      page = Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.space.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.clip,
              textScaler: TextScaler.noScaling,
              style: context.type.ayah.copyWith(
                fontSize: 13,
                height: 1.6,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            for (final width in const [1.0, 0.7]) ...[
              FractionallySizedBox(
                widthFactor: width,
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      );
    } else {
      final tinted = mode.pack?.tinted ?? false;
      page = Image.asset(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        color: tinted ? scheme.onSurface : null,
        colorBlendMode: tinted ? BlendMode.srcIn : null,
        filterQuality: FilterQuality.medium,
      );
    }
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color:
                mode.pack != null &&
                    !mode.pack!.tinted &&
                    theme.brightness == Brightness.dark
                ? Color.alphaBlend(
                    scheme.surface.withValues(alpha: 0.32),
                    scheme.inverseSurface,
                  )
                : Color.alphaBlend(
                    tokens.gilt.withValues(alpha: 0.06),
                    scheme.surfaceContainerLow,
                  ),
            borderRadius: BorderRadius.circular(tokens.radius.sm),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radius.sm),
            child: Padding(
              padding: EdgeInsets.fromLTRB(4, path == null ? 4 : 28, 4, 4),
              child: page,
            ),
          ),
        ),
      ),
    );
  }
}
