import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrcode_keeper/widgets/shimmer.dart';

class QRCodePreview extends StatelessWidget {
  const QRCodePreview({
    required this.size,
    required this.value,
    super.key,
  });

  final double size;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.only(
            top: 8,
            bottom: 5,
          ),
          width: size,
          height: size,
          child: _buildQrCode(
            data: value,
            size: size,
            onTap: () => _qrcodeTapped(context),
          ),
        ),
        ShimmerLoading(
          debugLabel: 'QR Preview Shimmer',
          isLoading: value == null,
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.blueGrey.shade200,
            child: Text(
              value ?? ' ',
              textAlign: TextAlign.center,
              textScaleFactor: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  void _qrcodeTapped(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierColor: Theme.of(context).scaffoldBackgroundColor,
      barrierDismissible: true,
      barrierLabel: value,
      pageBuilder: (context, animation, secondaryAnimation) {
        final size = MediaQuery.of(context).size;
        return SafeArea(
          child: Container(
            width: size.width,
            height: size.height,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _buildQrCode(
                data: value,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQrCode({
    required String? data,
    double? size,
    void Function()? onTap,
  }) {
    return ShimmerLoading(
      debugLabel: 'QR Preview Value Shimmer',
      isLoading: data == null,
      child: data == null
          ? Container(
              color: Colors.white,
              width: size,
              height: size,
            )
          : GestureDetector(
              onTap: onTap,
              child: QrImage(
                data: data,
                version: QrVersions.auto,
                size: size,
                backgroundColor: Colors.white,
              ),
            ),
    );
  }
}
