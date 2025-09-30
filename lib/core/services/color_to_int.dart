import 'dart:ui';

int colorToInt(Color color) {
  int a = (color.a * 255).toInt();
  int r = (color.r * 255).toInt();
  int g = (color.g * 255).toInt();
  int b = (color.b * 255).toInt();

  return (a << 24) | (r << 16) | (g << 8) | b;
}