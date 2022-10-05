import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrcode_keeper/models/code.dart';

class QRCodeDisplayPage extends StatefulWidget {
  const QRCodeDisplayPage({Key? key}) : super(key: key);

  @override
  State<QRCodeDisplayPage> createState() => _QRCodeDisplayPageState();
}

class _QRCodeDisplayPageState extends State<QRCodeDisplayPage> {
  String qrCode = '895479044';
  bool isDone = false;
  DateTime? useDate;
  DateTime? expirationDate;
  bool isOutdated = false;

  @override
  void initState() {
    super.initState();
    expirationDate = DateTime.now().add(Duration(days: 1));
    isOutdated =
        expirationDate != null && expirationDate!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final qrSize = MediaQuery.of(context).size.shortestSide.clamp(100.0, 300.0);
    final args = ModalRoute.of(context)?.settings.arguments as QRCode?;

    final codeValue = args?.value ?? qrCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code"),
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
                  data: codeValue,
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
                  codeValue,
                  textAlign: TextAlign.center,
                  textScaleFactor: 1.3,
                ),
              ),
              Container(
                // margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.done),
                  label: Text(isDone ? 'Undone' : 'Done'),
                  style: ElevatedButton.styleFrom(
                    primary: isDone
                        ? Colors.deepOrange.shade600
                        : Colors.lightGreen.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      isDone = !isDone;
                      if (isDone) {
                        useDate = DateTime.now();
                      }
                    });
                    // Navigator.of(context).pop();
                  },
                ),
              ),
              if (!isDone && isOutdated)
                Text(
                  'This code expired at $expirationDate.',
                  textAlign: TextAlign.center,
                ),
              if (isDone && useDate != null)
                Text(
                  'This code was used at $useDate.',
                  textAlign: TextAlign.center,
                ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton(
                    child: const Text('Next'),
                    onPressed: () {
                      setState(() {
                        qrCode =
                            DateTime.now().millisecondsSinceEpoch.toString();
                      });
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
