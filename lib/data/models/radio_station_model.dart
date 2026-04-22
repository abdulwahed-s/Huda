class RadioStationModel {
  final List<RadioStation>? radios;

  RadioStationModel({this.radios});

  factory RadioStationModel.fromJson(Map<String, dynamic> json) {
    return RadioStationModel(
      radios: json['radios'] != null
          ? (json['radios'] as List<dynamic>)
              .map((r) => RadioStation.fromJson(r))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'radios': radios?.map((r) => r.toJson()).toList(),
    };
  }
}

class RadioStation {
  final dynamic id;
  final dynamic name;
  final dynamic url;
  final dynamic recentDate;

  RadioStation({
    required this.id,
    required this.name,
    required this.url,
    required this.recentDate,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      recentDate: json['recent_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'recent_date': recentDate,
    };
  }
}
