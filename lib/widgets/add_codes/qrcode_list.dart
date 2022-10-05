import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/add_codes/error_text.dart';
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
  List<QRCode> codes = [];
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
    } else if (codes.isEmpty) {
      content =
          Text('No Codes found for month: ${_expirationDate.monthDesc()}');
    } else {
      content = Expanded(
        child: ListView.separated(
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
            separatorBuilder: ((context, index) => const Divider(
                  height: 4,
                ))),
      );
    }

    // final items = months
    //     .map<DropdownMenuItem<String>>(
    //       (String e) => DropdownMenuItem(
    //         value: e,
    //         child: Text(e),
    //       ),
    //     )
    //     .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(
            top: 8,
            left: 16,
            right: 16,
            // bottom: 16,
          ),
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // const Text('Month: '),
              // DropdownButton<String>(
              //   hint: const Text('select'),
              //   value: _month,
              //   items: items,
              //   onChanged: _setMonth,
              // ),
              // const Text('Year: '),
              // DropdownButton<String>(
              //   hint: const Text('select'),
              //   value: _month,
              //   items: items,
              //   onChanged: _setMonth,
              // ),
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
}
