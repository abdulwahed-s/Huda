import 'dart:io';

class NetworkInfo {
  static const List<_Probe> _probes = <_Probe>[
    _Probe('1.1.1.1', 443),
    _Probe('8.8.8.8', 443),
    _Probe('google.com', 443),
  ];

  static Future<bool> checkInternetConnectivity() async {
    for (final probe in _probes) {
      try {
        final socket = await Socket.connect(
          probe.host,
          probe.port,
          timeout: const Duration(seconds: 3),
        );
        socket.destroy();
        return true;
      } catch (_) {}
    }
    return false;
  }
}

class _Probe {
  final String host;
  final int port;
  const _Probe(this.host, this.port);
}
