import 'package:flutter/material.dart';

class ModeProvider with ChangeNotifier {
  String _currentMode = "No Mode";

  String get currentMode => _currentMode;

  void changeMode(String newMode) {
    _currentMode = newMode;
    notifyListeners();
  }
}
