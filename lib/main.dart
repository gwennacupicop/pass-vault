import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'database_helper.dart';
import 'splash_screen.dart';
import 'auth/auth_flow.dart';
import 'theme_manager.dart';

void main() => runApp(const PasswordManagerApp());

class PasswordManagerApp extends StatefulWidget {
  const PasswordManagerApp({super.key});

  @override
  State<PasswordManagerApp> createState() => _PasswordManagerAppState();
}

class _PasswordManagerAppState extends State<PasswordManagerApp> {
  bool _isDarkMode = false;
  String _themeColor = 'Red Velvet';
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  int _restartKey = 0;

  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
  }

  void restartApp() {
    // Clear all cached data and completely restart the app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use runApp to completely restart the application
      runApp(const PasswordManagerApp());
    });
  }

  Future<void> _loadThemePreferences() async {
    final darkMode = await ThemeManager.getDarkMode();
    final themeColor = await ThemeManager.getThemeColor();
    setState(() {
      _isDarkMode = darkMode;
      _themeColor = themeColor;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    // Update UI immediately for instant feedback
    setState(() {
      _isDarkMode = value;
    });
    
    // Save preference asynchronously without blocking UI
    await ThemeManager.setDarkMode(value);
  }

  Future<void> _setThemeColor(String colorName) async {
    await ThemeManager.setThemeColor(colorName);
    setState(() {
      _themeColor = colorName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = ThemeManager.getColorByName(_themeColor);
    
    return MaterialApp(
      key: ValueKey(_restartKey),
      navigatorKey: _navigatorKey,
      title: 'Pass Vault',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _buildDarkTheme(primaryColor) : _buildLightTheme(primaryColor),
      home: SplashScreen(
        primaryColor: primaryColor,
        child: AuthFlow(
          child: PasswordManagerHome(
            key: ValueKey('home_${_isDarkMode}_${_themeColor}'),
            onDarkModeToggle: _toggleDarkMode,
            onThemeColorChange: _setThemeColor,
            onAppRestart: restartApp,
            isDarkMode: _isDarkMode,
            themeColor: _themeColor,
          ),
        ),
      ),
    );
  }

  ThemeData _buildLightTheme(Color primaryColor) {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: primaryColor,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(Color primaryColor) {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: primaryColor,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: const Color(0xFF121212),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      cardColor: const Color(0xFF2C2C2C),
      dialogBackgroundColor: const Color(0xFF2C2C2C),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            // For Piano Black, use light grey
            if (primaryColor == const Color(0xFF000000)) {
              return const Color(0xFF666666); // Light grey for Piano Black
            }
            // For all other colors in dark mode, make them just slightly lighter
            return Color.fromARGB(
              255,
              math.min(255, (primaryColor.red * 1.2).round()),
              math.min(255, (primaryColor.green * 1.2).round()),
              math.min(255, (primaryColor.blue * 1.2).round()),
            );
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            // For Piano Black, use lighter track
            if (primaryColor == const Color(0xFF000000)) {
              return const Color(0xFF888888).withOpacity(0.6);
            }
            // For all other colors, make track just slightly lighter
            return Color.fromARGB(
              255,
              math.min(255, (primaryColor.red * 1.15).round()),
              math.min(255, (primaryColor.green * 1.15).round()),
              math.min(255, (primaryColor.blue * 1.15).round()),
            ).withOpacity(0.7);
          }
          return Colors.grey.withOpacity(0.3);
        }),
        overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            // Add a subtle light outline for better visibility in dark mode for all colors
            return Colors.white.withOpacity(0.15);
          }
          return Colors.transparent;
        }),
        splashRadius: 20,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

class PasswordEntry {
  int? id;
  String website;
  String username;
  String password;
  bool showPassword;

  PasswordEntry({
    this.id,
    required this.website,
    required this.username,
    required this.password,
    this.showPassword = false,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'website': website,
      'username': username,
      'password': password,
    };
  }

  // Create from Map (from database)
  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'],
      website: map['website'],
      username: map['username'],
      password: map['password'],
    );
  }
}

