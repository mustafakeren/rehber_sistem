import 'package:flutter/material.dart';

class DetectedObjectsNotifier {
  static final ValueNotifier<List<String>> detectedObjects = ValueNotifier<List<String>>([]);
}