import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

void main() async {
  try {
    final bytes = await File('assets/animations/welcome.lottie').readAsBytes();
    final composition = await LottieComposition.fromBytes(bytes);
    print('SUCCESS');
  } catch (e) {
    print('ERROR: $e');
  }
}
