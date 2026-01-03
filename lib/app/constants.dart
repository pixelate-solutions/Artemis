import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFA1CDF4);
  static const Color neutral = Color(0xFF595959);
  static const Color accent = Color(0xFF02C39A);

  static const Color lightBackground = Color(0xFFF4F8FB);
  static const Color darkBackground = Color(0xFF0F1418);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1A2127);
}

class AppDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration long = Duration(milliseconds: 350);
}

class BleUuids {
  static const String service = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String notifyChar = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String batteryService = '0000180F-0000-1000-8000-00805F9B34FB';
  static const String batteryLevelChar = '00002A19-0000-1000-8000-00805F9B34FB';
}

class AppSpacing {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppLimits {
  static const int maxEmergencyContacts = 5;
}
