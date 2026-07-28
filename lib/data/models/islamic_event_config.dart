import 'dart:convert';

enum IslamicEventSource {
  remote,
  localRecurring,
}

class IslamicEventConfig {
  final String id;
  final String eventKey;
  final int hijriMonth;
  final int hijriDayStart;
  final int hijriDayEnd;
  final String actionRoute;
  final String iconName;
  final int priority;
  final IslamicEventSource source;

  const IslamicEventConfig({
    required this.id,
    required this.eventKey,
    required this.hijriMonth,
    required this.hijriDayStart,
    required this.hijriDayEnd,
    required this.actionRoute,
    required this.iconName,
    required this.priority,
    this.source = IslamicEventSource.remote,
  });

  bool get isRemoteConfigured => source == IslamicEventSource.remote;
  bool get isLocalRecurring => source == IslamicEventSource.localRecurring;

  factory IslamicEventConfig.fromJson(Map<String, dynamic> json) {
    return IslamicEventConfig(
      id: json['id'] as String,
      eventKey: json['event_key'] as String,
      hijriMonth: json['hijri_month'] as int,
      hijriDayStart: json['hijri_day_start'] as int,
      hijriDayEnd: json['hijri_day_end'] as int,
      actionRoute: json['action_route'] as String,
      iconName: json['icon_name'] as String,
      priority: json['priority'] as int,
      source: IslamicEventSource.remote,
    );
  }

  Map<String, dynamic> toJson() {
    if (!isRemoteConfigured) {
      throw StateError(
        'Locally calculated Islamic events must not be serialized as remote data.',
      );
    }
    return {
      'id': id,
      'event_key': eventKey,
      'hijri_month': hijriMonth,
      'hijri_day_start': hijriDayStart,
      'hijri_day_end': hijriDayEnd,
      'action_route': actionRoute,
      'icon_name': iconName,
      'priority': priority,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory IslamicEventConfig.fromJsonString(String jsonString) {
    return IslamicEventConfig.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IslamicEventConfig &&
        other.id == id &&
        other.eventKey == eventKey &&
        other.hijriMonth == hijriMonth &&
        other.hijriDayStart == hijriDayStart &&
        other.hijriDayEnd == hijriDayEnd &&
        other.actionRoute == actionRoute &&
        other.iconName == iconName &&
        other.priority == priority &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(
        id,
        eventKey,
        hijriMonth,
        hijriDayStart,
        hijriDayEnd,
        actionRoute,
        iconName,
        priority,
        source,
      );
}
