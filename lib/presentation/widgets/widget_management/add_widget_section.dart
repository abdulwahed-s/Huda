import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:home_widget/home_widget.dart';

class AddWidgetSection extends StatefulWidget {
  final bool isDark;

  const AddWidgetSection({
    super.key,
    required this.isDark,
  });

  @override
  State<AddWidgetSection> createState() => _AddWidgetSectionState();
}

class _AddWidgetSectionState extends State<AddWidgetSection> {
  bool _isPinSupported = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPinSupport();
  }

  Future<void> _checkPinSupport() async {
    if (Platform.isAndroid) {
      try {
        final isSupported = await HomeWidget.isRequestPinWidgetSupported();
        if (mounted) {
          setState(() {
            _isPinSupported = isSupported == true;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isPinSupported = false;
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isPinSupported = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPinWidget() async {
    try {
      await HomeWidget.requestPinWidget(
        androidName: 'HudaGlanceWidgetReceiver',
        qualifiedAndroidName: 'com.aw.huda.widget.HudaGlanceWidgetReceiver',
      );
    } catch (e) {
      debugPrint('Error adding widget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.add_to_home_screen_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                AppLocalizations.of(context)!.addWidgetToHomeScreen,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            )
          else if (Platform.isAndroid && _isPinSupported)
            _buildAndroidSupportedContent(context)
          else if (Platform.isAndroid && !_isPinSupported)
            _buildAndroidInstructions(context)
          else if (Platform.isIOS)
            _buildIOSInstructions(context)
          else
            _buildGenericInstructions(context),
        ],
      ),
    );
  }

  Widget _buildAndroidSupportedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.addWidgetInstructions,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey[600],
            height: 1.4,
            fontFamily: 'Amiri',
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: _requestPinWidget,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.widgets_rounded, size: 18.sp),
                SizedBox(width: 6.w),
                Text(
                  AppLocalizations.of(context)!.addWidget,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAndroidInstructions(BuildContext context) {
    return _buildInstructionsCard(
      context,
      icon: Icons.android_rounded,
      iconColor: Colors.green,
      steps: [
        AppLocalizations.of(context)!.androidWidgetStep1,
        AppLocalizations.of(context)!.androidWidgetStep2,
        AppLocalizations.of(context)!.androidWidgetStep3,
        AppLocalizations.of(context)!.androidWidgetStep4,
      ],
    );
  }

  Widget _buildIOSInstructions(BuildContext context) {
    return _buildInstructionsCard(
      context,
      icon: Icons.phone_iphone_rounded,
      iconColor: Colors.grey[700]!,
      steps: [
        AppLocalizations.of(context)!.iosWidgetStep1,
        AppLocalizations.of(context)!.iosWidgetStep2,
        AppLocalizations.of(context)!.iosWidgetStep3,
        AppLocalizations.of(context)!.iosWidgetStep4,
      ],
    );
  }

  Widget _buildGenericInstructions(BuildContext context) {
    return _buildInstructionsCard(
      context,
      icon: Icons.info_outline_rounded,
      iconColor: Colors.blue,
      steps: [
        AppLocalizations.of(context)!.genericWidgetStep1,
        AppLocalizations.of(context)!.genericWidgetStep2,
      ],
    );
  }

  Widget _buildInstructionsCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required List<String> steps,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color:
            widget.isDark ? Colors.grey[800]!.withAlpha(128) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.howToAddWidget,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Amiri',
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color:
                            widget.isDark ? Colors.grey[300] : Colors.grey[700],
                        height: 1.4,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
