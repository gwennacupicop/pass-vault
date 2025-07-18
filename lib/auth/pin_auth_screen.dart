import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PinAuthScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final bool isFirstTime;

  const PinAuthScreen({
    super.key,
    required this.onSuccess,
    this.isFirstTime = false,
  });

  @override
  State<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isLoading = false;
  String _errorMessage = '';

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
                const SizedBox(height: 40),
                
                // Header
                const Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Color(0xFF8B2635),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isFirstTime
                      ? (_isConfirming ? 'Confirm PIN' : 'Set PIN')
                      : 'Enter PIN',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B2635),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isFirstTime
                      ? (_isConfirming ? 'Re-enter your 4-digit PIN' : 'Create a 4-digit PIN')
                      : 'Enter your 4-digit PIN to continue',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // PIN Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final currentPin = _isConfirming ? _confirmPin : _pin;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < currentPin.length
                            ? const Color(0xFF8B2635)
                            : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Spacer to push keypad to center
                const Spacer(),

                // Number Keypad
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      // First row: 1, 2, 3
                      _buildNumberButton('1'),
                      _buildNumberButton('2'),
                      _buildNumberButton('3'),
                      // Second row: 4, 5, 6
                      _buildNumberButton('4'),
                      _buildNumberButton('5'),
                      _buildNumberButton('6'),
                      // Third row: 7, 8, 9
                      _buildNumberButton('7'),
                      _buildNumberButton('8'),
                      _buildNumberButton('9'),
                      // Fourth row: empty, 0, delete
                      Container(), // Empty space
                      _buildNumberButton('0'),
                      _buildDeleteButton(),
                    ],
                  ),
                ),

                // Spacer to center the keypad
                const Spacer(),

                // Loading indicator
                if (_isLoading)
                  const CircularProgressIndicator(
                    color: Color(0xFF8B2635),
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

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () {
        print('DEBUG: Number button pressed: $number');
        _onNumberPressed(number);
      },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.white,
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _onDeletePressed,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.white,
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 22,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  void _onNumberPressed(String number) {
    if (_isLoading) return;
    
    setState(() {
      _errorMessage = '';
      if (_isConfirming) {
        if (_confirmPin.length < 4) {
          _confirmPin += number;
          if (_confirmPin.length == 4) {
            _handlePinComplete();
          }
        }
      } else {
        if (_pin.length < 4) {
          _pin += number;
          if (_pin.length == 4) {
            _handlePinComplete();
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    if (_isLoading) return;
    
    setState(() {
      _errorMessage = '';
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  void _handlePinComplete() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (widget.isFirstTime) {
      if (_isConfirming) {
        if (_pin == _confirmPin) {
          await _savePinToStorage(_pin);
          widget.onSuccess();
        } else {
          setState(() {
            _errorMessage = 'PINs do not match. Try again.';
            _confirmPin = '';
            _isConfirming = false;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isConfirming = true;
          _isLoading = false;
        });
      }
    } else {
      final isValid = await _validatePin(_pin);
      if (isValid) {
        widget.onSuccess();
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. Try again.';
          _pin = '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePinToStorage(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPin = sha256.convert(utf8.encode(pin)).toString();
    await prefs.setString('user_pin', hashedPin);
  }

  Future<bool> _validatePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('user_pin');
    if (storedPin == null) return false;
    
    final hashedPin = sha256.convert(utf8.encode(pin)).toString();
    return hashedPin == storedPin;
  }
}
