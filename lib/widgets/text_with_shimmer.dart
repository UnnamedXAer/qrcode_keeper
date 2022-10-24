import 'package:flutter/material.dart';
import 'package:qrcode_keeper/widgets/shimmer.dart';

class TextWithShimmer extends StatelessWidget {
  const TextWithShimmer({
    Key? key,
    required this.isLoading,
    required this.bgColor,
    required this.text,
  }) : super(key: key);

  final bool isLoading;
  final Color? bgColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: isLoading,
      child: Container(
        color: bgColor,
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
