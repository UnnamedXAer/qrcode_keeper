import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:qrcode_keeper/helpers/snackbar.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/pages/qrcode_details_page.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/error_text.dart';
import 'package:qrcode_keeper/extensions/date_time.dart';

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
  List<QRCode> _codes = [];
  String? _error;
  bool _loading = false;
  late DateTime _expirationDate;
  int _getCodesCnt = 0;

  @override
  void initState() {
    super.initState();
    _setDate(widget.expirationDate);
  }

  @override
  void didUpdateWidget(covariant QRCodeList oldWidget) {
    super.didUpdateWidget(oldWidget);

    _setDate(widget.expirationDate);
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
      includeExpired: true,
      includeUsed: true,
    )
        .then(
      (value) {
        if (currentGetIdx != _getCodesCnt) {
          debugPrint('skipped, $currentGetIdx, $_getCodesCnt');
          return;
        }
        setState(() {
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
        _error = '$err';
        _loading = false;
      });
    });
  }

  void _setDate(DateTime date) {
    setState(() {
      _expirationDate = date;
      _error = null;
    });
    _getCodes();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_error != null) {
      content = ErrorText(_error!);
    } else if (_loading) {
      content = const Center(child: CircularProgressIndicator.adaptive());
    } else if (_codes.isEmpty) {
      content =
          Text('No Codes found for month: ${_expirationDate.monthDesc()}');
    } else {
      final captionStyle = Theme.of(context).textTheme.caption;

      content = Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Expanded(
          child: ListView.builder(
            shrinkWrap: true, // TODO remove shrinkWrap & expanded
            itemCount: _codes.length,
            itemBuilder: (context, i) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ExpansionTile(
                  childrenPadding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    bottom: 8,
                  ),
                  collapsedBackgroundColor:
                      Colors.blueGrey.shade50.withOpacity(.6),
                  title: Text(_codes[i].value),
                  subtitle: _codes[i].usedAt == null
                      ? null
                      : Text(
                          _codes[i].usedAt!.format(),
                          style: captionStyle,
                        ),
                  trailing: _buildItemActions(i),
                  backgroundColor: Colors.blueGrey.shade50,
                  expandedAlignment: Alignment.topLeft,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_codes[i].usedAt != null)
                      Text(
                        'Used at: ${_codes[i].usedAt!.format(withSeconds: true)}',
                      ),
                    if (_codes[i].usedAt != null)
                      const SizedBox(
                        height: 8,
                      ),
                    Text(
                      'Added at: ${_codes[i].createdAt.format()}',
                    ),
                  ],
                ),
              );
            },
            // separatorBuilder: (context, index) => const Divider(height: 4),
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
                onPressed: _getCodes,
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

  Widget _buildItemActions(int i) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_codes[i].usedAt != null) const Icon(Icons.done),
        IconButton(
          onPressed: () => _openCodeDetails(_codes[i].id),
          icon: const Icon(Icons.remove_red_eye_outlined),
        ),
        _buildItemMenu(i),
      ],
    );
  }

  Widget _buildItemMenu(int i) {
    return PopupMenuButton(
      itemBuilder: (context) {
        return [
          if (_codes[i].usedAt != null)
            PopupMenuItem(
              child: TextButton.icon(
                onPressed: () => _showDialogUnmarkUsed(_codes[i].id),
                icon: const Icon(Icons.done),
                label: const Text('Un-Done'),
              ),
            ),
          PopupMenuItem(
            child: TextButton.icon(
              onPressed: () =>
                  _showDialogDelete(_codes[i].id, _codes[i].usedAt),
              icon: const Icon(Icons.delete_outlined),
              label: const Text('Delete'),
            ),
          ),
        ];
      },
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
      _setDate(selectedDate);
    }
  }

  void _openCodeDetails(int codeId) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) {
          return QrCodeDetailsPage(id: codeId);
        },
      ),
    ).then((value) => setState(() {}));
  }

  void _showDialogDelete(int id, DateTime? usedAt) {
    Navigator.of(context).pop();

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

    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          content: Text(
            'Delete Code: ${_codes[idx].value}?',
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
                _deleteCode(id).then((value) => Navigator.of(context).pop());
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCode(int id) async {
    final db = DBService();
    await db.deleteQRCode(id);

    setState(() {
      _codes.removeWhere((c) => c.id == id);
    });
  }

  void _showDialogUnmarkUsed(int id) {
    Navigator.of(context).pop();

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
}
