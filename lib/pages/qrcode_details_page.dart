import 'package:flutter/material.dart';
import 'package:qrcode_keeper/extensions/date_time.dart';
import 'package:qrcode_keeper/helpers/qrcode_dialogs.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/error_text.dart';
import 'package:qrcode_keeper/widgets/qrcode_favorite.dart';
import 'package:qrcode_keeper/widgets/qrcode_done_button.dart';
import 'package:qrcode_keeper/widgets/qrcode_preview.dart';

class QrCodeDetailsPage extends StatefulWidget {
  const QrCodeDetailsPage({
    required this.id,
    super.key,
  });

  final int id;

  @override
  State<QrCodeDetailsPage> createState() => _QrCodeDetailsPageState();
}

class _QrCodeDetailsPageState extends State<QrCodeDetailsPage> {
  QRCode? _code;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _getCode(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final qrSize = MediaQuery.of(context).size.shortestSide.clamp(100.0, 300.0);
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 8,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                ErrorText(_error!)
              else if (_loading)
                const Center(child: CircularProgressIndicator()),
              if (_code != null) ...[
                QRCodePreview(
                  size: qrSize,
                  value: _code!.value,
                ),
                QRCodeFavorite(
                  favorite: _code!.favorite,
                  onTap: _toggleFavorite,
                ),
                QRCodeDoneButton(
                    id: _code!.id,
                    wasUsed: _code!.usedAt != null,
                    toggleCodeUsed: () {
                      showDialogToggleCodeUsed(
                        context,
                        _code!.id,
                        _code!.usedAt != null,
                        _toggleCodeUsed,
                      );
                    }),
                if (_code!.expiresAt != null)
                  Text(
                    'This code ${_code!.expiresAt!.isBefore(DateTime.now()) ? 'expired' : 'expires'} at ${_code!.expiresAt!.format(withTime: false)}.',
                    textAlign: TextAlign.center,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite() {
    if (_code == null) {
      return;
    }
    final db = DBService();
    db.toggleFavorite(_code!.id);
    setState(() {
      _code = _code!.copyWith(favorite: !_code!.favorite);
    });
  }

  void _getCode(int codeId, {bool toggleLoading = true}) async {
    if (toggleLoading) {
      setState(() {
        _loading = true;
      });
    }
    final db = DBService();

    final code = await db.getCode(codeId);
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _error = null;
      _code = code;
    });
  }

  Future<void> _toggleCodeUsed(int _) async {
    final db = DBService();
    final when = _code!.usedAt != null ? null : DateTime.now();
    await db.toggleCodeUsed(_code!.id, when);
    if (mounted) {
      setState(() {
        _code = QRCode(
          id: _code!.id,
          value: _code!.value,
          createdAt: _code!.createdAt,
          expiresAt: _code!.expiresAt,
          usedAt: when,
          validForMonth: _code!.validForMonth,
        );
      });
    }
  }
}
