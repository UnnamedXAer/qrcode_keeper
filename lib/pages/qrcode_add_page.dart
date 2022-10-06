import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:qrcode_keeper/helpers/snackabar.dart';
import 'package:qrcode_keeper/pages/qrcode_scann_page.dart';
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
  final List<String> _codes = [];
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
                      _codes.isEmpty ? 'Scan code(s)' : 'Continue scanning',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      if (_saving) {
                        return;
                      }
                      final updatedCodes = await Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => QRCodeScanPage(codes: _codes),
                        ),
                      );
                      setState(() {
                        _codes.clear();
                        _codes.addAll(updatedCodes);
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
        widget._persistentTabController.jumpToTab(0);
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
}
