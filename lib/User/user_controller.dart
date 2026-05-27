import 'package:flutter/material.dart';

class UserController extends ChangeNotifier {
  static final UserController _instance = UserController._internal();
  factory UserController() => _instance;
  UserController._internal();

  // Make sure this name matches exactly what the HomePage calls
  final ValueNotifier<String?> profileImagePath = ValueNotifier<String?>(null);

  void updateImage(String path) {
    profileImagePath.value = path;
  }
}
