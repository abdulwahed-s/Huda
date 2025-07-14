import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  static Future<bool> checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // Only log when there's no connectivity for debugging offline scenarios
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('No internet connectivity detected');
      }
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }
}
