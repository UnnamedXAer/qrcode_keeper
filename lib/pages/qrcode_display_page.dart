import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:qrcode_keeper/helpers/qrcode_dialogs.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/models/code_unmarked.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/extensions/date_time.dart';
import 'package:qrcode_keeper/widgets/error_text.dart';
import 'package:qrcode_keeper/widgets/qrcode_done_button.dart';
import 'package:qrcode_keeper/widgets/qrcode_favorite.dart';
import 'package:qrcode_keeper/widgets/qrcode_preview.dart';
import 'package:qrcode_keeper/widgets/shimmer.dart';
import 'package:qrcode_keeper/widgets/text_with_shimmer.dart';

class QRCodeDisplayPage extends StatefulWidget {
  const QRCodeDisplayPage(
      {required PersistentTabController tabBarController, Key? key})
      : _persistentTabController = tabBarController,
        super(key: key);

  final PersistentTabController _persistentTabController;

  @override
  State<QRCodeDisplayPage> createState() => _QRCodeDisplayPageState();
}

class _QRCodeDisplayPageState extends State<QRCodeDisplayPage>
    with WidgetsBindingObserver {
  List<QRCode> _codes = [];
  int _selectedCodeIdx = -1;
  String? _error;
  bool _loading = false;
  DateTime _expirationDate = DateTime.now();
  DateTime? _screenInactivatedAt;
  bool _debugAnyCodeUsed = false;
  bool _screenChanged = false;
  int _getCodesCnt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getCodes();
    _checkForNotMarkedCode();
    widget._persistentTabController.addListener(_onScreenChangeHandler);
  }

  @override
  void dispose() {
    widget._persistentTabController.removeListener(_onScreenChangeHandler);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('didChangeAppLifecycleState, $state');

    if (state == AppLifecycleState.inactive &&
        _selectedCodeIdx != -1 &&
        !_debugAnyCodeUsed) {
      _screenInactivatedAt = DateTime.now();
      final currentCode = _codes[_selectedCodeIdx];

      if (!_screenChanged &&
          currentCode.usedAt == null &&
          (currentCode.expiresAt == null ||
              currentCode.expiresAt!.isAfter(DateTime.now()))) {
        final db = DBService();
        db.createUnmarkedCodeWarn(currentCode);
      }
    } else if (state == AppLifecycleState.resumed) {
      _checkForNotMarkedCode();
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final QRCode? code =
        _selectedCodeIdx == -1 ? null : _codes[_selectedCodeIdx];

    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code"),
      ),
      body: Shimmer(
        linearGradient: ShimmerLoading.shimmerGradient,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._buildMonthPicker(),
                    if (_error != null)
                      ErrorText(_error!)
                    else if (!_loading && _codes.isEmpty)
                      ..._buildNoCodesContent()
                    else ...[
                      ..._buildQrCodeContent(code),
                      TextWithShimmer(
                        isLoading: _loading,
                        bgColor: bgColor,
                        text:
                            'Got ${_codes.length} code${_codes.length > 1 ? 's' : ''} currently at position ${_selectedCodeIdx + 1}.',
                      ),
                      const SizedBox(height: 120),
                    ],
                  ],
                ),
              ),
            ),
            if (_loading || (_error == null && _codes.isNotEmpty))
              Positioned(
                bottom: 0,
                left: 16,
                right: 16,
                child: QRCodeDoneButton(
                  showShimmering: code == null,
                  wasUsed: code?.usedAt != null,
                  toggleCodeUsed: code == null || code.usedAt != null
                      ? null
                      : () => _markAsUsed(code.id),
                ),
              ),
          ],
        ),
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

  List<Widget> _buildNoCodesContent() {
    return [
      const Text('There are tough times in life... no codes found.',
          textScaleFactor: 1.4),
      const SizedBox(height: 16),
      const Text(
          'Scan some or report a bug if you believe there should be some unused codes for current month.'),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.center,
        child: TextButton.icon(
          onPressed: () => widget._persistentTabController.jumpToTab(2),
          icon: Stack(
            clipBehavior: Clip.none,
            children: const [
              Icon(Icons.qr_code, size: 30),
              Positioned(
                right: -6,
                top: -6,
                child: Icon(Icons.add, size: 14),
              ),
            ],
          ),
          label: const Text('Add Some Codes'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            textStyle: const TextStyle(
              fontSize: 20,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildQrCodeContent(
    QRCode? code,
  ) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final size = MediaQuery.of(context).size;
    final qrSize = size.shortestSide.clamp(
      100.0,
      (size.longestSide / 2.5).clamp(100.0, 300.0),
    );

    return [
      Stack(
        clipBehavior: Clip.none,
        children: [
          QRCodePreview(
            size: qrSize,
            value: code?.value,
          ),
          Positioned(
            right: -16,
            top: -20,
            child: ShimmerLoading(
              isLoading: _loading,
              child: QRCodeFavorite(
                onTap: code == null
                    ? null
                    : () => _toggleFavorite(_selectedCodeIdx),
                favorite: code?.favorite ?? false,
              ),
            ),
          ),
        ],
      ),
      TextWithShimmer(
        isLoading: code == null,
        bgColor: bgColor,
        text:
            'This is a not used code for the selected month.\nWhen scanned use the Done button to mark it as used.\nAfter that the app will close.',
        textScaleFactor: 0.85,
        style: TextStyle(
          color: (code?.usedAt != null ? Colors.grey : null),
        ),
      ),
      if (code?.expiresAt != null && code!.expiresAt!.isBefore(DateTime.now()))
        Text(
          'This code expired at ${code.expiresAt!.format(withTime: false)}.',
          textAlign: TextAlign.center,
        ),
      if (code?.usedAt != null)
        TextButton(
          onPressed: () {
            showDialogToggleCodeUsed(
                context, code!.id, code.usedAt != null, _unmarkUsed);
          },
          child: Text(
            'This code was used at ${code!.usedAt!.format()}.',
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          ShimmerLoading(
            debugLabel: 'Button Previous Shimmer',
            isLoading: _loading,
            child: OutlinedButton(
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
          ),
          ShimmerLoading(
            debugLabel: 'Button Next Shimmer',
            isLoading: _loading,
            child: OutlinedButton(
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
          ),
        ]),
      ),
    ];
  }

  void _checkForNotMarkedCode() async {
    if (_screenInactivatedAt != null) {
      final inactiveTime = DateTime.now().difference(_screenInactivatedAt!);

      const ignoredInactiveDuration = Duration(seconds: kReleaseMode ? 60 : 3);
      if (inactiveTime < ignoredInactiveDuration) {
        debugPrint(
            'checking for "unmarked" codes skipped due to screen inactive time less then $ignoredInactiveDuration s ($inactiveTime).');
        return;
      }
    }

    final db = DBService();

    final QrCodeUnmarked? possibleUnmarkedQRCode =
        await db.getPossibleUnmarkedQRCode();

    if (!mounted || possibleUnmarkedQRCode == null) {
      return;
    }

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsetsDirectional.only(
          start: 8.0,
          top: 8.0,
          end: 8.0,
          bottom: 0.0,
        ),
        backgroundColor: Colors.amber.shade300,
        content: Text(
          'Possibly unchecked code.\nLast time ${possibleUnmarkedQRCode.createdAt.format()} you saw code ${possibleUnmarkedQRCode.codeValue} but did not "Done" it.',
          textScaleFactor: 0.8,
        ),
        forceActionsBelow: true,
        actions: [
          Wrap(
            children: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  final db = DBService();
                  db.deleteQRUnmarkedCodes();
                },
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text(
                  'Nah, I wasn\'t using any codes',
                  textScaleFactor: 0.9,
                ),
              ),
              TextButton(
                onPressed:
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner,
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text(
                  'Yes, mark the code as used',
                  textScaleFactor: 0.9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _getCodes() {
    setState(() {
      _loading = true;
      _error = null;
    });

    _getCodesCnt++;
    final currentGetIdx = _getCodesCnt;

    final db = DBService();
    db
        .getQRCodesForMonth(
      _expirationDate,
    )
        .then(
      (value) {
        if (currentGetIdx != _getCodesCnt) {
          debugPrint('skipped, $currentGetIdx, $_getCodesCnt');
          return;
        }
        setState(() {
          _selectedCodeIdx = value.isEmpty ? -1 : 0;
          _codes = value;
          _error = null;
          _loading = false;
        });
      },
    ).catchError((err) {
      if (currentGetIdx != _getCodesCnt) {
        debugPrint('skipped, $currentGetIdx, $_getCodesCnt');
        return;
      }
      setState(() {
        _error = 'Error: $err';
        _loading = false;
      });
    });
  }

  void _markAsUsed(int id) async {
    final idx = _codes.indexWhere((c) => c.id == id);

    if (_codes[idx].usedAt != null) {
      return;
    }

    final db = DBService();
    final now = DateTime.now();
    await db.toggleCodeUsed(id, now);

    if (kReleaseMode) {
      exit(0);
    }
    _debugAnyCodeUsed = true;

    if (idx == -1) {
      return;
    }

    setState(() {
      _codes[idx] = _codes[idx].copyWith(usedAt: now);
    });
  }

  Future<void> _unmarkUsed(int id) async {
    final db = DBService();
    const now = null;
    await db.toggleCodeUsed(id, now);

    if (!mounted) {
      return;
    }

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
        favorite: _codes[idx].favorite,
      );
    });
  }

  void _toggleFavorite(int idx) {
    final db = DBService();
    setState(() {
      _codes[idx] = QRCode(
        id: _codes[idx].id,
        value: _codes[idx].value,
        createdAt: _codes[idx].createdAt,
        expiresAt: _codes[idx].expiresAt,
        usedAt: _codes[idx].usedAt,
        validForMonth: _codes[idx].validForMonth,
        favorite: !_codes[idx].favorite,
      );
    });

    db.toggleFavorite(_codes[idx].id);
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

  void _onScreenChangeHandler() {
    debugPrint('screen changed');

    if (widget._persistentTabController.index == 0) {
      if (!_loading && _codes.isEmpty) {
        _getCodes();
      }
    } else {
      if (!_screenChanged) {
        _screenChanged = widget._persistentTabController.index != 0;
        final db = DBService();
        db.deleteQRUnmarkedCodes();
      }
      ScaffoldMessenger.maybeOf(context)?.removeCurrentMaterialBanner();
    }
  }
}
