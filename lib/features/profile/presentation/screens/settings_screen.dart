import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Settings Section
          _buildSectionHeader(context, 'App Settings'),
          
          // Dark Mode Toggle
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: Text(isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
              value: isDarkMode,
              onChanged: (_) {
                themeProvider.toggleTheme();
              },
              secondary: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: isDarkMode 
                    ? AppColors.darkColorScheme.primary 
                    : AppColors.lightColorScheme.primary,
              ),
            ),
          ),
          
          // ... Rest of your existing settings UI ...
          
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
