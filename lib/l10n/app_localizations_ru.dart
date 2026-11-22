// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get updateAvailableTitle => 'Доступно обновление';

  @override
  String get updateAvailableBody =>
      'Доступна новая версия Huda с последними функциями и улучшениями.';

  @override
  String get updateNow => 'Обновить';

  @override
  String get updateLater => 'Позже';

  @override
  String get chooseUpdateSource => 'Выберите источник обновления';

  @override
  String get fdroidStore => 'F-Droid';

  @override
  String get fdroidUpdateSourceDescription =>
      'Открыть официальную страницу пакета Huda в F-Droid';

  @override
  String get crashReportingConsentTitle => 'Помочь улучшить Huda?';

  @override
  String get crashReportingConsentDescription =>
      'Отправляйте автоматические отчёты о сбоях, чтобы помочь нам находить и устранять проблемы в FOSS-версии.';

  @override
  String get crashReportingConsentAllow => 'Разрешить отчёты о сбоях';

  @override
  String get crashReportingConsentDecline => 'Не разрешать';

  @override
  String get crashReportingSettingsTitle => 'Отчёты о сбоях';

  @override
  String get crashReportingSettingsDescription =>
      'Автоматически отправлять сведения о сбоях и устройстве, чтобы помочь улучшить Huda';

  @override
  String get crashReportingSharedDataTitle => 'Какие данные отправляются';

  @override
  String get crashReportingSharedDataDescription =>
      'Сведения о сбоях и трассировки стека, модель и производитель устройства, версия Android и версия Huda.';

  @override
  String get crashReportingPrivacyNote =>
      'До вашего разрешения ничего не отправляется. Это можно изменить в любое время в настройках.';

  @override
  String get crashReportingDisabledDescription =>
      'Автоматическая отправка отчётов о сбоях отключена. Её можно включить в настройках.';

  @override
  String get searchCityHint => 'Поиск города (например, Нью-Йорк)...';

  @override
  String get typeCityNameHint => 'Введите название города выше';

  @override
  String get appTitle => 'Huda';

  @override
  String get settings => 'Настройки';

  @override
  String get theme => 'Тема';

  @override
  String get textSize => 'Размер текста';

  @override
  String get reset => 'Сброс';

  @override
  String get language => 'Язык';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get turkish => 'Türkçe';

  @override
  String get french => 'Français';

  @override
  String get german => 'Deutsch';

  @override
  String get spanish => 'Español';

  @override
  String get urdu => 'اردو';

  @override
  String get russian => 'Русский';

  @override
  String get malay => 'Bahasa Melayu';

  @override
  String get bengali => 'বাংলা';

  @override
  String get chinese => '中文';

  @override
  String get colorTheme => 'Цветовая тема';

  @override
  String get prayerTimes => 'Времена намазов';

  @override
  String get qiblahDirection => 'Направление Киблы';

  @override
  String get tasbih => 'Тасбих';

  @override
  String get hadith => 'Хадис';

  @override
  String get hadithChapters => 'Главы хадисов';

  @override
  String get hadithDetails => 'Детали хадиса';

  @override
  String get books => 'Книги';

  @override
  String get bookmarks => 'Закладки';

  @override
  String get loading => 'Загрузка...';

  @override
  String get retry => 'Повторить';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Редактировать';

  @override
  String get clear => 'Очистить';

  @override
  String get refresh => 'Обновить';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get start => 'Начать';

  @override
  String get stop => 'Остановить';

  @override
  String get restart => 'Перезапустить';

  @override
  String get copyText => 'Копировать текст';

  @override
  String get clearAllBookmarks => 'Очистить все закладки';

  @override
  String get downloadFeatureComingSoon =>
      'Функция загрузки скоро будет доступна!';

  @override
  String get failedToShareImage => 'Не удалось поделиться изображением';

  @override
  String get addEvent => 'Добавить событие';

  @override
  String get editEvent => 'Редактировать событие';

  @override
  String get receiveNotification => 'Получить уведомление';

  @override
  String get getNotifiedAboutEvent => 'Получить уведомление об этом событии';

  @override
  String get allDayEvent => 'Событие на весь день';

  @override
  String get hijriCalendar => 'Хиджри календарь';

  @override
  String get hijriAdjustmentTitle => 'Настроить календарь хиджры';

  @override
  String get hijriAdjustmentDescription =>
      'Выберите, как Huda отображает даты по хиджре.';

  @override
  String get hijriAdjustmentAction => 'Настройка календаря';

  @override
  String get hijriAutomaticAdjustmentDescription =>
      'Используется официальный календарь Умм аль-Кура.';

  @override
  String get hijriManualAdjustment => 'Ручная настройка';

  @override
  String get hijriManualAdjustmentDescription =>
      'Сдвиньте дату по хиджре вперёд или назад не более чем на два дня.';

  @override
  String get selectedDate => 'Выбранная дата';

  @override
  String get noEventsForThisDate => 'Нет событий на эту дату';

  @override
  String get muharram => 'Мухаррам';

  @override
  String get safar => 'Сафар';

  @override
  String get rabiAlAwwal => 'Раби\' аль-авваль';

  @override
  String get rabiAlThani => 'Раби\' ас-сани';

  @override
  String get jumadaAlAwwal => 'Джумада аль-авваль';

  @override
  String get jumadaAlThani => 'Джумада ас-сани';

  @override
  String get rajab => 'Раджаб';

  @override
  String get shaban => 'Ша\'бан';

  @override
  String get ramadan => 'Рамадан';

  @override
  String get shawwal => 'Шавваль';

  @override
  String get dhuAlQidah => 'Зу-ль-Ка\'да';

  @override
  String get dhuAlHijjah => 'Зу-ль-Хиджа';

  @override
  String get may => 'Май';

  @override
  String get eventTitle => 'Название события';

  @override
  String get description => 'Описание';

  @override
  String get startTime => 'Время начала';

  @override
  String get endTime => 'Время окончания';

  @override
  String get startTimeRequired => 'Время начала обязательно';

  @override
  String get endTimeAfterStart =>
      'Время окончания должно быть после времени начала';

  @override
  String get startPrefix => 'Начало';

  @override
  String get endPrefix => 'Конец';

  @override
  String get allDay => 'Весь день';

  @override
  String get endTimeRequired => 'Время окончания обязательно';

  @override
  String get notify => 'Уведомить';

  @override
  String get library => 'Библиотека';

  @override
  String get all => 'Все';

  @override
  String get readMore => 'Читать далее';

  @override
  String get readLess => 'Свернуть';

  @override
  String get aboutThisAudio => 'Об этом аудио';

  @override
  String get page => 'Страница';

  @override
  String get pageOf => 'из';

  @override
  String get first => 'Первая';

  @override
  String get prev => 'Предыдущая';

  @override
  String get next => 'Следующая';

  @override
  String get last => 'Последняя';

  @override
  String get jumpTo => 'Перейти к:';

  @override
  String get go => 'Перейти';

  @override
  String get chooseLanguage => 'Выберите язык';

  @override
  String get searchLanguages => 'Поиск языков...';

  @override
  String get saveEvent => 'Сохранить событие';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get select => 'Выбрать';

  @override
  String get error => 'Ошибка';

  @override
  String get fajr => 'Фаджр';

  @override
  String get dhuhr => 'Зухр';

  @override
  String get asr => 'Аср';

  @override
  String get maghrib => 'Магриб';

  @override
  String get isha => 'Иша';

  @override
  String get resetCounter => 'Сбросить счетчик';

  @override
  String get note => 'Заметка';

  @override
  String get dhikr => 'Зикр';

  @override
  String get minus => 'Минус';

  @override
  String get addDhikr => 'Добавить Зикр';

  @override
  String get noDhikrYet => 'Зикр ещё не добавлен';

  @override
  String get enterDhikrHint => 'Введите ваш зикр здесь...';

  @override
  String get vibrate => 'Вибрация';

  @override
  String get silent => 'Беззвучный';

  @override
  String get tasbihTapToCount => 'Нажмите в любом месте, чтобы считать';

  @override
  String get tasbihClickToCount =>
      'Нажмите мышью или клавишу «Пробел», чтобы считать';

  @override
  String get tasbihYourDhikr => 'Ваши зикры';

  @override
  String get tasbihEmptyMessage => 'Добавьте зикр, чтобы начать счёт.';

  @override
  String get tasbihLoadError => 'Не удалось загрузить список зикров.';

  @override
  String get tasbihDhikrRemoved => 'Зикр удалён';

  @override
  String get undo => 'Отменить';

  @override
  String get tasbihResetMessage =>
      'Его счёт вернётся к 0. Счёт других зикров сохранится.';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get calibrateCompass => 'Требуется калибровка компаса';

  @override
  String get calibrateCompassInstruction =>
      'Подвигайте телефон в форме восьмёрки, чтобы повысить точность';

  @override
  String get clearAll => 'Очистить все';

  @override
  String get continueReading => 'Продолжить';

  @override
  String get huda => 'Худа';

  @override
  String get widgetManagement => 'Управление виджетами';

  @override
  String get nextPrayer => 'Следующий намаз';

  @override
  String get hijriDate => 'Дата по Хиджри';

  @override
  String get remove => 'Удалить';

  @override
  String get today => 'Сегодня';

  @override
  String get sunrise => 'ВОСХОД СОЛНЦА';

  @override
  String get noInternetConnection => 'Нет интернет-соединения';

  @override
  String get offlineAudioUnavailable =>
      'Нет подключения к интернету. Офлайн-аудио недоступно.';

  @override
  String get offlineTafsirUnavailable =>
      'Нет подключения к интернету. Офлайн-тафсир недоступен.';

  @override
  String get offlineTranslationUnavailable =>
      'Нет подключения к интернету. Офлайн-перевод недоступен.';

  @override
  String get noInternetSettings =>
      'Нет интернет-соединения. Пожалуйста, проверьте настройки сети и попробуйте снова.';

  @override
  String get unexpectedError =>
      'Произошла неожиданная ошибка. Пожалуйста, попробуйте снова.';

  @override
  String get tooManyRequests =>
      'Слишком много запросов. Пожалуйста, подождите и попробуйте позже.';

  @override
  String get tafsirDownloadSuccess => 'Тафсир успешно загружен!';

  @override
  String get translationDownloadSuccess => 'Перевод успешно загружен!';

  @override
  String tafsirError(String message) {
    return 'Ошибка тафсира: $message';
  }

  @override
  String translationError(String message) {
    return 'Ошибка перевода: $message';
  }

  @override
  String get suratAlKahf => 'Сура Аль-Кахф';

  @override
  String get morningEveningAthkar => 'Утренние и вечерние Азкар';

  @override
  String get randomAthkar => 'Случайные Азкар';

  @override
  String everyMinutes(String minutes, Object frequency) {
    return 'Каждые $minutes минут';
  }

  @override
  String get quranReadingReminder => 'Напоминание о чтении Корана';

  @override
  String get debug => 'Отладка';

  @override
  String get gotIt => 'Понятно';

  @override
  String get athkarFrequency => 'Частота Азкар';

  @override
  String get howOftenReceiveAthkar =>
      'Как часто вы хотите получать случайные Азкар?';

  @override
  String get notificationScheduleFailed =>
      'Не удалось запланировать это напоминание. Попробуйте ещё раз.';

  @override
  String get notificationsEnabled => 'Уведомления включены';

  @override
  String get notifications => 'Уведомления';

  @override
  String get home => 'Главная';

  @override
  String get searchHint => 'Поиск...';

  @override
  String get searchBookmarksHint => 'Поиск закладок...';

  @override
  String get typeMessageHint => 'Введите ваше сообщение...';

  @override
  String get searchAthkarHint => 'Поиск азкар...';

  @override
  String get exitDialog => 'Выйти из приложения';

  @override
  String get exitConfirmation => 'Вы уверены, что хотите выйти?';

  @override
  String get ok => 'ОК';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get done => 'Готово';

  @override
  String get close => 'Закрыть';

  @override
  String get back => 'Назад';

  @override
  String get previous => 'Предыдущий';

  @override
  String get failedToLoad => 'Не удалось загрузить';

  @override
  String get connectionError => 'Ошибка соединения';

  @override
  String get permissionDenied => 'Разрешение отклонено';

  @override
  String get bookName => 'Название книги';

  @override
  String get athkar => 'Азкар';

  @override
  String searchResultsFound(int count) {
    return 'Найдено $count результатов';
  }

  @override
  String get noResultsFound => 'Результаты не найдены';

  @override
  String get tryDifferentSearch => 'Попробуйте другие поисковые термины';

  @override
  String get welcomeToHudaAI => 'Добро пожаловать в Huda AI';

  @override
  String get aiIntroMessage =>
      'Задайте мне любые вопросы об Исламе, и я предоставлю ответы на основе Корана и достоверной Сунны.';

  @override
  String get verifySourcesSubtitle =>
      'Всегда проверяйте ответы ИИ с Кораном и Сунной.';

  @override
  String get tryAsking => 'Попробуйте спросить:';

  @override
  String get exampleQuestion1 => 'Каковы пять столпов Ислама?';

  @override
  String get exampleQuestion2 => 'Как я могу улучшить свой хушу в молитве?';

  @override
  String get exampleQuestion3 => 'Что мне сказать перед сном?';

  @override
  String get exampleQuestion4 => 'Расскажите мне хадис о доброте.';

  @override
  String get hudaAIThinking => 'Huda AI думает...';

  @override
  String get analyzingQuestion =>
      'Анализирую ваш вопрос с исламскими источниками';

  @override
  String get aiGeneratedDisclaimer =>
      'Контент, созданный ИИ. Пожалуйста, проверьте с достоверными источниками.';

  @override
  String get messageCopied => 'Сообщение скопировано в буфер обмена';

  @override
  String get hudaAI => 'Huda AI';

  @override
  String get bookmark => 'Закладка';

  @override
  String get star => 'Звезда';

  @override
  String get bookmarkColor => 'Цвет закладки';

  @override
  String get yourNote => 'Ваша заметка';

  @override
  String get editNote => 'Редактировать заметку';

  @override
  String get addNote => 'Добавить заметку';

  @override
  String get noteHint =>
      'Напишите вашу личную заметку или размышление об этом аяте...';

  @override
  String get update => 'Обновить';

  @override
  String get includeTafsir => 'Включить тафсир';

  @override
  String get generating => 'Генерация...';

  @override
  String get shareAsImage => 'Поделиться как изображением';

  @override
  String get tafsirLabel => 'Тафсир:';

  @override
  String get shareImageTagline => 'Ваш исламский спутник';

  @override
  String get translationNotAvailable => 'Перевод недоступен';

  @override
  String get tafsirNotAvailable => 'Тафсир недоступен';

  @override
  String get unknownSurah => 'Неизвестная сура';

  @override
  String get sharedViaHuda =>
      'Опубликовано через Huda - Ваш исламский спутник\nСкачать Huda: http://huda.awrs.me/download';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get unknown => 'Неизвестно';

  @override
  String ayahNumber(int number) {
    return 'Аят $number';
  }

  @override
  String get loadingAudio => 'Загрузка аудио...';

  @override
  String get filterByLanguage => 'Фильтровать по языку';

  @override
  String get allLanguages => 'Все языки';

  @override
  String get unknownReader => 'Неизвестный чтец';

  @override
  String get tafsirCommentary => 'Тафсир (Комментарий)';

  @override
  String get selectTafsirSource => 'Выбрать источник тафсира';

  @override
  String get none => 'Нет';

  @override
  String get noTafsirAvailable => 'Нет доступного источника тафсира';

  @override
  String get translation => 'Перевод';

  @override
  String get selectTranslationSource => 'Выбрать источник перевода';

  @override
  String get noTranslationAvailable =>
      'Нет доступного источника перевода для выбранного языка';

  @override
  String get filterTranslationLanguage => 'Фильтровать язык перевода';

  @override
  String get preview => 'Предпросмотр';

  @override
  String get audio => 'Аудио';

  @override
  String get tafsir => 'Тафсир';

  @override
  String get share => 'Поделиться';

  @override
  String get widget => 'Виджет';

  @override
  String get ayahText => 'Текст аята';

  @override
  String get audioControls => 'Аудио управление';

  @override
  String get readerSelection => 'Выбор чтеца';

  @override
  String get audioDownloads => 'Аудио загрузки';

  @override
  String get audioSettings => 'Аудио настройки';

  @override
  String get includedInAll => 'Включено во все';

  @override
  String get surahDownloaded => 'Сура загружена';

  @override
  String get downloading => 'Загрузка...';

  @override
  String get downloadSurah => 'Загрузить суру';

  @override
  String get allDownloaded => 'Все загружено';

  @override
  String get downloadAll => 'Загрузить все';

  @override
  String get checking => 'Проверка...';

  @override
  String get readPdf => 'Читать PDF';

  @override
  String get openFile => 'Открыть файл';

  @override
  String get download => 'Загрузить';

  @override
  String get bookDetails => 'Детали книги';

  @override
  String get attachments => 'Вложения';

  @override
  String get youreOffline => 'Вы оффлайн';

  @override
  String get shareAsPdf => 'Поделиться как PDF';

  @override
  String get shareInMessage => 'Поделиться в сообщении';

  @override
  String shareBookTitle(String title) {
    return 'Поделиться «$title»';
  }

  @override
  String shareBookSubject(String title) {
    return 'Ознакомьтесь с этой книгой: $title';
  }

  @override
  String get preparingPdfForSharing => 'Подготовка PDF к отправке...';

  @override
  String athkarShareRepeatCount(int count) {
    return 'Количество повторений: $count';
  }

  @override
  String everyFridayAtTime(String time) {
    return 'Каждую пятницу в $time';
  }

  @override
  String get weeklyReminderKahf =>
      'Еженедельное напоминание читать Суру Аль-Кахф по пятницам для благословений и защиты.';

  @override
  String get morningEveningAthkarTitle => 'Утренние и вечерние Азкар';

  @override
  String get dailyRemindersAthkar =>
      'Ежедневные напоминания о поминании Аллаха утром и вечером.';

  @override
  String get randomAthkarTitle => 'Случайные Азкар';

  @override
  String get periodicRemindersAthkar =>
      'Периодические напоминания со случайными Азкар в течение дня.';

  @override
  String get quranReadingReminderTitle => 'Напоминание о чтении Корана';

  @override
  String dailyAtTime(String time) {
    return 'Ежедневно в $time';
  }

  @override
  String get dailyReminderQuran =>
      'Ежедневное напоминание читать и размышлять над Священным Кораном.';

  @override
  String get minutes => 'Минуты';

  @override
  String get minutesExample => 'например, 30, 60, 120';

  @override
  String get minutesUnit => 'минут';

  @override
  String get recommendedMinutes =>
      'Рекомендуется: 30-120 минут для сбалансированных напоминаний';

  @override
  String get validNumberMinutes =>
      'Пожалуйста, введите действительное число от 10 до 1440 минут';

  @override
  String get selectQuranReminderTime => 'Выбрать время напоминания Корана';

  @override
  String get selectKahfFridayTime => 'Выбрать время пятницы для Кахф';

  @override
  String get athkarTimes => 'Времена Азкар';

  @override
  String get morning => 'Утро: ';

  @override
  String get evening => 'Вечер: ';

  @override
  String get selectMorningAthkarTime => 'Выбрать время утренних Азкар';

  @override
  String get selectEveningAthkarTime => 'Выбрать время вечерних Азкар';

  @override
  String get pdfViewer => 'Просмотрщик PDF';

  @override
  String get goToPage => 'Перейти к странице';

  @override
  String get search => 'Поиск';

  @override
  String get contents => 'Содержание';

  @override
  String get pages => 'Страницы';

  @override
  String get markers => 'Маркеры';

  @override
  String get goToPageTitle => 'Перейти к странице';

  @override
  String enterPageNumber(String pageCount) {
    return 'Введите номер страницы (от 1 до $pageCount)';
  }

  @override
  String get pageNumber => 'Номер страницы';

  @override
  String get searchInDocument => 'Поиск в документе...';

  @override
  String matchesCount(String current, String total) {
    return '$current из $total совпадений';
  }

  @override
  String pageLabel(String pageNumber) {
    return 'Страница $pageNumber';
  }

  @override
  String get noTableOfContents => 'Нет оглавления';

  @override
  String get bookmarkUpdated => 'Закладка обновлена';

  @override
  String get notes => 'Заметки';

  @override
  String get stars => 'Звезды';

  @override
  String get errorLoadingBookmarks => 'Ошибка при загрузке закладок';

  @override
  String get noBookmarksYet => 'Пока нет закладок';

  @override
  String get startBookmarkingFavoriteVerses =>
      'Начните добавлять ваши любимые аяты в закладки';

  @override
  String get noNotesYet => 'Пока нет заметок';

  @override
  String get addNotesToFavoriteVerses =>
      'Добавьте заметки к вашим любимым аятам';

  @override
  String get noStarredVersesYet => 'Пока нет аятов со звездами';

  @override
  String get starImportantVerses => 'Отметьте звездами ваши самые важные аяты';

  @override
  String get browseQuran => 'Просматривать Коран';

  @override
  String get total => 'Всего';

  @override
  String get clearAllBookmarksConfirmation =>
      'Вы уверены, что хотите удалить все закладки? Это действие нельзя отменить.';

  @override
  String get location => 'Местоположение';

  @override
  String get stopped => 'Остановлено';

  @override
  String errorUpdatingWidget(String error) {
    return 'Ошибка при обновлении виджета: $error';
  }

  @override
  String get sahih => 'сахих';

  @override
  String get daif => 'даиф';

  @override
  String get hasan => 'хасан';

  @override
  String get bukhari => 'Сахих аль-Бухари';

  @override
  String get muslim => 'Сахих Муслим';

  @override
  String get tirmidhi => 'Джами\' ат-Тирмизи';

  @override
  String get ahmad => 'Муснад Ахмад';

  @override
  String get contains => 'содержит';

  @override
  String get comingSoon => 'Скоро будет';

  @override
  String get hadithCollections => 'Коллекции хадисов';

  @override
  String get success => 'успех';

  @override
  String get warning => 'предупреждение';

  @override
  String get info => 'информация';

  @override
  String get notification => 'уведомление';

  @override
  String get sampleTextPreview =>
      'Я прошу прощения у Аллаха и каюсь перед Ним.';

  @override
  String get small => 'маленький';

  @override
  String get normal => 'нормальный';

  @override
  String get large => 'большой';

  @override
  String get extraLarge => 'очень большой';

  @override
  String get quran => 'Коран';

  @override
  String get quranKit => 'Набор Корана';

  @override
  String get continueHome => 'Продолжить чтение';

  @override
  String get continueActivityPrompt =>
      'Продолжите с того места, где остановились';

  @override
  String get noRecentActivityHome => 'Нет недавней активности';

  @override
  String get chooseThemeColor => 'Выберите цвет темы';

  @override
  String get themeDescription => 'Персонализируйте ваш опыт приложения';

  @override
  String get themeInfo =>
      'Ваша выбранная тема будет применена во всем приложении';

  @override
  String get purple => 'фиолетовый';

  @override
  String get green => 'зеленый';

  @override
  String get blue => 'синий';

  @override
  String get red => 'красный';

  @override
  String get orange => 'оранжевый';

  @override
  String get teal => 'бирюзовый';

  @override
  String get indigo => 'индиго';

  @override
  String get pink => 'розовый';

  @override
  String get yellow => 'жёлтый';

  @override
  String get brown => 'коричневый';

  @override
  String get cream => 'кремовый';

  @override
  String get goldTheme => 'золотой';

  @override
  String get settingsPureBlack => 'Чисто чёрный';

  @override
  String get settingsPureBlackDescription =>
      'Чёрный фон в тёмном режиме, для OLED-экранов';

  @override
  String get supportAndFeedback => 'Поддержка и обратная связь';

  @override
  String get shareYourThoughts => 'Общий отзыв';

  @override
  String get feedbackDescription => 'Поделитесь впечатлением о приложении';

  @override
  String get feedbackAndIssueActionTitle =>
      'Отправить отзыв или сообщить о проблеме';

  @override
  String get feedbackAndIssueActionSubtitle =>
      'Сообщите о проблеме, предложите улучшение или поделитесь мнением';

  @override
  String get rateOurApp => 'Оцените наше приложение';

  @override
  String get rateAppDescription =>
      'Помогите другим открыть для себя это приложение';

  @override
  String get batteryOptimizationExemptionGranted =>
      'Исключение из оптимизации батареи предоставлено';

  @override
  String get batteryOptimizationExemptionDenied =>
      'Исключение из оптимизации батареи отклонено';

  @override
  String get notificationsWillWorkReliably =>
      'Уведомления будут работать надежно';

  @override
  String get playing => 'Воспроизведение';

  @override
  String get islamicChecklistTitle => 'Ежедневный исламский контрольный список';

  @override
  String get backToToday => 'Вернуться к сегодня';

  @override
  String get dailyProgress => 'Ежедневный прогресс';

  @override
  String get noTasksForDay => 'Нет задач на этот день';

  @override
  String get fajrPrayer => 'Намаз Фаджр';

  @override
  String get dhuhrPrayer => 'Намаз Зухр';

  @override
  String get asrPrayer => 'Намаз Аср';

  @override
  String get maghribPrayer => 'Намаз Магриб';

  @override
  String get ishaPrayer => 'Намаз Иша';

  @override
  String get readingQuran => 'Чтение Корана';

  @override
  String get athkarSabah => 'Утренние Азкар';

  @override
  String get athkarMasaa => 'Вечерние Азкар';

  @override
  String get frequencyDaily => 'Ежедневно';

  @override
  String get frequencyEvery2Days => 'Каждые 2 дня';

  @override
  String get frequencyEvery3Days => 'Каждые 3 дня';

  @override
  String get frequencyEvery4Days => 'Каждые 4 дня';

  @override
  String get frequencyEvery5Days => 'Каждые 5 дней';

  @override
  String get frequencyEvery6Days => 'Каждые 6 дней';

  @override
  String get frequencyWeekly => 'Еженедельно';

  @override
  String get morningAthkar => 'Утренние Азкар';

  @override
  String get addCustomItem => 'Добавить пользовательский элемент';

  @override
  String get congratsMessage1 => 'Да вознаградит вас Аллах добром';

  @override
  String get congratsMessage2 => 'Да благословит вас Аллах';

  @override
  String get congratsMessage3 => 'О Аллах, благослови';

  @override
  String get congratsMessage4 => 'Ма ша Аллах';

  @override
  String get congratsMessage5 => 'Альхамдулиллах';

  @override
  String get congratsMessage6 => 'Табаракаллах';

  @override
  String get congratsMessage7 => 'Да принесет вам Аллах пользу';

  @override
  String get congratsMessage8 => 'Поздравления';

  @override
  String get congratsMessage9 => 'Да примет Аллах от нас и от вас';

  @override
  String get congratsMessage10 => 'Да дарует вам мой Господь успех';

  @override
  String get congratsMessage11 => 'Да благословит вас Аллах';

  @override
  String get congratsMessage12 => 'Да увеличит Аллах ваши знания';

  @override
  String get congratsMessage13 => 'Да помилует вас Аллах';

  @override
  String get islamicChecklist => 'Исламский контрольный список';

  @override
  String get dailyChecklistReminder =>
      'Напоминание о ежедневном контрольном списке';

  @override
  String dailyChecklistSubtitle(String time) {
    return 'Ежедневно в $time';
  }

  @override
  String get checklistReminderDescription =>
      'Получайте напоминания о выполнении ваших ежедневных исламских задач';

  @override
  String get selectChecklistReminderTime =>
      'Выберите время напоминания контрольного списка';

  @override
  String get status => 'Статус';

  @override
  String get enableNotificationsSettings =>
      'Пожалуйста, включите уведомления в системных настройках';

  @override
  String get notificationKahfTitle => '🕌 Напоминание о суре Аль-Кахф';

  @override
  String get notificationKahfBody =>
      'Сегодня пятница! Не забудьте прочитать суру Аль-Кахф для благословений и защиты.';

  @override
  String get notificationMorningAthkarTitle => '🌅 Утренние азкар';

  @override
  String get notificationMorningAthkarBody =>
      'Начните свой день с утренних азкар и поминания Аллаха.';

  @override
  String get notificationEveningAthkarTitle => '🌅 Вечерние азкар';

  @override
  String get notificationEveningAthkarBody =>
      'Завершите свой день вечерними азкар и благодарностью Аллаху.';

  @override
  String get notificationQuranTitle => '📖 Напоминание о чтении Корана';

  @override
  String get notificationQuranBody =>
      'Время прочитать несколько аятов Священного Корана и поразмышлять над его руководством.';

  @override
  String get notificationChecklistTitle =>
      '📋 Напоминание о ежедневном контрольном списке';

  @override
  String get notificationChecklistBody =>
      'Время заполнить свой ежедневный исламский контрольный список и отследить духовный прогресс.';

  @override
  String get notificationKhatmaTitle => '📖 Ежедневное напоминание о хатме';

  @override
  String get notificationKhatmaBody =>
      'Время прочитать ваш ежедневный вирд Корана и следовать плану хатмы.';

  @override
  String get notificationRandomAthkarTitle => '🤲 Случайные азкар';

  @override
  String notificationPrayerTimeTitle(String prayerName) {
    return '🕌 Время намаза $prayerName';
  }

  @override
  String notificationPrayerTimeBody(String prayerName) {
    return 'Время намаза $prayerName. Да примет Аллах ваши молитвы.';
  }

  @override
  String get prayerCountdownLoadingText => 'Загрузка времен намазов...';

  @override
  String get zakatCalculator => 'Калькулятор Закята';

  @override
  String get calculate => 'Рассчитать';

  @override
  String get results => 'Результаты';

  @override
  String get assets => 'Активы';

  @override
  String get liabilities => 'Обязательства';

  @override
  String get resetAll => 'Сбросить Все';

  @override
  String get zakatIsDue => 'Закят Обязателен';

  @override
  String get noZakatDue => 'Закят Не Обязателен';

  @override
  String get totalAssets => 'Общие Активы';

  @override
  String get totalDebts => 'Общие Долги';

  @override
  String get netAssets => 'Чистые Активы';

  @override
  String nisabThreshold(String type) {
    return 'Порог Нисаба ($type)';
  }

  @override
  String get currency => 'Валюта';

  @override
  String get nisabSettings => 'Настройки Нисаба';

  @override
  String get goldPricePerGram => 'Цена Золота за Грамм';

  @override
  String get silverPricePerGram => 'Цена Серебра за Грамм';

  @override
  String get nisabDescription =>
      'Нисаб - это минимальный порог богатства, который делает Закят обязательным. Он может быть рассчитан на основе стоимости золота (87,48г) или серебра (612,36г).';

  @override
  String get assetBreakdown => 'Разбивка Активов';

  @override
  String get nisabCalculationBasedOn => 'Расчет Нисаба Основан На';

  @override
  String get gold => 'Золото';

  @override
  String get silver => 'Серебро';

  @override
  String get goldGrams => '87,48 грамм';

  @override
  String get silverGrams => '612,36 грамм';

  @override
  String get aboutZakat => 'О Закяте';

  @override
  String get zakatDescription =>
      'Закят является одним из пяти столпов Ислама и обязательной милостыней. Он рассчитывается как 2,5% от квалифицированного богатства, которое находилось в собственности не менее одного лунного года (хауль).\n\nНисаб - это минимальный порог богатства, который делает Закят обязательным. Он может быть рассчитан на основе:\n• Золото: 87,48 грамм (20 мискаль)\n• Серебро: 612,36 грамм (200 дирхамов)\n\nЭтот калькулятор поможет вам определить, достигает ли ваше богатство порога нисаба и рассчитать точную сумму причитающегося Закята.';

  @override
  String get cashAndBankBalances => 'Наличные и Банковские Остатки';

  @override
  String get goldAssets => 'Золото';

  @override
  String get silverAssets => 'Серебро';

  @override
  String get businessAssets => 'Деловые Активы';

  @override
  String get investmentsAssets => 'Инвестиции';

  @override
  String get moneyOwedToYou => 'Деньги, Которые Вам Должны';

  @override
  String get debtsAndLiabilities => 'Долги и Обязательства';

  @override
  String get cashDescription =>
      'Сберегательные счета, текущие счета, наличные деньги, цифровые кошельки';

  @override
  String get goldDescription =>
      'Стоимость золотых украшений, монет и слитков (рыночная стоимость)';

  @override
  String get silverDescription =>
      'Стоимость серебряных украшений, монет и слитков (рыночная стоимость)';

  @override
  String get businessDescription =>
      'Инвентарь, деловые наличные, прибыль, удерживаемая в бизнесе';

  @override
  String get investmentsDescription =>
      'Акции, облигации, взаимные фонды, пенсионные счета (если подлежат закяту)';

  @override
  String get receivablesDescription =>
      'Деньги, которые вам должны и которые вы ожидаете получить';

  @override
  String get debtsDescription =>
      'Долги по кредитным картам, кредиты, счета к оплате в течение года';

  @override
  String get feedbackAppBarTitle => 'Отправить отзыв';

  @override
  String get feedbackEmptyWarning =>
      'Пожалуйста, введите свой отзыв перед отправкой';

  @override
  String get feedbackSuccessMessage => 'Спасибо! Ваш отзыв был отправлен.';

  @override
  String get feedbackHeroSubtitle =>
      'Помогите нам улучшить Huda, делясь своими мыслями, предложениями или сообщая о найденных проблемах.';

  @override
  String get feedbackFormTitle => 'Что вы хотите сделать?';

  @override
  String get feedbackFormSubtitle =>
      'Выберите один вариант, затем напишите сообщение.';

  @override
  String get feedbackHintText =>
      'Поделитесь мыслями, предложениями или сообщите о проблемах...';

  @override
  String get feedbackSending => 'Отправка...';

  @override
  String get feedbackSendButton => 'Отправить отзыв';

  @override
  String get feedbackPrivacyTitle => 'Уведомление о конфиденциальности';

  @override
  String get feedbackPrivacyDescription =>
      'Ваше сообщение и основные сведения о приложении и устройстве передаются безопасно. Электронная почта добавляется только в том случае, если вы ее укажете.';

  @override
  String get detailedFeedbackTitle => 'Предложить улучшение';

  @override
  String get detailedFeedbackSubtitle => 'Поделитесь идеей для Huda';

  @override
  String get reportAnIssue => 'Сообщить о проблеме';

  @override
  String get issueDescription =>
      'Помогите нам стать лучше, сообщив о любых проблемах';

  @override
  String get skip => 'пропустить';

  @override
  String get getStarted => 'Начать';

  @override
  String get shareAsText => 'Поделиться как текстом';

  @override
  String get shareDhikr => 'Поделиться зикром';

  @override
  String get generatingImage => 'Создание изображения...';

  @override
  String get rateAppTitle => 'Оцените приложение Huda';

  @override
  String get rateExperienceQuestion =>
      'Как бы вы оценили свой опыт использования нашего приложения?';

  @override
  String get helpUsImprove => 'Помогите нам улучшиться:';

  @override
  String get feedbackHint => 'Что мы можем улучшить?';

  @override
  String get rateButton => 'Оценить';

  @override
  String get maybeLater => 'Может быть позже';

  @override
  String get dontAskAgain => 'Больше не спрашивать';

  @override
  String get pleaseSelectRating => 'Пожалуйста, выберите оценку';

  @override
  String get provideFeedback => 'Пожалуйста, оставьте отзыв для улучшения';

  @override
  String get thankYouRedirect => 'Спасибо! Вы будете перенаправлены в магазин.';

  @override
  String get thankYouFeedback =>
      'Спасибо за ваш отзыв! Мы будем работать над улучшениями.';

  @override
  String get mawdu => 'Подделанный (Мауду’)';

  @override
  String get shadh => 'Ненормальный (Шаз)';

  @override
  String get munkar => 'Отклонённый (Мункар)';

  @override
  String get gharib => 'Редкий (Гариб)';

  @override
  String get chain => 'в цепочке передатчиков';

  @override
  String get noChapters => 'Главы недоступны';

  @override
  String get newContent =>
      'Новый контент скоро будет добавлен.\nПроверьте позже для обновлений.';

  @override
  String get meccan => 'Мекканская';

  @override
  String get medinan => 'Мединская';

  @override
  String get ayahs => 'Аяты';

  @override
  String get downloaded => 'Загруженный';

  @override
  String get loopThisAyah => 'Повторять этот аят';

  @override
  String get autoplayNextAyah => 'Автовоспроизведение следующего аята';

  @override
  String get memorizationMode => 'Режим заучивания';

  @override
  String get memorizationDescription =>
      'Проверьте свою память, скрывая аяты и читая их наизусть. Приложение будет слушать ваше чтение и открывать аяты по мере правильного чтения.';

  @override
  String get speechRecognitionDisclaimer =>
      'Качество распознавания речи зависит от возможностей вашего устройства.';

  @override
  String get startMemorization => 'Начать заучивание';

  @override
  String get stopMemorization => 'Остановить заучивание';

  @override
  String get listening => 'Слушаю...';

  @override
  String get microphoneIdle => 'Микрофон неактивен';

  @override
  String get reciteToReveal => 'Прочитайте аят, чтобы открыть его';

  @override
  String get beta => 'БЕТА';

  @override
  String get surahMemorized => 'Вы успешно выучили эту Суру.';

  @override
  String get counseling => 'Консультация';

  @override
  String get chat => 'Чат';

  @override
  String get counselingIntro =>
      'Поделитесь своими чувствами, и пусть Huda направит вас с исламской мудростью.';

  @override
  String get guidanceTitle => 'Наставление';

  @override
  String get quranTitle => 'Коран';

  @override
  String get duaaTitle => 'Дуа';

  @override
  String get exampleFeelAnxious => 'Я чувствую тревогу';

  @override
  String get exampleFeelOverwhelmed => 'Я чувствую себя перегруженным';

  @override
  String get exampleFeelingGrateful => 'Я чувствую благодарность';

  @override
  String get exampleSeekingPeace => 'Я ищу покоя';

  @override
  String get guidance => 'Руководство';

  @override
  String get quranicWisdom => 'Мудрость Корана';

  @override
  String get duaa => 'Дуа';

  @override
  String get addWidgetToHomeScreen => 'Добавить виджет на главный экран';

  @override
  String get addWidget => 'Добавить виджет';

  @override
  String get howToAddWidget => 'Как добавить виджет';

  @override
  String get androidWidgetStep1 =>
      'Нажмите и удерживайте пустую область на главном экране';

  @override
  String get androidWidgetStep2 => 'Нажмите \'Виджеты\' в меню';

  @override
  String get androidWidgetStep3 => 'Найдите \'Huda\' в списке виджетов';

  @override
  String get androidWidgetStep4 => 'Перетащите виджет на главный экран';

  @override
  String get iosWidgetStep1 =>
      'Нажмите и удерживайте пустую область на главном экране';

  @override
  String get iosWidgetStep2 => 'Нажмите кнопку \'+\' в верхнем левом углу';

  @override
  String get iosWidgetStep3 => 'Найдите \'Huda\' в галерее виджетов';

  @override
  String get iosWidgetStep4 =>
      'Выберите размер виджета и нажмите \'Добавить виджет\'';

  @override
  String get genericWidgetStep1 =>
      'Нажмите и удерживайте главный экран и найдите \'Виджеты\'';

  @override
  String get genericWidgetStep2 =>
      'Найдите виджет \'Huda\' и добавьте его на главный экран';

  @override
  String get macWidgetStep1 =>
      'Нажмите на рабочий стол, удерживая Control, и выберите «Изменить виджеты».';

  @override
  String get macWidgetStep2 =>
      'Найдите Huda и выберите «Аят Корана» или «Время молитв».';

  @override
  String get macWidgetStep3 =>
      'Нажмите на виджет, чтобы добавить его, или перетащите его на рабочий стол.';

  @override
  String get sahurAlarmTitle => 'Будильник на Сухур';

  @override
  String get sahurAlarmDescription => 'Просыпайтесь на Сухур до молитвы Фаджр.';

  @override
  String get exactTime => 'Точное время';

  @override
  String get minutesBeforeFajr => 'Минут до Фаджра';

  @override
  String atExactTime(String time) {
    return 'В $time';
  }

  @override
  String minsBeforeFajr(int minutes) {
    return '$minutes мин до Фаджра';
  }

  @override
  String get sahurAlarmRinging => 'Будильник на Сухур';

  @override
  String get stopAlarm => 'Остановить';

  @override
  String get sahurAlarmNotificationBody => 'Пора просыпаться на Сухур';

  @override
  String get miqaatLock => 'Блокировка Микаат';

  @override
  String get enableMiqaatLock => 'Включить блокировку Микаат';

  @override
  String get lockedApps => 'Заблокированные приложения';

  @override
  String get noAppsSelected => 'Приложения не выбраны';

  @override
  String get addApps => 'Добавить приложения';

  @override
  String get timeSlots => 'Временные интервалы';

  @override
  String get noTimeSlotsConfigured => 'Временные интервалы не настроены';

  @override
  String get addTimeSlot => 'Добавить временной интервал';

  @override
  String get editTimeSlot => 'Изменить временной интервал';

  @override
  String get sessionDuration => 'Продолжительность сеанса';

  @override
  String get sessionDurationDescription =>
      'Требуемое время в Huda (например, чтение Корана) для разблокировки ваших приложений';

  @override
  String get customDuration => 'Своя продолжительность';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get selectApps => 'Выбрать приложения';

  @override
  String get searchApps => 'Поиск приложений...';

  @override
  String get loadingApps => 'Загрузка приложений...';

  @override
  String get noAppsFound => 'Приложения не найдены';

  @override
  String get label => 'Метка (необязательно)';

  @override
  String get labelHint => 'напр., Время Фаджра, Рабочие часы';

  @override
  String get timeRange => 'Временной диапазон';

  @override
  String get repeatOn => 'Повторять';

  @override
  String get leaveEmptyForEveryday =>
      'Оставьте пустым для ежедневного повторения';

  @override
  String get everyday => 'Каждый день';

  @override
  String get monday => 'Понедельник';

  @override
  String get tuesday => 'Вторник';

  @override
  String get wednesday => 'Среда';

  @override
  String get thursday => 'Четверг';

  @override
  String get friday => 'Пятница';

  @override
  String get saturday => 'Суббота';

  @override
  String get sunday => 'Воскресенье';

  @override
  String get permissionsRequired => 'Требуются разрешения';

  @override
  String get permissionsRequiredDescription =>
      'Предоставьте следующие разрешения для включения Блокировки Микаат';

  @override
  String get accessibilityService => 'Служба специальных возможностей';

  @override
  String get accessibilityServiceDescription =>
      'Требуется для обнаружения запуска приложений';

  @override
  String get overlayPermission => 'Отображение поверх других приложений';

  @override
  String get overlayPermissionDescription =>
      'Требуется для отображения экрана блокировки';

  @override
  String get screenTimeAccess => 'Доступ к Экранному времени';

  @override
  String get screenTimeAccessDescription =>
      'Требуется для управления ограничениями приложений';

  @override
  String get checkPermissions => 'Проверить разрешения';

  @override
  String daysUntilRamadan(int days) {
    return '$days дней до Рамадана';
  }

  @override
  String ramadanDayLabel(int day) {
    return 'Рамадан $day';
  }

  @override
  String durationOfFasting(int hours, int minutes) {
    return 'Продолжительность поста: $hours часов и $minutes минут';
  }

  @override
  String durationOfIftar(int hours, int minutes) {
    return 'Продолжительность ифтара: $hours часов и $minutes минут';
  }

  @override
  String get imsaakLabel => 'Имсак';

  @override
  String get iftarLabel => 'Ифтар';

  @override
  String get fastedStatus => 'постился';

  @override
  String get missedStatus => 'пропущено';

  @override
  String get qadhaaInfoTitle => 'О када (восполнение пропущенных постов)';

  @override
  String get qadhaaInfoQ1Title => 'Что такое када?';

  @override
  String get qadhaaInfoQ1Body =>
      'Када — это пост в дни, когда мусульманин прервал свой пост во время Рамадана по уважительной исламской причине, такой как болезнь, путешествие, менструация или послеродовое кровотечение. Их необходимо восполнить до начала следующего Рамадана.';

  @override
  String get qadhaaInfoQ2Title => 'Положение о када';

  @override
  String get qadhaaInfoQ2Body1 => 'Всевышний Аллах сказал:';

  @override
  String get qadhaaInfoQ2Verse =>
      '«А если кто из вас болен или находится в пути, то пусть постится столько же дней в другое время». [Аль-Бакара: 184]';

  @override
  String get qadhaaInfoQ2Body2 =>
      'Поэтому каждый, кто прервал пост в Рамадан по уважительной причине, обязан восполнить эти дни.';

  @override
  String get qadhaaInfoQ3Title => 'Когда нужно совершать када?';

  @override
  String get qadhaaInfoQ3Body =>
      'Пропущенные дни Рамадана необходимо восполнить до начала следующего Рамадана. Их разрешается восполнять в любое время года, кроме дней двух праздников Ид и дней ат-Ташрик. Лучше поспешить с восполнением и не откладывать.';

  @override
  String get qadhaaInfoQ4Title => 'Как пользоваться';

  @override
  String get qadhaaInfoQ4Body1 =>
      'Во время Рамадана: нажмите на день, когда вы прервали пост, чтобы отметить его.';

  @override
  String get qadhaaInfoQ4Body2 =>
      'После Рамадана: нажмите на отмеченный день, чтобы подтвердить, что вы его восполнили.';

  @override
  String get whatsNewTitle => 'Что нового';

  @override
  String whatsNewVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get whatsNewExploreButton => 'Понятно!';

  @override
  String get whatsNew153Feature1 =>
      'Трекер поста Рамадана с ежедневным журналом каза';

  @override
  String get whatsNew153Feature2 =>
      'Блокировка Микаат для блокировки отвлекающих приложений во время молитвы';

  @override
  String get whatsNew153Feature3 =>
      'Трекер каза для записи и восполнения пропущенных дней поста';

  @override
  String get whatsNew200Feature1 =>
      'Блокировка Miqaat: блокируйте отвлекающие приложения в заданное время';

  @override
  String get whatsNew200Feature2 =>
      'Страница Рамадана: трекер Каза для записи пропущенных дней поста';

  @override
  String get whatsNew200Feature3 =>
      'Будильник Сухур: выберите фиксированное время или настройте автоматический звонок прямо перед Фаджром.';

  @override
  String get whatsNew200Feature4 => 'Улучшения интерфейса';

  @override
  String get whatsNew200Feature5 => 'Исправления ошибок';

  @override
  String get whatsNew300Feature1 =>
      'Похожие аяты: Находите аяты со схожими темами и смыслами по всему Корану';

  @override
  String get whatsNew300Feature2 =>
      'Трекер Хатма: Планируйте и отслеживайте чтение Корана с ежедневными напоминаниями';

  @override
  String get whatsNew300Feature3 =>
      'Макет Мусхафа: Читайте Коран в традиционном макете страницы Мусхафа';

  @override
  String get whatsNew300Feature4 =>
      'Аудио Коран: Слушайте чтение различных чтецов с возможностью скачивания';

  @override
  String get whatsNew300Feature5 =>
      'Радио Коран: Прямые радиостанции Корана для непрерывного прослушивания';

  @override
  String get whatsNew300Feature6 =>
      'Настройка времени молитвы: Точная настройка смещений для более точных уведомлений';

  @override
  String get whatsNew300Feature7 =>
      'Улучшения UI/UX, адаптивный дизайн и улучшенный опыт';

  @override
  String get whatsNew310Feature1iOS =>
      'Виджет времени молитв: виджет на главном экране и экране блокировки с обратным отсчётом до следующей молитвы в реальном времени';

  @override
  String get whatsNew310Feature1Android =>
      'Виджет времени молитв: виджет на главном экране с обратным отсчётом до следующей молитвы в реальном времени';

  @override
  String get whatsNew310Feature2 => 'Улучшения UI/UX';

  @override
  String get whatsNew310Feature3 => 'Исправление ошибок';

  @override
  String get whatsNew330Feature1 =>
      '«Продолжить чтение» перемещено: нажмите на карточку Корана на главном экране, чтобы развернуть её и найти свой прогресс чтения';

  @override
  String get whatsNew330Feature2 => 'Исправления ошибок и улучшения';

  @override
  String get whatsNew340Feature1 =>
      'Аудио: просматривайте и слушайте все виды исламского аудиоконтента с поддержкой офлайн-загрузки и таймера сна';

  @override
  String get whatsNew340Feature2 =>
      'Отслеживание чтеца и радио: последний прослушанный чтец и радиостанция теперь сохраняются — возобновите их с главного экрана';

  @override
  String get whatsNew340Feature3 =>
      'Прогресс чтения книги: последняя читаемая книга теперь сохраняется — продолжайте с того места, где остановились, со страницы книг';

  @override
  String get whatsNew340Feature4 => 'Исправления ошибок и улучшения';

  @override
  String get whatsNew350Feature1 =>
      'Шрифт приложения: измените шрифт приложения в настройках по своему вкусу';

  @override
  String get whatsNew350Feature2 =>
      'Исправления ошибок и улучшение производительности';

  @override
  String get whatsNew350Feature3 =>
      'Штрихи интерфейса: свежий и аккуратный вид на нескольких экранах';

  @override
  String get whatsNew370Feature1 =>
      'Улучшения времени молитв: более точное время с новыми методами расчёта, включая Оман, Алжир и другие';

  @override
  String get whatsNew370Feature2 =>
      'Компас Qiblah: улучшена работа компаса и точность направления Qiblah';

  @override
  String get whatsNew370Feature3 =>
      'Исправления ошибок и улучшение производительности';

  @override
  String get whatsNew400Feature1 =>
      'Настраивайте главный экран: выбирайте тему, меняйте порядок разделов и определяйте отображаемые функции';

  @override
  String get whatsNew400Feature2 => 'Повышена точность календаря хиджры';

  @override
  String get whatsNew400Feature3 =>
      'Уведомления о времени молитв теперь охватывают больше дней для более надёжных напоминаний';

  @override
  String get whatsNew400Feature4 => 'Улучшен дизайн во всём приложении';

  @override
  String get whatsNew400Feature5 =>
      'Более плавная и интуитивная работа с приложением';

  @override
  String get whatsNew420Feature1 =>
      'Обновлённые виджеты молитв и Корана с улучшенной настройкой, надёжностью и новыми вариантами для экрана блокировки iOS';

  @override
  String get whatsNew420Feature2 =>
      'Добавлены пользовательские углы расчёта для Фаджра, Магриба и Иша';

  @override
  String get whatsNew420Feature3 =>
      'Время молитв, уведомления и виджеты теперь могут автоматически обновляться во время путешествий';

  @override
  String get whatsNew420Feature4 =>
      'Huda AI теперь локально сохраняет историю разговоров с возможностью поиска';

  @override
  String get whatsNew420Feature5 => 'Улучшена настройка главного экрана';

  @override
  String get whatsNew420Feature6 =>
      'Обновлён интерфейс обратной связи и сообщений о проблемах';

  @override
  String get whatsNew430Feature1 => 'Время молитв и виджеты стали надёжнее.';

  @override
  String get whatsNew430Feature2 =>
      'Более плавная и продуманная работа во всём приложении.';

  @override
  String get whatsNew500Feature1 => 'Совершенно новый облик всего приложения.';

  @override
  String get whatsNew500Feature2 =>
      'Выберите азан и настройте оповещения для каждой молитвы.';

  @override
  String get whatsNew500Feature3 => 'Укажите время икамата для вашей мечети.';

  @override
  String get whatsNew500Feature4 =>
      'Читайте Коран на страницах Хафс, Таджвид или ИндоПак.';

  @override
  String get whatsNew500Feature5iOS =>
      'Будильники молитв теперь могут воспроизводить азан полностью.';

  @override
  String get whatsNew500Feature5Android =>
      'Добавьте время молитв на экран блокировки Samsung.';

  @override
  String get whatsNew500Feature5Desktop =>
      'Время молитв теперь в строке меню или на панели задач.';

  @override
  String showingDownloadedBooks(int count) {
    return 'Показано $count загруженных книг';
  }

  @override
  String get bookDownloadedSuccessfully => 'Книга успешно загружена!';

  @override
  String get iosAppsSelectedSuccessfully => 'Приложения успешно выбраны';

  @override
  String iosAppSelectionError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get iosScreenTimeProtection => 'Защита Экранного времени';

  @override
  String iosAppsAndCategoriesSelected(int appCount, int categoryCount) {
    return 'Выбрано $appCount прил. + $categoryCount кат.';
  }

  @override
  String iosAppSelected(int appCount) {
    return 'Выбрано $appCount приложение';
  }

  @override
  String iosAppsSelected(int appCount) {
    return 'Выбрано $appCount приложения';
  }

  @override
  String get noDownloadedBooks => 'Нет скачанных книг';

  @override
  String get downloadBooksWhenOnlineToAccessThemOffline =>
      'Скачивайте книги, когда вы в сети, чтобы читать их офлайн';

  @override
  String get accessibilityServiceRequiredDialogTitle =>
      'Требуется служба специальных возможностей';

  @override
  String get accessibilityServiceRequiredDialogDesc =>
      'Miqaat Lock требует API службы специальных возможностей для обнаружения запуска приложений и отображения экрана блокировки.';

  @override
  String get accessibilityServiceRequiredDialogPrivacy =>
      'Мы не используем эту службу для сбора, хранения или передачи каких-либо личных или конфиденциальных данных пользователей.';

  @override
  String get agree => 'Согласиться';

  @override
  String get quranAudio => 'Аудио Корана';

  @override
  String get searchReciters => 'Поиск чтецов...';

  @override
  String get verses => 'аяты';

  @override
  String get connectToDownload =>
      'Подключитесь к интернету, чтобы просматривать и загружать чтения Корана';

  @override
  String get quranRadio => 'Радио Коран';

  @override
  String get searchRadio => 'Поиск радиостанций...';

  @override
  String get khatmaTitle => 'Хатм Корана';

  @override
  String get khatmaDescription =>
      'Установите свою ежедневную порцию или срок завершения Корана и отслеживайте свой хатм в течение года.';

  @override
  String get khatmaStartNew => 'Начать новый хатм';

  @override
  String get khatmaNewTitle => 'Новый хатм';

  @override
  String get khatmaSuggested => 'Рекомендуется';

  @override
  String get khatmaDailyWirdJuz => 'Ежедневная порция: один джуз';

  @override
  String get khatmaDailyWirdRubu => 'Ежедневная порция: один рубъ';

  @override
  String get khatmaDailyWirdTwoRubu => 'Ежедневная порция: два рубъа';

  @override
  String get khatmaDailyWird3Rubu => 'Ежедневная порция: 3 рубъа';

  @override
  String get khatmaDailyWirdHizb => 'Ежедневная порция: один хизб';

  @override
  String get khatmaDailyWirdHizbAndHalf => 'Ежедневная порция: 1,5 хизба';

  @override
  String get khatmaDailyWirdJuzAndHalf => 'Ежедневная порция: 1,5 джуза';

  @override
  String get khatmaDailyWirdTwoJuz => 'Ежедневная порция: два джуза';

  @override
  String get khatmaDailyWird3Juz => 'Ежедневная порция: 3 джуза';

  @override
  String get khatmaDailyWird5Juz => 'Ежедневная порция: 5 джузов';

  @override
  String get khatmaDailyWird10Juz => 'Ежедневная порция: 10 джузов';

  @override
  String get khatmaStartFromTitle => 'Начать хатм с';

  @override
  String get khatmaFromBeginningSubtitle => 'Начать с Аль-Фатихи';

  @override
  String get khatmaSpecificWirdSubtitle => 'Выберите день из списка порций';

  @override
  String khatmaDayOf(int current, int total) {
    return 'День $current из $total';
  }

  @override
  String get khatmaTomorrow => 'Завтра';

  @override
  String get khatmaInTwoDays => 'Через два дня';

  @override
  String khatmaInDays(int count) {
    return 'Через $count дня';
  }

  @override
  String khatmaInManyDays(int count) {
    return 'Через $count дней';
  }

  @override
  String get khatmaYesterday => 'Вчера';

  @override
  String get khatmaTwoDaysAgo => 'Два дня назад';

  @override
  String khatmaDaysAgo(int count) {
    return '$count дня назад';
  }

  @override
  String khatmaManyDaysAgo(int count) {
    return '$count дней назад';
  }

  @override
  String get khatmaLegendKhatma => 'Хатм';

  @override
  String get khatmaCommitment => 'Приверженность';

  @override
  String get khatmaDaysRemaining => 'Осталось дней';

  @override
  String get khatmaPagesRead => 'Прочитано страниц';

  @override
  String get khatmaPagesRemaining => 'Осталось (стр.)';

  @override
  String khatmaDailyWirdOf(int day) {
    return 'Порция дня $day';
  }

  @override
  String khatmaFromSurah(String surah, int verse) {
    return 'От $surah: $verse';
  }

  @override
  String khatmaToSurah(String surah, int verse) {
    return 'До $surah: $verse';
  }

  @override
  String get khatmaMarkDone => 'Я завершил эту порцию';

  @override
  String get khatmaDailyReminderSection => 'Ежедневное напоминание';

  @override
  String get khatmaDailyWirdTitle => 'Ежедневная порция';

  @override
  String get khatmaAllWirds => 'Все порции';

  @override
  String get khatmaDeleteTitle => 'Удалить хатм';

  @override
  String get khatmaDeleteSubtitle => 'Очистить все данные прогресса';

  @override
  String get khatmaCongrats => 'Да благословит вас Аллах!';

  @override
  String get khatmaCompletedMsg => 'Вы успешно завершили этот хатм';

  @override
  String get khatmaRepeat => 'Повторить этот хатм';

  @override
  String get khatmaDeleteConfirmContent =>
      'Вы уверены, что хотите удалить текущий хатм и стереть все данные о вашем прогрессе?';

  @override
  String khatmaDailyWirdPages(int pages) {
    return 'Ежедневная порция: ~$pages страниц';
  }

  @override
  String get surahsLabel => 'Суры';

  @override
  String get surahIndexSubtitle => '114 Сур';

  @override
  String get searchSurahHint => 'Поиск суры...';

  @override
  String get surahNoResults => 'Результаты не найдены';

  @override
  String verseCountLabel(int count) {
    return '$count аят';
  }

  @override
  String get tabMemorization => 'Хифз';

  @override
  String get readingModeScrollList => 'Прокрутка списка';

  @override
  String get readingModeMushaf => 'Макет Мусхафа';

  @override
  String get readingModeTajweed => 'Макет Мусхафа Таджвид';

  @override
  String get readingModeIndopak => 'Мусхаф ИндоПак';

  @override
  String get mushafFlipHorizontal => 'Горизонтальный переворот';

  @override
  String get mushafFlipVertical => 'Вертикальный переворот';

  @override
  String get mushafDisplaySingle => 'Одна страница';

  @override
  String get mushafDisplayDouble => 'Двойная страница';

  @override
  String get mushafDisplayZoomed => 'Увеличенный';

  @override
  String mushafJuzHeader(String name) {
    return 'Джуз $name';
  }

  @override
  String mushafPageNumber(int number) {
    return 'Страница $number';
  }

  @override
  String get settingsReadingMode => 'Режим чтения';

  @override
  String get settingsFlipDirection => 'Направление листания';

  @override
  String get settingsQuranFont => 'Шрифт Корана';

  @override
  String get settingsAppFont => 'Шрифт приложения';

  @override
  String get settingsAppFontDescription =>
      'Шрифт, используемый в интерфейсе приложения';

  @override
  String get settingsSystemFont => 'Системный по умолчанию';

  @override
  String get settingsSystemFontDescription =>
      'Использует стандартный шрифт вашего устройства';

  @override
  String surahNumberBadge(int number) {
    return 'Сура $number';
  }

  @override
  String get fontExtractingLabel => 'Извлечение…';

  @override
  String get fontLoadingLabel => 'Загрузка…';

  @override
  String get mushafPackTitle => 'Страницы Мусхафа';

  @override
  String get mushafPackBody =>
      'Теперь Мусхаф использует изображения страниц для более плавного листания. Загрузите их один раз, чтобы продолжить чтение в этом виде.';

  @override
  String mushafPackDownload(String size) {
    return 'Загрузить ($size)';
  }

  @override
  String get nextSurah => 'Следующая сура';

  @override
  String get previousSurah => 'Предыдущая сура';

  @override
  String get noSimilarAyahsFound => 'Похожих аятов не найдено';

  @override
  String similarAyahsCountLabel(String ayahKey, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count похожих аятов',
      few: '$count похожих аята',
      one: '1 похожий аят',
    );
    return '$ayahKey имеет $_temp0';
  }

  @override
  String similarAyahsMatchStats(
    int matchedWordsCount,
    int coverage,
    int score,
  ) {
    return 'Совпадает $matchedWordsCount слов · охват $coverage% · Счёт: $score';
  }

  @override
  String get quranVerseWidget => 'Аят Корана';

  @override
  String get prayerTimesWidget => 'Время молитв';

  @override
  String get addPrayerWidget => 'Добавить на главный экран';

  @override
  String get prayerWidgetTimeFormat => 'Формат времени молитв';

  @override
  String get prayerWidgetTwelveHour => '12 часов';

  @override
  String get prayerWidgetTwentyFourHour => '24 часа';

  @override
  String get design => 'Дизайн';

  @override
  String get designHero => 'В центре внимания';

  @override
  String get designHeroDescription =>
      'Атмосферный акцент на следующей молитве с точным отсчётом и спокойным небесным ритмом.';

  @override
  String get designCompact => 'Альманах';

  @override
  String get designCompactDescription =>
      'Редакционная дата и расписание с выделением следующей молитвы и ночным временем.';

  @override
  String get size => 'Размер';

  @override
  String get medium => 'Средний';

  @override
  String get lockScreen => 'Экран блокировки';

  @override
  String get background => 'Фон';

  @override
  String get backgroundColor => 'Цвет фона';

  @override
  String get glassify => 'Эффект стекла';

  @override
  String get rounded => 'Закруглённые углы';

  @override
  String get content => 'Содержимое';

  @override
  String get contentColor => 'Цвет содержимого';

  @override
  String get contentSize => 'Размер содержимого';

  @override
  String get region => 'Регион';

  @override
  String get numerals => 'Цифры';

  @override
  String get automatic => 'Автоматически';

  @override
  String get advanced => 'Дополнительно';

  @override
  String get resetWidgetCustomization => 'Сбросить до значений по умолчанию';

  @override
  String get forcePrayerWidgetUpdate => 'Обновить виджет молитв';

  @override
  String get prayerWidgetUpdated => 'Виджет молитв обновлён';

  @override
  String get prayerWidgetUpdating => 'Обновление…';

  @override
  String get widgetTheme => 'Тема';

  @override
  String get themeAuto => 'Тема приложения';

  @override
  String get themeOcean => 'Океан';

  @override
  String get themeSunset => 'Закат';

  @override
  String get themeForest => 'Лес';

  @override
  String get themeMidnight => 'Полночь';

  @override
  String get themeSandstone => 'Песчаник';

  @override
  String get themeRose => 'Роза';

  @override
  String get themeLavender => 'Лаванда';

  @override
  String get themeCharcoal => 'Уголь';

  @override
  String get themeAmber => 'Янтарь';

  @override
  String get themeArctic => 'Арктика';

  @override
  String get themeBurgundy => 'Бордовый';

  @override
  String get themeSage => 'Шалфей';

  @override
  String get eventRamadan => 'Рамадан Мубарак';

  @override
  String get calendarEventFirstDayRamadan => 'Первый день Рамадана';

  @override
  String get calendarEventEidAlFitr => 'Ид аль-Фитр';

  @override
  String get calendarEventEidAlAdha => 'Ид аль-Адха';

  @override
  String get eventLastTenRamadan => 'Последние десять ночей';

  @override
  String get eventEidAlFitr => 'Ид аль-Фитр Мубарак';

  @override
  String get eventEidAlAdha => 'Ид аль-Адха Мубарак';

  @override
  String get eventDayOfArafah => 'День Арафат';

  @override
  String get eventFirstTenDhulHijjah => 'Первые десять дней Зу-ль-Хиджи';

  @override
  String get eventAshura => 'День Ашура';

  @override
  String get eventDaysTashreeq => 'Дни Ташрик';

  @override
  String get eventRamadanSubtitle =>
      'Месяц поста, ночной молитвы и чтения Корана';

  @override
  String get eventLastTenRamadanSubtitle =>
      'Ищите Лейлат аль-Кадр в эти благословенные ночи';

  @override
  String get eventEidAlFitrSubtitle =>
      'Отпразднуйте завершение Рамадана с радостью и благодарностью';

  @override
  String get eventEidAlAdhaSubtitle =>
      'Праздник жертвоприношения — день преданности и щедрости';

  @override
  String get eventDayOfArafahSubtitle =>
      'Лучший день, над которым взошло солнце';

  @override
  String get eventFirstTenDhulHijjahSubtitle =>
      'Самые любимые Аллахом дни для праведных дел';

  @override
  String get eventAshuraSubtitle => 'День поста и поминания милости Аллаха';

  @override
  String get eventDaysTashreeqSubtitle => 'Дни еды, питья и поминания Аллаха';

  @override
  String get eventRamadanArabic =>
      'شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ هُدًى لِّلنَّاسِ وَبَيِّنَاتٍ مِّنَ الْهُدَىٰ وَالْفُرْقَانِ';

  @override
  String get eventRamadanTranslation =>
      'Месяц Рамадан, в который был ниспослан Коран как руководство для людей и ясные доказательства руководства и различения.';

  @override
  String get eventRamadanSource => 'Коран 2:185';

  @override
  String get eventLastTenRamadanArabic =>
      'إِنَّا أَنزَلْنَاهُ فِي لَيْلَةِ الْقَدْرِ · وَمَا أَدْرَاكَ مَا لَيْلَةُ الْقَدْرِ · لَيْلَةُ الْقَدْرِ خَيْرٌ مِّنْ أَلْفِ شَهْرٍ';

  @override
  String get eventLastTenRamadanTranslation =>
      'Поистине, Мы ниспослали его в Ночь предопределения. Откуда тебе знать, что такое Ночь предопределения? Ночь предопределения лучше тысячи месяцев.';

  @override
  String get eventLastTenRamadanSource => 'Коран 97:1-3';

  @override
  String get eventEidAlFitrArabic =>
      'لِلصَّائِمِ فَرْحَتَانِ: فَرْحَةٌ عِندَ فِطْرِهِ، وَفَرْحَةٌ عِندَ لِقَاءِ رَبِّهِ';

  @override
  String get eventEidAlFitrTranslation =>
      'У постящегося две радости: радость при разговении и радость при встрече со своим Господом.';

  @override
  String get eventEidAlFitrSource => 'Бухари и Муслим';

  @override
  String get eventEidAlAdhaArabic =>
      'لَن يَنَالَ اللَّهَ لُحُومُهَا وَلَا دِمَاؤُهَا وَلَٰكِن يَنَالُهُ التَّقْوَىٰ مِنكُمْ';

  @override
  String get eventEidAlAdhaTranslation =>
      'Ни их мясо, ни их кровь не достигнут Аллаха, но Его достигнет ваша богобоязненность.';

  @override
  String get eventEidAlAdhaSource => 'Коран 22:37';

  @override
  String get eventDayOfArafahArabic =>
      'صِيَامُ يَوْمِ عَرَفَةَ أَحْتَسِبُ عَلَى اللَّهِ أَن يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ وَالسَّنَةَ الَّتِي بَعْدَهُ';

  @override
  String get eventDayOfArafahTranslation =>
      'Пост в день Арафа, я надеюсь от Аллаха, что он искупит грехи предыдущего и последующего года.';

  @override
  String get eventDayOfArafahSource => 'Сахих Муслим';

  @override
  String get eventFirstTenDhulHijjahArabic =>
      'مَا مِنْ أَيَّامٍ الْعَمَلُ الصَّالِحُ فِيهِنَّ أَحَبُّ إِلَى اللَّهِ مِنْ هَذِهِ الأَيَّامِ';

  @override
  String get eventFirstTenDhulHijjahTranslation =>
      'Нет дней, в которые праведные дела были бы более любимы Аллахом, чем в эти дни.';

  @override
  String get eventFirstTenDhulHijjahSource => 'Сахих аль-Бухари';

  @override
  String get eventAshuraArabic =>
      'صِيَامُ يَوْمِ عَاشُورَاءَ أَحْتَسِبُ عَلَى اللَّهِ أَن يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ';

  @override
  String get eventAshuraTranslation =>
      'Пост в день Ашура, я надеюсь от Аллаха, что он искупит грехи предыдущего года.';

  @override
  String get eventAshuraSource => 'Сахих Муслим';

  @override
  String get eventDaysTashreeqArabic =>
      'وَاذْكُرُوا اللَّهَ فِي أَيَّامٍ مَّعْدُودَاتٍ';

  @override
  String get eventDaysTashreeqTranslation =>
      'И поминайте Аллаха в считанные дни.';

  @override
  String get eventDaysTashreeqSource => 'Коран 2:203';

  @override
  String get eventRamadanGuidance =>
      'Соблюдайте пост от рассвета до заката, совершайте молитву Таравих ночью, читайте Коран, давайте милостыню, увеличивайте мольбы и просите прощения у Аллаха.';

  @override
  String get eventLastTenRamadanGuidance =>
      'Ищите ночь Предопределения особенно в нечетные ночи. Увеличивайте ночные молитвы и совершайте итикаф если возможно. Чаще повторяйте: Аллахумма иннакя Афуввун тухиббуль-афва фа\'фу анни.';

  @override
  String get eventEidAlFitrGuidance =>
      'Выплатите закят аль-фитр до праздничной молитвы. Совершите праздничную молитву совместно, произносите такбир, наденьте лучшую одежду и разделите радость с семьей и соседями.';

  @override
  String get eventEidAlAdhaGuidance =>
      'Совершите праздничную молитву, принесите жертву после молитвы и произносите такбир после каждой обязательной молитвы. Разделите мясо с семьей, соседями и нуждающимися.';

  @override
  String get eventDayOfArafahGuidance =>
      'Соблюдайте пост в этот благословенный день если вы не совершаете хадж. Усердно молитесь, ибо в этот день Аллах освобождает от Огня больше всего людей. Увеличивайте поминание Аллаха и произносите Ля иляха иллаЛлах вахдаху ля шарика лях.';

  @override
  String get eventFirstTenDhulHijjahGuidance =>
      'Соблюдайте пост первые девять дней, особенно в день Арафа. Увеличивайте благие дела и обильно произносите такбир, тахлиль и тахмид в эти дни.';

  @override
  String get eventAshuraGuidance =>
      'Соблюдайте пост 10-го Мухаррама и добавьте 9-й день следуя Сунне. Помните, что Пророк постился в этот день из благодарности Аллаху за спасение Мусы от Фараона.';

  @override
  String get eventDaysTashreeqGuidance =>
      'Обильно поминайте Аллаха и произносите такбир после каждой обязательной молитвы. Это дни еды, питья и благодарности. Пост в эти дни запрещен кроме паломника, который не может принести жертву.';

  @override
  String get eventWhiteDaysFasting => 'Сунна поста в Белые дни';

  @override
  String get eventMondayThursdayFasting =>
      'Сунна поста по понедельникам и четвергам';

  @override
  String get eventWhiteDaysMondayThursdayFasting =>
      'Белые дни, совпавшие с понедельником или четвергом';

  @override
  String get eventWhiteDaysFastingSubtitle =>
      'Пост 13-го, 14-го и 15-го числа каждого месяца хиджры.';

  @override
  String get eventMondayThursdayFastingSubtitle =>
      'Добровольный пост в два дня, когда представляются деяния.';

  @override
  String get eventWhiteDaysMondayThursdayFastingSubtitle =>
      'Белый день, выпавший на понедельник или четверг.';

  @override
  String get eventWhiteDaysFastingArabic =>
      'كَانَ يَأْمُرُنَا أَنْ نَصُومَ الْبِيضَ ثَلَاثَ عَشْرَةَ وَأَرْبَعَ عَشْرَةَ وَخَمْسَ عَشْرَةَ';

  @override
  String get eventWhiteDaysFastingTranslation =>
      'Он велел нам поститься в белые дни: тринадцатого, четырнадцатого и пятнадцатого числа месяца.';

  @override
  String get eventWhiteDaysFastingSource => 'Сунан Абу Дауд 2449';

  @override
  String get eventWhiteDaysFastingGuidance =>
      'Старайтесь поститься в Белые дни — 13-го, 14-го и 15-го числа месяца хиджры — следуя сунне Пророка ﷺ.';

  @override
  String get eventMondayThursdayFastingArabic =>
      'تُعْرَضُ الأَعْمَالُ يَوْمَ الاِثْنَيْنِ وَالْخَمِيسِ فَأُحِبُّ أَنْ يُعْرَضَ عَمَلِي وَأَنَا صَائِمٌ';

  @override
  String get eventMondayThursdayFastingTranslation =>
      'Дела представляются в понедельник и четверг, и я люблю, чтобы мои дела представлялись, когда я пощусь.';

  @override
  String get eventMondayThursdayFastingSource => 'Джами ат-Тирмизи 747';

  @override
  String get eventMondayThursdayFastingGuidance =>
      'Поститесь по понедельникам и четвергам по мере возможности, следуя сунне Пророка ﷺ: в эти дни представляются деяния, и он любил, чтобы его деяния представлялись, когда он постился.';

  @override
  String get eventWhiteDaysMondayThursdayFastingArabic =>
      'كَانَ يَأْمُرُنَا أَنْ نَصُومَ الْبِيضَ ثَلَاثَ عَشْرَةَ وَأَرْبَعَ عَشْرَةَ وَخَمْسَ عَشْرَةَ · تُعْرَضُ الأَعْمَالُ يَوْمَ الاِثْنَيْنِ وَالْخَمِيسِ';

  @override
  String get eventWhiteDaysMondayThursdayFastingTranslation =>
      'Белые дни — это 13-й, 14-й и 15-й дни месяца по хиджре; дела представляются в понедельник и четверг.';

  @override
  String get eventWhiteDaysMondayThursdayFastingSource =>
      'Сунан Абу Дауд 2449 · Джами ат-Тирмизи 747';

  @override
  String get eventWhiteDaysMondayThursdayFastingGuidance =>
      'Если Белый день выпадает на понедельник или четверг, воспользуйтесь этим днём для добровольного поста по сунне Пророка ﷺ и чаще обращайтесь с мольбами и поминайте Аллаха.';

  @override
  String get audios => 'Аудио';

  @override
  String get audiobooks => 'Исламские аудио';

  @override
  String get audiobook => 'Исламское аудио';

  @override
  String get chapters => 'Главы';

  @override
  String chapter(int number) {
    return 'Глава $number';
  }

  @override
  String get continueListening => 'Продолжить прослушивание';

  @override
  String get continueBook => 'Продолжить чтение';

  @override
  String resumePage(int number) {
    return 'Страница $number';
  }

  @override
  String resumeChapter(int number) {
    return 'Продолжить главу $number';
  }

  @override
  String get continueRadio => 'Продолжить радио';

  @override
  String get playbackSpeed => 'Скорость воспроизведения';

  @override
  String get sleepTimer => 'Таймер сна';

  @override
  String get endOfChapter => 'Конец главы';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get downloadAudiobook => 'Скачать исламское аудио';

  @override
  String get audiobookDownloaded => 'Загружено';

  @override
  String get play => 'Воспроизвести';

  @override
  String get pause => 'Пауза';

  @override
  String get noOfflineAudiobooks => 'Нет загруженных исламских аудио';

  @override
  String chapterProgress(int current, int total) {
    return 'Глава $current из $total';
  }

  @override
  String get chatErrorNoConnection =>
      'Нет подключения к интернету. Проверьте сеть и повторите попытку.';

  @override
  String get chatErrorRateLimit =>
      'Слишком много запросов. Подождите немного и повторите попытку.';

  @override
  String get chatErrorServer =>
      'Не удаётся связаться с сервером. Повторите попытку чуть позже.';

  @override
  String get chatErrorSafety =>
      'Этот запрос не удалось выполнить из-за правил безопасности контента. Измените формулировку и повторите попытку.';

  @override
  String get chatErrorGeneric => 'Что-то пошло не так. Повторите попытку.';

  @override
  String get emailOptional => 'Электронная почта (необязательно — для ответа)';

  @override
  String get errorDetailsCopied =>
      'Сведения об ошибке скопированы в буфер обмена';

  @override
  String get restartAppButton => 'Перезапустить приложение';

  @override
  String get copyButton => 'Копировать';

  @override
  String get pleaseEnterMessage => 'Введите сообщение перед отправкой';

  @override
  String get helpUsImproveTitle => 'Помогите нам стать лучше';

  @override
  String get errorFeedbackPrompt =>
      'Что вы делали, когда произошла эта ошибка? Ваш отзыв поможет нам быстрее устранить эти проблемы.';

  @override
  String get errorFeedbackHint => 'Я пытался...';

  @override
  String get feedbackThankYou => 'Спасибо!';

  @override
  String get feedbackThankYouMessage =>
      'Ваш отзыв отправлен. Мы используем его, чтобы улучшить приложение.';

  @override
  String get describeIssueHint => 'Опишите проблему или отзыв...';

  @override
  String get prayerSettingsTitle => 'Настройки времени намаза';

  @override
  String get prayerSettingsSubtitle => 'Метод, мазхаб и точная настройка';

  @override
  String get prayerCalculationMethod => 'Метод расчёта';

  @override
  String get prayerCustomAnglesTitle => 'Пользовательские углы';

  @override
  String get prayerCustomAnglesSubtitle =>
      'Задайте углы солнца для Фаджра, Магриба и Иши.';

  @override
  String get prayerAngleRangeExclusive =>
      'Введите угол больше 0° и не более 30°.';

  @override
  String get prayerAngleRangeInclusive => 'Введите угол от 0° до 30°.';

  @override
  String get prayerMaghribZeroMeansSunset =>
      '0° означает, что Магриб наступает на закате.';

  @override
  String get prayerAsrMethod => 'Метод Аср (Мазхаб)';

  @override
  String get prayerHighLatitudeRule => 'Правило высоких широт';

  @override
  String get prayerTimeAdjustment => 'Корректировка времени';

  @override
  String get prayerAdjustmentSubtitle => 'Нажмите + или - для настройки';

  @override
  String get prayerMethodAuto => 'Автоматически (по стране)';

  @override
  String get prayerHighLatitudeNone => 'Нет';

  @override
  String get prayerHighLatitudeMiddleOfTheNight => 'Середина ночи';

  @override
  String get prayerHighLatitudeSeventhOfTheNight => 'Одна седьмая ночи';

  @override
  String get prayerHighLatitudeTwilightAngle => 'Угол сумерек';

  @override
  String get prayerMadhabShafi => 'Шафии';

  @override
  String get prayerMadhabHanafi => 'Ханафи';

  @override
  String get prayerMethodUmmAlQura => 'Умм аль-Кура';

  @override
  String get prayerMethodMuslimWorldLeague => 'Всемирная исламская лига';

  @override
  String get prayerMethodEgyptian => 'Египетское главное управление геодезии';

  @override
  String get prayerMethodKarachi => 'Университет исламских наук, Карачи';

  @override
  String get prayerMethodNorthAmerica => 'Северная Америка (ISNA)';

  @override
  String get prayerMethodEmirates => 'ОАЭ (GAIAE)';

  @override
  String get prayerMethodDubai => 'Дубай';

  @override
  String get prayerMethodQatar => 'Катарский календарный дом';

  @override
  String get prayerMethodKuwait => 'Кувейт';

  @override
  String get prayerMethodOman => 'Оман';

  @override
  String get prayerMethodOmanMuscat => 'Маскат, Оман';

  @override
  String get prayerMethodJordan => 'Иордания';

  @override
  String get prayerMethodPalestine => 'Палестина';

  @override
  String get prayerMethodSyria => 'Сирия (Хашимитская)';

  @override
  String get prayerMethodIraq => 'Ирак';

  @override
  String get prayerMethodMorocco => 'Марокко (Хабус)';

  @override
  String get prayerMethodAzrou => 'Азру, Марокко';

  @override
  String get prayerMethodAlgeria => 'Алжир';

  @override
  String get prayerMethodTunisia => 'Тунис';

  @override
  String get prayerMethodLibya => 'Ливия';

  @override
  String get prayerMethodSudan => 'Судан';

  @override
  String get prayerMethodTurkey => 'Турция (Диянет)';

  @override
  String get prayerMethodMalaysia => 'Юго-Восточная Азия';

  @override
  String get prayerMethodMalaysia2 => 'Малайзия';

  @override
  String get prayerMethodIndonesia => 'Индонезия';

  @override
  String get prayerMethodKazakhstan => 'Казахстан';

  @override
  String get prayerMethodTajikistan => 'Таджикистан';

  @override
  String get prayerMethodMaldives => 'Мальдивы';

  @override
  String get prayerMethodSouthKorea => 'Южная Корея';

  @override
  String get prayerMethodUoif => 'UOIF';

  @override
  String get prayerMethodParis => 'Париж';

  @override
  String get prayerMethodToulouse => 'Тулуза';

  @override
  String get prayerMethodLyon => 'Лион';

  @override
  String get prayerMethodOrleans => 'Орлеан';

  @override
  String get prayerMethodMoscow => 'Москва';

  @override
  String get prayerMethodCzech => 'Чехия';

  @override
  String get prayerMethodSwitzerland => 'Швейцария (Женева)';

  @override
  String get prayerMethodFribourg => 'Фрибур, Швейцария';

  @override
  String get prayerMethodBelgium => 'Бельгия';

  @override
  String get prayerMethodLuxembourg => 'Люксембург';

  @override
  String get prayerMethodAustria => 'Австрия';

  @override
  String get prayerMethodLondon => 'Лондон';

  @override
  String get prayerMethodBirmingham => 'Бирмингем';

  @override
  String get prayerMethodBlackburn => 'Блэкберн';

  @override
  String get prayerMethodAachen => 'Ахен';

  @override
  String get prayerMethodMunchen => 'Мюнхен';

  @override
  String get prayerMethodPotsdam => 'Потсдам';

  @override
  String get prayerMethodNurnberg => 'Нюрнберг';

  @override
  String get prayerMethodRotterdam => 'Роттердам';

  @override
  String get prayerMethodDordrecht => 'Дордрехт';

  @override
  String get prayerMethodEindhoven => 'Эйндховен';

  @override
  String get prayerMethodMontreal => 'Монреаль';

  @override
  String get prayerMethodWindsor => 'Виндзор';

  @override
  String get prayerMethodCalgary => 'Калгари';

  @override
  String get prayerMethodMississauga => 'Миссиссога';

  @override
  String get prayerMethodOther => 'Пользовательский';

  @override
  String get prayerSettingsApply => 'Применить';

  @override
  String get customizeHome => 'Настроить главный экран';

  @override
  String get editHome => 'Изменить главный экран';

  @override
  String get homeTheme => 'Тема главного экрана';

  @override
  String get homeStyle => 'Стиль главного экрана';

  @override
  String get themeClassic => 'Классическая';

  @override
  String get themePrayerToday => 'Путь молитвы';

  @override
  String get themeQuranJourney => 'Путь Корана';

  @override
  String get themeClassicDescription =>
      'Знакомая сетка со всеми инструментами.';

  @override
  String get themePrayerTodayDescription =>
      'Сначала время и следующая молитва.';

  @override
  String get themeQuranJourneyDescription =>
      'Сначала чтение Корана и прогресс хатмы.';

  @override
  String get onHome => 'На главном экране';

  @override
  String get viewMore => 'Показать больше';

  @override
  String get showLess => 'Показать меньше';

  @override
  String get moveToHome => 'Переместить на главный экран';

  @override
  String get moveToViewMore => 'Переместить в дополнительные';

  @override
  String get homeSections => 'Разделы';

  @override
  String get moveUp => 'Переместить вверх';

  @override
  String get moveDown => 'Переместить вниз';

  @override
  String get restoreDefaultLayout => 'Восстановить стандартный макет';

  @override
  String get restoreDefaultLayoutMessage =>
      'Это восстановит порядок и стандартные разделы инструментов для этого стиля главного экрана.';

  @override
  String get viewMoreEmpty =>
      'Переместите сюда редко используемые инструменты, чтобы упростить главный экран.';

  @override
  String get discardChanges => 'Отменить изменения?';

  @override
  String get discardChangesMessage =>
      'Изменения главного экрана еще не применены.';

  @override
  String get discard => 'Отменить';

  @override
  String get todaysAyah => 'Аят дня';

  @override
  String get khatmaProgress => 'Прогресс хатмы';

  @override
  String get noActiveKhatma => 'Нет активного плана хатмы';

  @override
  String get prayerSetupRequired =>
      'Укажите местоположение для показа времени молитв';

  @override
  String get gregorianDate => 'Григорианская дата';

  @override
  String get quranTools => 'Инструменты Корана';

  @override
  String get sectionDateAndPrayer => 'Дата и следующая молитва';

  @override
  String get sectionPrayerSchedule => 'Расписание молитв на день';

  @override
  String get sectionDailyAyah => 'Аят дня';

  @override
  String get sectionContinueReading => 'Продолжить чтение';

  @override
  String get sectionKhatmaProgress => 'Прогресс хатмы';

  @override
  String get sectionQuranTools => 'Инструменты Корана';

  @override
  String get keepEditing => 'Продолжить редактирование';

  @override
  String get discardChangesAction => 'Отменить изменения';

  @override
  String get saving => 'Сохранение';

  @override
  String get customizeHomeHint =>
      'Нажмите и перетащите любую карточку, чтобы изменить порядок. Кнопка перемещает инструмент между главным экраном и дополнительными.';

  @override
  String get homeChangesSaveFailed =>
      'Не удалось сохранить изменения. Попробуйте еще раз.';

  @override
  String get eventSpecialOccasion => 'Особый день';

  @override
  String get eventSpecialOccasionSubtitle =>
      'Значимый день исламского календаря';

  @override
  String get eventSpecialOccasionGuidance =>
      'Проведите этот день в поминании, благодарности и следовании достоверным наставлениям, относящимся к этому событию.';

  @override
  String get snackbarNeutral => 'Уведомление';

  @override
  String get enableNotifications => 'Включить уведомления';

  @override
  String get batteryOptimizationDescription =>
      'Оптимизация батареи Android может задерживать напоминания. Разрешите Huda работать без оптимизации, чтобы оповещения приходили надежнее.';

  @override
  String get batteryOptimizationExactAlarmDescription =>
      'Оптимизация батареи Android может задерживать напоминания. Разрешите Huda работать без оптимизации, чтобы оповещения приходили надежнее; на Android 12 и новее это также включает планирование точно по времени.';

  @override
  String get keepRemindersReliable => 'Разрешить надежные напоминания';

  @override
  String get prayerTimesPermissionTitle =>
      'Получать оповещения о времени намаза';

  @override
  String get prayerTimesPermissionDescription =>
      'Включите уведомления, чтобы получать каждое оповещение о времени намаза, даже когда приложение Huda закрыто.';

  @override
  String get calendarPermissionTitle => 'Получать напоминания о событиях';

  @override
  String get calendarPermissionDescription =>
      'Включите уведомления, чтобы получать напоминания о выбранных вами событиях хиджрийского календаря.';

  @override
  String get remindersPermissionTitle => 'Включить свои напоминания';

  @override
  String get remindersPermissionDescription =>
      'Включите уведомления для Корана, азкаров, сухура и других напоминаний, которые вы активируете.';

  @override
  String get khatmaPermissionTitle => 'Не сбиваться с пути в хатме';

  @override
  String get khatmaPermissionDescription =>
      'Включите уведомления, чтобы получать ежедневное напоминание о вирде в выбранное время.';

  @override
  String get batteryOptimizationTitle => 'Получать напоминания вовремя';

  @override
  String get notificationsReadyTitle => 'Уведомления включены';

  @override
  String get notificationsReadyDescription =>
      'Выбранные напоминания готовы к доставке.';

  @override
  String get batteryOptimizationReadyTitle => 'Оптимизация батареи отключена';

  @override
  String get batteryOptimizationReadyDescription =>
      'Huda может надежнее работать в фоновом режиме.';

  @override
  String get exactAlarmTitle => 'Использовать точные будильники вместо этого';

  @override
  String get exactAlarmDescription =>
      'Оставьте оптимизацию батареи включенной и разрешите точные будильники для точного планирования. Ограничения батареи всё равно могут задерживать доставку.';

  @override
  String get allowExactAlarms => 'Разрешить точные будильники';

  @override
  String get exactAlarmsReadyTitle => 'Точное по времени планирование готово';

  @override
  String get exactAlarmsReadyDescription =>
      'Huda может планировать оповещения о намазе и напоминания точно по времени.';

  @override
  String get quranWidgetTypography => 'Стиль текста';

  @override
  String get ayahAutoFit => 'Автоподбор аята';

  @override
  String get translationAutoFit => 'Автоподбор перевода';

  @override
  String get ayahTextSize => 'Размер аята';

  @override
  String get translationTextSize => 'Размер перевода';

  @override
  String get boldAyah => 'Жирный аят';

  @override
  String get boldTranslation => 'Жирный перевод';

  @override
  String get translationLanguage => 'Язык перевода';

  @override
  String get translationLanguageDescription =>
      'Выберите язык текста под арабским аятом.';

  @override
  String translationSource(String source) {
    return 'Перевод: $source';
  }

  @override
  String get accentColor => 'Цвет акцента';

  @override
  String get quranWidgetUpdated => 'Виджет Корана обновлён';

  @override
  String get forceQuranWidgetUpdate => 'Показать другой аят';

  @override
  String get quranWidgetUpdating => 'Обновление виджета…';

  @override
  String get arabicTranslationHidden =>
      'При арабском языке приложения виджет показывает только арабский аят.';

  @override
  String get aiHistory => 'История Huda AI';

  @override
  String get newChat => 'Новый чат';

  @override
  String get searchConversations => 'Поиск разговоров';

  @override
  String get noChatHistory => 'Сохранённых разговоров пока нет';

  @override
  String get noHistoryResults => 'Подходящих разговоров нет';

  @override
  String get clearAllHistory => 'Очистить всю историю';

  @override
  String get clearAllHistoryConfirmation =>
      'Удалить все разговоры Huda AI? Это действие нельзя отменить.';

  @override
  String get deleteChat => 'Удалить разговор';

  @override
  String get deleteChatConfirmation =>
      'Удалить этот разговор? Это действие нельзя отменить.';

  @override
  String get aiResponseGenerating => 'Создаётся';

  @override
  String get aiResponseInterrupted => 'Прерван';

  @override
  String get aiResponseFailed => 'Ошибка';

  @override
  String get aiStorageWarning =>
      'Не удалось сохранить историю Huda AI на этом устройстве. Разговор останется доступен до закрытия приложения.';

  @override
  String get aiBusyOtherConversation => 'Huda AI отвечает в другом разговоре.';

  @override
  String get chatErrorInterrupted =>
      'Ответ был прерван. Попробуйте ещё раз, чтобы продолжить.';

  @override
  String get manual => 'Вручную';

  @override
  String get travelPermissionRequired => 'Требуется разрешение';

  @override
  String get travelAllowLocation => 'Разрешить доступ к геопозиции';

  @override
  String get travelTurnOnLocation => 'Включить геолокацию';

  @override
  String get travelAllowAllTheTime => 'Разрешить всегда';

  @override
  String travelBackgroundPermissionInstructions(String optionLabel) {
    return 'Чтобы обновлять время намаза, когда Huda закрыта, откройте разрешения приложения на геолокацию и выберите «$optionLabel».';
  }

  @override
  String get prayerNotificationIssueMessage =>
      'Не удалось завершить расписание уведомлений о молитве. Время молитв по-прежнему доступно.';

  @override
  String get prayerNotificationRetry => 'Повторить';

  @override
  String get prayerNotificationsScheduledTitle =>
      'Уведомления о молитве готовы';

  @override
  String prayerNotificationsScheduledUntil(String date) {
    return 'Запланировано до $date';
  }

  @override
  String get prayerNotificationsCoverageReminder =>
      'Откройте Huda до этой даты, чтобы продлить расписание.';

  @override
  String get prayerNotificationsIosReminder =>
      'Время от времени открывайте Huda, чтобы уведомления о молитве оставались запланированными.';

  @override
  String get prayerNotificationsCoverageExpired =>
      'Срок расписания уведомлений истёк. Нажмите «Повторить», чтобы обновить его.';

  @override
  String get prayerNotificationSettingsChanged =>
      'Настройки уведомлений о молитве изменились. Нажмите «Повторить», чтобы обновить расписание.';

  @override
  String get prayerNotificationSyncBusy =>
      'Сервис планирования уведомлений о молитве сейчас занят. Повторите попытку немного позже.';

  @override
  String get prayerNotificationSyncUnavailable =>
      'Планирование уведомлений о молитве временно недоступно.';

  @override
  String get prayerNotificationSyncVerificationFailed =>
      'Не удалось проверить расписание уведомлений о молитве. Повторите попытку.';

  @override
  String get ayahAudioRange => 'Выбрать аяты';

  @override
  String get audioFromAyah => 'С аята';

  @override
  String get audioToAyah => 'По аят';

  @override
  String get audioRepeatRange => 'Повторять выбранное';

  @override
  String get audioRangeEndHint =>
      'Воспроизведение остановится после последнего выбранного аята.';

  @override
  String get downloadAyah => 'Скачать аят';

  @override
  String get ayahDownloaded => 'Аят скачан';

  @override
  String get audioRangeRepeatHint =>
      'Выбранные аяты повторяются, пока вы не остановите воспроизведение.';

  @override
  String playingAyahOfTotal(int current, int total) {
    return 'Аят $current из $total';
  }

  @override
  String prayerNotificationsBridgedUntil(String date) {
    return 'Уведомления обновлены по $date. Последующие могут по-прежнему соответствовать прежним настройкам или местоположению. Вернитесь, когда появится интернет, чтобы обновить их.';
  }

  @override
  String get prayerIssueLocationAccess => 'Доступ к местоположению';

  @override
  String get prayerCountryQuestion => 'В какой вы стране?';

  @override
  String get prayerCountryQuestionHint =>
      'Не удалось автоматически определить вашу страну, например рядом с границей. Выберите её, чтобы использовать правильный метод расчёта.';

  @override
  String get prayerCountryNotSure => 'Не уверен';

  @override
  String get prayerCalendarShare => 'Поделиться календарём намазов';

  @override
  String get prayerCalendarOneDay => 'Один день';

  @override
  String get prayerCalendarOneMonth => 'Один месяц';

  @override
  String get prayerCalendarWholeYear => 'Весь год';

  @override
  String get prayerCalendarGenerate => 'Создать и поделиться';

  @override
  String prayerCalendarPreparing(Object current, Object total) {
    return 'Подготовка страницы $current из $total…';
  }

  @override
  String get prayerCalendarError =>
      'Не удалось создать календарь намазов или поделиться им. Повторите попытку.';

  @override
  String get prayerCalendarUnavailable =>
      'Для отправки нужны проверенные времена намаза.';

  @override
  String get prayerCalendarTitle => 'Календарь времени намаза';

  @override
  String get prayerCalendarDate => 'Дата';

  @override
  String get prayerCalendarDay => 'День';

  @override
  String get prayerCalendarTimeZone => 'Часовой пояс';

  @override
  String prayerCalendarGenerated(Object date) {
    return 'Создано $date';
  }

  @override
  String prayerCalendarPage(Object page, Object total) {
    return 'Страница $page из $total';
  }

  @override
  String prayerCalendarShareText(Object location, Object period) {
    return 'Время намаза на $period в $location';
  }

  @override
  String get prayerCalendarSunriseColumn => 'Восход';

  @override
  String get prayerNotificationsOffTitle => 'Уведомления о молитве выключены';

  @override
  String get prayerNotificationsOffMessage =>
      'Уведомления выключены, поэтому напоминания о молитве не запланированы. Включите их, чтобы получать напоминание в каждое время молитвы.';

  @override
  String get prayerNotificationsTurnOn => 'Включить';

  @override
  String get prayerNotificationsWaitingTitle => 'Уведомления о молитве ожидают';

  @override
  String get prayerNotificationsWaitingMessage =>
      'Напоминания о молитве будут запланированы после проверки вашего местоположения.';

  @override
  String get prayerNotificationsNoneScheduled =>
      'Уведомления о молитве пока не запланированы. Нажмите «Повторить», чтобы запланировать их.';

  @override
  String prayerSetupStepLabel(int step, int total) {
    return 'Шаг $step из $total';
  }

  @override
  String get prayerSetupLocationTitle => 'Ваше местоположение';

  @override
  String get prayerSetupLocationIntro =>
      'Huda нужно ваше местоположение, чтобы рассчитать время намаза там, где вы находитесь.';

  @override
  String get prayerSetupLocationServicesOff =>
      'Службы геолокации на этом устройстве отключены. Включите их — время намаза загрузится автоматически, когда вы вернётесь.';

  @override
  String get prayerSetupUseMyLocation => 'Использовать моё местоположение';

  @override
  String get prayerSetupSearchCity => 'Найти город';

  @override
  String get prayerSetupAlertsTitle => 'Оповещения о намазе';

  @override
  String get prayerSetupAlertsHint =>
      'Оповещение в каждое время намаза, даже когда Huda закрыто.';

  @override
  String get prayerSetupReliableTitle => 'Надёжные напоминания';

  @override
  String get prayerTimelineNext => 'Следующий';

  @override
  String get prayerTimelineNow => 'Сейчас';

  @override
  String get prayerHeroStarted => 'Время намаза наступило';

  @override
  String get prayerTimesProvisional => 'Предварительное время';

  @override
  String get prayerMoreOptions => 'Другие параметры';

  @override
  String prayerOffsetBadge(String offset) {
    return '$offset мин';
  }

  @override
  String get prayerSetupAlertsIntro =>
      'Получайте мягкое оповещение в каждое время намаза, даже когда Huda закрыто.';

  @override
  String get prayerSetupAlertsAllow => 'Разрешить оповещения о намазе';

  @override
  String get prayerSetupAlertsDeclined =>
      'Без уведомлений Huda не сможет напомнить вам о времени намаза. Расписание по-прежнему будет здесь, а оповещения можно включить позже.';

  @override
  String get prayerSetupContinueWithoutAlerts => 'Продолжить без оповещений';

  @override
  String get prayerSetupAlertsOn => 'Оповещения включены';

  @override
  String get prayerSetupReliableIntro =>
      'Android может задерживать оповещения ради экономии заряда. Разрешите Huda работать без ограничений батареи, чтобы каждое оповещение приходило вовремя.';

  @override
  String get prayerSetupReliableOn => 'Оповещения будут приходить вовремя';

  @override
  String get prayerHeroRemaining => 'осталось';

  @override
  String get prayerSunriseLabel => 'Восход';

  @override
  String get prayerCalendarFormatImage => 'Отправляется как изображение';

  @override
  String get prayerCalendarFormatPdf => 'Отправляется как PDF-документ';

  @override
  String prayerHeroStartedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Наступило $minutes мин назад',
      many: 'Наступило $minutes мин назад',
      few: 'Наступило $minutes мин назад',
      one: 'Наступило $minutes мин назад',
      zero: 'Только что наступило',
    );
    return '$_temp0';
  }

  @override
  String get macPrayerMenuTitle => 'Время молитв в строке меню';

  @override
  String get macPrayerMenuDescription =>
      'Показывать время молитв и обратный отсчёт после закрытия окна Huda.';

  @override
  String get macPrayerMenuStyle => 'Надпись в строке меню';

  @override
  String get macPrayerMenuSettings => 'Настройки молитв…';

  @override
  String get macPrayerMenuQuit => 'Выйти из Huda';

  @override
  String get macPrayerMenuNeedsSetup =>
      'Откройте страницу времени молитв в Huda, чтобы указать местоположение.';

  @override
  String get macPrayerMenuVerifyLocation => 'Проверьте местоположение в Huda';

  @override
  String macPrayerMenuNameCountdown(String prayer, String time) {
    return '$prayer через $time';
  }

  @override
  String get macPrayerMenuIconOnly => 'Только значок';

  @override
  String get macPrayerMenuError =>
      'Не удалось обновить строку меню. Повторите попытку.';

  @override
  String get macPrayerMenuHourShort => 'ч';

  @override
  String get macPrayerMenuMinuteShort => 'мин';

  @override
  String get windowsPrayerTaskbarTitle => 'Обратный отсчёт намаза в Windows';

  @override
  String get windowsPrayerTaskbarDescription =>
      'Отсчёт продолжается после закрытия Huda. Выйдите из Huda через значок в трее, чтобы остановить его на этот сеанс.';

  @override
  String get windowsPrayerShowTaskbar => 'Показывать отсчёт на панели задач';

  @override
  String get windowsPrayerStartup => 'Запускать с Windows';

  @override
  String get windowsPrayerSeconds => 'Показывать секунды';

  @override
  String get windowsPrayerStartupDisabled =>
      'Автозапуск отключён в параметрах Windows.';

  @override
  String get windowsPrayerOpenStartupSettings =>
      'Открыть параметры автозапуска Windows';

  @override
  String get windowsPrayerPlacementUnavailable =>
      'Не удалось показать обратный отсчёт на этой панели задач. Окно намаза доступно через значок в трее, если он включён.';

  @override
  String get windowsPrayerHelperUnavailable =>
      'Отсчёт Windows недоступен. Восстановите или обновите Huda.';

  @override
  String get windowsPrayerOpenHuda => 'Открыть Huda';

  @override
  String get windowsPrayerCalendarUnavailable =>
      'Данные календаря Рамадана недоступны для этой даты.';

  @override
  String get windowsPrayerNoNextPrayer => 'Следующее время намаза недоступно.';

  @override
  String get windowsPrayerStartupEffectiveEnabled =>
      'Автозапуск Windows: включён';

  @override
  String get windowsPrayerStartupEffectiveDisabled =>
      'Автозапуск Windows: отключён';

  @override
  String get windowsPrayerStyle => 'Надпись на панели задач';

  @override
  String get windowsPrayerPreview => 'Предпросмотр панели задач';

  @override
  String get windowsPrayerStyleCountdown =>
      'Название молитвы и обратный отсчёт';

  @override
  String get windowsPrayerStyleClock => 'Название и время молитвы';

  @override
  String get windowsPrayerTransparentBackground => 'Прозрачный фон';

  @override
  String get windowsPrayerShowIcon => 'Показывать логотип Huda';

  @override
  String get windowsPrayerTextColor => 'Цвет текста';

  @override
  String get windowsPrayerTextColorAutomatic =>
      'Автоматически (панель задач Windows)';

  @override
  String get windowsPrayerTextColorLight => 'Светлый';

  @override
  String get windowsPrayerTextColorDark => 'Тёмный';

  @override
  String get windowsPrayerTextColorApp => 'Цвет приложения';

  @override
  String get windowsPrayerTextSize => 'Размер текста';

  @override
  String get windowsPrayerTextSizeSmall => 'Маленький';

  @override
  String get windowsPrayerTextSizeMedium => 'Средний';

  @override
  String get windowsPrayerTextSizeLarge => 'Большой';

  @override
  String get windowsPrayerResetAppearance => 'Сбросить оформление';

  @override
  String get windowsPrayerError =>
      'Не удалось обновить обратный отсчёт Windows. Попробуйте ещё раз.';

  @override
  String get windowsPrayerFocusMode => 'Режим концентрации';

  @override
  String get windowsPrayerStopAdhan => 'Остановить азан';

  @override
  String get windowsPrayerDismissFocus => 'Закрыть';

  @override
  String get windowsPrayerFocusMessage =>
      'Пришло время молитвы. Сделайте перерыв.';

  @override
  String get windowsPrayerFocusExitHint =>
      'Закройте окно или нажмите Escape в любой момент.';

  @override
  String windowsPrayerNextNotification(String prayer, String duration) {
    return 'Следующая: $prayer через $duration';
  }

  @override
  String get windowsPrayerFocusLockedHint =>
      'Режим фокуса завершится, когда таймер достигнет нуля.';

  @override
  String get windowsPrayerFocusVerseReference => 'Ан-Ниса · 4:103';

  @override
  String get windowsPrayerFocusTimeRemaining => 'Осталось времени';

  @override
  String get macPrayerLoginSettings => 'Открыть настройки объектов входа';

  @override
  String get macPrayerEmergencyExit => 'Аварийный выход';

  @override
  String get macPrayerApplyError =>
      'Не удалось применить настройки молитвы macOS. Обновите и повторите попытку.';

  @override
  String get macPrayerVerse =>
      '﴿ إِنَّ ٱلصَّلَوٰةَ كَانَتْ عَلَى ٱلْمُؤْمِنِينَ كِتَٰبًا مَّوْقُوتًا ﴾';

  @override
  String get iosPrayerAdvanceTitle => 'Prayer reminder';

  @override
  String iosPrayerAdvanceBody(String prayer, String minutes) {
    return '$prayer in $minutes minutes.';
  }

  @override
  String get iosPrayerRenewalTitle => 'Extend prayer alerts';

  @override
  String get iosPrayerRenewalBody =>
      'Open Huda to extend your scheduled prayer alerts.';

  @override
  String get linuxPrayerTrayTitle => 'Панель молитв';

  @override
  String get linuxPrayerTrayDescription =>
      'Показывать время молитв на верхней панели GNOME, когда Huda закрыта.';

  @override
  String get linuxPrayerTrayStartAtLogin => 'Запускать при входе';

  @override
  String get linuxRemindersReady =>
      'Напоминания приходят, даже когда Huda закрыта';

  @override
  String get linuxRemindersNeedService =>
      'Напоминания приходят, только пока работает фоновая служба Huda. Включите «Запускать при входе» в разделе времени молитв, чтобы они приходили и после перезагрузки.';

  @override
  String get windowsRemindersReady =>
      'Напоминания приходят, даже когда Huda закрыта';

  @override
  String windowsRemindersQueuedUntil(String date) {
    return 'Напоминания запланированы до $date';
  }

  @override
  String get windowsRemindersNeedStartup =>
      'Включите «Запускать с Windows», чтобы Huda продлевала их без открытия.';

  @override
  String get windowsRemindersOpenHuda =>
      'Откройте Huda до этой даты, чтобы они продолжились.';

  @override
  String get linuxPrayerTrayInstall => 'Настроить панель молитв';

  @override
  String get linuxPrayerTrayInstallHelp =>
      'Панель молитв нужно настроить один раз.';

  @override
  String get linuxPrayerTrayExtensionMissing =>
      'Расширение панели не установлено.';

  @override
  String get linuxPrayerTrayExtensionDisabled => 'Расширение панели отключено.';

  @override
  String get linuxPrayerTrayExtensionIncompatible =>
      'Обновите расширение для этой версии GNOME.';

  @override
  String get linuxPrayerTrayAvailable => 'Панель молитв готова.';

  @override
  String get linuxPrayerTrayServiceUnavailable =>
      'Отображение молитв недоступно. Откройте Huda для перезапуска.';

  @override
  String get linuxPrayerTrayCalculationUnavailable =>
      'Время молитв недоступно. Проверьте местоположение и параметры расчёта.';

  @override
  String get linuxPrayerTrayQuitExplanation =>
      'Закрыть Huda и панель молитв на этот сеанс. Текущие уведомления о молитвах продолжат работать.';

  @override
  String get linuxPrayerTrayStopped => 'Панель молитв остановлена.';

  @override
  String get linuxPrayerTrayError =>
      'Не удалось применить настройки панели молитв.';

  @override
  String get linuxPrayerTrayRestart => 'Перезапустить панель молитв';

  @override
  String get linuxPrayerTraySetupIntro =>
      'Однократная настройка. Расширение панели уже входит в Huda.';

  @override
  String get linuxPrayerTrayInstallStepTitle => 'Установите панель';

  @override
  String get linuxPrayerTrayInstallStep =>
      'Скопируйте команду ниже. Откройте Терминал, вставьте её и нажмите Enter.';

  @override
  String get linuxPrayerTrayCopyCommand => 'Копировать команду';

  @override
  String get linuxPrayerTrayCommandCopied =>
      'Команда скопирована. Вставьте её в Терминал и нажмите Enter.';

  @override
  String get linuxPrayerTrayEnableStepTitle => 'Включите расширение';

  @override
  String get linuxPrayerTrayEnableStep =>
      'Откройте приложение «Расширения» и включите «Huda Prayer Panel».';

  @override
  String get linuxPrayerTrayLoginHint =>
      'Если его ещё нет в списке, выйдите из сеанса рабочего стола и войдите снова, затем вновь откройте «Расширения».';

  @override
  String get linuxPrayerTrayFinishStepTitle => 'Вернитесь в Huda';

  @override
  String get linuxPrayerTrayFinishStep =>
      'Вернитесь сюда и выберите «Проверить настройку», чтобы включить панель молитв.';

  @override
  String get linuxPrayerTrayCheckSetup => 'Проверить настройку';

  @override
  String get linuxPrayerTraySetupNotReady =>
      'Панель ещё не готова. Выполните шаги выше и проверьте снова.';

  @override
  String get linuxPrayerTrayDownloadStep =>
      'Скачайте из выпусков Huda файл с окончанием «gnome-prayer-tray.zip». Откройте Терминал, вставьте команду ниже, добавьте пробел, перетащите ZIP-файл и нажмите Enter.';

  @override
  String get linuxPrayerTrayDownloads => 'Открыть загрузки';

  @override
  String get linuxPrayerTrayUpdateStep =>
      'Перед повторной установкой панели обновите Huda до выпуска, поддерживающего вашу версию GNOME.';

  @override
  String get linuxPrayerExperienceQuitInfo =>
      'Закрытие окна сохраняет фоновые напоминания. Выход из Huda останавливает напоминания, азан и фокус до повторного открытия.';

  @override
  String get linuxPrayerExperienceCommitmentInfo =>
      'Обычное закрытие скрыто до окончания таймера. Экстренный выход, Escape и выход из Huda остаются доступны. Предпросмотр всегда можно закрыть сразу.';

  @override
  String get samsungLockWidgetsTitle => 'Виджеты экрана блокировки Samsung';

  @override
  String get samsungLockWidgetsInstructions =>
      'В Samsung One UI 8 нажмите и удерживайте экран блокировки, нажмите Добавить виджеты и выберите Huda. Добавьте отсчёт до молитвы или аят Корана и нажмите Готово.';

  @override
  String get samsungLockWidgetsHint =>
      'На экране блокировки мало места. Выберите подходящие вам виджеты.';

  @override
  String get testNotificationTitle => 'Тестовое уведомление';

  @override
  String get testNotificationDescription =>
      'Отправляет уведомление примерно через 10 секунд тем же путём, что и ваши напоминания. Пока ждёте, Huda можно закрыть.';

  @override
  String get testNotificationSend => 'Отправить тест';

  @override
  String get testNotificationContentTitle => 'Тестовое уведомление Huda';

  @override
  String get testNotificationContentBody => 'Уведомления Huda работают.';

  @override
  String get testNotificationArrivesSoon =>
      'Тестовое уведомление придёт примерно через 10 секунд. Huda можно закрыть.';

  @override
  String get testNotificationMayBeLate =>
      'Тестовое уведомление в пути. Точные будильники выключены, поэтому оно может прийти на несколько минут позже.';

  @override
  String get testNotificationNotificationsOff =>
      'Уведомления для Huda выключены. Включите их и попробуйте снова.';

  @override
  String get testNotificationServiceNotRunning =>
      'Фоновая служба Huda не запущена, поэтому уведомления не могут прийти. Запустите её в разделе времени молитв и попробуйте снова.';

  @override
  String get testNotificationFailed =>
      'Не удалось запланировать тестовое уведомление. Попробуйте снова.';

  @override
  String get permissionExplainerContinue => 'Продолжить';

  @override
  String get permissionExplainerNotNow => 'Не сейчас';

  @override
  String get permissionExplainerNotificationsTitle => 'Разрешить уведомления';

  @override
  String get permissionExplainerNotificationsMessage =>
      'Huda нужны уведомления, чтобы напоминать вам в выбранное время. Сейчас устройство попросит разрешение.';

  @override
  String get prayerReadyTitle => 'Настройте оповещения о молитве';

  @override
  String prayerReadyStepsLeft(int count) {
    return 'Настройте оповещения о молитве · шагов: $count';
  }

  @override
  String get prayerReadyNotificationsBlocked =>
      'Уведомления Huda выключены. Включите их в настройках и вернитесь сюда.';

  @override
  String get prayerReadyChannelsTitle => 'Оповещения о молитве отключены';

  @override
  String get prayerReadyChannelsMessage =>
      'Уведомления включены, но Android блокирует категорию оповещений о молитве в Huda. Включите её, чтобы получать оповещение о каждой молитве.';

  @override
  String get prayerReadyExactTitle => 'Оповещения точно вовремя';

  @override
  String get prayerReadyExactMessage =>
      'Разрешите Huda ставить будильники, чтобы каждое оповещение приходило точно вовремя, а не с опозданием на несколько минут.';

  @override
  String get prayerReadyAllow => 'Разрешить';

  @override
  String get prayerReadyAlarmTitle => 'Разрешить будильники молитв';

  @override
  String get prayerReadyAlarmMessage =>
      'Будильник молитвы воспроизводит азан как будильник, даже в беззвучном режиме. Для этого iPhone нужно ваше разрешение.';

  @override
  String get prayerReadyBannersTitle => 'Показывать уведомления Huda';

  @override
  String get prayerReadyBannersMessage =>
      'Уведомления разрешены, но macOS настроена не показывать их. Выберите для Huda «Баннеры» или «Напоминания» в настройках уведомлений.';

  @override
  String get prayerReadyLoginTitle => 'Запускать Huda при входе';

  @override
  String get prayerReadyLoginMessage =>
      'Азан воспроизводится из Huda в строке меню. Разрешите запуск при входе, чтобы всё работало и после перезагрузки.';

  @override
  String get prayerReadyWindowsStartupTitle =>
      'Запускать Huda вместе с Windows';

  @override
  String get prayerReadyWindowsStartupMessage =>
      'Фоновый помощник Huda воспроизводит азан и поддерживает напоминания. Разрешите ему запускаться вместе с Windows, чтобы всё работало после перезагрузки.';

  @override
  String get prayerReadyLinuxStartupTitle => 'Запускать Huda при входе';

  @override
  String get prayerReadyLinuxStartupMessage =>
      'Фоновая служба Huda доставляет оповещения о молитве и напоминания. Разрешите ей запускаться при входе, чтобы всё работало после перезагрузки.';

  @override
  String get prayerReadyTurnOn => 'Включить';

  @override
  String get travelExplainerTitle => 'Обновлять время в поездках';

  @override
  String get travelExplainerMessage =>
      'Когда вы приезжаете в новый город, Huda сама обновляет время молитв и оповещения. Чтобы замечать переезд при закрытом приложении, устройство попросит доступ к геопозиции всегда.';

  @override
  String get prayerAlertTitle => 'Азан и оповещения';

  @override
  String get prayerAlertMasterTitle => 'Оповещения о молитве';

  @override
  String get prayerAlertMasterOff => 'Без оповещений во время молитв';

  @override
  String prayerAlertPrayersOn(int count) {
    return '$count из 5 молитв';
  }

  @override
  String get prayerAlertSaving => 'Сохранение…';

  @override
  String get prayerAlertSaved => 'Сохранено';

  @override
  String get prayerAlertNotSaved => 'Не сохранено';

  @override
  String get prayerAlertRetrying => 'Повторная попытка…';

  @override
  String get prayerAlertUndo => 'Отменить';

  @override
  String get prayerAlertFailureCompanion =>
      'Помощник Huda для Windows не запущен, поэтому азан нельзя настроить. Запустите помощник на панели задач и повторите попытку.';

  @override
  String get prayerAlertFailureService =>
      'Фоновая служба Huda не отвечает. Повторите попытку чуть позже.';

  @override
  String get prayerAlertFailureSchedule =>
      'Не удалось запланировать новые настройки. Прежние оповещения сохранены.';

  @override
  String get prayerAlertFailureUnknown => 'Не удалось сохранить изменения.';

  @override
  String get prayerAlertStartupWarning =>
      'Сохранено, но macOS не разрешила запуск Huda при входе. Проверьте объекты входа в Системных настройках.';

  @override
  String get prayerAlertSectionStyle => 'Как сообщать о молитве';

  @override
  String get prayerAlertSectionSound => 'Звук';

  @override
  String get prayerAlertSectionPrayers => 'Каждая молитва';

  @override
  String get prayerAlertSectionBefore => 'Перед молитвой';

  @override
  String get prayerAlertSectionTest => 'Проверить';

  @override
  String get prayerAlertSectionFocus => 'Фокус';

  @override
  String get prayerAlertSectionMore => 'Другие параметры';

  @override
  String get prayerAlertStyleOff => 'Выкл.';

  @override
  String get prayerAlertStyleOffHint => 'Без оповещения об этой молитве';

  @override
  String get prayerAlertStyleSilent => 'Уведомление';

  @override
  String get prayerAlertStyleSilentHint => 'Уведомление без азана';

  @override
  String get prayerAlertStyleShort => 'Короткий азан';

  @override
  String get prayerAlertStyleShortHint => 'Уведомление с началом азана';

  @override
  String get prayerAlertStyleFull => 'Полный азан';

  @override
  String get prayerAlertStyleFullHint =>
      'Звучит азан; его можно остановить в любой момент';

  @override
  String get prayerAlertStyleAlarm => 'Будильник молитвы';

  @override
  String get prayerAlertStyleAlarmHint =>
      'Звонит как будильник, даже в беззвучном режиме';

  @override
  String get prayerAlertStyleFocus => 'Фокус';

  @override
  String get prayerAlertStyleFocusHint =>
      'Спокойная полноэкранная пауза для молитвы';

  @override
  String get prayerAlertRecording => 'Запись';

  @override
  String get prayerAlertVolume => 'Громкость';

  @override
  String get prayerAlertLength => 'Длительность';

  @override
  String get prayerAlertLengthWhole => 'Весь азан';

  @override
  String prayerAlertLengthSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String prayerAlertLengthMinutes(String minutes) {
    return '$minutes мин';
  }

  @override
  String get prayerAlertFadeIn => 'Плавное нарастание';

  @override
  String get prayerAlertNone => 'Нет';

  @override
  String get prayerAlertSoundTitle => 'Выберите запись';

  @override
  String prayerAlertSoundDownloaded(String size) {
    return 'Загружено: $size';
  }

  @override
  String get prayerAlertSoundBuiltIn => 'Встроенная';

  @override
  String get prayerAlertSoundReady => 'Доступно офлайн';

  @override
  String prayerAlertSoundSize(String size) {
    return '$size для загрузки';
  }

  @override
  String get prayerAlertSoundDownload => 'Загрузить';

  @override
  String prayerAlertSoundDownloading(int percent) {
    return 'Загрузка $percent%';
  }

  @override
  String get prayerAlertSoundCancel => 'Отменить загрузку';

  @override
  String get prayerAlertSoundRemove => 'Удалить загрузку';

  @override
  String prayerAlertSoundInUse(String prayers) {
    return 'Используется для: $prayers. Сначала выберите для них другую запись.';
  }

  @override
  String get prayerAlertSoundOutdated =>
      'Показан сохранённый список. Не удалось проверить новые записи.';

  @override
  String get prayerAlertSoundListFailed => 'Не удалось загрузить записи.';

  @override
  String get prayerAlertSoundPlay => 'Прослушать отрывок';

  @override
  String get prayerAlertSoundStop => 'Остановить';

  @override
  String get prayerAlertSoundSelectAfter => 'Будет использована после загрузки';

  @override
  String get prayerAlertDownloadNetwork =>
      'Нет подключения к интернету. Повторите попытку, когда будете онлайн.';

  @override
  String get prayerAlertDownloadServer =>
      'Сервер загрузки сейчас недоступен. Повторите попытку позже.';

  @override
  String get prayerAlertDownloadIntegrity =>
      'Загрузка повреждена. Повторите попытку.';

  @override
  String get prayerAlertDownloadStorage =>
      'Недостаточно места. Освободите место и повторите попытку.';

  @override
  String get prayerAlertSameAsAll => 'Как для всех молитв';

  @override
  String get prayerAlertCustom => 'Своё';

  @override
  String prayerAlertReset(String prayer) {
    return 'Сбросить $prayer к общим настройкам';
  }

  @override
  String prayerAlertMoreFor(String prayer) {
    return 'Ещё для $prayer';
  }

  @override
  String get prayerAlertDefault => 'По умолчанию';

  @override
  String get prayerAlertDefaultAdhan => 'Азан по умолчанию';

  @override
  String get prayerAlertOn => 'Вкл.';

  @override
  String prayerAlertBeforeMinutes(String minutes) {
    return 'За $minutes мин';
  }

  @override
  String get prayerAlertBeforeHint => 'Мягкое напоминание, чтобы подготовиться';

  @override
  String get prayerAlertBeforeSound => 'Звук напоминания';

  @override
  String get prayerAlertBeforeSilent => 'Без звука';

  @override
  String get prayerAlertBeforeShort => 'Короткий звук';

  @override
  String get prayerAlertFallback => 'Если будильник недоступен';

  @override
  String get prayerAlertTestHint =>
      'Придёт примерно через 10 секунд с настройками этой молитвы. Можно выйти из Huda.';

  @override
  String get prayerAlertTestHintDesktop =>
      'Придёт примерно через 10 секунд с настройками этой молитвы. Не закрывайте Huda до этого.';

  @override
  String get prayerAlertTestSend => 'Отправить';

  @override
  String prayerAlertTestWaiting(String seconds) {
    return 'Придёт через $seconds с';
  }

  @override
  String get prayerAlertTestScheduled =>
      'Тест отправлен. Он должен прийти через несколько секунд.';

  @override
  String get prayerAlertTestShown => 'Тест показан. Вы его увидели и услышали?';

  @override
  String get prayerAlertTestNotificationsOff =>
      'Уведомления Huda выключены, поэтому тест не придёт.';

  @override
  String get prayerAlertTestExactOff =>
      'Huda не может ставить точные будильники, оповещения могут опаздывать. Сначала разрешите их.';

  @override
  String get prayerAlertTestPrayerOff =>
      'Оповещения об этой молитве выключены.';

  @override
  String get prayerAlertTestAlarmPermission =>
      'Сначала разрешите будильники молитв, затем повторите попытку.';

  @override
  String get prayerAlertTestServiceOff =>
      'Фоновый помощник Huda не запущен, поэтому тест не воспроизвести.';

  @override
  String get prayerAlertTestAudioMissing =>
      'Выбранная запись не воспроизвелась, поэтому использован встроенный азан.';

  @override
  String get prayerAlertTestFailed =>
      'Не удалось отправить тест. Повторите попытку.';

  @override
  String get prayerAlertFocusDuration => 'Длится';

  @override
  String get prayerAlertFocusAudio => 'Воспроизводить азан во время фокуса';

  @override
  String get prayerAlertFocusCommitment => 'Нельзя закрыть раньше';

  @override
  String get prayerAlertFocusCommitmentHint =>
      'Фокус завершится по истечении времени. В экстренном случае его закроет Esc.';

  @override
  String get prayerAlertFocusFullScreen => 'На весь экран';

  @override
  String get prayerAlertSummaryOff => 'Оповещения о молитве выключены';

  @override
  String get prayerAlertSummaryMixed => 'Для некоторых молитв по-другому';

  @override
  String get prayerAlertStopAdhan => 'Остановить азан';

  @override
  String get prayerAlertEndFocus => 'Завершить фокус';

  @override
  String get prayerAlertOnThisDevice => 'На этом устройстве';

  @override
  String get prayerAlertBack => 'Назад';

  @override
  String get prayerAlertClose => 'Закрыть';

  @override
  String get prayerAlertNeedsCompanion => 'Нужно, чтобы Huda работала в фоне';

  @override
  String get prayerAlertToggleAlarmScreen => 'Экран будильника';

  @override
  String get prayerAlertToggleAlarmScreenHint =>
      'Показывает полноэкранный будильник при начале азана';

  @override
  String get prayerAlertToggleFlip => 'Перевернуть, чтобы остановить';

  @override
  String get prayerAlertToggleFlipHint =>
      'Положите телефон экраном вниз, чтобы остановить азан';

  @override
  String get prayerAlertToggleVibrate => 'Вибрация';

  @override
  String get prayerAlertToggleRinger => 'Учитывать беззвучный режим';

  @override
  String get prayerAlertToggleRingerHint =>
      'Без звука азана, когда телефон в беззвучном режиме или на вибрации';

  @override
  String get prayerAlertToggleHeadset =>
      'Останавливать при отключении наушников';

  @override
  String get prayerAlertToggleMissed =>
      'Показывать молитвы, пропущенные при выключенном телефоне';

  @override
  String get prayerAlertToggleTimeSensitive => 'Срочные';

  @override
  String get prayerAlertToggleTimeSensitiveHint =>
      'Оповещения о молитве приходят даже в режимах фокусирования и «Не беспокоить»';

  @override
  String get prayerAlertToggleLockedAudio =>
      'Воспроизводить при заблокированном экране';

  @override
  String get prayerAlertToggleQuiet => 'Приостановить азан и фокус';

  @override
  String get prayerAlertToggleQuietHint =>
      'Уведомления по-прежнему приходят, но без звука';

  @override
  String get prayerAlertToggleBackground => 'Оставлять Huda работать в фоне';

  @override
  String get prayerAlertToggleBackgroundHint =>
      'Нужно для азана и фокуса после закрытия окна Huda';

  @override
  String get prayerAlertToggleStartAtLogin => 'Запуск при входе';

  @override
  String get prayerAlertStyleAdhan => 'Азан';

  @override
  String get prayerAlertStyleAdhanHint =>
      'Звучит азан; длительность выбирается в разделе «Звук»';

  @override
  String get prayerAlertLengthOpening => 'Только начало';

  @override
  String get prayerAlertStyleNotificationAdhan => 'Азан в уведомлении';

  @override
  String get prayerAlertStyleNotificationAdhanHint =>
      'До 30 секунд вместе с уведомлением; работает, даже когда Huda закрыта';

  @override
  String get prayerCountdownTitle => 'Обратный отсчёт до намаза';

  @override
  String get prayerCountdownDescription =>
      'Тихое уведомление с отсчётом до следующего намаза. Работает и после перезагрузки, не открывая Huda.';

  @override
  String get prayerCountdownShowing => 'Отображается в уведомлениях';

  @override
  String get prayerCountdownNotShowing => 'Включено, но сейчас не отображается';

  @override
  String get prayerCountdownOff => 'Выключено';

  @override
  String get prayerCountdownStyle => 'Вид';

  @override
  String get prayerCountdownStyleProgress => 'Шкала';

  @override
  String get prayerCountdownStyleTimetable => 'Расписание';

  @override
  String get prayerCountdownStyleMinimal => 'Кратко';

  @override
  String get prayerCountdownLockScreen => 'Показывать на экране блокировки';

  @override
  String get prayerCountdownShowSunrise => 'Показывать восход';

  @override
  String get prayerCountdownLiveUpdate =>
      'Показывать отсчёт в строке состояния';

  @override
  String get prayerCountdownNotificationsOff =>
      'Уведомления для Huda выключены.';

  @override
  String get prayerCountdownChannelOff =>
      'Категория уведомлений «Обратный отсчёт до намаза» выключена.';

  @override
  String get prayerCountdownLiveUpdateOff => 'Live Updates для Huda выключены.';

  @override
  String get prayerCountdownNeedsLocation =>
      'Укажите местоположение, чтобы показать отсчёт.';

  @override
  String get prayerCountdownSaveFailed =>
      'Не удалось сохранить настройку отсчёта.';

  @override
  String get active => 'Активно';

  @override
  String get prayerCountdownLiveUpdateHint =>
      'Live Update в Android. Таймер переходит в верхнюю часть уведомления вместо текста.';

  @override
  String get prayerAlertFlipTry => 'Проверить';

  @override
  String get prayerAlertFlipHold => 'Держите телефон как обычно…';

  @override
  String get prayerAlertFlipNow => 'Теперь переверните его экраном вниз';

  @override
  String get prayerAlertFlipDetected =>
      'Переворот распознан. Азан остановился бы.';

  @override
  String get prayerAlertFlipMissed =>
      'Переворот не замечен. Попробуйте ещё раз.';

  @override
  String get prayerAlertFlipUnavailable =>
      'Этот телефон не может распознать переворот.';

  @override
  String get prayerAlertStyleMacFullHint =>
      'Huda воспроизводит весь азан; приложение остаётся в строке меню и запускается при входе';

  @override
  String get prayerAlertStyleMacFocusHint =>
      'Спокойная полноэкранная пауза для молитвы; Huda остаётся в строке меню и запускается при входе';

  @override
  String macPrayerMenuNameElapsed(String prayer, String time) {
    return '$prayer $time';
  }

  @override
  String get prayerIqamahTitle => 'Время икамата';

  @override
  String get prayerIqamahExplanation =>
      'После азана счётчик показывает время, прошедшее с начала молитвы, в течение этого периода.';

  @override
  String prayerIqamahMinutes(String minutes) {
    return '+$minutes мин';
  }

  @override
  String get prayerIqamahReset => 'Восстановить значения по умолчанию';

  @override
  String get prayerIqamahOff => 'Выкл.';

  @override
  String get prayerIqamahSaveError =>
      'Не удалось сохранить или синхронизировать настройки икамата. Попробуйте ещё раз.';

  @override
  String get notificationAthkarMeaning01 => 'Пречист Аллах, и хвала Ему';

  @override
  String get notificationAthkarMeaning02 =>
      'Нет силы и могущества ни у кого, кроме Аллаха';

  @override
  String get notificationAthkarMeaning03 => 'Прошу прощения у Аллаха Великого';

  @override
  String get notificationAthkarMeaning04 => 'Хвала Аллаху, Господу миров';

  @override
  String get notificationAthkarMeaning05 =>
      'Нет божества, кроме одного Аллаха, у Которого нет сотоварища';

  @override
  String get notificationAthkarMeaning06 => 'Пречист Аллах Великий';

  @override
  String get notificationAthkarMeaning07 =>
      'О Аллах, благослови Мухаммада и семью Мухаммада';

  @override
  String get notificationAthkarMeaning08 =>
      'Господь наш, даруй нам добро в этом мире и в Последней жизни и защити нас от мучений Огня';

  @override
  String get notificationAthkarMeaning09 => 'Пречист Аллах';

  @override
  String get notificationAthkarMeaning10 => 'Хвала Аллаху';

  @override
  String get notificationAthkarMeaning11 => 'Нет божества, кроме Аллаха';

  @override
  String get notificationAthkarMeaning12 => 'Аллах превыше всего';

  @override
  String get notificationAthkarMeaning13 =>
      'Пречист Аллах, хвала Аллаху, нет божества, кроме Аллаха, и Аллах превыше всего';

  @override
  String get notificationAthkarMeaning14 =>
      'Пречист Аллах, и хвала Ему; пречист Аллах Великий';

  @override
  String get notificationAthkarMeaning15 =>
      'Господи, прости меня и прими моё покаяние. Поистине, Ты — Принимающий покаяние, Милосердный';

  @override
  String get notificationAthkarMeaning16 => 'Господи, приумножь мои знания';

  @override
  String get notificationAthkarMeaning17 =>
      'Нет божества, кроме Тебя. Пречист Ты. Поистине, я был одним из несправедливых';

  @override
  String get notificationAthkarMeaning18 =>
      'Господи, я нуждаюсь в любом благе, которое Ты ниспошлёшь мне';

  @override
  String get notificationAthkarMeaning19 =>
      'О Аллах, прошу Тебя о верном пути, богобоязненности, целомудрии и довольстве';

  @override
  String get notificationAthkarMeaning20 =>
      'О Аллах, Ты — Прощающий и любишь прощать, так прости меня';

  @override
  String get sahurNotificationOnlyDescription =>
      'В iOS до версии 26 уведомление о сухуре звучит один раз около 30 секунд и не повторяется.';

  @override
  String get stateRetrying => 'Повторная попытка…';

  @override
  String get stateUpdating => 'Обновление…';

  @override
  String get stateOfflineSaved =>
      'Показано то, что сохранено на этом устройстве.';

  @override
  String get athkarSource => 'Хисн аль-Муслим';

  @override
  String get athkarDaily => 'Каждый день';

  @override
  String get athkarOccasions => 'На любой случай';

  @override
  String athkarProgress(int done, int total) {
    return 'Выполнено $done из $total';
  }

  @override
  String athkarRepeatTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раза',
      many: '$count раз',
      few: '$count раза',
      one: '$count раз',
    );
    return '$_temp0';
  }

  @override
  String athkarLeft(int count) {
    return 'Осталось $count';
  }

  @override
  String get athkarTapToCount => 'Нажмите, чтобы считать';

  @override
  String get athkarAllDone => 'Всё выполнено';

  @override
  String get athkarAllDoneMessage => 'Да примет Аллах это от тебя.';

  @override
  String get athkarStartAgain => 'Начать заново';

  @override
  String get athkarCountReset => 'Счёт сброшен';

  @override
  String get athkarLoadError => 'Не удалось загрузить азкары.';

  @override
  String get athkarAudioError => 'Не удалось воспроизвести запись.';

  @override
  String get athkarClearSearch => 'Очистить поиск';

  @override
  String get athkarListen => 'Слушать';

  @override
  String get shareSaveImage => 'Сохранить изображение';

  @override
  String get shareImageSaved => 'Сохранено в фото';

  @override
  String get shareSaveUnavailable =>
      'Сохранение изображений пока недоступно на этом устройстве.';

  @override
  String get shareImageSavedDownloads => 'Сохранено в «Загрузки»';

  @override
  String get shareSaveFailed =>
      'Не удалось сохранить изображение. Попробуйте ещё раз.';

  @override
  String get shareIncludeTranslation => 'Добавить перевод';

  @override
  String get hadithSixBooks => 'Шесть книг';

  @override
  String get hadithMoreCollections => 'Другие сборники';

  @override
  String hadithCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString хадиса',
      many: '$countString хадисов',
      few: '$countString хадиса',
      one: '$countString хадис',
    );
    return '$_temp0';
  }

  @override
  String hadithBookCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString книги',
      many: '$countString книг',
      few: '$countString книги',
      one: '$countString книга',
    );
    return '$_temp0';
  }

  @override
  String hadithRange(String start, String end) {
    return 'Хадисы $start–$end';
  }

  @override
  String hadithNumber(String number) {
    return 'Хадис $number';
  }

  @override
  String get hadithSearchBooks => 'Поиск книг';

  @override
  String get hadithChooseBook => 'Выберите книгу, чтобы начать чтение';

  @override
  String hadithPageOf(int page, int total) {
    return 'Страница $page из $total';
  }

  @override
  String get hadithLoadError => 'Не удалось загрузить хадисы.';

  @override
  String get hadithShare => 'Поделиться хадисом';

  @override
  String hadithBookNumber(String number) {
    return 'Книга $number';
  }

  @override
  String get hadithBookEmpty => 'В этой книге пока нет хадисов.';

  @override
  String get hadithBooksLoadError =>
      'Не удалось загрузить книги этого сборника.';

  @override
  String get hadithAbout => 'Об этом сборнике';

  @override
  String get zakatDueLabel => 'Закят к уплате';

  @override
  String get zakatNisab => 'Нисаб';

  @override
  String zakatRateOf(String amount) {
    return '2.5 % от $amount';
  }

  @override
  String zakatAboveNisab(String amount) {
    return 'На $amount выше нисаба';
  }

  @override
  String zakatBelowNisab(String amount) {
    return 'На $amount ниже нисаба';
  }

  @override
  String get zakatEmptyTitle => 'Укажите, чем вы владеете';

  @override
  String get zakatEmptyMessage =>
      'Добавьте сбережения, золото и другое имущество, чтобы узнать, достигают ли они нисаба.';

  @override
  String get zakatClearAmounts => 'Очистить суммы';

  @override
  String get zakatAmountsCleared => 'Суммы очищены';

  @override
  String get zakatShowResult => 'Показать результат';

  @override
  String zakatNisabIs(String weight) {
    return 'Нисаб — $weight';
  }

  @override
  String get zakatCalcError => 'Не удалось выполнить расчёт.';

  @override
  String zakatPriceMarket(String date) {
    return 'Рыночная цена · $date';
  }

  @override
  String get zakatPriceYours => 'Ваша цена';

  @override
  String get zakatPriceUpdating => 'Обновляем цены на золото и серебро…';

  @override
  String zakatPriceFailed(String date) {
    return 'Не удалось обновить цены на золото и серебро. Используются цены на $date.';
  }

  @override
  String get zakatUseMarketPrice => 'Использовать рыночную цену';

  @override
  String zakatLocalPriceNote(String currency) {
    return 'Цены на золото в $currency могут отличаться от мировых. Уточните местную цену и при необходимости введите её.';
  }

  @override
  String zakatPerGram(String price) {
    return '$price за грамм';
  }

  @override
  String get zakatCurrencySearch => 'Поиск валюты';

  @override
  String get zakatCurrencySuggested => 'Рекомендуемые';

  @override
  String get zakatCurrencyAll => 'Все валюты';

  @override
  String zakatCurrencyNoMatch(String query) {
    return 'Нет валют по запросу «$query»';
  }

  @override
  String zakatTypedPricesReplaced(String currency) {
    return 'Ваши цены заменены рыночными в $currency.';
  }

  @override
  String get setupWelcomeTitle => 'Добро пожаловать в Huda';

  @override
  String get setupWelcomeMessage =>
      'Давайте настроим Huda для вас. Это займёт около минуты.';

  @override
  String get setupLookTitle => 'Выберите оформление';

  @override
  String get setupLookMessage =>
      'Светлое или тёмное, и цвет. Оба можно изменить позже в настройках.';

  @override
  String get setupThemeLight => 'Светлая';

  @override
  String get setupThemeDark => 'Тёмная';

  @override
  String get setupThemeSystem => 'Как на устройстве';

  @override
  String get setupFocusTitle =>
      'Для чего вы чаще всего будете пользоваться Huda?';

  @override
  String get setupFocusMessage =>
      'Главный экран покажет это первым. Изменить можно в любой момент на главном экране.';

  @override
  String get setupFocusPrayer => 'Молитва';

  @override
  String get setupFocusQuran => 'Коран';

  @override
  String get setupFocusEverything => 'Всё понемногу';

  @override
  String get setupLocating => 'Определяем местоположение…';

  @override
  String setupNextPrayer(String prayer, String time) {
    return 'Далее: $prayer в $time';
  }

  @override
  String get setupAsrMessage =>
      'Мазхабы по-разному определяют начало Асра. Выберите тот, которому следуете.';

  @override
  String get setupAsrStandard => 'Стандартный';

  @override
  String get setupAsrStandardSchools =>
      'Шафиитский, маликитский и ханбалитский';

  @override
  String get setupAsrHanafiNote => 'Аср начинается позже';

  @override
  String get setupSuggested => 'Рекомендуем';

  @override
  String get setupAlertsOff => 'Оповещения выключены';

  @override
  String get setupReliableTitle => 'Надёжные оповещения';

  @override
  String setupReliableCount(int current, int total) {
    return '$current из $total';
  }

  @override
  String get setupMushafTitle => 'Как вы читаете Коран?';

  @override
  String get setupMushafMessage =>
      'Выберите вид. Его можно сменить в любой момент в настройках чтения.';

  @override
  String get setupScrollListHint => 'Аят за аятом, с переводом';

  @override
  String setupMushafSize(String size) {
    return 'Загрузка $size';
  }

  @override
  String get setupMushafReady => 'На устройстве';

  @override
  String get setupDownloadNow => 'Скачать сейчас';

  @override
  String setupDownloadWifi(String size) {
    return 'Скачивается в фоне ($size).';
  }

  @override
  String get setupDownloadCellular =>
      'Вы в мобильной сети, поэтому загрузка начнётся, когда вы откроете Коран.';

  @override
  String get setupRemindersTitle => 'Ежедневные напоминания';

  @override
  String get setupRemindersMessage =>
      'Мягкие напоминания в привычное время. Каждое выключено, пока вы его не включите.';

  @override
  String get setupReminderFailed =>
      'Не удалось включить это напоминание. Попробуйте снова в разделе «Напоминания».';

  @override
  String setupRemindersOn(int count) {
    return 'Включено: $count из 3';
  }

  @override
  String get setupSummaryTitle => 'Всё готово';

  @override
  String get setupSummaryMessage => 'Нажмите на шаг, чтобы изменить его.';

  @override
  String get setupSkippedLater => 'Пропущено · можно настроить позже';

  @override
  String get setupStart => 'Начать пользоваться Huda';

  @override
  String get setupLocationFailedTitle => 'Не удалось определить местоположение';

  @override
  String get setupPermissionsTitle => 'Что нужно Huda';

  @override
  String get setupPermissionsLabel => 'Разрешения';

  @override
  String get setupPermissionsMessage =>
      'Два разрешения позволяют Huda работать для вас. Их можно изменить в любое время в настройках устройства.';

  @override
  String get setupPermissionLocationWhy =>
      'Чтобы рассчитать время намаза и направление киблы там, где вы находитесь.';

  @override
  String get setupPermissionNotificationsWhy =>
      'Чтобы звучал азан в каждое время намаза и приходили выбранные вами напоминания.';

  @override
  String get setupAllowNotifications => 'Разрешить уведомления';

  @override
  String get setupPermissionAllowed => 'Разрешено';

  @override
  String get setupPermissionNotAllowed => 'Не разрешено';

  @override
  String get setupPermissionNotAsked => 'Ещё не запрошено';

  @override
  String get setupPermissionAsking => 'Запрашиваем…';

  @override
  String get setupTimesTitle => 'Ваше время намаза';

  @override
  String get setupTimesToday =>
      'Время намаза на сегодня, рассчитанное для вашего местоположения.';

  @override
  String get setupAdhanTitle => 'Призыв к молитве';

  @override
  String get setupAdhanMessage =>
      'В каждое время намаза Huda воспроизводит азан, даже когда приложение закрыто.';

  @override
  String get setupAsrShadowOnce => 'Когда тень равна высоте предмета';

  @override
  String get setupAsrShadowTwice => 'Когда тень вдвое длиннее предмета';

  @override
  String get setupNow => 'сейчас';

  @override
  String get setupSkipStep => 'Пропустить шаг';

  @override
  String get setupSkipAll => 'Пропустить всё';

  @override
  String get setupCalcTitle => 'Как рассчитывать время намаза?';

  @override
  String get setupCalcLabel => 'Расчёт';

  @override
  String get setupCalcMessage =>
      'Автоматически используется метод вашей страны. Выбирайте другой, только если ему следует ваша мечеть.';

  @override
  String get setupMethodOther => 'Или выберите метод';

  @override
  String get setupAlertStyleLabel => 'Как оповещать о каждом намазе';

  @override
  String get setupAdhanVoiceLater =>
      'Голос азана и другое можно выбрать позже в настройках намаза.';

  @override
  String get setupAlertSaveFailed => 'Не удалось сохранить выбор.';

  @override
  String get setupSkipAllTitle => 'Пропустить оставшуюся настройку?';

  @override
  String get setupSkipAllMessage =>
      'Huda откроется сейчас. О пропущенном спросим позже, там, где это нужно.';

  @override
  String get setupKeepSettingUp => 'Продолжить настройку';

  @override
  String setupMethodUses(String method) {
    return 'Используется: $method';
  }

  @override
  String get setupMethodSearch => 'Поиск метода';

  @override
  String get quranSearchHint => 'Поиск сур или аятов';

  @override
  String get quranLoadError => 'Не удалось открыть список сур.';

  @override
  String get quranAyatSection => 'Аяты';

  @override
  String get quranDisplay => 'Отображение';

  @override
  String get quranMore => 'Ещё';

  @override
  String get quranSimilarTab => 'Похожие';

  @override
  String get quranSurahLoadError => 'Не удалось открыть эту суру.';

  @override
  String get quranBookmarkDeleted => 'Закладка удалена';

  @override
  String get quranWirdDone => 'Я завершил(а) сегодняшний вирд';

  @override
  String get quranOfflineLoading => 'Загрузка сохранённого на устройстве…';

  @override
  String get quranWirdStartsHere => 'Сегодняшний вирд начинается здесь';

  @override
  String get quranWirdEndsHere => 'Сегодняшний вирд заканчивается здесь';

  @override
  String get quranRecitersError => 'Не удалось загрузить чтецов.';

  @override
  String get quranZoomHint =>
      'Страницы заполняют ширину и прокручиваются; две страницы прокручиваются вместе.';

  @override
  String get quranPages => 'Страницы';

  @override
  String get quranZoomFillsAlready =>
      'Одна страница уже заполняет ширину этого экрана; увеличение полезно на более широких экранах.';

  @override
  String get quranTwoPagesSideways =>
      'Две страницы открываются, когда экран повёрнут горизонтально.';

  @override
  String get khatmaChoosePace => 'Выберите темп';

  @override
  String get khatmaStartFromDay => 'Начать с другого дня';

  @override
  String khatmaPaceUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'дня',
      many: 'дней',
      few: 'дня',
      one: 'день',
    );
    return '$_temp0';
  }

  @override
  String khatmaPagesADay(int pages) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages страницы в день',
      many: '$pages страниц в день',
      few: '$pages страницы в день',
      one: '$pages страница в день',
    );
    return '$_temp0';
  }

  @override
  String get khatmaReminderTime => 'Время напоминания';

  @override
  String khatmaFinishOn(String date) {
    return 'Завершение: $date';
  }

  @override
  String khatmaStatJuz(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'джуза',
      many: 'джузов',
      few: 'джуза',
      one: 'джуз',
    );
    return '$_temp0';
  }

  @override
  String khatmaStatPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'страницы',
      many: 'страниц',
      few: 'страницы',
      one: 'страница',
    );
    return '$_temp0';
  }

  @override
  String quranAudioSurahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count суры',
      many: '$count сур',
      few: '$count суры',
      one: '$count сура',
    );
    return '$_temp0';
  }

  @override
  String quranAudioDownloadedCount(int count) {
    return 'Загружено: $count';
  }

  @override
  String quranAudioDownloadingCount(int done, int total) {
    return 'Загрузка $done из $total';
  }

  @override
  String get quranAudioPlayFromStart => 'Воспроизвести с начала';

  @override
  String get quranAudioOfflineNote =>
      'Нет подключения. Показаны загруженные чтения.';

  @override
  String get quranAudioLoadFailed => 'Не удалось загрузить чтецов';

  @override
  String get quranAudioChooseTitle => 'Выберите чтение';

  @override
  String get quranAudioChooseMessage =>
      'Выберите чтение одного из чтецов, чтобы увидеть его суры и послушать их.';

  @override
  String quranAudioSurahOfTotal(int index, int total) {
    return 'Сура $index из $total';
  }

  @override
  String get quranAudioShuffle => 'Перемешать';

  @override
  String get quranAudioRepeatOff => 'Повтор выключен';

  @override
  String get quranAudioRepeatAll => 'Повторять все';

  @override
  String get quranAudioRepeatOne => 'Повторять эту суру';

  @override
  String get quranAudioBack10 => 'Назад на 10 секунд';

  @override
  String get quranAudioForward10 => 'Вперёд на 10 секунд';

  @override
  String get quranAudioPosition => 'Позиция воспроизведения';

  @override
  String get quranAudioOpenPlayer => 'Открыть плеер';

  @override
  String get quranAudioPreparing => 'Подготовка…';

  @override
  String get quranAudioHidePlayer => 'Скрыть плеер';

  @override
  String get quranAudioAllDownloaded => 'Всё загружено';

  @override
  String get radioLive => 'В эфире';

  @override
  String get radioPaused => 'Пауза';

  @override
  String get radioConnecting => 'Подключение…';

  @override
  String get radioLoadFailed => 'Не удалось загрузить станции';

  @override
  String prayerAlertFor(String prayer) {
    return 'Оповещения для $prayer';
  }

  @override
  String get prayerFixSavingTitle => 'Последние изменения не сохранены';

  @override
  String get prayerFixSavingMessage =>
      'Huda не удалось сохранить настройки намаза на этом устройстве. Нажмите «Повторить», чтобы сохранить их снова.';

  @override
  String get prayerFixCalculationTitle =>
      'Не удалось пересчитать сегодняшнее время';

  @override
  String get prayerFixCalculationMessage =>
      'Показанное время может не учитывать ваше последнее изменение. Нажмите «Повторить», чтобы пересчитать его.';

  @override
  String get prayerFixCheckTitle => 'Время может отличаться на несколько минут';

  @override
  String get prayerFixCheckMessage =>
      'Huda не удалось подтвердить, какие местные правила действуют здесь, например у границы или побережья. Время рассчитано, но может немного отличаться от времени вашей мечети.';

  @override
  String get prayerFixCheckAction => 'Проверить снова';

  @override
  String get prayerFixWidgetTitle => 'Виджет на главном экране не обновлён';

  @override
  String get prayerFixWidgetMessage =>
      'Время здесь верное, но виджет может показывать прежнее. Нажмите «Повторить», чтобы обновить его.';

  @override
  String get prayerRetryingTitle => 'Пробуем снова…';

  @override
  String get prayerAlertsPreviousPlace =>
      'Уже запланированные оповещения могут следовать прежнему месту, пока их не заменят.';

  @override
  String get prayerAlertsRetryingMessage =>
      'Оповещения о намазе планируются заново.';

  @override
  String get prayerAlertsUpdatingTitle => 'Обновляем оповещения…';

  @override
  String get prayerAlertsUpdatingMessage =>
      'Планируем следующие оповещения о намазе. Время уже актуально.';

  @override
  String get prayerAlertsNotScheduledTitle =>
      'Оповещения о намазе не запланированы';

  @override
  String get prayerAlertsLateNote =>
      'Оповещения могут приходить с опозданием на несколько минут. Разрешите точные будильники, чтобы каждое приходило вовремя.';

  @override
  String get prayerAlertsUnsupportedTitle =>
      'Оповещения о намазе здесь недоступны';

  @override
  String get prayerAlertsUnsupportedMessage =>
      'Это устройство не может показывать оповещения о намазе. Всё время намазов по-прежнему на этой странице.';

  @override
  String get prayerAlertsNeedsOnline =>
      'Huda нужно один раз выйти в интернет, чтобы перенести ваши оповещения на это устройство. Подключитесь к интернету и нажмите «Повторить».';

  @override
  String get prayerAlertsNeedsOnlineOffline =>
      'Нет подключения. Huda сам завершит настройку оповещений, когда связь появится.';

  @override
  String get prayerAlertsNoRoom =>
      'Другие напоминания Huda занимают все оповещения, которые разрешает это устройство. Отключите несколько напоминаний и нажмите «Повторить».';

  @override
  String get prayerAlertsLocalFailure =>
      'Устройство не приняло расписание оповещений. Нажмите «Повторить». Если это повторится, перезапустите Huda.';

  @override
  String get prayerWhereTitle => 'Где вы находитесь?';

  @override
  String get prayerWhereMessage =>
      'Время намаза зависит от того, где вы находитесь. Используйте местоположение устройства или выберите свой город.';

  @override
  String get prayerWhereMessageCityOnly =>
      'Время намаза зависит от того, где вы находитесь. Выберите свой город, чтобы увидеть его.';

  @override
  String get prayerChooseCity => 'Выбрать город';

  @override
  String get prayerProblemDenied =>
      'Доступ к местоположению не разрешён. Разрешите его или выберите свой город.';

  @override
  String get prayerProblemBlocked =>
      'Местоположение для Huda отключено. Включите его в настройках или выберите свой город.';

  @override
  String get prayerProblemServicesOff =>
      'Службы геолокации на этом устройстве выключены. Включите их или выберите свой город.';

  @override
  String get prayerProblemNoDeviceLocation =>
      'Это устройство не может передавать своё местоположение. Выберите свой город.';

  @override
  String get prayerProblemNoFix =>
      'Huda не удалось вовремя определить ваше местоположение. Попробуйте снова, например у окна, или выберите свой город.';

  @override
  String get prayerProblemTimeZone =>
      'Huda нашёл место, но не смог определить его часовой пояс. Проверьте подключение к интернету и попробуйте снова или выберите город поблизости.';

  @override
  String get prayerProblemPlaceInvalid =>
      'Это место не удалось использовать. Попробуйте снова или выберите другой город.';

  @override
  String get prayerProblemSaveFailed =>
      'Не удалось сохранить место на этом устройстве. Попробуйте снова.';

  @override
  String get prayerProblemCalculation =>
      'Huda не удалось рассчитать время намаза для этого места. Попробуйте снова или выберите другой город.';

  @override
  String get prayerProblemUnknown =>
      'Что-то помешало Huda использовать это место. Попробуйте снова или выберите свой город.';

  @override
  String get prayerLocationTitle => 'Местоположение';

  @override
  String get prayerLocationAutomatic => 'Автоматически';

  @override
  String get prayerLocationChosen => 'Выбранный город';

  @override
  String get prayerLocationAutomaticHint =>
      'Время следует за местоположением устройства.';

  @override
  String get prayerLocationChosenHint =>
      'Время остаётся для выбранного города, где бы вы ни были.';

  @override
  String get prayerLocationUpdateNow => 'Обновить сейчас';

  @override
  String get prayerLocationUpdating => 'Обновление…';

  @override
  String get prayerLocationChangeCity => 'Сменить город';

  @override
  String get prayerLocationTravel => 'Следовать за мной в поездках';

  @override
  String get prayerLocationTravelHint =>
      'Когда вы приезжаете в новое место, Huda сам обновляет время и оповещения, даже когда закрыт.';

  @override
  String get prayerLocationTravelForegroundOnly =>
      'Huda может следовать за вами, только пока открыт. Разрешите доступ к местоположению всегда, чтобы он делал это и в закрытом виде.';

  @override
  String get prayerLocationTravelNeedsPermission =>
      'Разрешите доступ к местоположению, чтобы Huda мог следовать за вами в поездках.';

  @override
  String prayerLocationRowSemantics(String place) {
    return 'Местоположение: $place. Нажмите, чтобы изменить.';
  }

  @override
  String get prayerProblemPlaceTitle => 'Не удалось использовать это место';

  @override
  String prayerSettingsAdjusted(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Изменено $number времён',
      few: 'Изменено $number времени',
      one: 'Изменено 1 время',
    );
    return '$_temp0';
  }

  @override
  String get qiblahNorthShort => 'С';

  @override
  String get qiblahEastShort => 'В';

  @override
  String get qiblahSouthShort => 'Ю';

  @override
  String get qiblahWestShort => 'З';

  @override
  String qiblahFromNorth(String degrees) {
    return 'Кибла: $degrees от севера';
  }

  @override
  String get qiblahTurnRight => 'Повернитесь направо';

  @override
  String get qiblahTurnLeft => 'Повернитесь налево';

  @override
  String get qiblahFacing => 'Вы смотрите на киблу';

  @override
  String get qiblahFacingHint => 'Держите так: Кааба прямо перед вами.';

  @override
  String get qiblahFinding => 'Определяем киблу…';

  @override
  String get qiblahNoCompassTitle => 'На этом устройстве нет компаса';

  @override
  String qiblahNoCompassMessage(String degrees) {
    return 'Повернитесь на север, затем на $degrees по часовой стрелке. На циферблате север вверху и отмечена Кааба.';
  }

  @override
  String get qiblahAllowTitle => 'Найдите киблу оттуда, где вы находитесь';

  @override
  String get qiblahAllowMessage =>
      'Huda использует ваше местоположение на этом устройстве, чтобы определить направление на Каабу.';

  @override
  String get qiblahAllowLocation => 'Разрешить геолокацию';

  @override
  String get qiblahLocationOffTitle => 'Геолокация выключена';

  @override
  String get qiblahLocationOffMessage =>
      'Включите геолокацию, чтобы Huda определил киблу оттуда, где вы находитесь.';

  @override
  String get qiblahTurnOnLocation => 'Включить геолокацию';

  @override
  String get qiblahBlockedTitle => 'Доступ Huda к геолокации запрещён';

  @override
  String get qiblahBlockedMessage =>
      'Разрешите Huda доступ к геолокации в настройках и вернитесь сюда.';

  @override
  String get qiblahErrorTitle => 'Не удалось определить киблу';

  @override
  String get qiblahErrorMessage =>
      'Huda не удалось получить ваше местоположение. Проверьте, что геолокация включена, и попробуйте снова.';

  @override
  String get qiblahHoldFlat =>
      'Держите телефон горизонтально, пока Huda определяет киблу.';

  @override
  String get qiblahTurnHint =>
      'Поворачивайтесь, пока Кааба не дойдёт до отметки вверху.';

  @override
  String get qiblahInterference =>
      'Рядом магнитные помехи. Отойдите от металла, магнитов и электроники.';

  @override
  String get qiblahTilted => 'Держите телефон горизонтально';

  @override
  String qiblahPlaceDistance(String place, String distance) {
    return '$place · $distance км до Каабы';
  }

  @override
  String qiblahDistance(String distance) {
    return '$distance км до Каабы';
  }

  @override
  String get qiblahUpdatingLocation => 'Обновляем местоположение…';

  @override
  String get qiblahLocationStale =>
      'Не удалось обновить местоположение. Если вы переместились, кибла может быть неточной.';

  @override
  String get qiblahUpdateLocation => 'Обновить местоположение';

  @override
  String get remindersNextReminder => 'Следующее напоминание';

  @override
  String remindersNextToday(String time) {
    return 'Сегодня в $time';
  }

  @override
  String remindersNextTomorrow(String time) {
    return 'Завтра в $time';
  }

  @override
  String remindersNextOnDay(String day, String time) {
    return '$day в $time';
  }

  @override
  String get remindersNoneOnTitle => 'Напоминания не включены';

  @override
  String get remindersNoneOnMessage =>
      'Включите одно ниже, и оно займёт своё место в вашем дне.';

  @override
  String remindersDialLabel(String reminders) {
    return 'Ваши напоминания сегодня: $reminders';
  }

  @override
  String get remindersDialEmptyLabel => 'Сегодня напоминаний нет';

  @override
  String get remindersRoutineSection => 'Распорядок дня';

  @override
  String get remindersDeliverySection => 'Проверить доставку';

  @override
  String get remindersScheduling => 'Планирование…';

  @override
  String remindersChangeTime(String time) {
    return 'Изменить время, $time';
  }

  @override
  String get qiblahAccuracyGood => 'Точность компаса: хорошая';

  @override
  String get qiblahAccuracyFair => 'Точность компаса: средняя';

  @override
  String get qiblahAccuracyPoor => 'Точность компаса: слабая';

  @override
  String get remindersTitle => 'Напоминания';

  @override
  String get eveningAthkar => 'Вечерние Азкар';

  @override
  String remindersInHoursMinutes(String hours, String minutes) {
    return 'через $hours ч $minutes мин';
  }

  @override
  String remindersInHours(String hours) {
    return 'через $hours ч';
  }

  @override
  String remindersInMinutes(String minutes) {
    return 'через $minutes мин';
  }

  @override
  String get remindersSahurAlarmsDenied =>
      'Будильники для Huda отключены. Разрешите их в Настройках, чтобы будильник сухура мог звонить.';

  @override
  String get remindersSahurNotificationsOff =>
      'Уведомления для Huda отключены. Разрешите их в Настройках, чтобы будильник сухура сработал.';

  @override
  String get remindersSahurSoundOff =>
      'Звуки уведомлений для Huda отключены. Включите их в Настройках, чтобы услышать будильник сухура.';

  @override
  String get remindersSahurNeedsPrayerTimes =>
      'Вариант «до Фаджра» требует времени намазов. Укажите местоположение во «Времени намаза» или выберите точное время.';

  @override
  String get remindersUseExactTime => 'Указать точное время';

  @override
  String get calendarChooseTitle => 'Какие даты по хиджре показывать в Huda?';

  @override
  String get calendarChooseMessage =>
      'Huda следует официальному календарю Умм аль-Кура. Если у вас луну видят в другой день, сдвиньте даты на день или два.';

  @override
  String get calendarUseUmmAlQura => 'Умм аль-Кура';

  @override
  String get calendarAdjustDays => 'Сдвинуть дни';

  @override
  String get calendarYourEvents => 'Ваши события';

  @override
  String get calendarEventDeleted => 'Событие удалено';

  @override
  String get calendarEventColor => 'Цвет';

  @override
  String calendarEventsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count события',
      many: '$count событий',
      few: '$count события',
      one: '$count событие',
    );
    return '$_temp0';
  }

  @override
  String get calendarAdjustmentFailed =>
      'Не удалось сохранить изменение. Попробуйте ещё раз.';

  @override
  String get ramadanTodaysFast => 'Сегодняшний пост';

  @override
  String ramadanIftarIn(String when) {
    return 'Ифтар $when';
  }

  @override
  String ramadanImsakIn(String when) {
    return 'Имсак $when';
  }

  @override
  String get ramadanYourFasts => 'Ваши посты';

  @override
  String ramadanYearLabel(String year) {
    return 'Рамадан $year';
  }

  @override
  String ramadanToMakeUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня восполнить',
      many: '$count дней восполнить',
      few: '$count дня восполнить',
      one: '$count день восполнить',
      zero: 'Восполнять нечего',
    );
    return '$_temp0';
  }

  @override
  String get ramadanClearDay => 'Сбросить';

  @override
  String get ramadanNotMarked => 'Не отмечено';

  @override
  String get ramadanNightsIntro =>
      'Отметьте каждый день прошлого Рамадана: постились или пропустили, и дни, которые нужно восполнить, будут подсчитаны за вас.';

  @override
  String get ramadanMarkFasts => 'Отметить посты';

  @override
  String get ramadanShowDays => 'Показать дни';

  @override
  String get ramadanHideDays => 'Скрыть дни';

  @override
  String get ramadanLocationError =>
      'Для времени Рамадана нужно ваше местоположение. Укажите его во «Времени намаза» и попробуйте снова.';

  @override
  String get booksLanguagesError => 'Не удалось загрузить языки.';

  @override
  String booksNoLanguageMatches(String query) {
    return 'Нет языков, похожих на «$query».';
  }

  @override
  String booksPageOf(int page, int total) {
    return 'Страница $page из $total';
  }

  @override
  String get booksLoadError =>
      'Не удалось загрузить библиотеку. Проверьте подключение и попробуйте снова.';

  @override
  String get booksLanguageUnavailable => 'Эта книга недоступна на этом языке.';

  @override
  String get booksDetailError => 'Не удалось загрузить книгу.';

  @override
  String get booksShowOriginal => 'Показать оригинал';

  @override
  String get booksDetailOffline =>
      'Подключитесь к интернету, чтобы открыть эту книгу. Загруженные книги открываются офлайн.';

  @override
  String get booksDownloadFailed => 'Не удалось скачать книгу.';

  @override
  String get booksRemoveDownloadTitle => 'Удалить загрузку?';

  @override
  String get booksRemoveDownloadBody =>
      'Книга останется в библиотеке. Её можно снова скачать, когда будет интернет.';

  @override
  String get booksRemove => 'Удалить';

  @override
  String get booksRemoveDownload => 'Удалить загрузку';

  @override
  String get booksDownloadRemoved => 'Загрузка удалена';

  @override
  String get booksShareFailed => 'Не удалось поделиться книгой.';

  @override
  String get booksRoleAuthor => 'Автор';

  @override
  String get booksRoleTranslator => 'Переводчик';

  @override
  String get booksRoleEditor => 'Редактор';

  @override
  String get booksRolePublisher => 'Издатель';

  @override
  String get booksRoleSource => 'Источник';

  @override
  String get booksRoleOther => 'Подготовил';

  @override
  String booksDownloading(int percent) {
    return 'Загрузка… $percent%';
  }

  @override
  String get booksDownloadedNote => 'Загружено · открывается офлайн';

  @override
  String booksDownloadedOn(String date) {
    return 'Загружено $date';
  }

  @override
  String get booksOtherFormats => 'Другие форматы';

  @override
  String get booksAlsoIn => 'Также на';

  @override
  String get booksHighlights => 'Выделения';

  @override
  String get booksHighlight => 'Выделить';

  @override
  String get booksContentsHint =>
      'В книге нет оглавления. Воспользуйтесь поиском или страницами.';

  @override
  String get booksNoMatches => 'Совпадений нет';

  @override
  String get booksNoHighlights => 'Выделений пока нет';

  @override
  String get booksHighlightsHint =>
      'Выделите текст на странице и выберите цвет.';

  @override
  String get booksHighlightRemoved => 'Выделение удалено';

  @override
  String get booksZoomIn => 'Увеличить';

  @override
  String get booksZoomOut => 'Уменьшить';

  @override
  String get booksOpening => 'Открываем книгу…';

  @override
  String get booksReaderError => 'Не удалось открыть книгу';

  @override
  String get booksReaderErrorMessage =>
      'Проверьте подключение и попробуйте снова.';

  @override
  String get booksReaderPanel => 'Оглавление и поиск';

  @override
  String get booksScrollDown => 'Листать вниз';

  @override
  String get booksScrollAcross => 'Листать вбок';

  @override
  String get booksInkRed => 'Красный';

  @override
  String get booksInkGreen => 'Зелёный';

  @override
  String get booksInkOrange => 'Оранжевый';

  @override
  String audiobooksChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count главы',
      many: '$count глав',
      few: '$count главы',
      one: '$count глава',
    );
    return '$_temp0';
  }

  @override
  String audiobooksShowingDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Показано $count загруженной записи',
      many: 'Показано $count загруженных записей',
      few: 'Показаны $count загруженные записи',
      one: 'Показана $count загруженная запись',
    );
    return '$_temp0';
  }

  @override
  String get audiobooksLoadError =>
      'Не удалось загрузить аудиотеку. Проверьте подключение и попробуйте снова.';

  @override
  String get audiobooksDetailError =>
      'Не удалось загрузить эту запись. Проверьте подключение и попробуйте снова.';

  @override
  String get audiobooksDetailOffline =>
      'Эта запись не загружена. Подключитесь к интернету, чтобы её прослушать.';

  @override
  String get audiobooksDownloadWhenOnline =>
      'Загружайте записи, пока вы в сети, чтобы слушать их здесь.';

  @override
  String get audiobooksRemoveDownloadBody =>
      'Запись останется в библиотеке. Её можно снова загрузить, когда будете в сети.';

  @override
  String get audiobooksDownloadFailed => 'Не удалось загрузить запись.';

  @override
  String audiobooksDownloadingPercent(String percent) {
    return 'Загрузка $percent%';
  }

  @override
  String get audiobooksCancelDownload => 'Отменить загрузку';

  @override
  String get audiobooksBack15 => 'Назад на 15 секунд';

  @override
  String get audiobooksForward15 => 'Вперёд на 15 секунд';

  @override
  String get audiobooksForward30 => 'Вперёд на 30 секунд';

  @override
  String get audiobooksPreviousChapter => 'Предыдущая глава';

  @override
  String get audiobooksNextChapter => 'Следующая глава';

  @override
  String audiobooksSleepPausesIn(String time) {
    return 'Пауза через $time';
  }

  @override
  String get audiobooksSleepEndOfChapter => 'Пауза в конце этой главы';

  @override
  String get audiobooksSleepOff => 'Выключить';

  @override
  String get audiobooksStartFailed =>
      'Не удалось запустить запись. Проверьте подключение и откройте её снова.';

  @override
  String get hudaAiYouAsked => 'Ваш вопрос';

  @override
  String get hudaAiYouShared => 'Вы поделились';

  @override
  String get hudaAiCounselingHint => 'Поделитесь тем, что у вас на сердце…';

  @override
  String get hudaAiShareAnswer => 'Поделиться ответом';

  @override
  String get hudaAiSend => 'Отправить';

  @override
  String get hudaAiWriting => 'Пишет…';

  @override
  String get hudaAiCounselHeading => 'Что у вас на сердце?';

  @override
  String get hudaAiSeekCounsel => 'Попросить совета';

  @override
  String get hudaAiAnotherFeeling => 'Поделиться другим чувством';

  @override
  String checklistDoneOf(int done, int total) {
    return 'Выполнено $done из $total';
  }

  @override
  String get checklistAllDone => 'Всё выполнено';

  @override
  String checklistStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня подряд',
      many: '$count дней подряд',
      few: '$count дня подряд',
      one: '$count день подряд',
    );
    return '$_temp0';
  }

  @override
  String get checklistStreakStart =>
      'Выполните сегодня всё, чтобы начать серию';

  @override
  String get checklistPastNote => 'Прошедшие дни остаются как были';

  @override
  String get checklistFutureNote =>
      'Этот день можно отметить, когда он наступит';

  @override
  String get checklistGroupPrayers => 'Молитвы';

  @override
  String get checklistGroupQuran => 'Коран';

  @override
  String get checklistGroupAthkar => 'Азкары';

  @override
  String get checklistGroupOther => 'Другое';

  @override
  String get checklistPreviousDay => 'Предыдущий день';

  @override
  String get checklistNextDay => 'Следующий день';

  @override
  String checklistRemoved(String title) {
    return '«$title» удалено';
  }

  @override
  String get checklistLoadError => 'Не удалось открыть ваш список';

  @override
  String get checklistEmptyMessage => 'На этот день ничего не запланировано.';

  @override
  String get checklistNewItem => 'Новый пункт';

  @override
  String get checklistItemName => 'Название';

  @override
  String get checklistItemNameHint => 'Например, прочитать суру «Аль-Мульк»';

  @override
  String get checklistItemGroup => 'Раздел';

  @override
  String get checklistItemRepeats => 'Повтор';

  @override
  String get checklistAdd => 'Добавить';

  @override
  String get miqaatGateOff => 'Выключено. Приложения открываются как обычно.';

  @override
  String get miqaatGateNeedsAccess => 'Разрешите доступ ниже, чтобы включить.';

  @override
  String get miqaatGateNoWindows =>
      'Добавьте временной интервал, чтобы начать.';

  @override
  String miqaatGateWaiting(String when) {
    return 'Следующий интервал: $when';
  }

  @override
  String miqaatGateLocked(String remaining) {
    return 'Проведите в Huda ещё $remaining, чтобы открыть приложения.';
  }

  @override
  String get miqaatGateDone =>
      'Цель достигнута. Приложения открыты до следующего интервала.';

  @override
  String get miqaatStatusOff => 'Выключено';

  @override
  String get miqaatStatusWaiting => 'Ожидание';

  @override
  String get miqaatStatusLocked => 'Сейчас заблокировано';

  @override
  String get miqaatStatusOpen => 'Снова открыто';

  @override
  String miqaatMinutesShort(int minutes) {
    return '$minutes мин';
  }

  @override
  String miqaatProgress(int done, int goal) {
    return '$done из $goal мин';
  }

  @override
  String miqaatSlotCount(int count, int max) {
    return '$count из $max';
  }

  @override
  String miqaatRemoved(String name) {
    return '$name удалено';
  }

  @override
  String get miqaatWindowRemoved => 'Интервал удалён';

  @override
  String get miqaatCheckAgain => 'Проверить снова';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsGeneral => 'Общие';

  @override
  String get settingsPrivacy => 'Конфиденциальность';

  @override
  String get settingsTextSizeRelative =>
      'Относительно размера текста на устройстве';

  @override
  String get settingsHapticFeedback => 'Тактильный отклик';

  @override
  String get settingsHapticFeedbackDescription =>
      'Лёгкая вибрация при счёте, переключении и завершении';

  @override
  String get settingsWidgetsSubtitle => 'Аят и время намаза на главном экране';

  @override
  String get widgetPreview => 'Предпросмотр';

  @override
  String get widgetResetDone => 'Виджет сброшен к настройкам по умолчанию';

  @override
  String get widgetResetConfirm =>
      'Вернуть тему, текст и макет этого виджета к настройкам по умолчанию?';

  @override
  String get errorScreenMessage =>
      'Эта часть Huda перестала работать. Обычно помогает перезапуск приложения.';

  @override
  String get errorReportSending => 'Отправка отчёта команде…';

  @override
  String get errorReportSent => 'Отчёт отправлен команде.';

  @override
  String get errorReportFailed => 'Не удалось отправить отчёт.';

  @override
  String get errorTechnicalDetails => 'Технические подробности';

  @override
  String get errorFeedbackFailed =>
      'Не удалось отправить ваше сообщение. Попробуйте ещё раз.';

  @override
  String get bootFailedTitle => 'Не удалось запустить Huda';

  @override
  String get bootFailedMessage =>
      'Что-то пошло не так во время подготовки. Попробуйте ещё раз или перезапустите приложение.';

  @override
  String get windowsPrayerShowTray => 'Показывать значок в трее';
}
