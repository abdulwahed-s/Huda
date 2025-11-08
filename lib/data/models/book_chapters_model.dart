class BookChaptersModel {
  List<Data>? data;
  int? total;
  int? limit;
  Null previous;
  Null next;

  BookChaptersModel(
      {this.data, this.total, this.limit, this.previous, this.next});

  BookChaptersModel.fromJson(Map<String, dynamic> json) {
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
  String? bookNumber;
  List<Book>? book;
  int? hadithStartNumber;
  int? hadithEndNumber;
  int? numberOfHadith;

  Data(
      {this.bookNumber,
      this.book,
      this.hadithStartNumber,
      this.hadithEndNumber,
      this.numberOfHadith});

  Data.fromJson(Map<String, dynamic> json) {
    bookNumber = json['bookNumber'];
    if (json['book'] != null) {
      book = <Book>[];
      json['book'].forEach((v) {
        book!.add(Book.fromJson(v));
      });
    }
    hadithStartNumber = json['hadithStartNumber'];
    hadithEndNumber = json['hadithEndNumber'];
    numberOfHadith = json['numberOfHadith'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['bookNumber'] = bookNumber;
    if (book != null) {
      data['book'] = book!.map((v) => v.toJson()).toList();
    }
    data['hadithStartNumber'] = hadithStartNumber;
    data['hadithEndNumber'] = hadithEndNumber;
    data['numberOfHadith'] = numberOfHadith;
    return data;
  }
}

class Book {
  String? lang;
  String? name;

  Book({this.lang, this.name});

  Book.fromJson(Map<String, dynamic> json) {
    lang = json['lang'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lang'] = lang;
    data['name'] = name;
    return data;
  }
}
