import 'package:flutter/material.dart';

enum MessageLevel {
  success,
  info,
  normal,
  warning,
  error,
}

class SnackbarCustom {
  static const errorTitle = 'An error occurred!';
  static const successTitle = 'Success';
  static const warningTitle = 'Warning';

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? show(
    BuildContext context, {
    String? message,
    String? title,
    bool mounted = true,
    MessageLevel level = MessageLevel.normal,
    Duration duration = const Duration(milliseconds: 2500),
    SnackBarAction? action,
    SnackBarActionConfig? actionConfig,
  }) {
    assert(!(action != null && actionConfig != null),
        'only `action` or `actionConfig` must be not null');
    assert((title != null || message != null),
        'at least one of the `message` or `title` must not be null');

    if (mounted == false) {
      return null;
    }

    Color? bgColor;
    Color? textColor;

    switch (level) {
      case MessageLevel.success:
        bgColor = Colors.green.shade700;
        break;
      case MessageLevel.info:
        bgColor = Colors.blue;
        break;
      case MessageLevel.normal:
        // bgColor = Colors.blue.;
        break;
      case MessageLevel.warning:
        bgColor = Colors.yellow.shade700;
        textColor = Colors.black;
        break;
      case MessageLevel.error:
        bgColor = Colors.red.shade700;
        break;
      default:
    }

    final messageStyle = TextStyle(
      fontSize: Theme.of(context).textTheme.labelMedium?.fontSize,
    );

    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        content: RichText(
          maxLines: title == null ? 3 : 4,
          text: TextSpan(
            style: textColor != null ? TextStyle(color: textColor) : null,
            text: title,
            children: message == null
                ? null
                : [
                    TextSpan(
                      text: (title == null ? '' : '\n') + message,
                      style: messageStyle,
                    ),
                  ],
          ),
        ),
        duration: duration,
        action: action ??
            (actionConfig != null
                ? SnackBarAction(
                    label: actionConfig.label,
                    onPressed: actionConfig.onPressed,
                    textColor: textColor,
                  )
                : null),
      ),
    );
  }

  static void hideCurrent(
    BuildContext context, {
    SnackBarClosedReason reason = SnackBarClosedReason.hide,
    bool? mounted,
  }) {
    if (mounted == false) {
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar(reason: reason);
  }
}

class SnackBarActionConfig {
  final String label;
  final void Function() onPressed;

  SnackBarActionConfig({
    required this.label,
    required this.onPressed,
  });
}
