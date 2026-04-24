import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huda/core/utils/platform_utils.dart';

class PrayerCountdownLocalizations {
  static const String _localeKey = 'locale';

  static Future<String> _getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'en';
  }

  static Future<String> getPrayerCountdownTitle({
    required String prefix,
    required String prayerName,
    required String timeText,
    required bool isUrgent,
  }) async {
    final language = await _getCurrentLanguage();
    final localizedPrayerName =
        await _getLocalizedPrayerName(prayerName, language);

    if (isUrgent) {
      switch (language) {
        case 'fr':
          return '$prefix $localizedPrayerName dans $timeText';
        case 'ar':
          return '$prefix $localizedPrayerName في $timeText';
        case 'es':
          return '$prefix $localizedPrayerName en $timeText';
        case 'de':
          return '$prefix $localizedPrayerName in $timeText';
        case 'ru':
          return '$prefix $localizedPrayerName через $timeText';
        case 'tr':
          return '$prefix $localizedPrayerName $timeText sonra';
        case 'ur':
          return '$prefix $localizedPrayerName $timeText میں';
        case 'ms':
          return '$prefix $localizedPrayerName dalam $timeText';
        case 'bn':
          return '$prefix $localizedPrayerName $timeText পরে';
        default:
          return '$prefix $localizedPrayerName in $timeText';
      }
    } else {
      switch (language) {
        case 'fr':
          return '$prefix Prochaine $localizedPrayerName dans $timeText';
        case 'ar':
          return '$prefix التالي $localizedPrayerName في $timeText';
        case 'es':
          return '$prefix Próxima $localizedPrayerName en $timeText';
        case 'de':
          return '$prefix Nächste $localizedPrayerName in $timeText';
        case 'ru':
          return '$prefix Следующий $localizedPrayerName через $timeText';
        case 'tr':
          return '$prefix Sonraki $localizedPrayerName $timeText sonra';
        case 'ur':
          return '$prefix اگلی $localizedPrayerName $timeText میں';
        case 'ms':
          return '$prefix $localizedPrayerName seterusnya dalam $timeText';
        case 'bn':
          return '$prefix পরবর্তী $localizedPrayerName $timeText পরে';
        default:
          return '$prefix Next $localizedPrayerName in $timeText';
      }
    }
  }

  static Future<String> _getLocalizedPrayerName(
      String prayerName, String language) async {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        switch (language) {
          case 'fr':
            return 'Fajr';
          case 'ar':
            return 'الفجر';
          case 'es':
            return 'Fajr';
          case 'de':
            return 'Fajr';
          case 'ru':
            return 'Фаджр';
          case 'tr':
            return 'Sabah';
          case 'ur':
            return 'فجر';
          case 'ms':
            return 'Subuh';
          case 'bn':
            return 'ফজর';
          default:
            return 'Fajr';
        }
      case 'dhuhr':
        switch (language) {
          case 'fr':
            return 'Dhuhr';
          case 'ar':
            return 'الظهر';
          case 'es':
            return 'Dhuhr';
          case 'de':
            return 'Dhuhr';
          case 'ru':
            return 'Зухр';
          case 'tr':
            return 'Öğle';
          case 'ur':
            return 'ظہر';
          case 'ms':
            return 'Zohor';
          case 'bn':
            return 'জোহর';
          default:
            return 'Dhuhr';
        }
      case 'asr':
        switch (language) {
          case 'fr':
            return 'Asr';
          case 'ar':
            return 'العصر';
          case 'es':
            return 'Asr';
          case 'de':
            return 'Asr';
          case 'ru':
            return 'Аср';
          case 'tr':
            return 'İkindi';
          case 'ur':
            return 'عصر';
          case 'ms':
            return 'Asar';
          case 'bn':
            return 'আসর';
          default:
            return 'Asr';
        }
      case 'maghrib':
        switch (language) {
          case 'fr':
            return 'Maghrib';
          case 'ar':
            return 'المغرب';
          case 'es':
            return 'Maghrib';
          case 'de':
            return 'Maghrib';
          case 'ru':
            return 'Магриб';
          case 'tr':
            return 'Akşam';
          case 'ur':
            return 'مغرب';
          case 'ms':
            return 'Maghrib';
          case 'bn':
            return 'মাগরিব';
          default:
            return 'Maghrib';
        }
      case 'isha':
        switch (language) {
          case 'fr':
            return 'Isha';
          case 'ar':
            return 'العشاء';
          case 'es':
            return 'Isha';
          case 'de':
            return 'Isha';
          case 'ru':
            return 'Иша';
          case 'tr':
            return 'Yatsı';
          case 'ur':
            return 'عشاء';
          case 'ms':
            return 'Isyak';
          case 'bn':
            return 'এশা';
          default:
            return 'Isha';
        }
      default:
        switch (language) {
          case 'fr':
            return 'Prière';
          case 'ar':
            return 'الصلاة';
          case 'es':
            return 'Oración';
          case 'de':
            return 'Gebet';
          case 'ru':
            return 'Намаз';
          case 'tr':
            return 'Namaz';
          case 'ur':
            return 'نماز';
          case 'ms':
            return 'Solat';
          case 'bn':
            return 'নামাজ';
          default:
            return 'Prayer';
        }
    }
  }

  static Future<String> getPrayerContextMessage(String prayerName) async {
    final language = await _getCurrentLanguage();

    switch (prayerName.toLowerCase()) {
      case 'fajr':
        switch (language) {
          case 'fr':
            return "Celui qui accomplit la prière de l’aube est sous la protection d’Allah";
          case 'ar':
            return "مَن صلَّى الصبحَ فهو في ذِمَّةِ اللهِ";
          case 'es':
            return "Quien reza Fajr está bajo la protección de Allah";
          case 'de':
            return "Wer das Morgengebet verrichtet, steht unter dem Schutz Allahs";
          case 'ru':
            return "Тот, кто совершает Фаджр, находится под защитой Аллаха";
          case 'tr':
            return "Sabah namazını kılan, Allah’ın koruması altındadır";
          case 'ur':
            return "جو فجر کی نماز پڑھتا ہے وہ اللہ کی حفاظت میں ہے";
          case 'ms':
            return "Sesiapa yang solat Subuh berada dalam perlindungan Allah";
          case 'bn':
            return "যে ফজরের নামাজ পড়ে, সে আল্লাহর নিরাপত্তায় থাকে";
          default:
            return "Whoever prays Fajr is under Allah’s protection";
        }

      case 'dhuhr':
        switch (language) {
          case 'fr':
            return "Quiconque accomplit quatre unités avant Dhuhr et quatre après, Allah l’interdit au Feu";
          case 'ar':
            return "مَنْ صلى أربعَ ركعاتٍ قبلَ الظهرِ وأربعًا بعدَها حرَّمَهُ اللهُ على النارِ";
          case 'es':
            return "Quien reza cuatro rak‘as antes de Dhuhr y cuatro después, Allah lo prohibirá al Fuego";
          case 'de':
            return "Wer vier Gebetseinheiten vor und nach Dhuhr verrichtet, dem verbietet Allah das Feuer";
          case 'ru':
            return "Кто совершит четыре рак‘ата до и после Зухра, того Аллах запретит огню";
          case 'tr':
            return "Öğle namazından önce ve sonra dört rekât kılanı Allah ateşe haram kılar";
          case 'ur':
            return "جو ظہر سے پہلے چار اور بعد میں چار رکعت پڑھتا ہے اللہ اسے آگ پر حرام کر دیتا ہے";
          case 'ms':
            return "Sesiapa yang solat empat rakaat sebelum dan selepas Zohor, Allah mengharamkannya daripada api neraka";
          case 'bn':
            return "যে জোহরের আগে চার রাকাআত এবং পরে চার রাকাআত নামাজ পড়ে, আল্লাহ তাকে আগুন থেকে রক্ষা করবেন";
          default:
            return "Whoever prays four rak‘as before Dhuhr and four after, Allah forbids him to the Fire";
        }

      case 'asr':
        switch (language) {
          case 'fr':
            return "Celui qui délaisse la prière de l’après-midi verra ses œuvres annulées";
          case 'ar':
            return "مَن ترَكَ صلاةَ العصرِ فقدْ حبِطَ عملُهُ";
          case 'es':
            return "Quien deja la oración de Asr, sus obras son anuladas";
          case 'de':
            return "Wer das Nachmittagsgebet auslässt, dessen Taten werden zunichte";
          case 'ru':
            return "Кто пропустит Аср, того деяния будут аннулированы";
          case 'tr':
            return "İkindi namazını terk edenin amelleri boşa gider";
          case 'ur':
            return "جو عصر کی نماز چھوڑ دے اس کے اعمال ضائع ہو جاتے ہیں";
          case 'ms':
            return "Siapa yang meninggalkan solat Asar, amalannya terhapus";
          case 'bn':
            return "যে আসরের নামাজ ছেড়ে দেয় তার আমল বাতিল হয়ে যায়";
          default:
            return "Whoever misses Asr, his deeds are nullified";
        }

      case 'maghrib':
        switch (language) {
          case 'fr':
            return "La prière du Maghrib est le Witr du jour";
          case 'ar':
            return "صلاةُ المغربِ وِترُ النَّهارِ";
          case 'es':
            return "La oración de Maghrib es el Witr del día";
          case 'de':
            return "Das Maghrib-Gebet ist das Witr des Tages";
          case 'ru':
            return "Магриб — это витр дня";
          case 'tr':
            return "Akşam namazı, gündüzün vitridir";
          case 'ur':
            return "مغرب کی نماز دن کا وتر ہے";
          case 'ms':
            return "Solat Maghrib adalah witir bagi siang hari";
          case 'bn':
            return "মাগরিবের নামাজ দিনটির বিতর";
          default:
            return "Maghrib prayer is the Witr of the day";
        }

      case 'isha':
        switch (language) {
          case 'fr':
            return "S’ils savaient ce qu’il y a dans Isha et Fajr, ils viendraient en rampant";
          case 'ar':
            return "ولو يعلمون ما في العتمة والصبح لأتوهما ولو حبواً";
          case 'es':
            return "Si supieran lo que hay en Isha y Fajr, vendrían arrastrándose";
          case 'de':
            return "Wenn sie wüssten, was im Nacht- und Morgengebet steckt, kämen sie kriechend";
          case 'ru':
            return "Если бы они знали награду за Иша и Фаджр, они пришли бы ползком";
          case 'tr':
            return "İnsanlar yatsı ve sabah namazındaki sevabı bilselerdi, emekleyerek bile gelirlerdi";
          case 'ur':
            return "اگر لوگ عشاء اور فجر کی فضیلت جان لیتے تو وہ گھسٹتے ہوئے بھی آتے";
          case 'ms':
            return "Jika mereka tahu kelebihan Isyak dan Subuh, mereka akan datang merangkak";
          case 'bn':
            return "যদি তারা ইশা ও ফজরের মর্যাদা জানত, তবে হামাগুড়ি দিয়েও আসত";
          default:
            return "If they knew the reward for Isha and Fajr, they would come crawling";
        }

      default:
        switch (language) {
          case 'fr':
            return "Prenez soin de vos prières";
          case 'ar':
            return "احرص على صلاتك";
          case 'es':
            return "Mantente atento a tus oraciones";
          case 'de':
            return "Achte auf deine Gebete";
          case 'ru':
            return "Будьте внимательны к своим намазам";
          case 'tr':
            return "Namazlarınıza dikkat edin";
          case 'ur':
            return "اپنی نماز کا خیال رکھو";
          case 'ms':
            return "Jaga solat anda";
          case 'bn':
            return "আপনার নামাজের যত্ন নিন";
          default:
            return "Take care of your prayers";
        }
    }
  }

  static Future<String> getUrgencyMessage(String urgencyLevel) async {
    final language = await _getCurrentLanguage();

    switch (urgencyLevel) {
      case 'critical':
        switch (language) {
          case 'fr':
            return 'L\'heure de la prière est très proche - préparez-vous maintenant!';
          case 'ar':
            return 'وقت الصلاة قريب جداً - استعد الآن!';
          case 'es':
            return 'La hora de oración está muy cerca - ¡prepárate ahora!';
          case 'de':
            return 'Die Gebetszeit ist sehr nahe - bereite dich jetzt vor!';
          case 'ru':
            return 'Время намаза очень близко - готовьтесь сейчас!';
          case 'tr':
            return 'Namaz vakti çok yakın - şimdi hazırlanın!';
          case 'ur':
            return 'نماز کا وقت بہت قریب ہے - اب تیاری کریں!';
          case 'ms':
            return 'Waktu solat sudah sangat dekat - bersiap sekarang!';
          case 'bn':
            return 'নামাজের সময় খুব কাছে - এখনই প্রস্তুত হন!';
          default:
            return 'Prayer time is very near - prepare now!';
        }
      case 'high':
        switch (language) {
          case 'fr':
            return 'Préparez-vous pour la prière bientôt';
          case 'ar':
            return 'استعد للصلاة قريباً';
          case 'es':
            return 'Prepárate para la oración pronto';
          case 'de':
            return 'Bereite dich bald auf das Gebet vor';
          case 'ru':
            return 'Готовьтесь к намазу скоро';
          case 'tr':
            return 'Yakında namaz için hazırlanın';
          case 'ur':
            return 'جلدی نماز کے لیے تیار ہو جائیں';
          case 'ms':
            return 'Bersiap untuk solat tidak lama lagi';
          case 'bn':
            return 'শীঘ্রই নামাজের জন্য প্রস্তুত হন';
          default:
            return 'Get ready for prayer soon';
        }
      case 'medium':
        switch (language) {
          case 'fr':
            return 'L\'heure de la prière approche';
          case 'ar':
            return 'وقت الصلاة يقترب';
          case 'es':
            return 'La hora de oración se acerca';
          case 'de':
            return 'Die Gebetszeit naht';
          case 'ru':
            return 'Время намаза приближается';
          case 'tr':
            return 'Namaz vakti yaklaşıyor';
          case 'ur':
            return 'نماز کا وقت آ رہا ہے';
          case 'ms':
            return 'Waktu solat semakin hampir';
          case 'bn':
            return 'নামাজের সময় এগিয়ে আসছে';
          default:
            return 'Prayer time approaching';
        }
      default:
        switch (language) {
          case 'fr':
            return 'Restez préparé pour l\'heure de la prière';
          case 'ar':
            return 'ابق مستعداً لوقت الصلاة';
          case 'es':
            return 'Mantente preparado para la hora de oración';
          case 'de':
            return 'Bleib bereit für die Gebetszeit';
          case 'ru':
            return 'Будьте готовы ко времени намаза';
          case 'tr':
            return 'Namaz vakti için hazır olun';
          case 'ur':
            return 'نماز کے وقت کے لیے تیار رہیں';
          case 'ms':
            return 'Bersiap sedia untuk waktu solat';
          case 'bn':
            return 'নামাজের সময়ের জন্য প্রস্তুত থাকুন';
          default:
            return 'Stay prepared for prayer time';
        }
    }
  }

  static Future<String> getLoadingTitle() async {
    final language = await _getCurrentLanguage();

    switch (language) {
      case 'fr':
        return '🕌 Compte à rebours des prières';
      case 'ar':
        return '🕌 العد التنازلي للصلاة';
      case 'es':
        return '🕌 Cuenta regresiva de oración';
      case 'de':
        return '🕌 Gebets-Countdown';
      case 'ru':
        return '🕌 Обратный отсчет до намаза';
      case 'tr':
        return '🕌 Namaz Geri Sayımı';
      case 'ur':
        return '🕌 نماز کی الٹ گنتی';
      case 'ms':
        return '🕌 Kira Mundur Solat';
      case 'bn':
        return '🕌 নামাজের কাউন্টডাউন';
      default:
        return '🕌 Prayer Countdown';
    }
  }

  static Future<String> getLoadingText() async {
    final language = await _getCurrentLanguage();

    switch (language) {
      case 'fr':
        return 'Chargement des heures de prière...';
      case 'ar':
        return 'جاري تحميل أوقات الصلاة...';
      case 'es':
        return 'Cargando horarios de oración...';
      case 'de':
        return 'Gebetszeiten werden geladen...';
      case 'ru':
        return 'Загрузка времен намазов...';
      case 'tr':
        return 'Namaz vakitleri yükleniyor...';
      case 'ur':
        return 'نماز کے اوقات لوڈ ہو رہے ہیں...';
      case 'ms':
        return 'Memuatkan waktu solat...';
      case 'bn':
        return 'নামাজের সময় লোড হচ্ছে...';
      default:
        return 'Loading prayer times...';
    }
  }

  static Future<String> getErrorText() async {
    final language = await _getCurrentLanguage();

    switch (language) {
      case 'fr':
        return 'Erreur lors du calcul de l\'heure de prière';
      case 'ar':
        return 'خطأ في حساب وقت الصلاة';
      case 'es':
        return 'Error calculando la hora de oración';
      case 'de':
        return 'Fehler beim Berechnen der Gebetszeit';
      case 'ru':
        return 'Ошибка при расчете времени намаза';
      case 'tr':
        return 'Namaz vakti hesaplanırken hata';
      case 'ur':
        return 'نماز کا وقت نکالنے میں خرابی';
      case 'ms':
        return 'Ralat mengira waktu solat';
      case 'bn':
        return 'নামাজের সময় গণনায় ত্রুটি';
      default:
        return 'Error calculating prayer time';
    }
  }

  static Future<String> getPostPrayerTitle({
    required String prayerName,
    required String elapsedText,
  }) async {
    final language = await _getCurrentLanguage();
    final localizedPrayer = await _getLocalizedPrayerName(prayerName, language);

    switch (language) {
      case 'ar':
        return '$elapsedText من أذان $localizedPrayer';
      case 'fr':
        return "$elapsedText depuis l'appel de $localizedPrayer";
      case 'es':
        return '$elapsedText desde el adhan de $localizedPrayer';
      case 'de':
        return '$elapsedText seit dem $localizedPrayer-Gebetsruf';
      case 'ru':
        return '$elapsedText после азана на $localizedPrayer';
      case 'tr':
        return '$localizedPrayer ezanından $elapsedText';
      case 'ur':
        return '$localizedPrayer کی اذان سے $elapsedText';
      case 'ms':
        return '$elapsedText sejak azan $localizedPrayer';
      case 'bn':
        return '$localizedPrayer আযানের $elapsedText পর';
      default:
        return '$elapsedText since $localizedPrayer athan';
    }
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(PrayerCountdownTaskHandler());
}

