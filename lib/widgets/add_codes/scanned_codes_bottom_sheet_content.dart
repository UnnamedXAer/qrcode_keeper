import 'package:flutter/material.dart';

class ScannedCodesBottomSheetContent extends StatelessWidget {
  final List<String> codes;
  final Map<String, bool> usedCodes;
  final void Function(String code, bool v) onCheckCode;
  final Future<void> Function() onSaveCodes;

  const ScannedCodesBottomSheetContent({
    required this.codes,
    required this.usedCodes,
    required this.onCheckCode,
    required this.onSaveCodes,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: SizedBox(
                    height: 30,
                    child: Center(
                      child: Container(
                        height: 5,
                        width: 100,
                        color: Colors.blueGrey.shade300,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Code'),
                  trailing: TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          action: SnackBarAction(
                              label: 'Ok',
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                              }),
                          content:
                              const Text('Check to mark already used codes'),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        ));
                      },
                      icon: const Icon(
                        Icons.info_outline,
                      ),
                      label: const Text('Used')),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [...codes, ...codes]
                        .map((code) => CheckboxListTile(
                            visualDensity: const VisualDensity(
                              vertical: VisualDensity.minimumDensity,
                            ),
                            dense: true,
                            title: Text(code),
                            value: usedCodes[code] ?? false,
                            onChanged: (v) {
                              setState(() {
                                onCheckCode(code, v ?? false);
                              });
                            }))
                        .toList(),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSaveCodes();
                      },
                      child: const Text('Save Codes'),
                    ),
                  ],
                )
              ]),
        );
      },
    );
    ;
  }
}
