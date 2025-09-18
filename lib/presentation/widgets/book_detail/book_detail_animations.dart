import 'package:flutter/material.dart';

class BookDetailAnimations {
  final TickerProvider vsync;
  late AnimationController fadeController;
  late AnimationController slideController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  BookDetailAnimations(this.vsync);

  void initialize() {
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );
    slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: fadeController, curve: Curves.easeInOut),
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: slideController, curve: Curves.easeOutBack),
    );

    fadeController.forward();
    slideController.forward();
  }

  void dispose() {
    fadeController.dispose();
    slideController.dispose();
  }
}