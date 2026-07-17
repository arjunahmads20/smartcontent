import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    return 'https://smartcontent.pythonanywhere.com/api/v1';
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      return 'http://127.0.0.1:8000/api/v1';
    }
  }
  
  // Auth
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String me = '/auth/me/';
  
  // Career
  static const String careerDreams = '/career-dreams/';
  
  // Content
  static const String content = '/content/';
  static const String contentStats = '/content/stats/';
  
  // Membership
  static const String membershipMe = '/membership/me/';
  static const String membershipRewards = '/membership/rewards/';
  
  // Distraction
  static const String distractionApps = '/distraction/apps/';

  // Pomodoro
  static const String pomodoroThemes = '/pomodoro/themes/';
}
