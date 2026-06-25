import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  static const List<Color> _palette = [
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF3949AB),
    Color(0xFF1E88E5),
    Color(0xFF039BE5),
    Color(0xFF00ACC1),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFFB8C00),
    Color(0xFFF4511E),
    Color(0xFF6D4C41),
  ];

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selected = widget.initialColor;

  List<Color> get _colors => [
        if (!ColorPickerDialog._palette.contains(widget.initialColor))
          widget.initialColor,
        ...ColorPickerDialog._palette,
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: _selected.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.palette, color: _selected, size: 20.w),
          ),
          SizedBox(width: 10.w),
          Text(l10n.pickColor, style: TextStyle(fontSize: 16.sp)),
        ],
      ),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 12.w,
          runSpacing: 12.w,
          children: [
            for (final color in _colors) _swatch(color),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: TextStyle(fontSize: 12.sp)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selected,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          onPressed: () {
            widget.onColorSelected(_selected);
            Navigator.of(context).pop();
          },
          child: Text(l10n.select, style: TextStyle(fontSize: 12.sp)),
        ),
      ],
    );
  }

  Widget _swatch(Color color) {
    final isSelected = color.toARGB32() == _selected.toARGB32();
    return GestureDetector(
      onTap: () => setState(() => _selected = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3.w,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.6 : 0.3),
              blurRadius: isSelected ? 10 : 4,
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: isSelected
            ? Icon(Icons.check, color: Colors.white, size: 22.w)
            : null,
      ),
    );
  }
}
