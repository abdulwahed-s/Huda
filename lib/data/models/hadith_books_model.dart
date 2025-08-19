class HadithBooksModel {
  int? status;
  String? message;
  List<Books>? books;

  HadithBooksModel({this.status, this.message, this.books});

  HadithBooksModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['books'] != null) {
      books = <Books>[];
      json['books'].forEach((v) {
        books!.add(Books.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (books != null) {
      data['books'] = books!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Books {
  int? id;
  String? bookName;
  String? writerName;
  String? aboutWriter;
  String? writerDeath;
  String? bookSlug;
  String? hadithsCount;
  String? chaptersCount;

  Books(
      {this.id,
      this.bookName,
      this.writerName,
      this.aboutWriter,
      this.writerDeath,
      this.bookSlug,
      this.hadithsCount,
      this.chaptersCount});

  Books.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookName = json['bookName'];
    writerName = json['writerName'];
    aboutWriter = json['aboutWriter'];
    writerDeath = json['writerDeath'];
    bookSlug = json['bookSlug'];
    hadithsCount = json['hadiths_count'];
    chaptersCount = json['chapters_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['bookName'] = bookName;
    data['writerName'] = writerName;
    data['aboutWriter'] = aboutWriter;
    data['writerDeath'] = writerDeath;
    data['bookSlug'] = bookSlug;
    data['hadiths_count'] = hadithsCount;
    data['chapters_count'] = chaptersCount;
    return data;
  }
}
