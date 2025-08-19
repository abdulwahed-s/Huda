class HadithDetailsModel {
  int? status;
  String? message;
  Hadiths? hadiths;

  HadithDetailsModel({this.status, this.message, this.hadiths});

  HadithDetailsModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    hadiths =
        json['hadiths'] != null ? Hadiths.fromJson(json['hadiths']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (hadiths != null) {
      data['hadiths'] = hadiths!.toJson();
    }
    return data;
  }
}

class Hadiths {
  int? currentPage;
  List<Data>? data;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  String? lastPageUrl;
  List<Links>? links;
  String? nextPageUrl;
  String? path;
  int? perPage;
  String? prevPageUrl;
  int? to;
  int? total;

  Hadiths(
      {this.currentPage,
      this.data,
      this.firstPageUrl,
      this.from,
      this.lastPage,
      this.lastPageUrl,
      this.links,
      this.nextPageUrl,
      this.path,
      this.perPage,
      this.prevPageUrl,
      this.to,
      this.total});

  Hadiths.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    firstPageUrl = json['first_page_url'];
    from = json['from'];
    lastPage = json['last_page'];
    lastPageUrl = json['last_page_url'];
    if (json['links'] != null) {
      links = <Links>[];
      json['links'].forEach((v) {
        links!.add(Links.fromJson(v));
      });
    }
    nextPageUrl = json['next_page_url'];
    path = json['path'];
    perPage = json['per_page'];
    prevPageUrl = json['prev_page_url'];
    to = json['to'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['first_page_url'] = firstPageUrl;
    data['from'] = from;
    data['last_page'] = lastPage;
    data['last_page_url'] = lastPageUrl;
    if (links != null) {
      data['links'] = links!.map((v) => v.toJson()).toList();
    }
    data['next_page_url'] = nextPageUrl;
    data['path'] = path;
    data['per_page'] = perPage;
    data['prev_page_url'] = prevPageUrl;
    data['to'] = to;
    data['total'] = total;
    return data;
  }
}

class Data {
  int? id;
  String? hadithNumber;
  String? englishNarrator;
  String? hadithEnglish;
  String? hadithUrdu;
  String? urduNarrator;
  String? hadithArabic;
  String? headingArabic;
  String? headingUrdu;
  String? headingEnglish;
  String? chapterId;
  String? bookSlug;
  String? volume;
  String? status;
  Book? book;
  Chapter? chapter;

  Data(
      {this.id,
      this.hadithNumber,
      this.englishNarrator,
      this.hadithEnglish,
      this.hadithUrdu,
      this.urduNarrator,
      this.hadithArabic,
      this.headingArabic,
      this.headingUrdu,
      this.headingEnglish,
      this.chapterId,
      this.bookSlug,
      this.volume,
      this.status,
      this.book,
      this.chapter});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    hadithNumber = json['hadithNumber'];
    englishNarrator = json['englishNarrator'];
    hadithEnglish = json['hadithEnglish'];
    hadithUrdu = json['hadithUrdu'];
    urduNarrator = json['urduNarrator'];
    hadithArabic = json['hadithArabic'];
    headingArabic = json['headingArabic'];
    headingUrdu = json['headingUrdu'];
    headingEnglish = json['headingEnglish'];
    chapterId = json['chapterId'];
    bookSlug = json['bookSlug'];
    volume = json['volume'];
    status = json['status'];
    book = json['book'] != null ? Book.fromJson(json['book']) : null;
    chapter =
        json['chapter'] != null ? Chapter.fromJson(json['chapter']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['hadithNumber'] = hadithNumber;
    data['englishNarrator'] = englishNarrator;
    data['hadithEnglish'] = hadithEnglish;
    data['hadithUrdu'] = hadithUrdu;
    data['urduNarrator'] = urduNarrator;
    data['hadithArabic'] = hadithArabic;
    data['headingArabic'] = headingArabic;
    data['headingUrdu'] = headingUrdu;
    data['headingEnglish'] = headingEnglish;
    data['chapterId'] = chapterId;
    data['bookSlug'] = bookSlug;
    data['volume'] = volume;
    data['status'] = status;
    if (book != null) {
      data['book'] = book!.toJson();
    }
    if (chapter != null) {
      data['chapter'] = chapter!.toJson();
    }
    return data;
  }
}

class Book {
  int? id;
  String? bookName;
  String? writerName;
  String? aboutWriter;
  String? writerDeath;
  String? bookSlug;

  Book(
      {this.id,
      this.bookName,
      this.writerName,
      this.aboutWriter,
      this.writerDeath,
      this.bookSlug});

  Book.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookName = json['bookName'];
    writerName = json['writerName'];
    aboutWriter = json['aboutWriter'];
    writerDeath = json['writerDeath'];
    bookSlug = json['bookSlug'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['bookName'] = bookName;
    data['writerName'] = writerName;
    data['aboutWriter'] = aboutWriter;
    data['writerDeath'] = writerDeath;
    data['bookSlug'] = bookSlug;
    return data;
  }
}

class Chapter {
  int? id;
  String? chapterNumber;
  String? chapterEnglish;
  String? chapterUrdu;
  String? chapterArabic;
  String? bookSlug;

  Chapter(
      {this.id,
      this.chapterNumber,
      this.chapterEnglish,
      this.chapterUrdu,
      this.chapterArabic,
      this.bookSlug});

  Chapter.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    chapterNumber = json['chapterNumber'];
    chapterEnglish = json['chapterEnglish'];
    chapterUrdu = json['chapterUrdu'];
    chapterArabic = json['chapterArabic'];
    bookSlug = json['bookSlug'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['chapterNumber'] = chapterNumber;
    data['chapterEnglish'] = chapterEnglish;
    data['chapterUrdu'] = chapterUrdu;
    data['chapterArabic'] = chapterArabic;
    data['bookSlug'] = bookSlug;
    return data;
  }
}

class Links {
  String? url;
  String? label;
  bool? active;

  Links({this.url, this.label, this.active});

  Links.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    label = json['label'];
    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['label'] = label;
    data['active'] = active;
    return data;
  }
}
