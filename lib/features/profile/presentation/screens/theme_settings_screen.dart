import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/theme/theme_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildThemeOption(
                context,
                'Light',
                Icons.light_mode,
                themeProvider.themeOption == ThemeOption.light,
                () => themeProvider.setTheme(ThemeOption.light),
              ),
              const Divider(),
              _buildThemeOption(
                context,
                'Dark',
                Icons.dark_mode,
                themeProvider.themeOption == ThemeOption.dark,
                () => themeProvider.setTheme(ThemeOption.dark),
              ),
              const Divider(),
              _buildThemeOption(
                context,
                'System',
                Icons.settings_suggest,
                themeProvider.themeOption == ThemeOption.system,
                () => themeProvider.setTheme(ThemeOption.system),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'System mode will automatically switch between light and dark theme based on your device settings.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: onTap,
    );
  }
}
