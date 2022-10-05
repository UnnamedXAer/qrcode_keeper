import 'package:flutter/material.dart';

class ScannedCodesBottomSheetContent extends StatelessWidget {
  final List<String> codes;
  final Map<String, bool> usedCodes;
  final void Function(String code, bool v) onCheckCode;
  final Future<void> Function() onSaveCodes;
  final void Function(String) onDeleteCode;

  const ScannedCodesBottomSheetContent({
    required this.codes,
    required this.usedCodes,
    required this.onCheckCode,
    required this.onSaveCodes,
    required this.onDeleteCode,
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
                leading: const Text('Del.', style: TextStyle(fontSize: 16)),
                title: const Text('Value', style: TextStyle(fontSize: 16)),
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
                        content: const Text('Check to mark already used codes'),
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
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: codes.length,
                  itemBuilder: ((context, index) {
                    final code = codes[index];
                    return ListTile(
                      visualDensity: const VisualDensity(
                        vertical: VisualDensity.minimumDensity,
                      ),
                      dense: true,
                      leading: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              onDeleteCode(code);
                            });
                          }),
                      title: Text(code),
                      trailing: Checkbox(
                        value: usedCodes[code] ?? false,
                        onChanged: (v) {
                          setState(() {
                            onCheckCode(code, v ?? false);
                          });
                        },
                      ),
                    );
                  }),
                  separatorBuilder: (context, index) => const Divider(),
                ),
              ),
              const Expanded(child: SizedBox()),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Total: ${codes.length}.')),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
