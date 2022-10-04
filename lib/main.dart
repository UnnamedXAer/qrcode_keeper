import 'package:flutter/material.dart';
import 'package:qrcode_keeper/pages/home_page.dart';
import 'package:qrcode_keeper/pages/qrcode_add_page.dart';
import 'package:qrcode_keeper/pages/qrcode_display_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const HomePage(),
      routes: {
        '/qr-display': (context) => const QRCodeDisplayPage(),
        '/qr-add': (context) => const QRCodeAddPage(),
      },
    );
  }
}
