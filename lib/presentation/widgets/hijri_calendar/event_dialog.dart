import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/color_to_int.dart';
import 'package:huda/data/models/hijri_event.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hijri_calendar/color_picker_dialog.dart';
import 'package:uuid/uuid.dart';

class EventDialog extends StatefulWidget {
  final bool isEditMode;
  final HijriEvent? oldEvent;
  final Function(HijriEvent) onSave;

  const EventDialog({
    super.key,
    required this.isEditMode,
    this.oldEvent,
    required this.onSave,
  });

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late bool _isAllDay;
  late TimeOfDay? _startTime;
  late TimeOfDay? _endTime;
  late Color _selectedColor;
  late bool _notify;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.oldEvent?.title ?? '');
    _descController =
        TextEditingController(text: widget.oldEvent?.description ?? '');
    _isAllDay = widget.oldEvent?.isAllDay ?? true;
    _startTime = widget.oldEvent?.startTime;
    _endTime = widget.oldEvent?.endTime;
    _selectedColor = widget.oldEvent != null
        ? Color(widget.oldEvent!.colorValue)
        : Colors.blue;
    _notify = widget.oldEvent?.notify ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  widget.isEditMode ? Icons.edit_calendar : Icons.event_note,
                  color: _selectedColor,
                  size: 20.w,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                widget.isEditMode
                    ? AppLocalizations.of(context)!.editEvent
                    : AppLocalizations.of(context)!.addEvent,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: "Amiri",
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.eventTitle,
                    labelStyle: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: "Amiri",
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: "Amiri",
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.description,
                    labelStyle: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: "Amiri",
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: "Amiri",
                  ),
                ),
                SizedBox(height: 12.h),
                SwitchListTile(
                  value: _notify,
                  title: Text(AppLocalizations.of(context)!.receiveNotification,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: "Amiri",
                      )),
                  subtitle:
                      Text(AppLocalizations.of(context)!.getNotifiedAboutEvent,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontFamily: "Amiri",
                          )),
                  onChanged: (value) => setState(() => _notify = value),
                ),
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)!.allDayEvent,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontFamily: "Amiri",
                      )),
                  value: _isAllDay,
                  onChanged: (value) => setState(() => _isAllDay = value!),
                ),
                if (!_isAllDay) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _startTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() => _startTime = picked);
                            }
                          },
                          icon: Icon(Icons.access_time, size: 16.w),
                          label: Text(
                              _startTime != null
                                  ? '${AppLocalizations.of(context)!.startPrefix}: ${_startTime!.format(context)}'
                                  : AppLocalizations.of(context)!.startTime,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: "Amiri",
                              )),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _endTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() => _endTime = picked);
                            }
                          },
                          icon: Icon(Icons.access_time_filled, size: 16.w),
                          label: Text(
                              _endTime != null
                                  ? '${AppLocalizations.of(context)!.endPrefix}: ${_endTime!.format(context)}'
                                  : AppLocalizations.of(context)!.endTime,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: "Amiri",
                              )),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.eventColor,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12.sp,
                              fontFamily: "Amiri",
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _selectedColor.withValues(alpha: 0.3),
                                  blurRadius: (6.r).clamp(0, double.infinity),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => ColorPickerDialog(
                              initialColor: _selectedColor,
                              onColorSelected: (color) {
                                setState(() => _selectedColor = color);
                              },
                            ),
                          ),
                          icon: Icon(Icons.palette, size: 16.w),
                          label: Text(AppLocalizations.of(context)!.chooseColor,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: "Amiri",
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: "Amiri",
                  )),
            ),
            ElevatedButton(
              onPressed: _titleController.text.trim().isEmpty ||
                      (!_isAllDay &&
                          (_startTime == null || _endTime == null)) ||
                      (!_isAllDay &&
                          (_startTime != null &&
                              _startTime!.isAfter(_endTime!)))
                  ? null
                  : () {
                      final event = HijriEvent(
                        id: widget.oldEvent?.id ?? const Uuid().v4(),
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        startTime: _isAllDay ? null : _startTime,
                        endTime: _isAllDay ? null : _endTime,
                        isAllDay: _isAllDay,
                        colorValue: colorToInt(_selectedColor),
                        notify: _notify,
                      );
                      widget.onSave(event);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                widget.isEditMode
                    ? AppLocalizations.of(context)!.saveChanges
                    : AppLocalizations.of(context)!.saveEvent,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: "Amiri",
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
