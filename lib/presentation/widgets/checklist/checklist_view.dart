import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/checklist_item.dart';
import '../../../cubit/checklist/checklist_cubit.dart';
import '../../widgets/checklist/checklist_item_card.dart';
import '../../widgets/checklist/empty_checklist_view.dart';

class ChecklistView extends StatelessWidget {
  final ChecklistLoaded state;
  final bool isToday;
  final Function(String, bool) onToggle;
  final Function(ChecklistItem) onDelete;

  const ChecklistView({
    super.key,
    required this.state,
    required this.isToday,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.dailyChecklist.items.isEmpty) {
      return EmptyChecklistView(isDark: isDark);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            itemCount: state.dailyChecklist.items.length + 1,
            itemBuilder: (_, index) {
              if (index == 0) return SizedBox(height: 20.h);

              final item = state.dailyChecklist.items[index - 1];
              final isCompleted = state.dailyChecklist.completedItems[item.id] ?? false;

              return ChecklistItemCard(
                item: item,
                isCompleted: isCompleted,
                isToday: isToday,
                isDark: isDark,
                onToggle: () => onToggle(item.id, !isCompleted),
                onDelete: () => onDelete(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
