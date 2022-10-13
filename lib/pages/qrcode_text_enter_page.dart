import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qrcode_keeper/helpers/snackbar.dart';

class QRCodeTextEnterPage extends StatefulWidget {
  const QRCodeTextEnterPage({
    required List<String> codes,
    Key? key,
  })  : _prevCodes = codes,
        super(key: key);

  final List<String> _prevCodes;

  @override
  State<QRCodeTextEnterPage> createState() => _QRCodeTextEnterPageState();
}

class _QRCodeTextEnterPageState extends State<QRCodeTextEnterPage> {
  late final List<String> _codes;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codes = [...widget._prevCodes];
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.shortestSide;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRCodes from Text'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 8,
              left: 16,
              right: 16,
            ),
            child: SizedBox(
              width: maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Enter the text with codes below.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.caption,
                          textScaleFactor: 1.2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter the text with your codes to the below text field. The text will be split by any non-digit character into separate codes which will only contain digits. Eg. for input like "123456 56555-45464543g543456/88888 xxx" the resulting codes will be [ 123456, 56555, 45464543, 543456, 88888 ].',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    color: Colors.white,
                    width: maxWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: _controller,
                      maxLines: 10,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: OutlinedButton.icon(
                      onPressed: _pasteToTextField,
                      icon: const Icon(Icons.paste_outlined),
                      label: const Text('Paste'),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 32, right: 32),
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.done,
                    size: 30,
                  ),
                  label: const Text('Read & Close'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 40,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _exitHandler,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pasteToTextField() async {
    final ClipboardData? cdata = await Clipboard.getData(Clipboard.kTextPlain);

    if (!mounted) {
      return;
    }

    if ((cdata == null || cdata.text == null || cdata.text!.trim().isEmpty)) {
      SnackbarCustom.hideCurrent(context);
      SnackbarCustom.show(
        context,
        message: 'There is nothing to paste.',
        duration: const Duration(milliseconds: 750),
        mounted: mounted,
      );

      return;
    }

    final String cText = cdata.text!.trim();

    int cursorPos = _controller.selection.base.offset;
    if (cursorPos < 0) {
      cursorPos = 0;
    }

    _controller.text =
        '${_controller.text.substring(0, cursorPos)} $cText ${_controller.text.substring(cursorPos)}';

    _controller.selection = TextSelection.collapsed(
      offset: cursorPos + cText.length + 2,
    );
  }

  void _exitHandler() {
    final cleanedText = _controller.text.replaceAll(
      RegExp(
        '[^\\d]',
        multiLine: true,
        caseSensitive: false,
      ),
      ' ',
    );

    final enteredCodes = cleanedText.split(' ');
    for (var code in enteredCodes) {
      if (code.isNotEmpty && !_codes.contains(code)) {
        _codes.add(code);
      }
    }

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    Navigator.of(context).pop(_codes);
  }
}
