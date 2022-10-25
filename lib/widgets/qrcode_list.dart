import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:qrcode_keeper/helpers/qrcode_dialogs.dart';
import 'package:qrcode_keeper/helpers/snackbar.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/pages/qrcode_details_page.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/error_text.dart';
import 'package:qrcode_keeper/extensions/date_time.dart';
import 'package:qrcode_keeper/widgets/shimmer.dart';

class QRCodeList extends StatefulWidget {
  const QRCodeList({
    required this.expirationDate,
    required this.onItemPressed,
    super.key,
  });
  final DateTime expirationDate;
  final void Function(QRCode) onItemPressed;

  @override
  State<QRCodeList> createState() => _QRCodeListState();
}

class _QRCodeListState extends State<QRCodeList> {
  late List<QRCode> _codes;
  String? _error;
  bool _loading = false;
  late DateTime _expirationDate;
  int _getCodesCnt = 0;

  @override
  void initState() {
    super.initState();
    _getCodes(widget.expirationDate);
  }

  @override
  void didUpdateWidget(covariant QRCodeList oldWidget) {
    super.didUpdateWidget(oldWidget);

    _getCodes(widget.expirationDate);
  }

  void _getCodes(DateTime month) async {
    setState(() {
      _expirationDate = month;
      _codes = _generatePlaceholderCodes();
      _loading = true;
      _error = null;
    });
    _getCodesCnt++;
    final currentGetIdx = _getCodesCnt;

    final db = DBService();
    try {
      final monthCodes = await db.getQRCodesForMonth(
        _expirationDate,
        includeExpired: true,
        includeUsed: true,
      );
      if (currentGetIdx != _getCodesCnt) {
        debugPrint('skipped, $currentGetIdx, $_getCodesCnt');
        return;
      }
      setState(() {
        _codes = monthCodes;
        _error = null;
        _loading = false;
      });
    } catch (err) {
      if (currentGetIdx != _getCodesCnt) {
        debugPrint('skipped, $currentGetIdx, $_getCodesCnt');
        return;
      }
      setState(() {
        _codes = [];
        _error = '$err';
        _loading = false;
      });
    }
  }

  List<QRCode> _generatePlaceholderCodes() {
    final dt = DateTime.now();
    final number = Random(dt.millisecondsSinceEpoch).nextInt(4);

    return List.generate(
      number + 3,
      (index) => QRCode(
        value: '',
        createdAt: dt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_error != null) {
      content = ErrorText(_error!);
    } else if (!_loading && _codes.isEmpty) {
      content = Text('No Codes found for: ${_expirationDate.monthDesc()}');
    } else {
      final captionStyle = Theme.of(context).textTheme.caption;

      content = Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Expanded(
          child: Shimmer(
            linearGradient: ShimmerLoading.shimmerGradient,
            child: ListView.builder(
              shrinkWrap: true, // TODO remove shrinkWrap & expanded
              itemCount: _codes.length,
              itemBuilder: (context, i) {
                final code = _codes[i];

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ShimmerLoading(
                    isLoading: _loading,
                    child: ExpansionTile(
                      childrenPadding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        bottom: 8,
                      ),
                      collapsedBackgroundColor:
                          Colors.blueGrey.shade50.withOpacity(.6),
                      title: Text(code.value),
                      subtitle: code.usedAt == null
                          ? null
                          : Text(
                              code.usedAt!.format(),
                              style: captionStyle,
                            ),
                      trailing: _buildItemActions(code),
                      backgroundColor: Colors.blueGrey.shade50,
                      expandedAlignment: Alignment.topLeft,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (code.usedAt != null)
                          Text(
                            'Used at: ${code.usedAt!.format(withSeconds: true)}',
                          ),
                        if (code.usedAt != null)
                          const SizedBox(
                            height: 8,
                          ),
                        Text(
                          'Added at: ${code.createdAt.format()}',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(
            top: 8,
            left: 16,
            right: 16,
          ),
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Month: '),
              OutlinedButton(
                onPressed: _selectMonth,
                child: Text(
                  _expirationDate.monthDesc(),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => _getCodes(_expirationDate),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Divider(
          height: 10,
          color: Colors.blueGrey.shade900,
        ),
        content,
      ],
    );
  }

  Widget? _buildItemActions(QRCode code) {
    if (_loading) {
      return null;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (code.favorite)
          Icon(
            Icons.money_outlined,
            color: Colors.amber.shade400,
          )
        else
          const SizedBox(
            width: 24,
          ),
        if (code.usedAt != null)
          const Icon(Icons.done)
        else
          const SizedBox(
            width: 24,
          ),
        IconButton(
          onPressed: () => _openCodeDetails(code.id),
          icon: const Icon(Icons.remove_red_eye_outlined),
        ),
        _buildItemMenu(code),
      ],
    );
  }

  Widget _buildItemMenu(QRCode code) {
    return PopupMenuButton(
      itemBuilder: (context) {
        return [
          if (code.usedAt != null)
            _buildMenuItem(
              () => _showDialogUnmarkUsed(code.id),
              'Un-Done',
              Icons.done,
            ),
          _buildMenuItem(
            () => _toggleFavorite(code.id),
            'Favorite',
            Icons.money_outlined,
          ),
          _buildMenuItem(
            () => _showDialogDelete(code.id, code.usedAt),
            'Delete',
            Icons.delete_outlined,
          ),
        ];
      },
    );
  }

  PopupMenuItem _buildMenuItem(
    VoidCallback onTap,
    String text,
    IconData iconData,
  ) {
    return PopupMenuItem(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(iconData),
          const SizedBox(width: 16),
          Text(text),
        ],
      ),
    );
  }

  void _selectMonth() async {
    final selectedDate = await showMonthYearPicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime(2012, 1, 1),
      lastDate: DateTime(2222, 12, 31),
    );

    if (selectedDate != null) {
      _getCodes(selectedDate);
    }
  }

  void _openCodeDetails(int codeId) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) {
          return QrCodeDetailsPage(id: codeId);
        },
      ),
    ).then((value) => _getCodes(_expirationDate));
  }

  void _showDialogDelete(int id, DateTime? usedAt) {
    if (usedAt != null) {
      SnackbarCustom.hideCurrent(context);
      SnackbarCustom.show(
        context,
        title: "Done codes cannot be deleted",
        message: "Un-done it to delete.",
      );
      return;
    }

    final idx = _codes.indexWhere((c) => c.id == id);

    showDialogDeleteCode(context, _codes[idx], _deleteCode);
  }

  Future<void> _deleteCode(int id) async {
    final db = DBService();
    await db.deleteQRCode(id);

    setState(() {
      _codes.removeWhere((c) => c.id == id);
    });
  }

  void _toggleFavorite(int id) async {
    final db = DBService();
    await db.toggleFavorite(id);

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
        usedAt: _codes[idx].usedAt,
        validForMonth: _codes[idx].validForMonth,
        favorite: !_codes[idx].favorite,
      );
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

    _getCodes(_expirationDate);
  }
}
