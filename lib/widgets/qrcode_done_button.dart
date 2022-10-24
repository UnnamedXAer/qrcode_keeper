import 'package:flutter/material.dart';
import 'package:qrcode_keeper/widgets/shimmer.dart';

class QRCodeDoneButton extends StatelessWidget {
  const QRCodeDoneButton({
    required this.wasUsed,
    required this.toggleCodeUsed,
    required this.showShimmering,
    super.key,
  });

  final bool wasUsed;
  final bool showShimmering;
  final VoidCallback? toggleCodeUsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 32,
      ),
      child: ShimmerLoading(
        debugLabel: 'Button Done Shimmer',
        isLoading: showShimmering,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.done),
          label: Text(wasUsed ? 'Already Used' : 'Done'),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey.shade300,
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
