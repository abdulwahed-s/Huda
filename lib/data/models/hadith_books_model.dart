class HadithBooksModel {
  List<Data>? data;
  int? total;
  int? limit;
  Null previous;
  Null next;

  HadithBooksModel(
      {this.data, this.total, this.limit, this.previous, this.next});

  HadithBooksModel.fromJson(Map<String, dynamic> json) {
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
  String? name;
  bool? hasBooks;
  bool? hasChapters;
  List<Collection>? collection;
  int? totalHadith;
  int? totalAvailableHadith;

  Data(
      {this.name,
      this.hasBooks,
      this.hasChapters,
      this.collection,
      this.totalHadith,
      this.totalAvailableHadith});

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    hasBooks = json['hasBooks'];
    hasChapters = json['hasChapters'];
    if (json['collection'] != null) {
      collection = <Collection>[];
      json['collection'].forEach((v) {
        collection!.add(Collection.fromJson(v));
      });
    }
    totalHadith = json['totalHadith'];
    totalAvailableHadith = json['totalAvailableHadith'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['hasBooks'] = hasBooks;
    data['hasChapters'] = hasChapters;
    if (collection != null) {
      data['collection'] = collection!.map((v) => v.toJson()).toList();
    }
    data['totalHadith'] = totalHadith;
    data['totalAvailableHadith'] = totalAvailableHadith;
    return data;
  }
}

class Collection {
  String? lang;
  String? title;
  String? shortIntro;

  Collection({this.lang, this.title, this.shortIntro});

  Collection.fromJson(Map<String, dynamic> json) {
    lang = json['lang'];
    title = json['title'];
    shortIntro = json['shortIntro'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lang'] = lang;
    data['title'] = title;
    data['shortIntro'] = shortIntro;
    return data;
  }
}
