import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔥 Global notifier
ValueNotifier<String> staffPhotoNotifier = ValueNotifier('');

/// 🔥 Load from SharedPreferences
Future<void> loadStaffPhoto() async {
  final prefs = await SharedPreferences.getInstance();
  staffPhotoNotifier.value = prefs.getString("staffPhoto") ?? '';
}
