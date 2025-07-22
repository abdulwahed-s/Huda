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

class QiblahPermissionDeniedForever extends QiblahState {
  final String message;
  QiblahPermissionDeniedForever(this.message);
}