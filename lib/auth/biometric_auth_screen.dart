import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

class FingerprintAuthScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onSkip;
  final bool isFingerprint;
  final bool showSkipButton;
  final bool isFirstTime;

  const FingerprintAuthScreen({
    super.key,
    required this.onSuccess,
    required this.onSkip,
    this.isFingerprint = true,
    this.showSkipButton = true,
    this.isFirstTime = false,
  });

  @override
  State<FingerprintAuthScreen> createState() => _FingerprintAuthScreenState();
}

class _FingerprintAuthScreenState extends State<FingerprintAuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _canCheckFingerprint = false;
  List<BiometricType> _availableFingerprints = [];

  @override
  void initState() {
    super.initState();
    _checkFingerprint();
  }

  Future<void> _checkFingerprint() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      print('DEBUG: Can check biometrics: $canCheckBiometrics');
      print('DEBUG: Available biometrics: ${availableBiometrics.map((b) => b.name).join(', ')}');
      print('DEBUG: Looking for: fingerprint');
      print('DEBUG: Is first time: ${widget.isFirstTime}');
      
      setState(() {
        _canCheckFingerprint = canCheckBiometrics;
        _availableFingerprints = availableBiometrics;
      });

      // Check if we can actually check biometrics
      if (!canCheckBiometrics) {
        setState(() {
          _errorMessage = 'Fingerprint authentication not available on this device';
        });
        return;
      }
      
      // If no biometrics are available at all, show error
      if (availableBiometrics.isEmpty) {
        setState(() {
          _errorMessage = 'No fingerprint authentication methods are enrolled. Please set up fingerprint in Settings.';
        });
        return;
      }
      
      // For devices that report specific biometric types, check for fingerprint
      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        // Perfect, fingerprint is available
      } else if (availableBiometrics.contains(BiometricType.strong) || 
          availableBiometrics.contains(BiometricType.weak) ||
          availableBiometrics.isNotEmpty) {
        // Generic biometric is available - this is fine
      } else {
        // If we get here, something went wrong
        setState(() {
          _errorMessage = 'No supported fingerprint authentication found. Please set up fingerprint in Settings.';
        });
        return;
      }
      
      // If it's NOT first time (returning user with fingerprint enabled), 
      // automatically start authentication
      if (!widget.isFirstTime) {
        await Future.delayed(const Duration(milliseconds: 500)); // Small delay for UI
        _authenticate();
      }
      
    } catch (e) {
      print('DEBUG: Error checking biometrics: $e');
      setState(() {
        _errorMessage = 'Error checking biometrics: $e';
      });
    }
  }

  Future<void> _authenticate() async {
    print('DEBUG: Starting fingerprint authentication');
    
    if (!_canCheckFingerprint) {
      print('DEBUG: Cannot check biometrics');
      setState(() {
        _errorMessage = 'Fingerprint not available on this device';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check if any biometric is available
      if (_availableFingerprints.isEmpty) {
        print('DEBUG: No available biometrics');
        setState(() {
          _errorMessage = 'No fingerprint authentication methods are enrolled';
          _isLoading = false;
        });
        return;
      }

      print('DEBUG: Attempting authentication with available biometrics: ${_availableFingerprints.map((b) => b.name).join(', ')}');
      
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please verify your identity using your fingerprint',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      print('DEBUG: Authentication result: $didAuthenticate');

      if (didAuthenticate) {
        print('DEBUG: Authentication successful, saving preferences');
        await _saveBiometricPreference();
        setState(() {
          _isLoading = false;
        });
        print('DEBUG: Calling onSuccess callback');
        widget.onSuccess();
      } else {
        print('DEBUG: Authentication failed');
        setState(() {
          _errorMessage = 'Authentication failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Authentication error: $e');
      setState(() {
        _isLoading = false;
        if (e.toString().contains(auth_error.notAvailable)) {
          _errorMessage = 'Fingerprint authentication not available';
        } else if (e.toString().contains(auth_error.notEnrolled)) {
          _errorMessage = 'No fingerprint enrolled. Please set up fingerprint in Settings.';
        } else {
          _errorMessage = 'Authentication error: ${e.toString()}';
        }
      });
    }
  }

  Future<void> _saveBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    
    print('DEBUG: Saving fingerprint preference');
    
    // Save in new format (preferred)
    await prefs.setBool('fingerprintEnabled', true);
    // Also save in old format for backward compatibility
    await prefs.setBool('fingerprint_enabled', true);
    print('DEBUG: Saved fingerprintEnabled = true');
  }

  Future<void> _handleSkip() async {
    print('DEBUG: Handling skip - turning off fingerprint by default');
    final prefs = await SharedPreferences.getInstance();
    
    // Turn off fingerprint by default when skipping
    await prefs.setBool('fingerprint_enabled', false);
    await prefs.setBool('fingerprintEnabled', false);
    
    print('DEBUG: Biometrics disabled, calling onSkip');
    widget.onSkip();
  }

  String _getBiometricTitle() {
    // Always use fingerprint title
    return 'Fingerprint Authentication';
  }

  String _getBiometricDescription() {
    // Always use fingerprint description
    return 'Use your fingerprint to secure your passwords';
  }

  String _getBiometricButtonText() {
    // Always use fingerprint button text
    return 'Use Fingerprint';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: Column(
              children: [
                // Top spacing
                const SizedBox(height: 60),
                
                // Header Icon
                Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: const Color(0xFF8B2635),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  _getBiometricTitle(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B2635),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  _getBiometricDescription(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Spacer to center the main content
                const Spacer(),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Authentication Button - only show for first time setup
                if (widget.isFirstTime) ...[
                  if (_isLoading)
                    const CircularProgressIndicator(
                      color: Color(0xFF8B2635),
                    )
                  else
                    ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B2635),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fingerprint),
                          const SizedBox(width: 8),
                          Text(
                            _getBiometricButtonText(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                ] else ...[
                  // For returning users, show authentication in progress
                  if (_isLoading)
                    Column(
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF8B2635),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Authenticating...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  else if (_errorMessage.isNotEmpty)
                    ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B2635),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fingerprint),
                          const SizedBox(width: 8),
                          const Text(
                            'Try Again',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                ],

                // Spacer to center vertically
                const Spacer(),

                // Skip Button - only show if showSkipButton is true
                if (widget.showSkipButton)
                  TextButton(
                    onPressed: _handleSkip,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),

                // Bottom spacing
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
