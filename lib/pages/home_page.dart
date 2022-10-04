import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRCode Keeper'),
      ),
      persistentFooterButtons: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/qr-display');
          },
          child: const Text('Display'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/qr-add');
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
