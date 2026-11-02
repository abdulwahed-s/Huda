import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';

/// A search field that lives in the page (not behind an icon), so finding
/// something is typing: a filled field with a hairline, a search mark, and
/// a clear button once there's text. Esc clears it too.
///
/// The same shape as Athkar's and Hadith's own fields (built before this
/// was shared); later features use this one.
class HudaSearchField extends StatelessWidget {
  const HudaSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.focusNode,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// Enter or the keyboard's search key (added in `prayer`).
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final FocusNode? focusNode;
  final bool autofocus;

  void _clear() {
    controller.clear();
    onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: tokens.radius.control,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _clear},
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: scheme.surfaceContainerLowest,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.athkarClearSearch,
                    onPressed: _clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
