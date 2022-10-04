import 'package:flutter/material.dart';
import 'package:qrcode_keeper/widgets/add_codes/qrcode_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRCode Keeper'),
      ),
      body: QRCodeList(expirationMonth: DateTime.now()),
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
