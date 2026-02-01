import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  static final ConnectivityHelper _instance = ConnectivityHelper._internal();
  factory ConnectivityHelper() => _instance;
  ConnectivityHelper._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if device is connected to internet
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();

      // Check if connected to wifi, mobile, or ethernet
      if (result.contains(ConnectivityResult.none)) {
        return false;
      }

      return true;
    } catch (e) {
      // If check fails, assume no connection
      return false;
    }
  }

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}
