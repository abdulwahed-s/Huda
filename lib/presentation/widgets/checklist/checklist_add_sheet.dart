import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/checklist_item.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/checklist/checklist_items.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';

typedef ChecklistNewItem = ({
  String title,
  ChecklistItemType type,
  RepetitionFrequency frequency,
});

class ChecklistAddController extends ChangeNotifier {
  ChecklistAddController() {
    name.addListener(notifyListeners);
  }

  final name = TextEditingController();
  ChecklistItemType _type = ChecklistItemType.custom;
  RepetitionFrequency _frequency = RepetitionFrequency.daily;

  ChecklistItemType get type => _type;
  set type(ChecklistItemType value) {
    _type = value;
    notifyListeners();
  }

  RepetitionFrequency get frequency => _frequency;
  set frequency(RepetitionFrequency value) {
    _frequency = value;
    notifyListeners();
  }

  bool get ready => name.text.trim().isNotEmpty;

  ChecklistNewItem get result =>
      (title: name.text.trim(), type: _type, frequency: _frequency);

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}

Future<ChecklistNewItem?> showChecklistAddSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final controller = ChecklistAddController();
  return showHudaSheet<ChecklistNewItem>(
    context: context,
    title: l10n.checklistNewItem,
    maxDialogWidth: 560,
    builder: (context) => ChecklistAddForm(controller: controller),
    footer: (context) => _Actions(controller: controller),
  );
}

class ChecklistAddForm extends StatelessWidget {
  const ChecklistAddForm({super.key, required this.controller});

  final ChecklistAddController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;

    Widget label(String text) => Padding(
      padding: EdgeInsets.only(top: space.md, bottom: space.xs),
      child: Text(text, style: theme.textTheme.titleSmall),
    );

    Widget chips<T>(
      List<T> values,
      T selected,
      String Function(T) name,
      ValueChanged<T> onSelected,
    ) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final value in values)
            Padding(
              padding: EdgeInsetsDirectional.only(end: space.xs),
              child: ChoiceChip(
                key: ValueKey('checklist-choice-$value'),
                label: Text(name(value)),
                selected: value == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(value),
              ),
            ),
        ],
      ),
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.checklistItemName, style: theme.textTheme.titleSmall),
          SizedBox(height: space.xs),
          TextField(
            key: const ValueKey('checklist-name'),
            controller: controller.name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (controller.ready) {
                Navigator.of(context).pop(controller.result);
              }
            },
            decoration: InputDecoration(hintText: l10n.checklistItemNameHint),
          ),
          label(l10n.checklistItemGroup),
          chips<ChecklistItemType>(
            checklistGroupOrder,
            controller.type,
            (type) => checklistGroupName(l10n, type),
            (type) => controller.type = type,
          ),
          label(l10n.checklistItemRepeats),
          chips<RepetitionFrequency>(
            RepetitionFrequency.values,
            controller.frequency,
            (frequency) => checklistFrequencyName(l10n, frequency),
            (frequency) => controller.frequency = frequency,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.controller});

  final ChecklistAddController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: space.sm,
        runSpacing: space.xs,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            key: const ValueKey('checklist-add-confirm'),
            onPressed: controller.ready
                ? () => Navigator.of(context).pop(controller.result)
                : null,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.checklistAdd),
          ),
        ],
      ),
    );
  }
}
