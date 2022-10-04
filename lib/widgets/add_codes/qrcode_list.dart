import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/add_codes/error_text.dart';

class QRCodeList extends StatefulWidget {
  const QRCodeList({
    required this.expirationMonth,
    super.key,
  });
  final DateTime expirationMonth;

  @override
  State<QRCodeList> createState() => _QRCodeListState();
}

class _QRCodeListState extends State<QRCodeList> {
  List<QRCode> codes = [];
  String? error;
  bool loading = false;

  @override
  void didUpdateWidget(covariant QRCodeList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final db = DBService();
    loading = true;
    db
        .getCodesForMonth(widget.expirationMonth)
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

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ErrorText(error!);
    }

    if (loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (codes.isEmpty) {
      return Text('No Codes found for month: ${widget.expirationMonth.month}');
    }

    return ListView.builder(
      itemCount: codes.length,
      itemBuilder: (context, i) {
        return ListTile(
          title: Text(codes[i].value),
          subtitle: codes[i].expiresAt != null
              ? Text(codes[i].expiresAt.toString())
              : null,
        );
      },
    );
  }
}
