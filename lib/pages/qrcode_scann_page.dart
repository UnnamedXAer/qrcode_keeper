import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScanPage extends StatefulWidget {
  const QRCodeScanPage({
    required List<String> codes,
    Key? key,
  })  : _prevCodes = codes,
        super(key: key);

  final List<String> _prevCodes;

  @override
  State<QRCodeScanPage> createState() => _QRCodeScanPageState();
}

class _QRCodeScanPageState extends State<QRCodeScanPage> {
  late final List<String> _codes;
  bool _openCamera = false;

  @override
  void initState() {
    super.initState();
    _codes = [...widget._prevCodes];

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _openCamera = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final qrSize = MediaQuery.of(context).size.shortestSide;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: qrSize,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    color: _openCamera ? Colors.black : Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
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
                                  if (!_codes.contains(code)) {
                                    setState(() {
                                      _codes.add(code);
                                    });
                                  }
                                }
                              },
                            )
                          : null,
                    ),
                  ),
                  Container(
                    width: qrSize,
                    margin: const EdgeInsets.only(
                      bottom: 5,
                    ),
                    padding: const EdgeInsets.all(8),
                    color: Colors.blueGrey.shade100,
                    child: Text(
                      'Got unique ${_codes.length} code${_codes.length > 1 ? 's' : ''}.',
                    ),
                  ),
                  Container(
                    color: Colors.lightBlue.shade200,
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          'Move camera around to catch all codes.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.caption,
                          textScaleFactor: 1.2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The camera will try to catch all unique codes. See the counter to know when all of your codes where scanned.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 32, right: 32),
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.done,
                    size: 30,
                  ),
                  label: const Text('Stop & Close'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 40),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(_codes);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
