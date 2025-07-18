import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'pin_auth_screen.dart';
import 'fingerprint_auth_screen.dart';

class AuthFlow extends StatefulWidget {
  final Widget child;

  const AuthFlow({super.key, required this.child});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  int _currentStep = 0;
  bool _isFirstTime = false;
  bool _isLoading = true;
  bool _shouldBypassAuth = false;
  bool _isFirstInstall = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  List<BiometricType> _availableFingerprints = [];
  BiometricType? _preferredFingerprint;
  bool _fingerprintEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if this is the first install
      final isFirstInstall = prefs.getBool('isFirstInstall') ?? true;
      
      if (isFirstInstall) {
        // First install - set up PIN authentication
        await prefs.setBool('isFirstInstall', false);
        await prefs.setBool('hasPin', true);
        
        // Check if device supports biometrics
        final canCheckBiometrics = await _localAuth.canCheckBiometrics;
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        
        BiometricType? preferredBiometric;
        if (canCheckBiometrics && availableBiometrics.isNotEmpty) {
          if (availableBiometrics.contains(BiometricType.fingerprint)) {
            preferredBiometric = BiometricType.fingerprint;
          } else if (availableBiometrics.contains(BiometricType.strong)) {
            preferredBiometric = BiometricType.strong;
          } else if (availableBiometrics.contains(BiometricType.weak)) {
            preferredBiometric = BiometricType.weak;
          } else {
            preferredBiometric = availableBiometrics.first;
          }
        }
        
        setState(() {
          _isFirstInstall = true;
          _isFirstTime = true;
          _availableFingerprints = availableBiometrics;
          _preferredFingerprint = preferredBiometric;
          _fingerprintEnabled = preferredBiometric != null;
          _isLoading = false;
        });
        return;
      }
      
      // Existing logic for returning users
      final hasPin = prefs.getBool('hasPin') ?? false;
      final fingerprintEnabled = prefs.getBool('fingerprintEnabled') ?? false;
      final fingerprintEnabledOld = prefs.getBool('fingerprint_enabled') ?? false;
      
      final anyFingerprintEnabled = fingerprintEnabled || fingerprintEnabledOld;
      
      final userPin = prefs.getString('user_pin');
      final pinActuallyExists = userPin != null && userPin.isNotEmpty;
      
      if (!hasPin && !anyFingerprintEnabled) {
        setState(() {
          _shouldBypassAuth = true;
          _isLoading = false;
        });
        _completeAuth();
        return;
      }
      
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      BiometricType? preferredBiometric;
      if (canCheckBiometrics && availableBiometrics.isNotEmpty) {
        if (availableBiometrics.contains(BiometricType.fingerprint)) {
          preferredBiometric = BiometricType.fingerprint;
        } else if (availableBiometrics.contains(BiometricType.strong)) {
          preferredBiometric = BiometricType.strong;
        } else if (availableBiometrics.contains(BiometricType.weak)) {
          preferredBiometric = BiometricType.weak;
        } else {
          preferredBiometric = availableBiometrics.first;
        }
      }
      
      setState(() {
        _isFirstTime = hasPin && !pinActuallyExists;
        _availableFingerprints = availableBiometrics;
        _preferredFingerprint = preferredBiometric;
        _fingerprintEnabled = anyFingerprintEnabled;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error checking auth status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextStep() {
    if (_isFirstTime) {
      if (_currentStep == 0) {
        // After PIN setup, go to fingerprint if available (for first install)
        if (_preferredFingerprint != null && _isFirstInstall) {
          setState(() {
            _currentStep = 1;
          });
        } else if (_preferredFingerprint != null && _fingerprintEnabled) {
          // For existing users with fingerprint enabled
          setState(() {
            _currentStep = 1;
          });
        } else {
          _completeAuth();
        }
      } else if (_currentStep == 1) {
        _completeAuth();
      }
    } else {
      if (_currentStep == 0) {
        _checkAndProceedToFingerprint();
      } else if (_currentStep == 1) {
        _completeAuth();
      }
    }
  }

  Future<void> _checkAndProceedToFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    bool fingerprintEnabled = false;
    
    if (_preferredFingerprint == BiometricType.fingerprint) {
      fingerprintEnabled = (prefs.getBool('fingerprint_enabled') ?? false) || 
                          (prefs.getBool('fingerprintEnabled') ?? false);
    } else if (_preferredFingerprint == BiometricType.strong || _preferredFingerprint == BiometricType.weak) {
      fingerprintEnabled = (prefs.getBool('fingerprint_enabled') ?? false) || 
                          (prefs.getBool('fingerprintEnabled') ?? false);
    }
    
    if (fingerprintEnabled && _preferredFingerprint != null) {
      setState(() {
        _currentStep = 1;
      });
    } else {
      _completeAuth();
    }
  }

  void _skipBiometric() {
    // If skipping during first install, keep fingerprint disabled
    if (_isFirstInstall) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('fingerprintEnabled', false);
      });
    }
    _completeAuth();
  }

  void _completeAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => widget.child),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _shouldBypassAuth) {
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
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B2635),
              ),
            ),
          ),
        ),
      );
    }

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
          child: Column(
            children: [
              // Progress indicator
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: AuthProgressIndicator(
                  currentStep: _currentStep,
                  totalSteps: (_isFirstInstall && _preferredFingerprint != null) ? 2 : 
                             (_preferredFingerprint != null && _fingerprintEnabled) ? 2 : 1,
                ),
              ),
              // Main content
              Expanded(
                child: _buildCurrentStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return PinAuthScreen(
          onSuccess: _nextStep,
          isFirstTime: _isFirstTime,
        );
      case 1:
        if (_preferredFingerprint != null) {
          bool isFingerprint = _preferredFingerprint == BiometricType.fingerprint;
          
          if (_preferredFingerprint == BiometricType.strong || 
              _preferredFingerprint == BiometricType.weak) {
            isFingerprint = true;
          }
          
          return FingerprintAuthScreen(
            onSuccess: _nextStep,
            onSkip: _skipBiometric,
            isFingerprint: isFingerprint,
            showSkipButton: _isFirstInstall, // Only show skip button on first install
            isFirstTime: _isFirstTime,
          );
        } else {
          return Container();
        }
      default:
        return Container();
    }
  }
}

// Progress indicator widget for showing authentication steps
class AuthProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const AuthProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= currentStep
                ? const Color(0xFF8B2635)
                : Colors.grey[300],
          ),
        );
      }),
    );
  }
}