class PrayerCountdownTaskHandler extends TaskHandler {
  Timer? _updateTimer;
  PrayerTimes? _prayerTimes;
  DateTime? _lastCalculationDate;
  Coordinates? _cachedCoordinates;
  NextPrayerInfo? _lastValidPrayerInfo;
  bool _hasShownError = false;
  bool _isCalculatingTomorrowPrayers = false;

  Map<String, int> _prayerOffsets = {
    'fajr': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  DateTime? _lastMinuteUpdate;

  static const Duration _postPrayerGracePeriod = Duration(minutes: 30);

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('Prayer countdown foreground task started');

    await _initializePrayerTimes();

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateNotification();
    });

    _updateNotification();
  }

  Future<void> _initializePrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final latStr = prefs.getString('latitude');
      final lonStr = prefs.getString('longitude');

      _prayerOffsets = {
        'fajr': prefs.getInt('prayer_offset_fajr') ?? 0,
        'dhuhr': prefs.getInt('prayer_offset_dhuhr') ?? 0,
        'asr': prefs.getInt('prayer_offset_asr') ?? 0,
        'maghrib': prefs.getInt('prayer_offset_maghrib') ?? 0,
        'isha': prefs.getInt('prayer_offset_isha') ?? 0,
      };

      if (latStr != null && lonStr != null) {
        final lat = double.parse(latStr);
        final lon = double.parse(lonStr);

        _cachedCoordinates = Coordinates(lat, lon);

        final cachedDateStr = prefs.getString('last_prayer_calculation_date');
        final now = DateTime.now();

        if (cachedDateStr != null) {
          final cachedDate = DateTime.parse(cachedDateStr);
          if (_isSameDay(now, cachedDate)) {
            _lastCalculationDate = cachedDate;
          }
        }

        if (_lastCalculationDate == null ||
            !_isSameDay(now, _lastCalculationDate!)) {
          final params = CalculationMethod.umm_al_qura.getParameters();
          params.madhab = Madhab.shafi;

          final date = DateComponents.from(now);
          _prayerTimes = PrayerTimes(_cachedCoordinates!, date, params);
          _lastCalculationDate = now;

          await prefs.setString(
              'last_prayer_calculation_date', now.toIso8601String());
        } else {
          final params = CalculationMethod.umm_al_qura.getParameters();
          params.madhab = Madhab.shafi;

          final date = DateComponents.from(_lastCalculationDate!);
          _prayerTimes = PrayerTimes(_cachedCoordinates!, date, params);
        }

        debugPrint(
            'Prayer times initialized successfully in persistent foreground task');
      } else {
        debugPrint('No cached coordinates found in persistent foreground task');
      }
    } catch (e) {
      debugPrint(
          'Error loading prayer times in persistent foreground task: $e');
    }
  }

  NextPrayerInfo? _getNextPrayerTime() {
    if (_prayerTimes == null) {
      return _lastValidPrayerInfo;
    }

    final now = DateTime.now();

    if (_lastCalculationDate == null) {
      debugPrint('No calculation date - recalculating for first time');
      _recalculatePrayerTimesSync(now);
    } else if (!_isSameDay(now, _lastCalculationDate!)) {
      debugPrint(
          'Day changed from ${_lastCalculationDate!.day} to ${now.day} - recalculating prayer times');
      _recalculatePrayerTimesSync(now);
    }

    final prayers = [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (final prayer in prayers) {
      final basePrayerTime = _prayerTimes!.timeForPrayer(prayer);
      if (basePrayerTime == null) continue;
      final offsetMinutes = _prayerOffsets[_getPrayerKey(prayer)] ?? 0;
      final prayerTime = basePrayerTime.add(Duration(minutes: offsetMinutes));
      if (prayerTime.isAfter(now)) {
        final duration = prayerTime.difference(now);
        final nextPrayerInfo = NextPrayerInfo(
          prayerName: _getPrayerDisplayName(prayer),
          duration: duration,
        );

        _lastValidPrayerInfo = nextPrayerInfo;
        _hasShownError = false;
        return nextPrayerInfo;
      }
    }

    if (!_isCalculatingTomorrowPrayers) {
      _isCalculatingTomorrowPrayers = true;
      _calculateTomorrowFajr(now);
    }

    return _lastValidPrayerInfo;
  }

  void _calculateTomorrowFajr(DateTime now) {
    SharedPreferences.getInstance().then((prefs) {
      final latStr = prefs.getString('latitude');
      final lonStr = prefs.getString('longitude');

      if (latStr != null && lonStr != null) {
        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowDate = DateComponents.from(tomorrow);
        final coordinates = Coordinates(
          double.parse(latStr),
          double.parse(lonStr),
        );
        final params = CalculationMethod.umm_al_qura.getParameters();
        params.madhab = Madhab.shafi;

        final tomorrowPrayerTimes =
            PrayerTimes(coordinates, tomorrowDate, params);
        final tomorrowFajr = tomorrowPrayerTimes.timeForPrayer(Prayer.fajr);

        if (tomorrowFajr != null) {
          _prayerTimes = tomorrowPrayerTimes;

          final adjustedFajr =
              tomorrowFajr.add(Duration(minutes: _prayerOffsets['fajr'] ?? 0));
          final duration = adjustedFajr.difference(now);
          _lastValidPrayerInfo = NextPrayerInfo(
            prayerName: 'Fajr',
            duration: duration,
          );

          prefs.setString(
              'last_prayer_calculation_date', tomorrow.toIso8601String());

          debugPrint('Tomorrow\'s Fajr calculated and cached successfully');
        }
      }

      _isCalculatingTomorrowPrayers = false;
    }).catchError((error) {
      debugPrint('Error calculating tomorrow\'s Fajr: $error');
      _isCalculatingTomorrowPrayers = false;
    });
  }

  void _recalculatePrayerTimesSync(DateTime date) {
    if (_lastCalculationDate != null &&
        _isSameDay(date, _lastCalculationDate!)) {
      return;
    }

    if (_cachedCoordinates != null) {
      try {
        final params = CalculationMethod.umm_al_qura.getParameters();
        params.madhab = Madhab.shafi;

        final dateComponents = DateComponents.from(date);
        _prayerTimes = PrayerTimes(_cachedCoordinates!, dateComponents, params);
        _lastCalculationDate = date;

        SharedPreferences.getInstance().then((prefs) {
          prefs.setString(
              'last_prayer_calculation_date', date.toIso8601String());
        });

        _isCalculatingTomorrowPrayers = false;
        _hasShownError = false;

        debugPrint('Prayer times recalculated for ${date.toString()}');
      } catch (e) {
        debugPrint('Error recalculating prayer times: $e');
      }
    } else {
      debugPrint('No cached coordinates available for recalculation');
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    final isSame = date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
    if (!isSame) {
      debugPrint(
          'Day comparison: ${date1.day}/${date1.month}/${date1.year} vs ${date2.day}/${date2.month}/${date2.year} = $isSame');
    }
    return isSame;
  }

  String _getPrayerDisplayName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      default:
        return 'Prayer';
    }
  }

  String _getPrayerKey(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'fajr';
      case Prayer.dhuhr:
        return 'dhuhr';
      case Prayer.asr:
        return 'asr';
      case Prayer.maghrib:
        return 'maghrib';
      case Prayer.isha:
        return 'isha';
      default:
        return '';
    }
  }

  PostPrayerInfo? _getPostPrayerInfo() {
    if (_prayerTimes == null) return null;

    final now = DateTime.now();
    final prayers = [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (final prayer in prayers.reversed) {
      final basePrayerTime = _prayerTimes!.timeForPrayer(prayer);
      if (basePrayerTime == null) continue;
      final offsetMinutes = _prayerOffsets[_getPrayerKey(prayer)] ?? 0;
      final prayerTime = basePrayerTime.add(Duration(minutes: offsetMinutes));
      if (prayerTime.isBefore(now)) {
        final elapsed = now.difference(prayerTime);
        if (elapsed <= _postPrayerGracePeriod) {
          return PostPrayerInfo(
            prayerName: _getPrayerDisplayName(prayer),
            elapsedDuration: elapsed,
          );
        }
        break;
      }
    }
    return null;
  }

  String _formatElapsedTime(Duration elapsed) {
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds.remainder(60);
    return '+$m:${s.toString().padLeft(2, '0')}';
  }

  String _getPrayerEmoji(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return '🌅';
      case 'dhuhr':
        return '☀️';
      case 'asr':
        return '🌤️';
      case 'maghrib':
        return '🌇';
      case 'isha':
        return '🌙';
      default:
        return '🕌';
    }
  }

  UrgencyStyle _getUrgencyStyle(Duration duration) {
    final totalMinutes = duration.inMinutes;

    if (totalMinutes <= 5) {
      return const UrgencyStyle(
        isUrgent: true,
        prefix: '🔥',
        urgencyLevel: 'critical',
      );
    } else if (totalMinutes <= 15) {
      return const UrgencyStyle(
        isUrgent: true,
        prefix: '⚡',
        urgencyLevel: 'high',
      );
    } else if (totalMinutes <= 30) {
      return const UrgencyStyle(
        isUrgent: true,
        prefix: '⚠️',
        urgencyLevel: 'medium',
      );
    } else {
      return const UrgencyStyle(
        isUrgent: false,
        prefix: '',
        urgencyLevel: 'normal',
      );
    }
  }

  String _formatTimeWithUrgency(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    if (h > 0) {
      return '${h}h ${m}m';
    } else {
      return '$m:${s.toString().padLeft(2, '0')}';
    }
  }

  bool _shouldSkipUpdate(Duration timeRemaining) {
    if (timeRemaining.inMinutes < 60) {
      _lastMinuteUpdate = null;
      return false;
    }

    final now = DateTime.now();
    if (_lastMinuteUpdate != null) {
      final secondsSinceLastUpdate =
          now.difference(_lastMinuteUpdate!).inSeconds;
      if (secondsSinceLastUpdate < 60) {
        return true;
      }
    }

    _lastMinuteUpdate = now;
    return false;
  }

  Future<String> _formatPrayerTime(DateTime prayerTime) async {
    final language = await PrayerCountdownLocalizations._getCurrentLanguage();
    final hour = prayerTime.hour;
    final minute = prayerTime.minute;

    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');

    String amPm;
    switch (language) {
      case 'ar':
        amPm = hour >= 12 ? 'م' : 'ص';
        break;
      case 'fr':
        amPm = hour >= 12 ? 'PM' : 'AM';
        break;
      case 'es':
        amPm = hour >= 12 ? 'PM' : 'AM';
        break;
      case 'de':
        amPm = hour >= 12 ? 'PM' : 'AM';
        break;
      case 'ru':
        amPm = hour >= 12 ? 'PM' : 'AM';
        break;
      case 'tr':
        amPm = hour >= 12 ? 'PM' : 'AM';
        break;
      case 'ur':
        amPm = hour >= 12 ? 'م' : 'ص';
        break;
      case 'ms':
        amPm = hour >= 12 ? 'PM' : 'AM';
        break;
      case 'bn':
        amPm = hour >= 12 ? 'PM' : 'AM';
        break;
      default:
        amPm = hour >= 12 ? 'PM' : 'AM';
    }

    return '$hour12:$minuteStr $amPm';
  }

  Future<String> _buildEnhancedSubtitle(NextPrayerInfo nextPrayer,
      Future<String> prayerTimeTextFuture, UrgencyStyle urgencyStyle) async {
    final now = DateTime.now();
    final currentTimeStr = await _formatPrayerTime(now);
    final prayerTimeText = await prayerTimeTextFuture;

    final language = await PrayerCountdownLocalizations._getCurrentLanguage();
    String nowText;
    switch (language) {
      case 'ar':
        nowText = 'الآن';
        break;
      case 'fr':
        nowText = 'Maintenant';
        break;
      case 'es':
        nowText = 'Ahora';
        break;
      case 'de':
        nowText = 'Jetzt';
        break;
      case 'ru':
        nowText = 'Сейчас';
        break;
      case 'tr':
        nowText = 'Şimdi';
        break;
      case 'ur':
        nowText = 'اب';
        break;
      case 'ms':
        nowText = 'Sekarang';
        break;
      case 'bn':
        nowText = 'এখন';
        break;
      default:
        nowText = 'Now';
    }

    String contextMessage;

    if (urgencyStyle.isUrgent) {
      contextMessage = await PrayerCountdownLocalizations.getUrgencyMessage(
          urgencyStyle.urgencyLevel);
    } else {
      contextMessage =
          await PrayerCountdownLocalizations.getPrayerContextMessage(
              nextPrayer.prayerName);
    }

    String atText;
    switch (language) {
      case 'ar':
        atText = 'في';
        break;
      case 'fr':
        atText = 'À';
        break;
      case 'es':
        atText = 'A las';
        break;
      case 'de':
        atText = 'Um';
        break;
      case 'ru':
        atText = 'В';
        break;
      case 'tr':
        atText = 'Saat';
        break;
      case 'ur':
        atText = 'بجے';
        break;
      case 'ms':
        atText = 'Pada';
        break;
      case 'bn':
        atText = 'সময়';
        break;
      default:
        atText = 'At';
    }

    return '$contextMessage • $atText $prayerTimeText • $nowText $currentTimeStr';
  }

  Future<String> _buildPostPrayerSubtitle(PostPrayerInfo postPrayerInfo) async {
    final language = await PrayerCountdownLocalizations._getCurrentLanguage();

    String message;
    switch (language) {
      case 'ar':
        message = 'حان وقت الصلاة 🤲';
        break;
      case 'fr':
        message = "C'est l'heure de prier 🤲";
        break;
      case 'es':
        message = 'Es hora de rezar 🤲';
        break;
      case 'de':
        message = 'Zeit zu beten 🤲';
        break;
      case 'ru':
        message = 'Время молиться 🤲';
        break;
      case 'tr':
        message = 'Namaz vakti 🤲';
        break;
      case 'ur':
        message = 'نماز کا وقت 🤲';
        break;
      case 'ms':
        message = 'Masa untuk solat 🤲';
        break;
      case 'bn':
        message = 'নামাজের সময় 🤲';
        break;
      default:
        message = 'Time to pray 🤲';
    }

    final now = DateTime.now();
    final currentTimeStr = await _formatPrayerTime(now);

    return '$message • $currentTimeStr';
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _updateNotification();
  }

  void _updateNotification() async {
    try {
      final postPrayerInfo = _getPostPrayerInfo();

      if (postPrayerInfo != null) {
        final prayerEmoji = _getPrayerEmoji(postPrayerInfo.prayerName);
        final elapsedText = _formatElapsedTime(postPrayerInfo.elapsedDuration);

        final title = await PrayerCountdownLocalizations.getPostPrayerTitle(
          prayerName: postPrayerInfo.prayerName,
          elapsedText: '$prayerEmoji $elapsedText',
        );

        final subtitle = await _buildPostPrayerSubtitle(postPrayerInfo);

        FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: subtitle,
        );

        _hasShownError = false;
        return;
      }

      final nextPrayer = _getNextPrayerTime();

      if (nextPrayer == null) {
        if (!_hasShownError && _lastValidPrayerInfo == null) {
          final loadingTitle =
              await PrayerCountdownLocalizations.getLoadingTitle();
          final loadingText =
              await PrayerCountdownLocalizations.getLoadingText();

          FlutterForegroundTask.updateService(
            notificationTitle: loadingTitle,
            notificationText: loadingText,
          );
          _hasShownError = true;
        }

        return;
      }

      if (_shouldSkipUpdate(nextPrayer.duration)) {
        return;
      }

      _hasShownError = false;

      final prayerEmoji = _getPrayerEmoji(nextPrayer.prayerName);
      final urgencyStyle = _getUrgencyStyle(nextPrayer.duration);

      final timeText = _formatTimeWithUrgency(nextPrayer.duration);

      final actualPrayerTime = DateTime.now().add(nextPrayer.duration);
      final prayerTimeTextFuture = _formatPrayerTime(actualPrayerTime);

      final title = await PrayerCountdownLocalizations.getPrayerCountdownTitle(
        prefix: urgencyStyle.isUrgent ? urgencyStyle.prefix : prayerEmoji,
        prayerName: nextPrayer.prayerName,
        timeText: timeText,
        isUrgent: urgencyStyle.isUrgent,
      );

      final subtitle = await _buildEnhancedSubtitle(
          nextPrayer, prayerTimeTextFuture, urgencyStyle);

      FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: subtitle,
      );
    } catch (e) {
      if (!_hasShownError) {
        final loadingTitle =
            await PrayerCountdownLocalizations.getLoadingTitle();
        final errorText = await PrayerCountdownLocalizations.getErrorText();

        FlutterForegroundTask.updateService(
          notificationTitle: loadingTitle,
          notificationText: errorText,
        );
        _hasShownError = true;
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _updateTimer?.cancel();
    debugPrint('Prayer countdown foreground task destroyed');
  }

  @override
  void onNotificationButtonPressed(String id) {
    switch (id) {
      case 'stop':
        FlutterForegroundTask.stopService();
        debugPrint('Prayer countdown stopped by user');
        break;
      case 'open_app':
        debugPrint('Open app button pressed');
        break;
      default:
        debugPrint('Unknown notification button pressed: $id');
    }
  }

  @override
  void onNotificationPressed() {
    debugPrint('Prayer countdown notification pressed');
  }
}

