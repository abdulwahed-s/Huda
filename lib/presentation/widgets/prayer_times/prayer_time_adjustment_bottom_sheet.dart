import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/persistent_prayer_countdown_service.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:intl/intl.dart';

class PrayerTimeAdjustmentBottomSheet extends StatefulWidget {
  const PrayerTimeAdjustmentBottomSheet({super.key});

  @override
  State<PrayerTimeAdjustmentBottomSheet> createState() =>
      _PrayerTimeAdjustmentBottomSheetState();
}

class _PrayerTimeAdjustmentBottomSheetState
    extends State<PrayerTimeAdjustmentBottomSheet> {
  late Map<String, int> _offsets;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PrayerTimesCubit>();
    _offsets = Map.from(cubit.prayerOffsets);
  }

  String _localized(String key) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (key) {
      case 'adjustPrayerTimes':
        switch (lang) {
          case 'ar':
            return 'ضبط أوقات الصلاة';
          case 'fr':
            return 'Ajuster les horaires de prière';
          case 'de':
            return 'Gebetszeiten anpassen';
          case 'es':
            return 'Ajustar horarios de oración';
          case 'tr':
            return 'Namaz vakitlerini ayarla';
          case 'ur':
            return 'نماز کے اوقات ایڈجسٹ کریں';
          case 'ru':
            return 'Настроить время намаза';
          case 'ms':
            return 'Laras waktu solat';
          case 'bn':
            return 'নামাজের সময় সামঞ্জস্য করুন';
          default:
            return 'Adjust Prayer Times';
        }
      case 'apply':
        switch (lang) {
          case 'ar':
            return 'تطبيق';
          case 'fr':
            return 'Appliquer';
          case 'de':
            return 'Anwenden';
          case 'es':
            return 'Aplicar';
          case 'tr':
            return 'Uygula';
          case 'ur':
            return 'لاگو کریں';
          case 'ru':
            return 'Применить';
          case 'ms':
            return 'Guna';
          case 'bn':
            return 'প্রয়োগ করুন';
          default:
            return 'Apply';
        }
      case 'cancel':
        switch (lang) {
          case 'ar':
            return 'إلغاء';
          case 'fr':
            return 'Annuler';
          case 'de':
            return 'Abbrechen';
          case 'es':
            return 'Cancelar';
          case 'tr':
            return 'İptal';
          case 'ur':
            return 'منسوخ کریں';
          case 'ru':
            return 'Отмена';
          case 'ms':
            return 'Batal';
          case 'bn':
            return 'বাতিল';
          default:
            return 'Cancel';
        }
      case 'adjustSubtitle':
        switch (lang) {
          case 'ar':
            return 'اضغط + أو − لضبط الدقائق';
          case 'fr':
            return 'Appuyez sur + ou − pour ajuster';
          case 'de':
            return 'Tippe + oder − zum Anpassen';
          case 'es':
            return 'Toca + o − para ajustar';
          case 'tr':
            return 'Ayarlamak için + veya − ye dokun';
          case 'ur':
            return '+ یا − دبا کر منٹ ایڈجسٹ کریں';
          case 'ru':
            return 'Нажмите + или − для настройки';
          case 'ms':
            return 'Ketik + atau − untuk laras';
          case 'bn':
            return '+ বা − চাপুন মিনিট সামঞ্জস্য করতে';
          default:
            return 'Tap + or − to adjust minutes';
        }
      default:
        return key;
    }
  }

  String _offsetLabel(int offset) {
    if (offset == 0) return '0';
    return offset > 0 ? '+$offset' : '$offset';
  }

  void _increment(String key) {
    setState(() {
      _offsets[key] = (_offsets[key] ?? 0) + 1;
    });
  }

  void _decrement(String key) {
    setState(() {
      _offsets[key] = (_offsets[key] ?? 0) - 1;
    });
  }

  Future<void> _apply() async {
    final cubit = context.read<PrayerTimesCubit>();
    await cubit.savePrayerOffsets(_offsets);

    if (PlatformUtils.isAndroid) {
      final service = PersistentPrayerCountdownService();
      if (service.isRunning) {
        await service.restart();
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;
    final state = context.read<PrayerTimesCubit>().state;
    if (state is! PrayerTimesLoaded) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).toString();
    final times = state.prayerTimes;

    final prayers = [
      _PrayerEntry(
        key: 'fajr',
        name: _prayerName(context, 'fajr'),
        baseTime: times.fajr,
        icon: Icons.wb_twilight_rounded,
      ),
      _PrayerEntry(
        key: 'sunrise',
        name: _prayerName(context, 'sunrise'),
        baseTime: times.sunrise,
        icon: Icons.wb_sunny_rounded,
      ),
      _PrayerEntry(
        key: 'dhuhr',
        name: _prayerName(context, 'dhuhr'),
        baseTime: times.dhuhr,
        icon: Icons.wb_sunny_rounded,
      ),
      _PrayerEntry(
        key: 'asr',
        name: _prayerName(context, 'asr'),
        baseTime: times.asr,
        icon: Icons.wb_sunny_outlined,
      ),
      _PrayerEntry(
        key: 'maghrib',
        name: _prayerName(context, 'maghrib'),
        baseTime: times.maghrib,
        icon: Icons.nights_stay_rounded,
      ),
      _PrayerEntry(
        key: 'isha',
        name: _prayerName(context, 'isha'),
        baseTime: times.isha,
        icon: Icons.dark_mode_rounded,
      ),
    ];

    final bgColor = isDark ? colors.darkGradientMid : colors.lightSurface;
    final cardColor = isDark ? colors.darkCardBackground : Colors.white;
    final dividerColor = isDark
        ? colors.primaryDark.withValues(alpha: 0.3)
        : colors.primaryExtraLight.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primaryDark, colors.primary],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            child: Column(
              children: [
                Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(7.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localized('adjustPrayerTimes'),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _localized('adjustSubtitle'),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: cardColor,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
              itemCount: prayers.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: dividerColor,
                indent: 48.w,
              ),
              itemBuilder: (context, index) {
                final entry = prayers[index];
                final offset = _offsets[entry.key] ?? 0;
                final adjustedTime =
                    entry.baseTime.add(Duration(minutes: offset));
                final hasOffset = offset != 0;
                final timeStr = DateFormat.Hm(locale).format(adjustedTime);

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                  child: Row(
                    children: [
                      _ThemedButton(
                        icon: Icons.add_rounded,
                        onTap: () => _increment(entry.key),
                        colors: colors,
                        isDark: isDark,
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 46.w,
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        decoration: BoxDecoration(
                          color: hasOffset
                              ? colors.primary.withValues(alpha: 0.12)
                              : (isDark
                                  ? colors.darkGradientMid
                                      .withValues(alpha: 0.6)
                                  : colors.primaryExtraLight
                                      .withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(10.r),
                          border: hasOffset
                              ? Border.all(
                                  color: colors.primaryVariant
                                      .withValues(alpha: 0.5),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Text(
                          _offsetLabel(offset),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: hasOffset
                                ? colors.primaryVariant
                                : (isDark ? Colors.white38 : Colors.black26),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _ThemedButton(
                        icon: Icons.remove_rounded,
                        onTap: () => _decrement(entry.key),
                        colors: colors,
                        isDark: isDark,
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                entry.name,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? colors.darkText
                                      : colors.lightText,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                entry.icon,
                                size: 14.sp,
                                color: hasOffset
                                    ? colors.primaryVariant
                                    : (isDark
                                        ? colors.primaryLight
                                            .withValues(alpha: 0.5)
                                        : colors.primary
                                            .withValues(alpha: 0.4)),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: hasOffset
                                  ? colors.accent
                                  : (isDark ? Colors.white38 : Colors.black26),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            color: bgColor,
            padding: EdgeInsets.fromLTRB(
              18.w,
              12.h,
              18.w,
              12.h + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _apply,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.accent, colors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _localized('apply'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colors.darkGradientEnd.withValues(alpha: 0.6)
                            : colors.primaryExtraLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isDark
                              ? colors.primaryDark.withValues(alpha: 0.4)
                              : colors.primaryExtraLight,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _localized('cancel'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? colors.darkText.withValues(alpha: 0.6)
                              : colors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _prayerName(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;
    final names = {
      'fajr': {
        'ar': 'الفجر',
        'fr': 'Fajr',
        'de': 'Fajr',
        'es': 'Fajr',
        'tr': 'Sabah',
        'ur': 'فجر',
        'ru': 'Фаджр',
        'ms': 'Subuh',
        'bn': 'ফজর',
      },
      'sunrise': {
        'ar': 'الشروق',
        'fr': 'Lever du soleil',
        'de': 'Sonnenaufgang',
        'es': 'Amanecer',
        'tr': 'Güneş Doğuşu',
        'ur': 'طلوع آفتاب',
        'ru': 'Восход',
        'ms': 'Terbit Matahari',
        'bn': 'সূর্যোদয়',
      },
      'dhuhr': {
        'ar': 'الظهر',
        'fr': 'Dhuhr',
        'de': 'Dhuhr',
        'es': 'Dhuhr',
        'tr': 'Öğle',
        'ur': 'ظہر',
        'ru': 'Зухр',
        'ms': 'Zuhur',
        'bn': 'যোহর',
      },
      'asr': {
        'ar': 'العصر',
        'fr': 'Asr',
        'de': 'Asr',
        'es': 'Asr',
        'tr': 'İkindi',
        'ur': 'عصر',
        'ru': 'Аср',
        'ms': 'Asar',
        'bn': 'আসর',
      },
      'maghrib': {
        'ar': 'المغرب',
        'fr': 'Maghrib',
        'de': 'Maghrib',
        'es': 'Maghrib',
        'tr': 'Akşam',
        'ur': 'مغرب',
        'ru': 'Магриб',
        'ms': 'Maghrib',
        'bn': 'মাগরিব',
      },
      'isha': {
        'ar': 'العشاء',
        'fr': 'Isha',
        'de': 'Isha',
        'es': 'Isha',
        'tr': 'Yatsı',
        'ur': 'عشاء',
        'ru': 'Иша',
        'ms': 'Isyak',
        'bn': 'ইশা',
      },
    };
    return names[key]?[lang] ?? key[0].toUpperCase() + key.substring(1);
  }
}

class _PrayerEntry {
  final String key;
  final String name;
  final DateTime baseTime;
  final IconData icon;

  const _PrayerEntry({
    required this.key,
    required this.name,
    required this.baseTime,
    required this.icon,
  });
}

class _ThemedButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppColorScheme colors;
  final bool isDark;

  const _ThemedButton({
    required this.icon,
    required this.onTap,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: isDark ? 0.35 : 0.15),
              colors.primaryVariant.withValues(alpha: isDark ? 0.25 : 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: colors.primaryVariant.withValues(alpha: isDark ? 0.5 : 0.35),
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: isDark ? colors.primaryLight : colors.primary,
        ),
      ),
    );
  }
}

void showPrayerTimeAdjustmentSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<PrayerTimesCubit>(),
      child: const PrayerTimeAdjustmentBottomSheet(),
    ),
  );
}
