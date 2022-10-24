import 'package:flutter/material.dart';
import 'package:qrcode_keeper/widgets/shimmer.dart';

class TextWithShimmer extends StatelessWidget {
  const TextWithShimmer({
    Key? key,
    required this.isLoading,
    required this.bgColor,
    required this.text,
    this.textScaleFactor,
    this.style,
  }) : super(key: key);

  final bool isLoading;
  final Color? bgColor;
  final String text;
  final double? textScaleFactor;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      isLoading: isLoading,
      child: Container(
        color: bgColor,
        child: Text(
          text,
          textAlign: TextAlign.center,
          textScaleFactor: textScaleFactor,
          style: style,
        ),
      ),
    );
  }
}
