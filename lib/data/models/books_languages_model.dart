class BooksLanguagesModel {
  String? langsymbol;
  String? langtranslation;

  BooksLanguagesModel({this.langsymbol, this.langtranslation});

  BooksLanguagesModel.fromJson(Map<String, dynamic> json) {
    langsymbol = json['langsymbol'];
    langtranslation = json['langtranslation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['langsymbol'] = langsymbol;
    data['langtranslation'] = langtranslation;
    return data;
  }
}
