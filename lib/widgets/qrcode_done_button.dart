import 'package:flutter/material.dart';
import 'package:qrcode_keeper/widgets/shimmer.dart';

class QRCodeDoneButton extends StatelessWidget {
  const QRCodeDoneButton({
    required this.wasUsed,
    required this.toggleCodeUsed,
    super.key,
  });

  final bool wasUsed;
  final VoidCallback? toggleCodeUsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 32,
      ),
      child: ShimmerLoading(
        isLoading: toggleCodeUsed == null,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.done),
          label: Text(wasUsed ? 'Already Used' : 'Done'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                wasUsed ? Colors.deepOrange : Colors.lightGreen.shade700,
            padding: const EdgeInsets.symmetric(vertical: 20),
            textStyle: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: toggleCodeUsed,
        ),
      ),
    );
  }
}
