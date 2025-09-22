import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class ColorPickerDialog extends StatelessWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    Color tempColor = initialColor;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: tempColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.palette, color: tempColor, size: 20.w),
          ),
          SizedBox(width: 10.w),
          Text(AppLocalizations.of(context)!.pickColor,
              style: TextStyle(
                fontSize: 16.sp,
                fontFamily: "Amiri",
              )),
        ],
      ),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: tempColor,
          onColorChanged: (color) => tempColor = color,
          enableAlpha: false,
          labelTypes: const [ColorLabelType.rgb],
          pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                fontSize: 12.sp,
                fontFamily: "Amiri",
              )),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: tempColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          child: Text(AppLocalizations.of(context)!.select,
              style: TextStyle(
                fontSize: 12.sp,
                fontFamily: "Amiri",
              )),
          onPressed: () {
            onColorSelected(tempColor);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}