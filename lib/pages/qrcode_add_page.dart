import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrcode_keeper/widgets/add_codes/scanned_codes_bottom_sheet_content.dart';

class QRCodeAddPage extends StatefulWidget {
  const QRCodeAddPage({Key? key}) : super(key: key);

  @override
  State<QRCodeAddPage> createState() => _QRCodeAddPageState();
}

class _QRCodeAddPageState extends State<QRCodeAddPage> {
  List<String> codes = [];
  Map<String, bool> usedCodes = {};
  bool _openCamera = false;

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
                color: Colors.grey.shade200,
                width: qrSize,
                height: qrSize,
                child: _openCamera
                    ? MobileScanner(
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
                              });
                            }
                          }
                        })
                    : const Icon(
                        Icons.camera,
                        color: Colors.grey,
                      ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  bottom: 5,
                ),
                padding: const EdgeInsets.all(8),
                color: Colors.blueGrey.shade200,
                child: Text('Scanned unique ${codes.length} code(s).'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    size: 30,
                  ),
                  label: Text(
                    _openCamera
                        ? 'Stop scanning'
                        : codes.isEmpty
                            ? 'Scan code(s)'
                            : 'Continue scanning',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _openCamera = !_openCamera;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    codes.clear();
                    usedCodes.clear();
                  });
                },
                child: const Text('Clear scanned codes'),
              ),
              const SizedBox(height: 16),
              Text(
                  'checked ${usedCodes.values.where((element) => element).length}'),
              OutlinedButton(
                onPressed: _showBottomSheetWithCodes,
                child: const Text('Show codes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBottomSheetWithCodes() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return ScannedCodesBottomSheetContent(
            codes: codes,
            usedCodes: usedCodes,
            onCheckCode: (String code, bool v) => usedCodes[code] = v,
            onSaveCodes: _saveCodes,
          );
        }).then((_) => setState(() {}));
  }

  Future<void> _saveCodes() {
    return Future.delayed(const Duration(milliseconds: 300));
  }
}
