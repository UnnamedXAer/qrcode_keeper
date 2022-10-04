import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeAddPage extends StatefulWidget {
  const QRCodeAddPage({Key? key}) : super(key: key);

  @override
  State<QRCodeAddPage> createState() => _QRCodeAddPageState();
}

class _QRCodeAddPageState extends State<QRCodeAddPage> {
  String qrCode = '0000';
  List<String> codes = [];

  @override
  Widget build(BuildContext context) {
    final qrSize = MediaQuery.of(context).size.shortestSide.clamp(100.0, 300.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add QR Codes"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(
                  top: 16,
                  bottom: 5,
                ),
                color: Colors.amber,
                width: qrSize,
                height: qrSize,
                child: QrImage(
                  data: qrCode,
                  version: QrVersions.auto,
                  size: qrSize,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  bottom: 5,
                ),
                padding: const EdgeInsets.all(16),
                color: Colors.blueGrey.shade200,
                child: Text(
                  qrCode,
                  textAlign: TextAlign.center,
                  textScaleFactor: 1.3,
                ),
              ),
              Container(
                // margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    size: 30,
                  ),
                  label: const Text('scan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MobileScanner(
                            allowDuplicates: false,
                            onDetect: (barcode, args) {
                              if (barcode.rawValue == null) {
                                debugPrint('Failed to scan Barcode');
                              } else {
                                final String code = barcode.rawValue!;
                                debugPrint('Barcode found! $code');
                                if (!codes.contains(code)) {
                                  setState(() {
                                    codes.add(code);
                                    qrCode = code;
                                  });
                                  Navigator.of(context).pop();
                                }
                              }
                            }),
                      ),
                    );
                  },
                ),
              ),
              Container(
                  height: 300,
                  child: ListView(children: codes.map((e) => Text(e)).toList()))
            ],
          ),
        ),
      ),
    );
  }
}
