part of 'qiblah_cubit.dart';

@immutable
sealed class QiblahState {}

final class QiblahInitial extends QiblahState {}

class QiblahLoading extends QiblahState {}

class QiblahReady extends QiblahState {}

class QiblahError extends QiblahState {
  final String message;
  QiblahError(this.message);
}

class QiblahPermissionDenied extends QiblahState {
  final String message;
  QiblahPermissionDenied(this.message);
}

/// Location services are off on the device (not a permission answer).
/// A [QiblahPermissionDenied], so older checks still match it.
class QiblahLocationServiceOff extends QiblahPermissionDenied {
  QiblahLocationServiceOff(super.message);
}

class QiblahPermissionDeniedForever extends QiblahState {
  final String message;
  QiblahPermissionDeniedForever(this.message);
}
