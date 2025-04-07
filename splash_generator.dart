// This is a simple Dart script to generate a larger splash image
// Run it with: dart splash_generator.dart
import 'dart:io';

void main() async {
  print('Generating larger splash images...');

  // Create directories for the new splash images
  for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
    final directory = 'android/app/src/main/res/drawable-$density';
    if (!await Directory(directory).exists()) {
      await Directory(directory).create(recursive: true);
    }
  }

  // Copy the app logo to all the drawable directories with a larger size
  final originalLogo = 'assets/images/logos/app_logo.png';

  // Copy to splash directories with different resize commands
  await Process.run(
      'cp', [originalLogo, 'android/app/src/main/res/drawable/splash.png']);

  // Now generate the Android 12 splash images
  await Process.run('cp',
      [originalLogo, 'android/app/src/main/res/drawable/android12splash.png']);

  print('Splash images generated! ✅');
  print('Now run: flutter pub run flutter_native_splash:create');
}
