import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Get a lighter version of the color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);

    return hsl.withLightness(lightness).toColor();
  }

  /// Get a darker version of the color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);

    return hsl.withLightness(lightness).toColor();
  }

  /// Get a color with modified saturation
  Color withSaturation(double saturation) {
    assert(saturation >= 0 && saturation <= 1);

    final hsl = HSLColor.fromColor(this);
    return hsl.withSaturation(saturation).toColor();
  }

  /// Creates a material color swatch from this color as primary
  MaterialColor toMaterialColor() {
    final strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    final swatch = <int, Color>{};
    final r = red, g = green, b = blue;

    for (final strength in strengths) {
      final ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(value, swatch);
  }

  /// Get a gradient from this color to another
  LinearGradient toGradient(Color endColor,
      {AlignmentGeometry begin = Alignment.centerLeft,
      AlignmentGeometry end = Alignment.centerRight}) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [this, endColor],
    );
  }

  /// Get a transparent version of this color
  Color withOpacity01() => withOpacity(0.1);
  Color withOpacity02() => withOpacity(0.2);
  Color withOpacity03() => withOpacity(0.3);
  Color withOpacity04() => withOpacity(0.4);
  Color withOpacity05() => withOpacity(0.5);
  Color withOpacity06() => withOpacity(0.6);
  Color withOpacity07() => withOpacity(0.7);
  Color withOpacity08() => withOpacity(0.8);
  Color withOpacity09() => withOpacity(0.9);
}
