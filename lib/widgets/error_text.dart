import 'package:flutter/material.dart';

class ErrorText extends StatelessWidget {
  const ErrorText(
    String text, {
    TextAlign? textAlign,
    // AlignmentGeometry? alignment,
    Key? key,
  })  : _text = text,
        _textAlign = textAlign,
        // _alignment = alignment,
        super(key: key);

  final String _text;
  final TextAlign? _textAlign;
  // final AlignmentGeometry? _alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        _text,
        textAlign: _textAlign,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).errorColor,
        ),
      ),
    );
  }
}