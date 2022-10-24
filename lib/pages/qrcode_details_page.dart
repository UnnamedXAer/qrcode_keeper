import 'package:flutter/material.dart';
import 'package:qrcode_keeper/extensions/date_time.dart';
import 'package:qrcode_keeper/helpers/qrcode_dialogs.dart';
import 'package:qrcode_keeper/helpers/snackbar.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/error_text.dart';
import 'package:qrcode_keeper/widgets/qrcode_favorite.dart';
import 'package:qrcode_keeper/widgets/qrcode_done_button.dart';
import 'package:qrcode_keeper/widgets/qrcode_preview.dart';
import 'package:qrcode_keeper/widgets/shimmer.dart';
import 'package:qrcode_keeper/widgets/text_with_shimmer.dart';

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
    final isLoading = _code == null || _loading;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Shimmer(
        linearGradient: ShimmerLoading.shimmerGradient,
        child: SingleChildScrollView(
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
                if (_error != null) ErrorText(_error!),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShimmerLoading(
                      isLoading: isLoading,
                      child: QRCodeFavorite(
                        favorite: _code?.favorite ?? false,
                        onTap: isLoading ? null : _toggleFavorite,
                      ),
                    ),
                    ShimmerLoading(
                      isLoading: isLoading,
                      child: IconButton(
                        onPressed: _showDeleteDialog,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ],
                ),
                QRCodePreview(
                  size: qrSize,
                  value: _code?.value,
                ),
                QRCodeDoneButton(
                  wasUsed: _code?.usedAt != null,
                  toggleCodeUsed: isLoading
                      ? null
                      : () {
                          showDialogToggleCodeUsed(
                            context,
                            _code!.id,
                            _code!.usedAt != null,
                            _toggleCodeUsed,
                          );
                        },
                ),
                if (isLoading || _code?.usedAt != null)
                  TextWithShimmer(
                    isLoading: isLoading,
                    bgColor: bgColor,
                    text:
                        'The code was used at ${_code?.usedAt?.format(withSeconds: true)}.',
                  ),
                const SizedBox(height: 8),
                if (isLoading || _code?.expiresAt != null)
                  TextWithShimmer(
                    isLoading: isLoading,
                    bgColor: bgColor,
                    text:
                        'The code ${(_code?.expiresAt?.isBefore(DateTime.now())) ?? false ? 'expired' : 'expires'} at ${_code?.expiresAt?.format(withTime: false)}.',
                  ),
              ],
            ),
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

  void _showDeleteDialog() {
    if (_code!.usedAt != null) {
      SnackbarCustom.hideCurrent(context);
      SnackbarCustom.show(
        context,
        title: "Done codes cannot be deleted",
        message: "Un-done it to delete.",
      );
      return;
    }

    showDialogDeleteCode(context, _code!, _deleteCode);
  }

  Future<void> _deleteCode(int id) async {
    final db = DBService();
    await db.deleteQRCode(id);

    if (mounted) {
      Navigator.of(context).pop();
    }
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
