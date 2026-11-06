import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:locale_names/locale_names.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/offline_content_banner.dart';

class ReaderSelectionWidget extends StatelessWidget {
  final List<edition.Data> readers;
  final String? selectedReaderId;
  final String? selectedLanguage;
  final List<String> availableLanguages;
  final Function(String) onReaderSelected;
  final Function(String?) onLanguageSelected;
  final bool isLoading;
  final String? offlineMessage;

  /// The reciter list is being fetched, and whether that's after a tap on
  /// Retry ([retrying]) or on its own.
  final bool loadingReaders;
  final bool retrying;
  final VoidCallback? onRetry;

  const ReaderSelectionWidget({
    super.key,
    required this.readers,
    required this.selectedReaderId,
    required this.selectedLanguage,
    required this.availableLanguages,
    required this.onReaderSelected,
    required this.onLanguageSelected,
    required this.isLoading,
    this.offlineMessage,
    this.loadingReaders = false,
    this.retrying = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String languageName(String code) {
      try {
        return Locale.fromSubtags(languageCode: code).nativeDisplayLanguage;
      } catch (_) {
        return code;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (offlineMessage != null && readers.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: space.sm),
            child: OfflineContentBanner(message: offlineMessage!),
          ),
        if (availableLanguages.length > 1)
          Padding(
            padding: EdgeInsets.only(bottom: space.sm),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.language_rounded),
                contentPadding: EdgeInsets.symmetric(horizontal: space.sm),
                border: OutlineInputBorder(borderRadius: tokens.radius.control),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  key: const ValueKey('quran-reader-language'),
                  value: selectedLanguage,
                  isExpanded: true,
                  hint: Text(l10n.filterByLanguage),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.allLanguages),
                    ),
                    for (final language in availableLanguages)
                      DropdownMenuItem<String?>(
                        value: language,
                        child: Text(languageName(language)),
                      ),
                  ],
                  onChanged: onLanguageSelected,
                ),
              ),
            ),
          ),
        if (isLoading)
          Padding(
            padding: EdgeInsets.all(space.md),
            child: const Center(child: HudaLampSpinner(size: 28)),
          )
        else if (readers.isEmpty)
          // Honest status: updating on its own, then an error with Retry,
          // then "Retrying…" after a tap.
          HudaStatusBanner(
            key: const ValueKey('quran-reciters-status'),
            status: loadingReaders
                ? (retrying ? HudaStatus.retrying : HudaStatus.updating)
                : offlineMessage == l10n.quranOfflineLoading
                ? HudaStatus.updating
                : HudaStatus.failed,
            message: offlineMessage ?? l10n.quranRecitersError,
            onRetry: onRetry,
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: readers.length,
              separatorBuilder: (_, _) => SizedBox(height: space.xs),
              itemBuilder: (context, index) {
                final reader = readers[index];
                final selected = reader.identifier == selectedReaderId;
                final language = reader.language;
                return Semantics(
                  button: true,
                  selected: selected,
                  child: Material(
                    color: selected
                        ? scheme.primary.withValues(alpha: 0.08)
                        : scheme.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: tokens.radius.control,
                      side: BorderSide(
                        color: selected
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: selected
                            ? tokens.stroke.fine
                            : tokens.stroke.hairline,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onReaderSelected(reader.identifier!),
                      child: Padding(
                        padding: EdgeInsets.all(space.sm),
                        child: Row(
                          children: [
                            Icon(
                              Icons.record_voice_over_rounded,
                              color: selected
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            SizedBox(width: space.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reader.name ?? l10n.unknownReader,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  if (language != null)
                                    Text(
                                      languageName(language),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(Icons.check_rounded, color: scheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
