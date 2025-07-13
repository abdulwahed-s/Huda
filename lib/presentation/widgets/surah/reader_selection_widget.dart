import 'package:flutter/material.dart';
import 'package:huda/data/models/edition_model.dart' as edition;

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
        const Text(
          'Select Reader',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 103, 43, 93),
          ),
        ),
        const SizedBox(height: 8),

        // Offline message
        if (offlineMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: readers.isEmpty ? Colors.red[50] : Colors.orange[50],
              border: Border.all(
                color: readers.isEmpty ? Colors.red[200]! : Colors.orange[200]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  readers.isEmpty ? Icons.error_outline : Icons.info_outline,
                  color: readers.isEmpty ? Colors.red[700] : Colors.orange[700],
                  size: 20,
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String?>(
                  value: selectedLanguage,
                  hint: const Text('Filter by language'),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All languages'),
                    ),
                    ...availableLanguages.map((language) {
                      return DropdownMenuItem<String?>(
                        value: language,
                        child: Text(language),
                      );
                    }),
                  ],
                  onChanged: onLanguageSelected,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),

        // Loading indicator
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 103, 43, 93),
                ),
              ),
            ),
          )
        else if (readers.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No readers available',
                style: TextStyle(color: Colors.grey),
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? const Color.fromARGB(255, 103, 43, 93)
                          : Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    title: Text(
                      reader.name ?? 'Unknown Reader',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? const Color.fromARGB(255, 103, 43, 93)
                            : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      reader.language ?? 'Unknown Language',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color.fromARGB(255, 103, 43, 93),
                          )
                        : null,
                    onTap: () => onReaderSelected(reader.identifier!),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
