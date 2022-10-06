import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/extensions/date_time.dart';

class QRCodeDisplayPage extends StatefulWidget {
  const QRCodeDisplayPage(
      {required PersistentTabController tabBarController, Key? key})
      : _persistentTabController = tabBarController,
        super(key: key);

  final PersistentTabController _persistentTabController;

  @override
  State<QRCodeDisplayPage> createState() => _QRCodeDisplayPageState();
}

class _QRCodeDisplayPageState extends State<QRCodeDisplayPage> {
  List<QRCode> _codes = [];
  int _selectedCodeIdx = -1;
  String? error;
  bool loading = false;
  DateTime _expirationDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _getCodes();
  }

  @override
  Widget build(BuildContext context) {
    final qrSize = MediaQuery.of(context).size.shortestSide.clamp(100.0, 300.0);
    final args = ModalRoute.of(context)?.settings.arguments as QRCode?;

    final QRCode? code =
        _selectedCodeIdx == -1 ? null : _codes[_selectedCodeIdx];

    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 8,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: (code == null)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildMonthPicker(),
                    const Text(
                        'There are tough times in life... no codes found.',
                        textScaleFactor: 1.4),
                    const SizedBox(height: 16),
                    const Text(
                        'Scan some or report a bug if you believe there should be some unused codes for current month.'),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                          onPressed: _getCodes,
                          child: const Text('Try to Refresh')),
                    )
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._buildMonthPicker(),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(
                        top: 8,
                        bottom: 5,
                      ),
                      width: qrSize,
                      height: qrSize,
                      child: _buildQrCode(
                        data: code.value,
                        size: qrSize,
                        onTap: _qrcodeTapped,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.blueGrey.shade200,
                      child: Text(
                        code.value,
                        textAlign: TextAlign.center,
                        textScaleFactor: 1.3,
                      ),
                    ),
                    Text(
                      'This is a random not used code for the selected month.\nWhen scanned use the Done button to mark it as used. The app will then close.',
                      textScaleFactor: 0.9,
                      style: TextStyle(
                          color: (code.usedAt != null ? Colors.grey : null)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.done),
                        label:
                            Text(code.usedAt != null ? 'Already Used' : 'Done'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.lightGreen.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: code.usedAt != null
                            ? null
                            : () => _markAsUsed(code.id),
                      ),
                    ),
                    if (code.expiresAt != null &&
                        code.expiresAt!.isBefore(DateTime.now()))
                      Text(
                        'This code expired at ${code.expiresAt!.format(withTime: false)}.',
                        textAlign: TextAlign.center,
                      ),
                    if (code.usedAt != null)
                      TextButton(
                        onPressed: () => _showDialogUnmarkUsed(code.id),
                        child: Text(
                          'This code was used at ${code.usedAt!.format()}.',
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(
                              child: const Text('Previous'),
                              onPressed: () {
                                setState(() {
                                  _selectedCodeIdx -= 1;
                                  if (_selectedCodeIdx < 0) {
                                    _selectedCodeIdx = _codes.length - 1;
                                  }
                                });
                              },
                            ),
                            OutlinedButton(
                              child: const Text('Next'),
                              onPressed: () {
                                setState(() {
                                  _selectedCodeIdx += 1;
                                  if (_selectedCodeIdx >= _codes.length) {
                                    _selectedCodeIdx = 0;
                                  }
                                });
                              },
                            ),
                          ]),
                    ),
                    Text(
                        'Got ${_codes.length} code${_codes.length > 1 ? 's' : ''} currently at position ${_selectedCodeIdx + 1}.'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQrCode({
    required String data,
    double? size,
    void Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: QrImage(
        data: data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
      ),
    );
  }

  List<Widget> _buildMonthPicker() {
    return [
      Container(
        margin: const EdgeInsets.only(
          left: 16,
          right: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Current month: '),
            OutlinedButton(
              onPressed: _selectMonth,
              child: Text(_expirationDate.monthDesc()),
            )
          ],
        ),
      ),
      Divider(
        height: 10,
        color: Colors.blueGrey.shade900,
      )
    ];
  }

  void _getCodes() {
    final db = DBService();
    loading = true;
    db
        .getCodesForMonth(
      _expirationDate,
    )
        .then(
      (value) {
        setState(() {
          _selectedCodeIdx = value.isEmpty ? -1 : 0;
          _codes = value;
          error = null;
          loading = false;
        });
      },
    ).catchError((err) {
      error = 'Error: $err';
      loading = false;
    });
  }

  void _markAsUsed(int id) async {
    final db = DBService();
    final now = DateTime.now();
    await db.toggleCodeUsed(id, now);

    if (kReleaseMode) {
      exit(0);
    }

    final idx = _codes.indexWhere((c) => c.id == id);

    if (idx == -1) {
      return;
    }

    setState(() {
      _codes[idx] = _codes[idx].copyWith(usedAt: now);
    });
  }

  void _showDialogUnmarkUsed(int id) {
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          content: const Text(
            'Undo "Done" for this code?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _unmarkUsed(id).then((value) => Navigator.of(context).pop());
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unmarkUsed(int id) async {
    final db = DBService();
    const now = null;
    await db.toggleCodeUsed(id, now);

    final idx = _codes.indexWhere((c) => c.id == id);

    if (idx == -1) {
      return;
    }

    setState(() {
      _codes[idx] = QRCode(
        id: _codes[idx].id,
        value: _codes[idx].value,
        createdAt: _codes[idx].createdAt,
        expiresAt: _codes[idx].expiresAt,
        usedAt: now,
        validForMonth: _codes[idx].validForMonth,
      );
    });
  }

  void _selectMonth() async {
    final selectedDate = await showMonthYearPicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime(2012, 1, 1),
      lastDate: DateTime(2222, 12, 31),
    );

    if (selectedDate != null) {
      _setDate(selectedDate);
    }
  }

  void _setDate(DateTime date) {
    setState(() {
      _expirationDate = date;
    });
    _getCodes();
  }

  void _qrcodeTapped() {
    final code = _codes[_selectedCodeIdx];

    showGeneralDialog(
      context: context,
      barrierColor: Theme.of(context).scaffoldBackgroundColor,
      barrierDismissible: true,
      barrierLabel: code.value,
      pageBuilder: (context, animation, secondaryAnimation) {
        final size = MediaQuery.of(context).size;
        return SafeArea(
            child: Container(
          width: size.width,
          height: size.height,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: _buildQrCode(
              data: code.value,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ));
      },
    );
  }
}
