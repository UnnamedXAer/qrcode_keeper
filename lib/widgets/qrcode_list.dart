import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/error_text.dart';
import 'package:qrcode_keeper/extensions/date_time.dart';

// const months = [
//   'January',
//   'February',
//   'March',
//   'April',
//   'May',
//   'June',
//   'July',
//   'August',
//   'September',
//   'October',
//   'November',
//   'December',
// ];

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
  String? error;
  bool loading = false;
  late DateTime _expirationDate;

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
    final db = DBService();
    loading = true;
    db
        .getCodesForMonth(
          _expirationDate,
          includeExpired: true,
          includeUsed: true,
        )
        .then(
          (value) => setState(() {
            _codes = value;
            error = null;
            loading = false;
          }),
        )
        .catchError((err) {
      error = 'Error: $err';
      loading = false;
    });
  }

  void _setDate(DateTime date) {
    setState(() {
      _expirationDate = date;
    });
    _getCodes();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Widget content;
    if (error != null) {
      content = ErrorText(error!);
    } else if (loading) {
      content = const Center(child: CircularProgressIndicator.adaptive());
    } else if (_codes.isEmpty) {
      content =
          Text('No Codes found for month: ${_expirationDate.monthDesc()}');
    } else {
      content = Expanded(
        child: ListView.separated(
            shrinkWrap: true, // TODO remove shrinkWrap & expanded
            itemCount: _codes.length,
            itemBuilder: (context, i) {
              return ListTile(
                title: Text(_codes[i].value),
                subtitle: Text(
                    '${_codes[i].expiresAt?.format()}${_codes[i].usedAt != null ? ' / ${_codes[i].usedAt!.format()}' : ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_codes[i].usedAt != null)
                      IconButton(
                        onPressed: () => _showDialogUnmarkUsed(_codes[i].id),
                        icon: const Icon(Icons.done),
                      ),
                    IconButton(
                      onPressed: _codes[i].usedAt != null
                          ? null
                          : () => _showDialogDelete(_codes[i].id),
                      icon: const Icon(Icons.delete_outlined),
                    ),
                  ],
                ),
                onTap: () {
                  widget.onItemPressed(_codes[i]);
                },
              );
            },
            separatorBuilder: ((context, index) => const Divider(
                  height: 4,
                ))),
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
            children: [
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
        ),
        content,
      ],
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

  void _showDialogDelete(int id) {
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
    const now = null;
    await db.deleteQRCodes(id);

    setState(() {
      _codes.removeWhere((c) => c.id == id);
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
}
