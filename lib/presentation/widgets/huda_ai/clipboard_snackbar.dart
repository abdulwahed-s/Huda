import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class ClipboardSnackbar {
  static void showCopySnackbar(
    BuildContext context,
    String text,
    AppLocalizations appLocalizations,
  ) {
    Clipboard.setData(ClipboardData(text: text));

    HudaSnackBar.success(
      context,
      message: appLocalizations.messageCopied,
      duration: const Duration(seconds: 2),
    );
  }
}
