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
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) => Container(
                margin: const EdgeInsets.only(top: kToolbarHeight),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDragBar(context),
                    ListTile(
                      leading:
                          const Text('Del.', style: TextStyle(fontSize: 16)),
                      title:
                          const Text('Value', style: TextStyle(fontSize: 16)),
                      trailing: TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            behavior: SnackBarBehavior.floating,
                            content:
                                const Text('Check to mark already used codes'),
                            action: SnackBarAction(
                                label: 'Ok',
                                onPressed: () {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                }),
                          ));
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          size: 16,
                        ),
                        label: const Text('Used'),
                      ),
                    ),
                    Flexible(
                      child: ListView.separated(
                        controller: scrollController,
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
                    Container(
                      padding: const EdgeInsets.only(top: 4),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                          'Total: ${codes.length} code${codes.length > 1 ? 's' : ''}.'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragBar(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Center(
        child: Container(
          height: 5,
          width: 100,
          color: Colors.blueGrey.shade300.withOpacity(0.5),
        ),
      ),
    );
  }
}
