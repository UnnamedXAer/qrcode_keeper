import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:qrcode_keeper/helpers/snackbar.dart';
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
  final List<String> _codes = [];
  final Map<String, bool> _usedCodes = {};
  bool _saving = false;
  late DateTime _expirationDate;
  bool _neverExpire = false;
  bool _validForMonth = true;

  @override
  void initState() {
    super.initState();

    _setDefaultExpirationDate();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.shortestSide;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add QR Codes"),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: maxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add your codes by scanning them or entering text',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 16),
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          size: 30,
                        ),
                        label: const Text('Scan codes'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _openAddCodesPage(
                          (context) => QRCodeScanPage(codes: _codes),
                        ),
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
                        label: const Text('Enter Text with Codes'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _openAddCodesPage(
                          (c) => QRCodeTextEnterPage(codes: _codes),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _codes.isNotEmpty ? _showClearAllDialog : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepOrange.shade400,
                        side: _codes.isNotEmpty
                            ? BorderSide(
                                color: Colors.deepOrange.shade200,
                              )
                            : null,
                      ),
                      icon: Stack(
                        children: const [
                          Icon(Icons.circle_outlined),
                          Positioned.fill(
                            child: Icon(
                              Icons.clear_outlined,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      label: const Text('Clear Added Codes'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select month for the codes.',
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
                    Text(
                      'The codes will expire at '
                      '${_neverExpire ? 'Never' : _validForMonth ? 'the end of ${_expirationDate.monthDesc()}' : _expirationDate.format(withTime: false)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.caption,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _showBottomSheetWithCodes,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Show Added Codes'),
                    ),
                    if (_codes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'You have ${_codes.length} codes to save.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.titleLarge?.fontSize,
                        ),
                      ),
                      Text(
                        '(where marked as used: ${_usedCodes.values.where((x) => x).length})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.titleMedium?.fontSize,
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.save_outlined,
                    size: 30,
                  ),
                  label: Text("Save code${_codes.length > 1 ? 's' : ''}"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 40,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _saveCodes,
                ),
              ),
            ),
          ),
        ],
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
      isDismissible: true,
      backgroundColor: Colors.transparent,
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
          },
        );
      },
    ).then((_) => setState(() {}));
  }

  Future<void> _saveCodes() async {
    if (_saving) return;

    if (_codes.isEmpty) {
      SnackbarCustom.show(
        context,
        message: '❗ Nothing to save! Idiot. Scan some codes.',
        level: MessageLevel.warning,
        action: SnackBarAction(
          label: 'Ok, sorry',
          onPressed: () {
            SnackbarCustom.hideCurrent(context);
          },
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });
    final db = DBService();
    try {
      await db.saveQRCodes(
        codes: _codes,
        usedCodes: _usedCodes,
        expireAt: _neverExpire ? null : _expirationDate,
        validForMonth: _validForMonth,
      );
      if (mounted) {
        SnackbarCustom.hideCurrent(context);
        SnackbarCustom.show(
          context,
          message: 'saved code${_codes.length > 1 ? 's' : ''} successfully',
          level: MessageLevel.success,
        );

        // widget._resetState();
        _resetState();
        // widget._persistentTabController.jumpToTab(0);
      }
    } catch (err) {
      log('Add QRs:', error: err);

      setState(() {
        _saving = false;
      });
      SnackbarCustom.hideCurrent(context, mounted: mounted);
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

  void _openAddCodesPage(Widget Function(BuildContext) pageBuilder) async {
    if (_saving) {
      return;
    }

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final updatedCodes = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: pageBuilder,
      ),
    );
    if (updatedCodes != null) {
      setState(() {
        _codes.clear();
        _codes.addAll(updatedCodes);
      });
    }
  }

  void _showClearAllDialog() {
    if (_saving) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Clear codes?',
          ),
          content: const Text(
            'This will reset list of currently added, not saved codes. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                textScaleFactor: 1.2,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _codes.clear();
                  _usedCodes.clear();
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                'Yes',
                textScaleFactor: 1.2,
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetState() {
    if (mounted) {
      setState(() {
        _neverExpire = false;
        _saving = false;
        _validForMonth = true;
        _codes.clear();
        _usedCodes.clear();
        _setDefaultExpirationDate();
      });
    }
  }

  void _setDefaultExpirationDate() {
    final now = DateTime.now();
    _expirationDate = DateTime(now.year, now.month + 1).subtract(
      const Duration(milliseconds: 1),
    );
  }
}
