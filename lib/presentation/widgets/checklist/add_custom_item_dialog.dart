import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import '../../../data/models/checklist_item.dart';

class AddCustomItemDialog extends StatefulWidget {
  const AddCustomItemDialog({super.key});

  @override
  State<AddCustomItemDialog> createState() => _AddCustomItemDialogState();
}

class _AddCustomItemDialogState extends State<AddCustomItemDialog> {
  final _titleController = TextEditingController();
  ChecklistItemType _selectedType = ChecklistItemType.custom;
  RepetitionFrequency _selectedFrequency = RepetitionFrequency.daily;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor:
          isDarkMode ? Colors.grey[900] : null, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: isDarkMode ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: context.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.addCustomItem,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Amiri",
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.itemTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: "Amiri",
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.enterItemTitle,
                              hintStyle: TextStyle(
                                fontFamily: "Amiri",
                                color: Colors.grey.shade500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: isDarkMode
                                        ? Colors.grey[600]!
                                        : Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor),
                              ),
                              filled: true,
                              fillColor:
                                  isDarkMode ? Colors.grey[700] : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: "Amiri",
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Type selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.itemType,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: "Amiri",
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isDarkMode
                                      ? Colors.grey[600]!
                                      : Colors.grey.shade300),
                              color:
                                  isDarkMode ? Colors.grey[700] : Colors.white,
                            ),
                            child: DropdownButtonFormField<ChecklistItemType>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              dropdownColor:
                                  isDarkMode ? Colors.grey[800] : Colors.white,
                              items: ChecklistItemType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    _getTypeDisplayName(type),
                                    style: TextStyle(
                                      fontFamily: "Amiri",
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedType = value;
                                  });
                                }
                              },
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Frequency selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.repetitionFrequency,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: "Amiri",
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isDarkMode
                                      ? Colors.grey[600]!
                                      : Colors.grey.shade300),
                              color:
                                  isDarkMode ? Colors.grey[700] : Colors.white,
                            ),
                            child: DropdownButtonFormField<RepetitionFrequency>(
                              value: _selectedFrequency,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              dropdownColor:
                                  isDarkMode ? Colors.grey[800] : Colors.white,
                              items:
                                  RepetitionFrequency.values.map((frequency) {
                                return DropdownMenuItem(
                                  value: frequency,
                                  child: Text(
                                    _getFrequencyDisplayName(frequency),
                                    style: TextStyle(
                                      fontFamily: "Amiri",
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedFrequency = value;
                                  });
                                }
                              },
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey.shade200,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(
                            fontFamily: "Amiri",
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _titleController.text.trim().isEmpty
                            ? null
                            : () {
                                Navigator.of(context).pop({
                                  'title': _titleController.text.trim(),
                                  'type': _selectedType,
                                  'frequency': _selectedFrequency,
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.addItem,
                          style: TextStyle(
                            fontFamily: "Amiri",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTypeDisplayName(ChecklistItemType type) {
    switch (type) {
      case ChecklistItemType.prayer:
        return AppLocalizations.of(context)!.itemTypePrayerShort;
      case ChecklistItemType.quran:
        return AppLocalizations.of(context)!.itemTypeQuranShort;
      case ChecklistItemType.athkar:
        return AppLocalizations.of(context)!.itemTypeAthkarShort;
      case ChecklistItemType.custom:
        return AppLocalizations.of(context)!.itemTypeCustom;
    }
  }

  String _getFrequencyDisplayName(RepetitionFrequency frequency) {
    switch (frequency) {
      case RepetitionFrequency.daily:
        return AppLocalizations.of(context)!.frequencyDaily;
      case RepetitionFrequency.every2Days:
        return AppLocalizations.of(context)!.frequencyEvery2Days;
      case RepetitionFrequency.every3Days:
        return AppLocalizations.of(context)!.frequencyEvery3Days;
      case RepetitionFrequency.every4Days:
        return AppLocalizations.of(context)!.frequencyEvery4Days;
      case RepetitionFrequency.every5Days:
        return AppLocalizations.of(context)!.frequencyEvery5Days;
      case RepetitionFrequency.every6Days:
        return AppLocalizations.of(context)!.frequencyEvery6Days;
      case RepetitionFrequency.weekly:
        return AppLocalizations.of(context)!.frequencyWeekly;
    }
  }
}
