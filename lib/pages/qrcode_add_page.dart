import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrcode_keeper/helpers/snackabar.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/add_codes/scanned_codes_bottom_sheet_content.dart';
import 'package:qrcode_keeper/extensions/date_time.dart';

class QRCodeAddPage extends StatefulWidget {
  const QRCodeAddPage({Key? key}) : super(key: key);

  @override
  State<QRCodeAddPage> createState() => _QRCodeAddPageState();
}

class _QRCodeAddPageState extends State<QRCodeAddPage> {
  final List<String> _codes = [];
  final Map<String, bool> _usedCodes = {};
  bool _openCamera = false;
  bool _saving = false;
  late DateTime _expirationDate;
  bool _neverExpire = false;
  bool _validForMonth = true;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _expirationDate = DateTime(now.year, now.month + 1).subtract(
      const Duration(milliseconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.shortestSide;
    final qrSize = MediaQuery.of(context).size.shortestSide.clamp(100.0, 300.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add QR Codes"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: maxWidth,
            child: Column(
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
                              if (!_codes.contains(code)) {
                                setState(() {
                                  _codes.add(code);
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
                  child: Text('Scanned unique ${_codes.length} code(s).'),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      size: 30,
                    ),
                    label: Text(
                      _openCamera
                          ? 'Stop scanning'
                          : _codes.isEmpty
                              ? 'Scan code(s)'
                              : 'Continue scanning',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (_saving && !_openCamera) {
                        return;
                      }
                      setState(() {
                        _openCamera = !_openCamera;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _codes.clear();
                            _usedCodes.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepOrange.shade600,
                          side: BorderSide(
                            color: Colors.deepOrange.shade600,
                          ),
                        ),
                        child: const Text('Clear scanned codes'),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showBottomSheetWithCodes,
                        child: const Text('Show scanned codes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'The codes will expire at '
                  '${_neverExpire ? 'Never' : _validForMonth ? 'the end of ${_expirationDate.monthDesc()}' : _expirationDate.format(withTime: false)}',
                  textAlign: TextAlign.center,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: _neverExpire
                            ? OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade800,
                              )
                            : null,
                        onPressed: true
                            ? null
                            : () => setState(() {
                                  _neverExpire = true;
                                }),
                        icon: const Icon(Icons.timer_off_outlined),
                        label: const Text('Never'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(width: 24),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: !_neverExpire
                            ? OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade800)
                            : null,
                        onPressed: () => _selectDate(context),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          _neverExpire
                              ? 'Pick Date'
                              : _validForMonth
                                  ? _expirationDate.monthDesc()
                                  : _expirationDate.format(withTime: false),
                        ),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  enabled: false && !_neverExpire,
                  title: const Text('Valid to the end of month'),
                  value: _validForMonth && !_neverExpire,
                  onChanged: (v) {
                    setState(() {
                      _validForMonth = v ?? false;
                    });
                  },
                ),
                if (_codes.isNotEmpty)
                  Text(
                    'You have ${_codes.length} codes to save.\n'
                    '(where marked as used: ${_usedCodes.values.where((x) => x).length})',
                    textAlign: TextAlign.center,
                  ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.save_outlined,
                      size: 30,
                    ),
                    label: const Text("Save code(s)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _openCamera = false;
                      });
                      _saveCodes();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheetWithCodes() {
    if (_saving) {
      return;
    }
    setState(() {
      _openCamera = false;
    });

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return ScannedCodesBottomSheetContent(
              codes: _codes,
              usedCodes: _usedCodes,
              onCheckCode: (String code, bool v) => _usedCodes[code] = v,
              onSaveCodes: _saveCodes,
              onDeleteCode: (
                String code,
              ) {
                _usedCodes.remove(code);
                _codes.removeWhere((x) => x == code);
              });
        }).then((_) => setState(() {}));
  }

  Future<void> _saveCodes() async {
    if (_saving) return;

    if (_codes.isEmpty) {
      SnackbarCustom.show(context,
          message: '❗ Nothing to save! Idiot. Scan some codes.',
          level: MessageLevel.warning,
          action: SnackBarAction(
              label: 'Ok, sorry',
              onPressed: () {
                SnackbarCustom.hideCurrent(context);
              }));
      return;
    }

    setState(() {
      _saving = true;
    });
    final db = DBService();
    try {
      await Future.delayed(const Duration(seconds: 1));
      await db.saveQrCodes(
        codes: _codes,
        usedCodes: _usedCodes,
        expireAt: _neverExpire ? null : _expirationDate,
        validForMonth: _validForMonth,
      );
      if (mounted) {
        SnackbarCustom.show(
          context,
          message: 'saved codes successfully',
          mounted: mounted,
          level: MessageLevel.success,
        );
        Navigator.of(context).pop();
      }
    } catch (err) {
      log('Add QRs:', error: err);

      setState(() {
        _saving = false;
      });
      SnackbarCustom.show(
        context,
        message: 'save qrcodes: $err',
        mounted: mounted,
        level: MessageLevel.error,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime(2012, 1, 1),
      lastDate: DateTime(2222, 12, 31),
    );

    if (picked != null && picked != _expirationDate) {
      setState(() {
        _neverExpire = false;
        picked = picked!.add(const Duration(days: 1));
        picked = picked!.subtract(
          const Duration(milliseconds: 1),
        );

        _expirationDate = picked!;
      });
    }
  }
}
