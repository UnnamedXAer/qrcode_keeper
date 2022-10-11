import 'package:flutter/material.dart';
import 'package:qrcode_keeper/helpers.dart';
import 'package:qrcode_keeper/my_app.dart';

void main() async {
  await initializeApp();

  runApp(const MyApp(
    flavor: 'development',
  ));
}
