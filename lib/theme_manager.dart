import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'dynamic_app_icon.dart'; // Temporarily disabled

class ThemeManager {
  static const String _themeColorKey = 'theme_color';
  static const String _darkModeKey = 'darkMode';

  static const Map<String, Color> themeColors = {
    'Red Velvet': Color(0xFF8B2635),
    'Royal Blue': Color(0xFF4169E1),
    'Emerald Green': Color(0xFF50C878),
    'Purple Majesty': Color(0xFF6A0DAD),
    'Sunset Orange': Color(0xFFFF6347),
    'Forest Green': Color(0xFF228B22),
    'Deep Pink': Color(0xFFFF1493),
    'Midnight Blue': Color(0xFF191970),
    'Golden Yellow': Color(0xFFFFD700),
    'Crimson Red': Color(0xFFDC143C),
    'Piano Black': Color(0xFF1C1C1C),
  };

  static Future<String> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeColorKey) ?? 'Red Velvet';
  }

  static Future<void> setThemeColor(String colorName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeColorKey, colorName);
    
    // Update app icon to match theme (disabled until icons are generated)
    /*
    try {
      await DynamicAppIcon.updateIconForTheme(colorName);
    } catch (e) {
      print('Could not update app icon: $e');
    }
    */
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDark);
  }

  static Color getColorByName(String name) {
    return themeColors[name] ?? themeColors['Red Velvet']!;
  }
}