class PasswordManagerHome extends StatefulWidget {
  final Function(bool) onDarkModeToggle;
  final Function(String) onThemeColorChange;
  final VoidCallback onAppRestart;
  final bool isDarkMode;
  final String themeColor;

  const PasswordManagerHome({
    super.key,
    required this.onDarkModeToggle,
    required this.onThemeColorChange,
    required this.onAppRestart,
    required this.isDarkMode,
    required this.themeColor,
  });

  @override
  State<PasswordManagerHome> createState() => _PasswordManagerHomeState();
}

class _PasswordManagerHomeState extends State<PasswordManagerHome> {
  final List<PasswordEntry> _entries = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  double _maxUsernameWidth = 0;
  bool _pinEnabled = false;
  bool _fingerprintEnabled = false;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadPasswords();
    _loadSettingsPreferences();
  }

  @override
  void didUpdateWidget(PasswordManagerHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      setState(() {
        _isDarkMode = widget.isDarkMode;
      });
    }
  }

  Future<void> _loadSettingsPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // If PIN is set up, show it as enabled
      _pinEnabled = prefs.getBool('hasPin') ?? false;
      // If fingerprint is enabled, show fingerprint as enabled
      // Check both old and new preference formats
      _fingerprintEnabled = (prefs.getBool('fingerprintEnabled') ?? false) ||
                          (prefs.getBool('fingerprint_enabled') ?? false);
    });
  }

  Future<void> _togglePinSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!value) {
      // Prepare warning message based on fingerprint status
      String warningText = 'Are you sure you want to disable PIN authentication?';
      if (_fingerprintEnabled) {
        warningText += ' This will also disable fingerprint authentication.';
      }
      
      // Show confirmation dialog before disabling PIN
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: const Text('Disable PIN'),
          content: Text(warningText),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Only disable PIN flag, keep the actual PIN stored
                await prefs.setBool('hasPin', false);
                // Clear fingerprint preferences when disabling PIN
                await prefs.remove('fingerprintEnabled');
                await prefs.remove('fingerprint_enabled'); // Remove old key format
                setState(() {
                  _pinEnabled = false;
                  _fingerprintEnabled = false;
                });
              },
              child: const Text('Disable'),
            ),
          ],
        ),
      );
    } else {
      // Check if PIN already exists
      final existingPin = prefs.getString('user_pin');
      if (existingPin != null && existingPin.isNotEmpty) {
        // PIN already exists, just enable it
        await prefs.setBool('hasPin', true);
        setState(() {
          _pinEnabled = true;
        });
      } else {
        // No PIN exists, need to set one up
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: const Text('Enable PIN'),
            content: const Text('PIN authentication will be enabled. You will need to set up your PIN.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Set flag to enable PIN - the actual PIN setup will happen in auth flow
                  await prefs.setBool('hasPin', true);
                  // Clear any existing authentication state
                  await prefs.remove('user_pin');
                  await prefs.remove('pinHash');
                  await prefs.remove('isAuthenticated');
                  await prefs.remove('authenticationBypassTime');
                  
                  setState(() {
                    _pinEnabled = true;
                  });
                  // Close the drawer
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Enable'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _toggleDarkModeSetting(bool value) async {
    // Update local state immediately for instant feedback
    setState(() {
      _isDarkMode = value;
    });
    
    // Call parent callback to update the overall app state
    widget.onDarkModeToggle(value);
  }

  Future<void> _toggleFingerprintSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_pinEnabled) {
      _showInfoDialog('PIN Required', 'You must enable PIN authentication before enabling fingerprint authentication.');
      return;
    }
    
    if (!value) {
      // Disable fingerprint - remove ALL fingerprint preferences
      await prefs.remove('fingerprintEnabled');
      await prefs.remove('fingerprint_enabled'); // Remove old format
      setState(() {
        _fingerprintEnabled = false;
      });
    } else {
      // Enable fingerprint - the actual fingerprint setup will happen during auth flow
      await prefs.setBool('fingerprintEnabled', true);
      setState(() {
        _fingerprintEnabled = true;
      });
    }
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPin() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First check if PIN is enabled
    if (!_pinEnabled) {
      _showInfoDialog('PIN Not Enabled', 'Please enable PIN authentication first.');
      return;
    }
    
    // Check if PIN exists
    final existingPin = prefs.getString('user_pin');
    if (existingPin == null || existingPin.isEmpty) {
      _showInfoDialog('No PIN Set', 'No PIN code is currently set up.');
      return;
    }
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: const Text('Reset PIN'),
        content: const Text('Are you sure you want to reset your PIN Code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show PIN verification dialog
              _showPinVerificationDialog();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showPinVerificationDialog() {
    String enteredPin = '';
    String errorMessage = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: const Text('Enter Current PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your current PIN to confirm reset:'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  border: const OutlineInputBorder(),
                  errorText: errorMessage.isNotEmpty ? errorMessage : null,
                ),
                onChanged: (value) {
                  enteredPin = value;
                  if (errorMessage.isNotEmpty) {
                    setDialogState(() {
                      errorMessage = '';
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (enteredPin.length < 4) {
                  setDialogState(() {
                    errorMessage = 'PIN must be at least 4 digits';
                  });
                  return;
                }
                
                // Verify PIN by hashing the entered PIN and comparing with stored hash
                final prefs = await SharedPreferences.getInstance();
                final storedPin = prefs.getString('user_pin');
                
                if (storedPin == null) {
                  setDialogState(() {
                    errorMessage = 'No PIN found';
                  });
                  return;
                }
                
                // Hash the entered PIN to compare with stored hash
                final hashedEnteredPin = sha256.convert(utf8.encode(enteredPin)).toString();
                
                if (hashedEnteredPin == storedPin) {
                  Navigator.pop(context);
                  _showPinResetRestartDialog();
                } else {
                  setDialogState(() {
                    errorMessage = 'Incorrect PIN';
                  });
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinResetRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: const Text('PIN Reset Complete'),
        content: const Text('Your PIN has been reset. You will now be redirected to set up a new PIN.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Clear all PIN-related and authentication preferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_pin');
              await prefs.remove('pinHash');
              await prefs.remove('isAuthenticated');
              await prefs.remove('authenticationBypassTime');
              // Keep hasPin=true so PIN setup will be triggered
              
              // Close the drawer first
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              
              // Navigate directly to the PIN setup screen
              _navigateToPinSetup();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _navigateToPinSetup() {
    // Navigate to the PIN setup screen by pushing the auth flow
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SplashScreen(
          primaryColor: Theme.of(context).primaryColor,
          child: AuthFlow(
            child: PasswordManagerHome(
              onDarkModeToggle: widget.onDarkModeToggle,
              onThemeColorChange: widget.onThemeColorChange,
              onAppRestart: widget.onAppRestart,
              isDarkMode: widget.isDarkMode,
              themeColor: widget.themeColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showThemeColorDialog() {
    String selectedColor = widget.themeColor;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choose Theme Color',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 8.0,
                radius: const Radius.circular(4),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ThemeManager.themeColors.entries.map((entry) {
                      return ListTile(
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: entry.value,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(entry.key),
                        trailing: selectedColor == entry.key ? const Icon(Icons.check) : null,
                        onTap: () {
                          setDialogState(() {
                            selectedColor = entry.key;
                          });
                          widget.onThemeColorChange(entry.key);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(24),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'About Pass Vault',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pass Vault is a secure and elegant password manager designed to keep your digital credentials safe and easily accessible. Built with Flutter and featuring a sophisticated customizable theme, this application provides a seamless user experience across all your devices.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 16),
            Text(
              'The app features robust security with PIN authentication, fingerprint verification, and encrypted local storage. With its intuitive interface and comprehensive password management capabilities, Pass Vault ensures your sensitive information remains protected while being conveniently accessible whenever you need it.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),
            Divider(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Creators:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Perlene Grace Hubac\nElmerio Talara\n\nBohol Island State University - Main Campus\n\n2025',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Load passwords from database
  Future<void> _loadPasswords() async {
    final List<Map<String, dynamic>> passwords = await _databaseHelper.queryAllPasswords();
    setState(() {
      _entries.clear();
      _entries.addAll(passwords.map((p) => PasswordEntry.fromMap(p)).toList());
      _calculateMaxUsernameWidth();
    });
  }

  // Calculate the maximum username width for alignment
  void _calculateMaxUsernameWidth() {
    if (_entries.isEmpty) {
      _maxUsernameWidth = 0;
      return;
    }
    
    _maxUsernameWidth = 0;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (final entry in _entries) {
      textPainter.text = TextSpan(
        text: entry.username,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      );
      textPainter.layout();
      if (textPainter.width > _maxUsernameWidth) {
        _maxUsernameWidth = textPainter.width;
      }
    }
    
    // Add some padding and ensure minimum width
    _maxUsernameWidth = (_maxUsernameWidth + 16).clamp(80.0, 120.0);
  }

  Future<void> _addEntry(String website, String username, String password) async {
    final newEntry = PasswordEntry(
      website: website,
      username: username,
      password: password,
    );
    
    // Insert into database
    final id = await _databaseHelper.insertPassword(newEntry.toMap());
    newEntry.id = id;
    
    setState(() {
      _entries.add(newEntry);
      _calculateMaxUsernameWidth();
    });
  }

  Future<void> _editEntry(int index) async {
    String website = _entries[index].website;
    String username = _entries[index].username;
    String password = _entries[index].password;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(24),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Edit Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Website',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: website),
              onChanged: (v) => website = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: username),
              onChanged: (v) => username = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: password),
              obscureText: true,
              onChanged: (v) => password = v,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (website.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
                      // Update in database
                      final updatedEntry = PasswordEntry(
                        id: _entries[index].id,
                        website: website,
                        username: username,
                        password: password,
                      );
                      await _databaseHelper.updatePassword(updatedEntry.toMap());
                      
                      setState(() {
                        _entries[index].website = website;
                        _entries[index].username = username;
                        _entries[index].password = password;
                        _calculateMaxUsernameWidth();
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEntry(int index) async {
    final entry = _entries[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(24),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Delete Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${entry.website}" password?',
          textAlign: TextAlign.justify,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final entryId = entry.id;
              if (entryId != null) {
                await _databaseHelper.deletePassword(entryId);
              }
              setState(() {
                _entries.removeAt(index);
                _calculateMaxUsernameWidth();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  void _showAddEntryDialog() {
    String website = '';
    String username = '';
    String password = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(24),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Add Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Website',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => website = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => username = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (v) => password = v,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (website.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
                      await _addEntry(website, username, password);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _togglePassword(int index, bool show) {
    setState(() {
      _entries[index].showPassword = show;
    });
  }

  void _showDetailDialog(int index) {
    final entry = _entries[index];
    bool showPasswordInDialog = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.website,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username section
              Row(
                children: [
                  Text(
                    'Username:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: entry.username));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Username copied to clipboard'),
                          backgroundColor: Theme.of(context).primaryColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[800] 
                      : Colors.grey[100],
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[600]! 
                        : Colors.grey[300]!,
                  ),
                ),
                child: SelectableText(
                  entry.username,
                  style: TextStyle(
                    fontSize: 16, 
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Password section
              Row(
                children: [
                  Text(
                    'Password:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      showPasswordInDialog ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        showPasswordInDialog = !showPasswordInDialog;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.grey[600],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: showPasswordInDialog ? () {
                      Clipboard.setData(ClipboardData(text: entry.password));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Password copied to clipboard'),
                          backgroundColor: Theme.of(context).primaryColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: showPasswordInDialog ? Colors.grey[600] : Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[800] 
                      : Colors.grey[100],
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[600]! 
                        : Colors.grey[300]!,
                  ),
                ),
                child: SelectableText(
                  showPasswordInDialog ? entry.password : '••••••••',
                  style: TextStyle(
                    fontFamily: showPasswordInDialog ? 'monospace' : null,
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'PASS VAULT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.security,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PASS VAULT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Security Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'SECURITY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('PIN Code'),
              trailing: Switch(
                value: _pinEnabled,
                onChanged: _togglePinSetting,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Fingerprint'),
              trailing: Switch(
                value: _fingerprintEnabled,
                onChanged: _toggleFingerprintSetting,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset PIN'),
              onTap: _resetPin,
            ),
            const Divider(),
            
            // Appearance Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'APPEARANCE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme Color'),
              trailing: Container(
                width: 48, // Same width as Switch widget
                height: 48, // Same height as Switch widget
                alignment: Alignment.center, // Perfect center alignment
                padding: const EdgeInsets.only(right: 10), // Changed from 9 to 10
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              onTap: _showThemeColorDialog,
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: _toggleDarkModeSetting,
              ),
            ),
            const Divider(),
            // Data Management Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'DATA MANAGEMENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Delete All Passwords'),
              onTap: _showDeleteAllPasswordsDialog,
            ),
            const Divider(),
            
            // Information Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'INFORMATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About App'),
              onTap: _showAboutDialog,
            ),
          ],
        ),
      ),
      body: _entries.isEmpty
          ? Center(
              child: Text(
                'No passwords added yet.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white54 
                      : const Color(0x80333333),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8), // Same padding for top and bottom
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return GestureDetector(
                  onTap: () => _showDetailDialog(index),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF2C2C2C) 
                        : const Color(0xFFE0E0E0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 12, right: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.website,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 18,
                                        color: Theme.of(context).brightness == Brightness.dark 
                                            ? Colors.white 
                                            : Colors.black)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: _maxUsernameWidth,
                                      child: Text(
                                        entry.username,
                                        style: TextStyle(
                                            fontSize: 14, 
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.white70 
                                                : Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        entry.showPassword ? entry.password : '**********',
                                        style: TextStyle(
                                            fontFamily: 'monospace', 
                                            fontSize: 14,
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.white70 
                                                : Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {}, // Absorb tap events to prevent row dialog from opening
                            child: Listener(
                              onPointerDown: (_) => _togglePassword(index, true),
                              onPointerUp: (_) => _togglePassword(index, false),
                              onPointerCancel: (_) => _togglePassword(index, false),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  entry.showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey[600], // Dark gray for visibility on light background
                                ),
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _editEntry(index);
                              if (value == 'delete') _deleteEntry(index);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: 'edit', 
                                  height: 28, // Further reduced height
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Minimal horizontal padding
                                  child: Text('Edit', style: TextStyle(fontSize: 13))), // Smaller font
                              const PopupMenuItem(
                                  value: 'delete', 
                                  height: 28, // Further reduced height
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Minimal horizontal padding
                                  child: Text('Delete', style: TextStyle(fontSize: 13))), // Smaller font
                            ],
                            icon: const Icon(Icons.more_vert),
                            padding: EdgeInsets.zero, // Remove padding
                            offset: const Offset(0, 0), // Remove offset
                            splashRadius: 20, // Smaller splash radius
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
  void _showDeleteAllPasswordsDialog() {
    String confirmationText = '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Delete All Passwords',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. All your saved passwords will be permanently deleted.',
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 16),
              const Text(
                'Type "DELETE ALL" to confirm:',
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'DELETE ALL',
                ),
                onChanged: (value) {
                  confirmationText = value;
                  setDialogState(() {}); // Refresh the dialog state
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: confirmationText == 'DELETE ALL' ? () {
                Navigator.pop(context);
                _showFinalDeleteConfirmation();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All'),
            ),
          ],
        ),
      ),
    );
  }
  void _showFinalDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(24),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Final Confirmation',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        content: const Text(
          'Are you absolutely sure you want to delete all passwords? This action cannot be undone.',
          textAlign: TextAlign.justify,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllPasswords();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllPasswords() async {
    try {
      await _databaseHelper.deleteAllPasswords();
      setState(() {
        _entries.clear();
        _calculateMaxUsernameWidth();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All passwords deleted successfully'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting passwords: $e'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }
}
