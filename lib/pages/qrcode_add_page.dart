import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:qrcode_keeper/helpers/snackabar.dart';
import 'package:qrcode_keeper/pages/qrcode_scann_page.dart';
import 'package:qrcode_keeper/pages/qrcode_text_enter_page.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/add_codes/scanned_codes_bottom_sheet_content.dart';
import 'package:qrcode_keeper/extensions/date_time.dart';

class QRCodeAddPage extends StatefulWidget {
  const QRCodeAddPage(
      {required PersistentTabController tabBarController, Key? key})
      : _persistentTabController = tabBarController,
        super(key: key);

  final PersistentTabController _persistentTabController;

  @override
  State<QRCodeAddPage> createState() => _QRCodeAddPageState();
}

class _QRCodeAddPageState extends State<QRCodeAddPage> {
  final List<String> _enteredWithTextCodes = [];
  final List<String> _scannedCodes = [];
  final Map<String, bool> _usedCodes = {};
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
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      size: 30,
                    ),
                    label: Text(
                      _scannedCodes.isEmpty
                          ? 'Scan codes'
                          : 'Continue scanning',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _openCodesScannerPage,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  child: ElevatedButton.icon(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: const [
                        Icon(
                          Icons.edit_outlined,
                          size: 30,
                        ),
                        Positioned(
                          bottom: -5,
                          right: 0,
                          child: Icon(
                            Icons.onetwothree_outlined,
                            size: 20,
                          ),
                        )
                      ],
                    ),
                    label: Text(
                      _enteredWithTextCodes.isEmpty
                          ? 'Enter Text with Codes'
                          : 'Continue Entering',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _openCodesTextEnterPage,
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
                            _scannedCodes.clear();
                            _usedCodes.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepOrange.shade600,
                          side: BorderSide(
                            color: Colors.deepOrange.shade600,
                          ),
                        ),
                        child: const Text('Clear Added Codes'),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showBottomSheetWithCodes,
                        child: const Text('Show Added Codes'),
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
                if (_scannedCodes.isNotEmpty)
                  Text(
                    'You have ${_scannedCodes.length} codes to save.\n'
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
                    label:
                        Text("Save code${_scannedCodes.length > 1 ? 's' : ''}"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _saveCodes,
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

    showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return ScannedCodesBottomSheetContent(
              codes: _scannedCodes,
              usedCodes: _usedCodes,
              onCheckCode: (String code, bool v) => _usedCodes[code] = v,
              onSaveCodes: _saveCodes,
              onDeleteCode: (
                String code,
              ) {
                _usedCodes.remove(code);
                _scannedCodes.removeWhere((x) => x == code);
              });
        }).then((_) => setState(() {}));
  }

  Future<void> _saveCodes() async {
    if (_saving) return;

    if (_scannedCodes.isEmpty) {
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
        codes: _scannedCodes,
        usedCodes: _usedCodes,
        expireAt: _neverExpire ? null : _expirationDate,
        validForMonth: _validForMonth,
      );
      if (mounted) {
        SnackbarCustom.show(
          context,
          message:
              'saved code${_scannedCodes.length > 1 ? 's' : ''} successfully',
          mounted: mounted,
          level: MessageLevel.success,
        );
        widget._persistentTabController.jumpToTab(0);
      }
    } catch (err) {
      log('Add QRs:', error: err);

      setState(() {
        _saving = false;
      });
      SnackbarCustom.show(
        context,
        message: 'Save error: $err',
        mounted: mounted,
        level: MessageLevel.error,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showMonthYearPicker(
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

  void _openCodesTextEnterPage() async {
    if (_saving) {
      return;
    }
    final updatedCodes = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => QRCodeTextEnterPage(codes: _enteredWithTextCodes),
      ),
    );
    setState(() {
      _enteredWithTextCodes.clear();
      _enteredWithTextCodes.addAll(updatedCodes);
    });
  }

  void _openCodesScannerPage() async {
    if (_saving) {
      return;
    }
    final updatedCodes = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => QRCodeScanPage(codes: _scannedCodes),
      ),
    );
    setState(() {
      _scannedCodes.clear();
      _scannedCodes.addAll(updatedCodes);
    });
  }
}
