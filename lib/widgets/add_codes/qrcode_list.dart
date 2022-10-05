import 'package:flutter/material.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/add_codes/error_text.dart';
import 'package:qrcode_keeper/extensions/date_time.dart';

const months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

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
  List<QRCode> codes = [];
  String? error;
  bool loading = false;
  String _month = months[0];
  late DateTime _expirationDate;

  @override
  void initState() {
    super.initState();
    _expirationDate = widget.expirationDate;
  }

  @override
  void didUpdateWidget(covariant QRCodeList oldWidget) {
    super.didUpdateWidget(oldWidget);

    _expirationDate = widget.expirationDate;
    _setMonth(months[_expirationDate.month - 1]);
  }

  void _getCodes() {
    final db = DBService();
    loading = true;
    db
        .getCodesForMonth(_expirationDate)
        .then(
          (value) => setState(() {
            codes = value;
            error = null;
            loading = false;
          }),
        )
        .catchError((err) {
      error = 'Error: $err';
      loading = false;
    });
  }

  void _setMonth(String? month) {
    setState(() {
      _month = month ?? _month;
    });
    _getCodes();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (error != null) {
      content = ErrorText(error!);
    } else if (loading) {
      content = const Center(child: CircularProgressIndicator.adaptive());
    } else if (codes.isEmpty) {
      content =
          Text('No Codes found for month: ${_expirationDate.monthDesc()}');
    } else {
      content = Expanded(
        child: ListView.builder(
          shrinkWrap: true, // TODO remove shrinkWrap & expanded
          itemCount: codes.length,
          itemBuilder: (context, i) {
            return ListTile(
              title: Text(codes[i].value),
              subtitle: codes[i].expiresAt != null
                  ? Text(codes[i].expiresAt.toString())
                  : null,
              onTap: () {
                widget.onItemPressed(codes[i]);
              },
            );
          },
        ),
      );
    }

    final items = months
        .map<DropdownMenuItem<String>>(
          (String e) => DropdownMenuItem(
            value: e,
            child: Text(e),
          ),
        )
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin:
              const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _month,
                  items: items,
                  onChanged: _setMonth,
                ),
              ],
            ),
          ),
        ),
        content,
      ],
    );
  }
}
