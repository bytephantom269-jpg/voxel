import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class SettingsProvider with ChangeNotifier {
  int _lateHour = AppConfig.defaultLateHour;
  int _lateMinute = AppConfig.defaultLateMinute;

  int get lateHour => _lateHour;
  int get lateMinute => _lateMinute;

  String get lateTimeDisplay {
    final hour = _lateHour.toString().padLeft(2, '0');
    final minute = _lateMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool get isLateTime {
    final now = DateTime.now();
    final lateTime = DateTime(now.year, now.month, now.day, _lateHour, _lateMinute);
    return now.isAfter(lateTime) || now.isAtSameMomentAs(lateTime);
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _lateHour = prefs.getInt(AppConfig.prefLateHour) ?? AppConfig.defaultLateHour;
    _lateMinute = prefs.getInt(AppConfig.prefLateMinute) ?? AppConfig.defaultLateMinute;
    notifyListeners();
  }

  Future<void> setLateTime(int hour, int minute) async {
    _lateHour = hour;
    _lateMinute = minute;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConfig.prefLateHour, hour);
    await prefs.setInt(AppConfig.prefLateMinute, minute);
    
    notifyListeners();
  }
}
