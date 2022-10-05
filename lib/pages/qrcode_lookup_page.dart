import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/widgets/add_codes/qrcode_list.dart';

class QRLookupPage extends StatelessWidget {
  const QRLookupPage(
      {required PersistentTabController tabBarController, Key? key})
      : _persistentTabController = tabBarController,
        super(key: key);

  final PersistentTabController _persistentTabController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRCode Keeper'),
      ),
      body: QRCodeList(
        expirationDate: DateTime.now(),
        onItemPressed: (QRCode code) {
          Navigator.of(context).pushNamed('/qr-display', arguments: code);
        },
      ),
    );
  }
}
