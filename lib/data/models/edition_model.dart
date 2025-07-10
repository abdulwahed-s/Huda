class EditionModel {
  int? code;
  String? status;
  List<Data>? data;

  EditionModel({this.code, this.status, this.data});

  EditionModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    status = json['status'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        // ignore: unnecessary_new
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['status'] = status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? identifier;
  String? language;
  String? name;
  String? englishName;
  String? format;
  String? type;
  String? direction;

  Data(
      {this.identifier,
      this.language,
      this.name,
      this.englishName,
      this.format,
      this.type,
      this.direction});

  Data.fromJson(Map<String, dynamic> json) {
    identifier = json['identifier'];
    language = json['language'];
    name = json['name'];
    englishName = json['englishName'];
    format = json['format'];
    type = json['type'];
    direction = json['direction'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['identifier'] = identifier;
    data['language'] = language;
    data['name'] = name;
    data['englishName'] = englishName;
    data['format'] = format;
    data['type'] = type;
    data['direction'] = direction;
    return data;
  }
}
