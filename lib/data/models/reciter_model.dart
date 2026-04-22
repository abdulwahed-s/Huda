class Reciter {
  final dynamic id;
  final dynamic name;
  final dynamic letter;
  final List<Moshaf> moshaf;

  Reciter({
    required this.id,
    required this.name,
    required this.letter,
    required this.moshaf,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'],
      name: json['name'],
      letter: json['letter'],
      moshaf: (json['moshaf'] as List<dynamic>)
          .map((moshaf) => Moshaf.fromJson(moshaf))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'letter': letter,
      'moshaf': moshaf.map((m) => m.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reciter && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Moshaf {
  final dynamic id;
  final dynamic name;
  final dynamic server;
  final dynamic surahTotal;
  final dynamic moshafType;
  final dynamic surahList;

  Moshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahList,
  });

  factory Moshaf.fromJson(Map<String, dynamic> json) {
    return Moshaf(
      id: json['id'],
      name: json['name'],
      server: json['server'],
      surahTotal: json['surah_total'],
      moshafType: json['moshaf_type'],
      surahList: json['surah_list'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'server': server,
      'surah_total': surahTotal,
      'moshaf_type': moshafType,
      'surah_list': surahList,
    };
  }
}
