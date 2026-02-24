import 'package:equatable/equatable.dart';

class LockedApp extends Equatable {
  final String packageId;

  final String appName;

  final String? iconBase64;

  const LockedApp({
    required this.packageId,
    required this.appName,
    this.iconBase64,
  });

  factory LockedApp.fromJson(Map<String, dynamic> json) {
    return LockedApp(
      packageId: json['packageId'] as String,
      appName: json['appName'] as String,
      iconBase64: json['iconBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageId': packageId,
      'appName': appName,
      'iconBase64': iconBase64,
    };
  }

  @override
  List<Object?> get props => [packageId, appName, iconBase64];
}
