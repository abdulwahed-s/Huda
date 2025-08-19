class BookChaptersModel {
  int? status;
  String? message;
  List<Chapters>? chapters;

  BookChaptersModel({this.status, this.message, this.chapters});

  BookChaptersModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['chapters'] != null) {
      chapters = <Chapters>[];
      json['chapters'].forEach((v) {
        chapters!.add(Chapters.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (chapters != null) {
      data['chapters'] = chapters!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Chapters {
  int? id;
  String? chapterNumber;
  String? chapterEnglish;
  String? chapterUrdu;
  String? chapterArabic;
  String? bookSlug;

  Chapters(
      {this.id,
      this.chapterNumber,
      this.chapterEnglish,
      this.chapterUrdu,
      this.chapterArabic,
      this.bookSlug});

  Chapters.fromJson(Map<String, dynamic> json) {
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