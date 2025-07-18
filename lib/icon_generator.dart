import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class IconGenerator {
  static Future<void> generateThemeIcons() async {
    final themeColors = {
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
      'Piano Black': Color(0xFF000000),
    };

    for (final entry in themeColors.entries) {
      await _generateIcon(entry.key, entry.value);
    }
  }

  static Future<void> _generateIcon(String themeName, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw background circle
    canvas.drawCircle(Offset(256, 256), 256, paint);
    
    // Draw shield icon
    final shieldPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final shieldPath = Path();
    shieldPath.moveTo(256, 100);
    shieldPath.lineTo(350, 150);
    shieldPath.lineTo(350, 300);
    shieldPath.quadraticBezierTo(350, 350, 300, 380);
    shieldPath.lineTo(256, 420);
    shieldPath.lineTo(212, 380);
    shieldPath.quadraticBezierTo(162, 350, 162, 300);
    shieldPath.lineTo(162, 150);
    shieldPath.close();
    
    canvas.drawPath(shieldPath, shieldPaint);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(512, 512);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final file = File('assets/images/icon_${themeName.toLowerCase().replaceAll(' ', '_')}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
  }
}
