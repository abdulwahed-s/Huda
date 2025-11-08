class HadithDetailsModel {
  List<Data>? data;
  int? total;
  int? limit;
  int? previous;
  int? next;

  HadithDetailsModel(
      {this.data, this.total, this.limit, this.previous, this.next});

  HadithDetailsModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    total = json['total'];
    limit = json['limit'];
    previous = json['previous'];
    next = json['next'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    data['limit'] = limit;
    data['previous'] = previous;
    data['next'] = next;
    return data;
  }
}

class Data {
  String? collection;
  String? bookNumber;
  String? chapterId;
  String? hadithNumber;
  List<Hadith>? hadith;

  Data(
      {this.collection,
      this.bookNumber,
      this.chapterId,
      this.hadithNumber,
      this.hadith});

  Data.fromJson(Map<String, dynamic> json) {
    collection = json['collection'];
    bookNumber = json['bookNumber'];
    chapterId = json['chapterId'];
    hadithNumber = json['hadithNumber'];
    if (json['hadith'] != null) {
      hadith = <Hadith>[];
      json['hadith'].forEach((v) {
        hadith!.add(Hadith.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['collection'] = collection;
    data['bookNumber'] = bookNumber;
    data['chapterId'] = chapterId;
    data['hadithNumber'] = hadithNumber;
    if (hadith != null) {
      data['hadith'] = hadith!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Hadith {
  String? lang;
  String? chapterNumber;
  String? chapterTitle;
  int? urn;
  String? body;
  List<Grades>? grades;

  Hadith(
      {this.lang,
      this.chapterNumber,
      this.chapterTitle,
      this.urn,
      this.body,
      this.grades});

  Hadith.fromJson(Map<String, dynamic> json) {
    lang = json['lang'];
    chapterNumber = json['chapterNumber'];
    chapterTitle = json['chapterTitle'];
    urn = json['urn'];
    body = json['body'];
    if (json['grades'] != null) {
      grades = <Grades>[];
      json['grades'].forEach((v) {
        grades!.add(Grades.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lang'] = lang;
    data['chapterNumber'] = chapterNumber;
    data['chapterTitle'] = chapterTitle;
    data['urn'] = urn;
    data['body'] = body;
    if (grades != null) {
      data['grades'] = grades!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Grades {
  String? gradedBy;
  String? grade;

  Grades({this.gradedBy, this.grade});

  Grades.fromJson(Map<String, dynamic> json) {
    gradedBy = json['graded_by'];
    grade = json['grade'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['graded_by'] = gradedBy;
    data['grade'] = grade;
    return data;
  }
}
