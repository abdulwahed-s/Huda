import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  static Future<bool> checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
      }
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }
}
