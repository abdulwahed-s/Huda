import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/data/models/edition_model.dart' as edition;
import 'package:locale_names/locale_names.dart';
import 'package:huda/l10n/app_localizations.dart';

class ReaderSelectionWidget extends StatelessWidget {
  final List<edition.Data> readers;
  final String? selectedReaderId;
  final String? selectedLanguage;
  final List<String> availableLanguages;
  final Function(String) onReaderSelected;
  final Function(String?) onLanguageSelected;
  final bool isLoading;
  final String? offlineMessage;

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          AppLocalizations.of(context)!.selectReader,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.9)
                : context.primaryColor,
          ),
        ),
        SizedBox(height: 6.h),

        // Offline message
        if (offlineMessage != null)
          Container(
            padding: EdgeInsets.all(10.r),
            margin: EdgeInsets.only(bottom: 14.h),
            decoration: BoxDecoration(
              color: readers.isEmpty
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.red[900]?.withValues(alpha: 0.3)
                      : Colors.red[50])
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.orange[900]?.withValues(alpha: 0.3)
                      : Colors.orange[50]),
              border: Border.all(
                color: readers.isEmpty ? Colors.red[200]! : Colors.orange[200]!,
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  readers.isEmpty ? Icons.error_outline : Icons.info_outline,
                  color: readers.isEmpty ? Colors.red[700] : Colors.orange[700],
                  size: 18.sp,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    offlineMessage!,
                    style: TextStyle(
                      color: readers.isEmpty
                          ? Colors.red[700]
                          : Colors.orange[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Language filter dropdown
        if (availableLanguages.length > 1)
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.primaryColor.withValues(alpha: 0.1),
                      context.primaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButton<String?>(
                  value: selectedLanguage,
                  hint: Text(
                    AppLocalizations.of(context)!.filterByLanguage,
                    style: TextStyle(
                      color: context.primaryColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: Theme.of(context).brightness == Brightness.dark
                      ? context.darkCardBackground
                      : Colors.white,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: context.primaryColor,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.language,
                              size: 20,
                              color:
                                  context.primaryColor.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.allLanguages,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...availableLanguages.map((language) {
                      Locale locale = Locale.fromSubtags(
                        languageCode: language,
                      );
                      return DropdownMenuItem<String?>(
                        value: language,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.language,
                                size: 20,
                                color:
                                    context.primaryColor.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                locale.nativeDisplayLanguage,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: onLanguageSelected,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        // Loading indicator
        if (isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.primaryColor,
                ),
              ),
            ),
          )
        else if (readers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)!.noReadersAvailable,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          // Readers list
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: readers.length,
              itemBuilder: (context, index) {
                final reader = readers[index];
                final isSelected = reader.identifier == selectedReaderId;
                Locale locale =
                    Locale.fromSubtags(languageCode: readers[index].language!);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.primaryColor,
                              context.primaryVariantColor,
                              context.primaryLightColor,
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (Theme.of(context).brightness == Brightness.dark
                            ? context.darkCardBackground
                            : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? context.primaryColor.withValues(alpha: 0.5)
                          : context.primaryColor.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? context.primaryColor.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onReaderSelected(reader.identifier!),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Reader avatar with improved design
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : context.primaryColor
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : context.primaryColor
                                          .withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.record_voice_over,
                                color: isSelected
                                    ? Colors.white
                                    : context.primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Reader info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reader.name ??
                                        AppLocalizations.of(context)!
                                            .unknownReader,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                                  .withValues(alpha: 0.9)
                                              : context.primaryColor
                                                  .withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : context.primaryColor
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      locale.nativeDisplayLanguage,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                                .withValues(alpha: 0.9)
                                            : Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                    .withValues(alpha: 0.9)
                                                : context.primaryColor
                                                    .withValues(alpha: 0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Selection indicator
                            if (isSelected)
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              )
                            else
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: context.primaryColor
                                        .withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
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
