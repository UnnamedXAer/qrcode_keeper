import 'package:flutter/material.dart';

Future<T?> showDialogToggleCodeUsed<T>(
  BuildContext context,
  int id,
  bool wasUsed,
  Future<void> Function(int id) onAccept,
) {
  bool isOpen = true;

  // indicates if we wait for the action to complete.
  // if true we do not allow to do any actions.
  bool isAwaiting = false;
  return showDialog<T?>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (context) {
      return WillPopScope(
        onWillPop: () {
          // will pop handles hardware back button
          if (isAwaiting) {
            return Future.value(false);
          }
          isOpen = false;
          return Future.value(true);
        },
        // `StatefulBuilder` is here for Alert action to react to the `isAwaiting` change
        // and update ui of the buttons in dialog's actions.
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            content: Text(wasUsed
                ? 'Undo "Done" for this code?'
                : 'Mark this code as used?'),
            actions: [
              TextButton(
                onPressed: isAwaiting
                    ? null
                    : () {
                        if (isAwaiting) {
                          return;
                        }
                        isOpen = false;
                        Navigator.of(context).pop();
                      },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isAwaiting
                    ? null
                    : () {
                        if (isAwaiting) {
                          return;
                        }

                        setState(() {
                          isAwaiting = true;
                        });

                        onAccept(id).whenComplete(
                          () {
                            if (!isOpen) {
                              // we do not want to use navigator actions here as the dialog is already gone
                              return;
                            }

                            // not necessary but in any case I will let it here
                            final canPop =
                                Navigator.maybeOf(context)?.canPop() ?? false;

                            if (canPop) {
                              Navigator.of(context).pop();
                            }
                          },
                        );
                      },
                child: const Text('Yes'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
