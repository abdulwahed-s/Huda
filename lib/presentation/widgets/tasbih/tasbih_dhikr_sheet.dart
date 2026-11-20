import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_list.dart';

Future<void> showTasbihDhikrSheet(BuildContext context, TasbihUndo undo) {
  final cubit = context.read<TasbihCubit>();
  return showHudaSheet<void>(
    context: context,
    title: AppLocalizations.of(context)!.tasbihYourDhikr,
    builder: (_) => TasbihDhikrSheet(cubit: cubit, undo: undo),
  );
}

class TasbihDhikrSheet extends StatelessWidget {
  const TasbihDhikrSheet({super.key, required this.cubit, required this.undo});

  final TasbihCubit cubit;
  final TasbihUndo undo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: undo,
      builder: (context, _) => BlocBuilder<TasbihCubit, TasbihState>(
        bloc: cubit,
        builder: (context, state) {
          final loaded = state is TasbihLoaded ? state : null;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TasbihDhikrComposer(cubit: cubit),
                SizedBox(height: space.md),
                if ((loaded == null || loaded.notes.isEmpty) &&
                    undo.note == null)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: space.md),
                    child: Text(
                      l10n.tasbihEmptyMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (loaded != null)
                  TasbihDhikrList(state: loaded, cubit: cubit, undo: undo),
              ],
            ),
          );
        },
      ),
    );
  }
}
