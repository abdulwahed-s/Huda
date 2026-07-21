import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';

import 'package:huda/core/bootstrap/bootstrap.dart';
import 'package:huda/presentation/screens/app.dart';
import 'package:huda/presentation/screens/error.dart' show setCustomErrorWidget;

const Color _bootBackground = Color(0xFF0c1d2b);
const String _bootLogo = 'assets/images/huda.png';

class Bootstrapper extends StatefulWidget {
  const Bootstrapper({super.key});

  @override
  State<Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<Bootstrapper> {
  String? _initialRoute;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _runGate();
  }

  void _runGate() {
    setState(() {
      _initialRoute = null;
      _error = null;
    });

    initCriticalAndGetRoute().then((route) {
      if (!mounted) return;
      setCustomErrorWidget();
      setState(() => _initialRoute = route);
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() => _error = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialRoute != null) {
      return App(initialRoute: _initialRoute!);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home:
          _error != null ? _RetryGate(onRetry: _runGate) : const _SplashGate(),
    );
  }
}

class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bootBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BootLogo(size: 160),
            const SizedBox(height: 40),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryGate extends StatelessWidget {
  const _RetryGate({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bootBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BootLogo(size: 120),
                const SizedBox(height: 32),
                const Text(
                  'Something went wrong while starting the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Restart.restartApp(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text('Restart app'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootLogo extends StatelessWidget {
  const _BootLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _bootLogo,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.mosque, size: size * 0.6, color: Colors.white70),
      ),
    );
  }
}