class NextPrayerInfo {
  final String prayerName;
  final Duration duration;

  const NextPrayerInfo({
    required this.prayerName,
    required this.duration,
  });
}

class UrgencyStyle {
  final bool isUrgent;
  final String prefix;
  final String urgencyLevel;

  const UrgencyStyle({
    required this.isUrgent,
    required this.prefix,
    required this.urgencyLevel,
  });
}

class PostPrayerInfo {
  final String prayerName;
  final Duration elapsedDuration;

  const PostPrayerInfo({
    required this.prayerName,
    required this.elapsedDuration,
  });
}

class PersistentPrayerCountdownService {
  static final PersistentPrayerCountdownService _instance =
      PersistentPrayerCountdownService._internal();
  factory PersistentPrayerCountdownService() => _instance;
  PersistentPrayerCountdownService._internal();

  bool _isRunning = false;
  bool _isInitialized = false;
  static const String _stateKey = 'persistent_prayer_countdown_enabled';

  Future<bool> getSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_stateKey) ?? false;
  }

  Future<void> _saveState(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stateKey, isEnabled);
    debugPrint('Prayer countdown service state saved: $isEnabled');
  }

  Future<void> initialize() async {
    if (!PlatformUtils.isMobile) return;
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'prayer_countdown_visible',
        channelName: 'Prayer Countdown',
        channelDescription: 'Persistent countdown to next prayer time',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        showWhen: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: false,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
    debugPrint(
        'Prayer countdown foreground service initialized with silent channel');
  }

  Future<void> startIfEnabled() async {
    if (!PlatformUtils.isMobile) return;
    final shouldStart = await getSavedState();
    if (shouldStart) {
      debugPrint(
          'Prayer countdown was previously enabled by user, starting...');
      await startPersistentCountdown();
    } else {
      debugPrint('Prayer countdown is disabled by user preference');
    }
  }

  Future<void> startPersistentCountdown() async {
    if (!PlatformUtils.isMobile) return;
    if (_isRunning) {
      debugPrint('Persistent countdown already running');
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('🕌 Starting persistent prayer countdown service...');

    await _ensureTestCoordinatesForDebug();

    try {
      final NotificationPermission notificationPermissionStatus =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermissionStatus != NotificationPermission.granted) {
        final NotificationPermission requestResult =
            await FlutterForegroundTask.requestNotificationPermission();
        if (requestResult != NotificationPermission.granted) {
          debugPrint('Notification permission denied');
          return;
        }
      }

      await FlutterForegroundTask.startService(
        notificationTitle: 'Prayer Countdown',
        notificationText: 'Loading prayer times...',
        callback: startCallback,
        notificationIcon: const NotificationIcon(
          metaDataName: 'com.aw.huda.service.PRAYER_ICON',
        ),
      );

      _isRunning = true;

      await _saveState(true);
      debugPrint('✅ Prayer countdown foreground service started successfully');
      debugPrint(
          '🛡️ Service uses isolated notifications - no interference with athkar');
    } catch (e) {
      debugPrint('❌ Error starting persistent countdown: $e');
      _isRunning = false;
      await _saveState(false);
      rethrow;
    }
  }

  Future<void> _ensureTestCoordinatesForDebug() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latStr = prefs.getString('latitude');
      final lonStr = prefs.getString('longitude');

      if (latStr == null || lonStr == null) {
        const testLat = 24.8607;
        const testLon = 67.0011;

        await prefs.setString('latitude', testLat.toString());
        await prefs.setString('longitude', testLon.toString());

        debugPrint('Set test coordinates for Karachi ($testLat, $testLon)');
        debugPrint(
            'NOTE: In production, user should set location via Prayer Times screen');
      }
    } catch (e) {
      debugPrint('Error setting test coordinates: $e');
    }
  }

  Future<void> stopPersistentCountdown() async {
    if (!PlatformUtils.isMobile) return;
    if (!_isRunning) return;

    try {
      await FlutterForegroundTask.stopService();
      _isRunning = false;

      await _saveState(false);
      debugPrint('✅ Prayer countdown foreground service stopped');
      debugPrint('🛡️ Athkar notifications remain unaffected');
    } catch (e) {
      debugPrint('❌ Error stopping persistent countdown: $e');
    }
  }

  bool get isRunning => _isRunning;

  Future<void> restart() async {
    if (!PlatformUtils.isMobile) return;
    if (_isRunning) {
      await stopPersistentCountdown();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    await startPersistentCountdown();
  }

  void dispose() {
    if (!PlatformUtils.isMobile) return;
    stopPersistentCountdown();
  }
}
