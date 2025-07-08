import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  static Future<bool> checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      print('Connectivity result: $connectivityResult');
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      print('Error checking connectivity: $e');
      return false; 
    }
  }
}
